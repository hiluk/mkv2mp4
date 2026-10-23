//! Распознавание речи для роликов: Whisper (whisper.cpp, локально, на GPU) превращает звук
//! в реплики с таймингами, Claude Haiku вычитывает текст: исправляет неверно услышанные слова,
//! пунктуацию и убирает «галлюцинации» Whisper на тишине («Субтитры сделаны…»).
//!
//! Настройки (ключ API, язык, модель) читаются из переменных окружения и файлов .env:
//! `./.env` и `~/Library/Application Support/MKV2MP4/.env`.

use std::collections::HashMap;
use std::ffi::OsString;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, RecvTimeoutError};
use std::thread;
use std::time::Duration;

use serde_json::{json, Value};

use crate::shorts::{Cue, ShortsEvent};
use crate::{find_tool, run_ffmpeg_args, Error};

pub(crate) const CLAUDE_MODEL: &str = "claude-haiku-5-5";
const API_URL: &str = "https://api.anthropic.com/v1/messages";
const DEFAULT_WHISPER_MODEL: &str = "large-v3-turbo-q5_0";
const MODEL_URL: &str = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main";
/// Реплик в одном запросе к Claude.
const CHUNK: usize = 80;
/// Максимальная длина реплики Whisper в символах (около двух строк на экране).
const MAX_CUE_CHARS: &str = "84";
/// Время слов по DTW запаздывает примерно на 0,15–0,3 с: показываем слово чуть раньше.
const DTW_LEAD: f64 = 0.15;

const ENV_TEMPLATE: &str = "\
# Настройки распознавания речи MKV2MP4.

# Ключ Claude API (Claude Console → API Keys). Нужен для вычитки текста моделью
# Claude Haiku; без ключа в ролики идёт текст Whisper как есть.
ANTHROPIC_API_KEY=

# Язык речи: ru, en, uk, … или auto (определить по началу записи).
WHISPER_LANGUAGE=auto

# Модель Whisper, скачивается при первом распознавании:
# large-v3-turbo-q5_0 (574 МБ, по умолчанию), large-v3-turbo (1,6 ГБ), medium, small, base.
WHISPER_MODEL=large-v3-turbo-q5_0
";

const SYSTEM_PROMPT: &str = "\
You proofread automatic speech recognition (Whisper) output that will be burned into \
short-form video subtitles. The user message is JSON: {\"lines\": [{\"id\", \"text\"}]}, \
consecutive fragments of one recording in order.

For every input line return one output line with the same id:
- Fix misrecognized words using the surrounding context, and fix spelling, punctuation \
and capitalization.
- Whisper spells names, brands, products and technical terms phonetically. Write them the \
way they are normally written in this kind of text, in Latin script when that is the usual \
spelling of a software product or company name.
- Restore short words Whisper dropped (conjunctions, prepositions, particles) when the \
sentence is clearly broken without them.
- Otherwise keep the speaker's language and wording. Do not translate, paraphrase, \
summarize or censor, and do not move words between lines: timings are tied to each line.
- If a line is not real speech (a Whisper hallucination on silence or music, such as \
subtitle credits, \"Thanks for watching\", \"Продолжение следует\", or a phrase looping \
over and over), return it with empty text.";

// ---------------------------------------------------------------------------
// Настройки

pub struct Config {
    pub api_key: Option<String>,
    pub language: String,
    pub whisper_model: String,
}

/// Папка настроек и моделей: `~/Library/Application Support/MKV2MP4`.
pub fn data_dir() -> PathBuf {
    let home = std::env::var_os("HOME").map_or_else(|| PathBuf::from("."), PathBuf::from);
    home.join("Library/Application Support/MKV2MP4")
}

/// Файл .env в папке настроек.
pub fn env_file() -> PathBuf {
    data_dir().join(".env")
}

/// Создаёт .env с пустым ключом, если его ещё нет. Возвращает путь к нему.
pub fn ensure_env_file() -> Result<PathBuf, Error> {
    let path = env_file();
    if !path.exists() {
        let io = |e: std::io::Error| Error::Failed(format!("{}: {e}", path.display()));
        fs::create_dir_all(data_dir()).map_err(io)?;
        fs::write(&path, ENV_TEMPLATE).map_err(io)?;
    }
    Ok(path)
}

impl Config {
    /// Переменные окружения важнее `./.env`, а он важнее .env в папке настроек.
    /// Пустое значение (как в заготовке `KEY=`) ничего не перекрывает.
    pub fn load() -> Self {
        let mut vars = HashMap::new();
        for path in [env_file(), PathBuf::from(".env")] {
            if let Ok(text) = fs::read_to_string(&path) {
                vars.extend(parse_env(&text).into_iter().filter(|(_, v)| !v.is_empty()));
            }
        }
        let get = |key: &str| {
            std::env::var(key)
                .ok()
                .or_else(|| vars.get(key).cloned())
                .map(|v| v.trim().to_string())
                .filter(|v| !v.is_empty())
        };
        Self {
            api_key: get("ANTHROPIC_API_KEY"),
            language: get("WHISPER_LANGUAGE").unwrap_or_else(|| "auto".into()),
            whisper_model: get("WHISPER_MODEL").unwrap_or_else(|| DEFAULT_WHISPER_MODEL.into()),
        }
    }
}

/// Строки `KEY=value`; поддерживаются комментарии `#`, `export` и кавычки.
fn parse_env(text: &str) -> HashMap<String, String> {
    let mut vars = HashMap::new();
    for line in text.lines() {
        let line = line.trim();
        let line = line.strip_prefix("export ").unwrap_or(line);
        if line.starts_with('#') {
            continue;
        }
        let Some((key, value)) = line.split_once('=') else { continue };
        let value = value.trim();
        let value = match value.chars().next() {
            Some(q @ ('"' | '\'')) => value[1..].split(q).next().unwrap_or(""),
            _ => value.split(" #").next().unwrap_or("").trim_end(),
        };
        vars.insert(key.trim().to_string(), value.to_string());
    }
    vars
}

/// Ищет whisper-cli так же, как ffmpeg; путь можно задать в `MKV2MP4_WHISPER`.
pub fn find_whisper() -> PathBuf {
    find_tool("whisper-cli", "MKV2MP4_WHISPER")
}

// ---------------------------------------------------------------------------
// Распознавание

pub struct SpeechOptions<'a> {
    pub ffmpeg: &'a Path,
    /// Номер аудиодорожки среди аудио.
    pub audio_track: u32,
    /// Длительность видео в секундах (для прогресса).
    pub duration: f64,
    pub cancel: Option<&'a AtomicBool>,
}

fn cancelled(cancel: Option<&AtomicBool>) -> bool {
    cancel.is_some_and(|c| c.load(Ordering::Relaxed))
}

/// Распознаёт речь в `input` и вычитывает текст через Claude, если задан ключ.
/// Временные файлы кладутся в `tmp`.
pub fn transcribe(
    input: &Path,
    tmp: &Path,
    opts: &SpeechOptions,
    on_event: &mut dyn FnMut(ShortsEvent),
) -> Result<Vec<Cue>, Error> {
    let cfg = Config::load();
    let whisper = find_whisper();
    if !crate::check_tool(&whisper, "--help") {
        return Err(Error::Failed(format!("не найден whisper-cli ({})", whisper.display())));
    }

    let model = data_dir().join("models").join(format!("ggml-{}.bin", cfg.whisper_model));
    ensure_model(&model, &cfg.whisper_model, opts.cancel, on_event)?;

    on_event(ShortsEvent::Stage("Извлекаю звук".into()));
    on_event(ShortsEvent::Progress(0.0));
    let wav = tmp.join("speech.wav");
    let args: Vec<OsString> = ["-i".into(), input.into()]
        .into_iter()
        .chain(
            ["-map", &format!("0:a:{}", opts.audio_track), "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le"]
                .iter()
                .map(OsString::from),
        )
        .chain([wav.clone().into()])
        .collect();
    run_ffmpeg_args(opts.ffmpeg, &args, Some((opts.duration * 1e6) as u64), opts.cancel, &mut |p| {
        on_event(ShortsEvent::Progress(p))
    })?;

    on_event(ShortsEvent::Stage("Распознаю речь (Whisper)".into()));
    on_event(ShortsEvent::Progress(0.0));
    let out_base = tmp.join("speech");
    let dtw = dtw_preset(&cfg.whisper_model);
    run_whisper(&whisper, &model, &wav, &cfg.language, dtw, &out_base, opts.cancel, &mut |p| {
        on_event(ShortsEvent::Progress(p))
    })?;
    // Токены бывают обрезаны посреди UTF-8 символа, поэтому читаем без строгой проверки.
    let json = fs::read(out_base.with_extension("json"))
        .map_err(|e| Error::Failed(format!("Whisper не записал результат: {e}")))?;
    let mut cues = parse_whisper_json(&String::from_utf8_lossy(&json))?;
    if cues.is_empty() {
        return Err(Error::Failed("Whisper не нашёл в звуке речи".into()));
    }

    let Some(key) = cfg.api_key else {
        on_event(ShortsEvent::Warning(format!(
            "ANTHROPIC_API_KEY не задан ({}), текст без вычитки Claude",
            env_file().display()
        )));
        return Ok(cues);
    };
    on_event(ShortsEvent::Stage("Вычитываю текст (Claude Haiku)".into()));
    on_event(ShortsEvent::Progress(0.0));
    let (polished, failure) = polish(&cues, &key, opts.cancel, &mut |p| on_event(ShortsEvent::Progress(p)))?;
    if let Some(msg) = failure {
        on_event(ShortsEvent::Warning(msg));
    }
    cues = polished;
    if cues.is_empty() {
        return Err(Error::Failed("после вычитки не осталось речи".into()));
    }
    Ok(cues)
}

/// Скачивает модель Whisper, если её ещё нет.
fn ensure_model(
    path: &Path,
    name: &str,
    cancel: Option<&AtomicBool>,
    on_event: &mut dyn FnMut(ShortsEvent),
) -> Result<(), Error> {
    if path.is_file() {
        return Ok(());
    }
    on_event(ShortsEvent::Stage(format!("Скачиваю модель Whisper {name} (один раз)")));
    on_event(ShortsEvent::Progress(0.0));
    let fail = |e: String| Error::Failed(format!("не удалось скачать модель Whisper {name}: {e}"));
    let agent = ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(30))
        .timeout_read(Duration::from_secs(60))
        .build();
    let resp = agent
        .get(&format!("{MODEL_URL}/ggml-{name}.bin"))
        .call()
        .map_err(|e| fail(e.to_string()))?;
    let total: Option<u64> = resp.header("Content-Length").and_then(|v| v.parse().ok());

    let dir = path.parent().expect("у модели есть папка");
    fs::create_dir_all(dir).map_err(|e| fail(e.to_string()))?;
    let part = path.with_extension("part");
    let result = (|| {
        let mut file = File::create(&part).map_err(|e| fail(e.to_string()))?;
        let mut reader = resp.into_reader();
        let mut buf = vec![0u8; 1 << 20];
        let mut done = 0u64;
        loop {
            if cancelled(cancel) {
                return Err(Error::Cancelled);
            }
            let n = reader.read(&mut buf).map_err(|e| fail(e.to_string()))?;
            if n == 0 {
                break;
            }
            file.write_all(&buf[..n]).map_err(|e| fail(e.to_string()))?;
            done += n as u64;
            if let Some(total) = total.filter(|&t| t > 0) {
                on_event(ShortsEvent::Progress(done as f64 / total as f64));
            }
        }
        if total.is_some_and(|t| t != done) {
            return Err(fail("загрузка оборвалась".into()));
        }
        fs::rename(&part, path).map_err(|e| fail(e.to_string()))
    })();
    if result.is_err() {
        let _ = fs::remove_file(&part);
    }
    result
}

/// Набор «голов внимания» для точного времени слов (DTW) под модель, если он известен.
fn dtw_preset(model: &str) -> Option<String> {
    const KNOWN: &[&str] = &[
        "tiny", "tiny.en", "base", "base.en", "small", "small.en", "medium", "medium.en",
        "large.v1", "large.v2", "large.v3", "large.v3.turbo",
    ];
    // large-v3-turbo-q5_0 → large.v3.turbo
    let name = model.split("-q").next().unwrap_or(model).replace('-', ".");
    KNOWN.contains(&name.as_str()).then_some(name)
}

/// Запускает whisper-cli; результат — `<out_base>.json` с токенами.
#[allow(clippy::too_many_arguments)]
fn run_whisper(
    whisper: &Path,
    model: &Path,
    wav: &Path,
    language: &str,
    dtw: Option<String>,
    out_base: &Path,
    cancel: Option<&AtomicBool>,
    on_progress: &mut dyn FnMut(f64),
) -> Result<(), Error> {
    let threads = thread::available_parallelism().map_or(4, |n| n.get().min(8));
    let mut cmd = Command::new(whisper);
    if let Some(preset) = dtw {
        // DTW считается только без flash attention.
        cmd.args(["-nfa", "-dtw", &preset]);
    }
    let mut child = cmd
        .arg("-m")
        .arg(model)
        .arg("-f")
        .arg(wav)
        .args(["-l", language, "-t", &threads.to_string(), "-ml", MAX_CUE_CHARS, "-sow"])
        // Без контекста предыдущего текста: иначе после музыки Whisper зацикливается
        // на галлюцинации («Субтитры делал …») и пропускает минуты настоящей речи.
        .args(["-mc", "0"])
        .args(["-ojf", "-pp", "-np", "-of"])
        .arg(out_base)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| Error::Failed(format!("не удалось запустить whisper-cli: {e}")))?;

    // stderr читаем в отдельном потоке, чтобы проверять отмену, даже когда Whisper молчит.
    let stderr = child.stderr.take().expect("stderr piped");
    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        for line in BufReader::new(stderr).lines().map_while(Result::ok) {
            if tx.send(line).is_err() {
                break;
            }
        }
    });

    let mut last_line = String::new();
    loop {
        if cancelled(cancel) {
            let _ = child.kill();
            let _ = child.wait();
            return Err(Error::Cancelled);
        }
        match rx.recv_timeout(Duration::from_millis(200)) {
            Ok(line) => match parse_progress(&line) {
                Some(p) => on_progress(p),
                None if !line.trim().is_empty() => last_line = line,
                None => {}
            },
            Err(RecvTimeoutError::Timeout) => {}
            Err(RecvTimeoutError::Disconnected) => break,
        }
    }
    let status = child.wait().map_err(|e| Error::Failed(e.to_string()))?;
    if status.success() {
        Ok(())
    } else {
        Err(Error::Failed(format!("Whisper: {}", last_line.trim())))
    }
}

/// "whisper_print_progress_callback: progress =  42%" → 0.42
fn parse_progress(line: &str) -> Option<f64> {
    let rest = line.split("progress =").nth(1)?;
    let pct: f64 = rest.trim().trim_end_matches('%').trim().parse().ok()?;
    Some((pct / 100.0).clamp(0.0, 1.0))
}

/// Реплики из JSON whisper-cli (`-ojf`), с временем слов из токенов.
fn parse_whisper_json(text: &str) -> Result<Vec<Cue>, Error> {
    let v: Value = serde_json::from_str(text)
        .map_err(|e| Error::Failed(format!("не удалось разобрать результат Whisper: {e}")))?;
    let mut cues = Vec::new();
    for seg in v["transcription"].as_array().into_iter().flatten() {
        let ms = |k: &str| seg["offsets"][k].as_f64().map(|t| t / 1000.0);
        let (Some(mut start), Some(mut end)) = (ms("from"), ms("to")) else { continue };
        let raw = seg["text"].as_str().unwrap_or("");
        let text = raw.trim();
        // [BLANK_AUDIO], [Музыка] и т. п. — не речь.
        let marker = text.starts_with('[') && text.ends_with(']');
        if text.is_empty() || marker || end <= start || is_hallucination(text) {
            continue;
        }
        let lead = raw.chars().take_while(|c| c.is_whitespace()).count();
        let total = text.chars().count() as f64;
        let words: Vec<(f64, f64)> = word_starts(seg["tokens"].as_array().map_or(&[], Vec::as_slice), raw)
            .into_iter()
            .filter(|&(ch, _)| ch >= lead)
            .map(|(ch, t)| ((ch - lead) as f64 / total, t))
            .collect();
        // Сегмент Whisper бывает намного длиннее фразы (захватывает паузу или музыку):
        // подрезаем по времени слов, чтобы текст не висел на экране до того, как его скажут.
        if let (Some(&(_, first)), Some(&(last_frac, last))) = (words.first(), words.last()) {
            if first > start + 1.0 && first < end {
                start = first;
            }
            let tail = (1.0 - last_frac) * total * 0.08 + 0.5;
            if last > start && end > last + tail + 1.0 {
                end = last + tail;
            }
        }
        let words = words.into_iter().map(|(f, t)| (f, t.clamp(start, end))).collect();
        cues.push(Cue { start, end, text: text.to_string(), words });
    }
    Ok(drop_repeats(cues))
}

/// Типичные галлюцинации Whisper на музыке и тишине: подписи авторов субтитров из его
/// обучающих данных, «Продолжение следует», надписи капсом вроде «ДИНАМИЧНАЯ МУЗЫКА».
fn is_hallucination(text: &str) -> bool {
    const PHRASES: &[&str] = &[
        "субтитры делал", "субтитры создавал", "субтитры сделал", "субтитры сделаны",
        "субтитры подготовил", "добавил субтитры", "редактор субтитров", "корректор субтитров",
        "subtitles by", "продолжение следует", "спасибо за просмотр", "thanks for watching",
        "dimatorzok", "amara.org",
    ];
    let lower = text.to_lowercase();
    if PHRASES.iter().any(|p| lower.contains(p)) {
        return true;
    }
    let words: Vec<&str> = text.split_whitespace().filter(|w| w.chars().any(char::is_alphabetic)).collect();
    words.len() >= 2 && text.chars().filter(|c| c.is_alphabetic()).all(char::is_uppercase)
}

/// Одна и та же фраза три раза подряд и больше — петля Whisper: оставляем первую.
fn drop_repeats(cues: Vec<Cue>) -> Vec<Cue> {
    let mut out: Vec<Cue> = Vec::with_capacity(cues.len());
    let mut i = 0;
    while i < cues.len() {
        let run = cues[i..].iter().take_while(|c| c.text == cues[i].text).count();
        out.push(cues[i].clone());
        if run < 3 {
            out.extend(cues[i + 1..i + run].iter().cloned());
        }
        i += run;
    }
    out
}

/// Начала слов сегмента: (номер символа в `text`, время). Пусто, если токены не
/// складываются в текст сегмента (например, символ разрезан между токенами).
fn word_starts(tokens: &[Value], text: &str) -> Vec<(usize, f64)> {
    let mut joined = String::new();
    let mut chars = 0;
    let mut words = Vec::new();
    for tok in tokens {
        let s = tok["text"].as_str().unwrap_or("");
        if s.starts_with("[_") {
            continue; // [_BEG_], [_TT_123]
        }
        let lead = s.chars().take_while(|c| c.is_whitespace()).count();
        if (lead > 0 || words.is_empty()) && s.chars().count() > lead {
            let dtw = tok["t_dtw"].as_f64().filter(|&t| t >= 0.0).map(|t| t / 100.0 - DTW_LEAD);
            let time = dtw.or_else(|| tok["offsets"]["from"].as_f64().map(|t| t / 1000.0));
            if let Some(time) = time {
                words.push((chars + lead, time));
            }
        }
        joined.push_str(s);
        chars += s.chars().count();
    }
    if joined != text {
        return Vec::new();
    }
    words
}

// ---------------------------------------------------------------------------
// Вычитка через Claude

/// Ошибка запроса к API. `fatal` — повторять для других фрагментов бессмысленно.
pub(crate) struct ApiError {
    pub(crate) message: String,
    pub(crate) fatal: bool,
}

/// Вычитывает реплики фрагментами по [`CHUNK`]. Фрагменты, которые не удалось вычитать,
/// остаются как есть; тогда второй элемент — предупреждение для пользователя.
fn polish(
    cues: &[Cue],
    key: &str,
    cancel: Option<&AtomicBool>,
    on_progress: &mut dyn FnMut(f64),
) -> Result<(Vec<Cue>, Option<String>), Error> {
    let agent = ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(30))
        .timeout_read(Duration::from_secs(300))
        .build();
    let chunks: Vec<&[Cue]> = cues.chunks(CHUNK).collect();
    let mut out = Vec::with_capacity(cues.len());
    let (mut failed, mut first_error, mut fatal) = (0, None, false);
    for (n, chunk) in chunks.iter().enumerate() {
        if cancelled(cancel) {
            return Err(Error::Cancelled);
        }
        let result = if fatal {
            Err(ApiError { message: String::new(), fatal: true })
        } else {
            polish_chunk(&agent, key, chunk)
        };
        match result {
            Ok(texts) => {
                for (cue, text) in chunk.iter().zip(texts) {
                    if !text.is_empty() {
                        out.push(Cue { text, ..cue.clone() });
                    }
                }
            }
            Err(e) => {
                failed += 1;
                fatal |= e.fatal;
                first_error.get_or_insert(e.message);
                out.extend(chunk.iter().cloned());
            }
        }
        on_progress((n + 1) as f64 / chunks.len() as f64);
    }
    let warning = first_error.map(|e| {
        if failed == chunks.len() {
            format!("вычитка Claude не удалась ({e}), текст без вычитки")
        } else {
            format!("Claude не вычитал {failed} из {} фрагментов текста ({e})", chunks.len())
        }
    });
    Ok((out, warning))
}

fn polish_schema() -> Value {
    json!({
        "type": "object",
        "properties": {
            "lines": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "integer"},
                        "text": {"type": "string"}
                    },
                    "required": ["id", "text"],
                    "additionalProperties": false
                }
            }
        },
        "required": ["lines"],
        "additionalProperties": false
    })
}

/// Тексты реплик фрагмента после вычитки, в том же порядке; "" — не речь.
fn polish_chunk(agent: &ureq::Agent, key: &str, chunk: &[Cue]) -> Result<Vec<String>, ApiError> {
    let lines: Vec<Value> = chunk
        .iter()
        .enumerate()
        .map(|(i, c)| json!({"id": i, "text": c.text.replace('\n', " ")}))
        .collect();
    let body = json!({
        "model": CLAUDE_MODEL,
        "max_tokens": 16000,
        "output_config": {
            "effort": "low",
            "format": {"type": "json_schema", "schema": polish_schema()}
        },
        "system": SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": json!({"lines": lines}).to_string()}]
    });
    let resp = call_claude(agent, key, &body)?;
    parse_polish_response(&resp, chunk.len())
        .map_err(|message| ApiError { message, fatal: false })
}

fn parse_polish_response(resp: &Value, count: usize) -> Result<Vec<String>, String> {
    match resp["stop_reason"].as_str() {
        Some("refusal") => return Err("Claude отказался обрабатывать фрагмент".into()),
        Some("max_tokens") => return Err("ответ Claude обрезан".into()),
        _ => {}
    }
    // Ответ может начинаться с блоков thinking — берём только текстовые.
    let text: String = resp["content"]
        .as_array()
        .into_iter()
        .flatten()
        .filter(|b| b["type"] == "text")
        .filter_map(|b| b["text"].as_str())
        .collect();
    let parsed: Value =
        serde_json::from_str(&text).map_err(|e| format!("непонятный ответ Claude: {e}"))?;
    let mut texts = vec![None; count];
    for line in parsed["lines"].as_array().into_iter().flatten() {
        let (Some(id), Some(t)) = (line["id"].as_u64(), line["text"].as_str()) else { continue };
        if let Some(slot) = texts.get_mut(id as usize) {
            *slot = Some(t.trim().to_string());
        }
    }
    texts
        .into_iter()
        .collect::<Option<Vec<_>>>()
        .ok_or_else(|| "Claude вернул не все строки".into())
}

/// POST /v1/messages с повторами при перегрузке и сетевых ошибках.
pub(crate) fn call_claude(agent: &ureq::Agent, key: &str, body: &Value) -> Result<Value, ApiError> {
    const ATTEMPTS: u32 = 4;
    let body = body.to_string();
    let mut delay = Duration::from_secs(2);
    for attempt in 1..=ATTEMPTS {
        let result = agent
            .post(API_URL)
            .set("x-api-key", key)
            .set("anthropic-version", "2023-06-01")
            .set("content-type", "application/json")
            .send_string(&body);
        let (message, retry) = match result {
            Ok(resp) => {
                return resp
                    .into_string()
                    .ok()
                    .and_then(|s| serde_json::from_str(&s).ok())
                    .ok_or(ApiError { message: "не удалось прочитать ответ API".into(), fatal: false });
            }
            Err(ureq::Error::Status(code, resp)) => {
                let wait = resp.header("retry-after").and_then(|v| v.parse::<u64>().ok());
                let message = api_error_message(code, &resp.into_string().unwrap_or_default());
                if let Some(secs) = wait {
                    delay = delay.max(Duration::from_secs(secs.min(60)));
                }
                (message, code == 429 || code >= 500)
            }
            Err(ureq::Error::Transport(t)) => (format!("нет связи с API: {t}"), true),
        };
        if !retry || attempt == ATTEMPTS {
            return Err(ApiError { message, fatal: true });
        }
        thread::sleep(delay);
        delay *= 2;
    }
    unreachable!()
}

fn api_error_message(code: u16, body: &str) -> String {
    let detail = serde_json::from_str::<Value>(body)
        .ok()
        .and_then(|v| v["error"]["message"].as_str().map(str::to_string))
        .unwrap_or_else(|| body.trim().chars().take(200).collect());
    match code {
        401 => "неверный ANTHROPIC_API_KEY".into(),
        _ => format!("API {code}: {detail}"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_env() {
        let vars = parse_env(
            "# комментарий\nANTHROPIC_API_KEY=sk-ant-123 # ключ\nexport WHISPER_LANGUAGE=\"ru\"\n\
             WHISPER_MODEL='small'\nEMPTY=\nbroken line\n",
        );
        assert_eq!(vars["ANTHROPIC_API_KEY"], "sk-ant-123");
        assert_eq!(vars["WHISPER_LANGUAGE"], "ru");
        assert_eq!(vars["WHISPER_MODEL"], "small");
        assert_eq!(vars["EMPTY"], "");
        assert_eq!(vars.len(), 4);
    }

    #[test]
    fn template_has_empty_key() {
        let vars = parse_env(ENV_TEMPLATE);
        assert_eq!(vars["ANTHROPIC_API_KEY"], "");
        assert_eq!(vars["WHISPER_MODEL"], DEFAULT_WHISPER_MODEL);
    }

    #[test]
    fn filters_hallucinations() {
        assert!(is_hallucination("Добавил субтитры DimaTorzok"));
        assert!(is_hallucination("Продолжение следует..."));
        assert!(is_hallucination("ДИНАМИЧНАЯ МУЗЫКА"));
        assert!(!is_hallucination("Второе правило: добавляйте субтитры."));
        assert!(!is_hallucination("НАТО"));
        assert!(!is_hallucination("Да."));

        let c = |t: &str| Cue { start: 0.0, end: 1.0, text: t.into(), words: Vec::new() };
        let texts = |v: Vec<Cue>| v.into_iter().map(|c| c.text).collect::<Vec<_>>();
        assert_eq!(texts(drop_repeats(vec![c("Да."), c("Да."), c("Нет")])), ["Да.", "Да.", "Нет"]);
        assert_eq!(texts(drop_repeats(vec![c("а"), c("б"), c("б"), c("б"), c("б"), c("в")])), ["а", "б", "в"]);
    }

    #[test]
    fn trims_segment_to_words() {
        // Сегмент 10–24 с, а слова звучат с 23,2 с (DTW 23,35 − 0,15).
        let cues = parse_whisper_json(
            r#"{"transcription": [{"offsets": {"from": 10000, "to": 24200}, "text": " Привет. Ты пришла?", "tokens": [
                {"text": " Привет.", "offsets": {"from": 10000, "to": 11000}, "t_dtw": 2335},
                {"text": " Ты пришла?", "offsets": {"from": 11000, "to": 24200}, "t_dtw": 2380}
            ]}]}"#,
        )
        .unwrap();
        assert!((cues[0].start - 23.2).abs() < 1e-9, "{:?}", cues[0]);
        assert_eq!(cues[0].end, 24.2);
    }

    #[test]
    fn picks_dtw_preset() {
        assert_eq!(dtw_preset("large-v3-turbo-q5_0").as_deref(), Some("large.v3.turbo"));
        assert_eq!(dtw_preset("medium.en").as_deref(), Some("medium.en"));
        assert_eq!(dtw_preset("my-custom"), None);
    }

    #[test]
    fn parses_whisper_progress() {
        assert_eq!(parse_progress("whisper_print_progress_callback: progress =  42%"), Some(0.42));
        assert_eq!(parse_progress("whisper_init_from_file: loading model"), None);
    }

    #[test]
    fn parses_whisper_json() {
        let cues = parse_whisper_json(
            r#"{"transcription": [
                {"offsets": {"from": 0, "to": 2500}, "text": " Привет, мир.", "tokens": [
                    {"text": "[_BEG_]", "offsets": {"from": 0, "to": 0}, "t_dtw": -1},
                    {"text": " При", "offsets": {"from": 0, "to": 300}, "t_dtw": 30},
                    {"text": "вет,", "offsets": {"from": 300, "to": 900}, "t_dtw": 60},
                    {"text": " мир.", "offsets": {"from": 900, "to": 2500}, "t_dtw": 140}
                ]},
                {"offsets": {"from": 2500, "to": 4000}, "text": " [BLANK_AUDIO]"},
                {"offsets": {"from": 4000, "to": 6100}, "text": " Вторая фраза"}
            ]}"#,
        )
        .unwrap();
        assert_eq!(cues.len(), 2);
        assert_eq!((cues[0].start, cues[0].end, cues[0].text.as_str()), (0.0, 2.5, "Привет, мир."));
        // «Привет» с 0,15 с (DTW 0,3 − 0,15), «мир» — с 8-го из 12 символов в 1,25 с.
        let w = &cues[0].words;
        assert_eq!(w.len(), 2);
        assert!((w[0].0 - 0.0).abs() < 1e-9 && (w[0].1 - 0.15).abs() < 1e-9);
        assert!((w[1].0 - 8.0 / 12.0).abs() < 1e-9 && (w[1].1 - 1.25).abs() < 1e-9);
        assert_eq!((cues[1].text.as_str(), cues[1].words.len()), ("Вторая фраза", 0));
    }

    #[test]
    fn parses_polish_response() {
        let resp = json!({
            "stop_reason": "end_turn",
            "content": [
                {"type": "thinking", "thinking": "", "signature": "x"},
                {"type": "text", "text": r#"{"lines":[{"id":1,"text":" Б "},{"id":0,"text":"А"}]}"#}
            ]
        });
        assert_eq!(parse_polish_response(&resp, 2).unwrap(), ["А", "Б"]);
        assert!(parse_polish_response(&resp, 3).is_err());
        assert!(parse_polish_response(&json!({"stop_reason": "refusal", "content": []}), 2).is_err());
    }
}
