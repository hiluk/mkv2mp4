//! Лучшие моменты для роликов, в два шага:
//! 1. Claude Haiku читает расшифровку с сигналами из звука и монтажа
//!    ([`crate::media_signals`]) и предлагает кандидатов — вдвое больше, чем нужно.
//! 2. Для каждого кандидата делается раскадровка (кадр каждые 2 с), Claude смотрит её
//!    и оценивает зрелищность; остаются лучшие.
//!
//! Границы всегда подгоняет код: по репликам, длина [`MIN_LEN`]–[`MAX_LEN`], без пересечений.

use std::fmt::Write as _;
use std::fs;
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use base64::Engine as _;
use serde_json::{json, Value};

use crate::media_signals::{self, Loudness, Signals, SHEET_COLS, SHEET_ROWS};
use crate::shorts::{Cue, ShortsEvent};
use crate::transcribe::{call_claude, CLAUDE_MODEL};
use crate::Error;

/// Длина ролика с моментом, секунды.
pub const MIN_LEN: f64 = 60.0;
pub const MAX_LEN: f64 = 180.0;
/// Запас до первой реплики и после последней.
const PAD_BEFORE: f64 = 0.4;
const PAD_AFTER: f64 = 0.8;
/// Отрезок без реплик длиннее этого попадает в список «без слов».
const NO_SPEECH_MIN: f64 = 8.0;
/// Шаг раскадровки и предел листов в одном запросе.
const STORYBOARD_STEP: f64 = 2.0;
const MAX_SHEETS: usize = 90;
/// Ниже этой суммы оценок по тексту и по кадрам (из 20) кандидат не берётся,
/// если есть кто-то лучше.
const MIN_SCORE_SUM: u64 = 11;

/// Выбранный момент.
#[derive(Debug, Clone, PartialEq)]
pub struct Moment {
    pub start: f64,
    pub end: f64,
    /// Первая и последняя реплика момента.
    pub first: usize,
    pub last: usize,
    /// Короткое название для подписи к ролику.
    pub title: String,
    /// Почему момент цепляет.
    pub reason: String,
    /// Оценка 1–10 по тексту и сигналам (первый шаг).
    pub score: u64,
    /// Оценка 1–10 по раскадровке; `None` — кадры не оценивались.
    pub visual_score: Option<u64>,
    /// Что на экране (после просмотра раскадровки).
    pub visual: String,
}

impl Moment {
    /// Сумма оценок по тексту и по кадрам (без кадров — удвоенная по тексту), из 20.
    fn score_sum(&self) -> u64 {
        self.score + self.visual_score.unwrap_or(self.score)
    }
}

/// Итог отбора: моменты для роликов и кандидаты, которые не вошли (для отчёта).
pub struct Selection {
    pub chosen: Vec<Moment>,
    pub rejected: Vec<Moment>,
    /// Какой-то шаг пришлось пропустить.
    pub warning: Option<String>,
}

/// Где взять видео для замеров и раскадровки.
pub struct Source<'a> {
    pub ffmpeg: &'a Path,
    pub input: &'a Path,
    pub audio_track: u32,
    /// Временная папка для листов раскадровки.
    pub tmp: &'a Path,
    pub cancel: Option<&'a AtomicBool>,
}

/// Сколько моментов оставить: примерно один на две минуты видео.
fn max_moments(duration: f64) -> usize {
    ((duration / 120.0).round() as usize).max(1)
}

/// Сколько кандидатов просить на первом шаге: вдвое больше.
fn max_candidates(duration: f64) -> usize {
    (max_moments(duration) * 2).max(2)
}

fn agent() -> ureq::Agent {
    ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(30))
        .timeout_read(Duration::from_secs(600))
        .build()
}

fn failed(e: Error) -> String {
    match e {
        Error::Failed(m) => m,
        other => other.to_string(),
    }
}

/// Лучшие моменты видео.
pub fn find_moments(
    cues: &[Cue],
    duration: f64,
    key: &str,
    src: &Source,
    on_event: &mut dyn FnMut(ShortsEvent),
) -> Result<Selection, Error> {
    let mut warnings = Vec::new();

    on_event(ShortsEvent::Stage("Анализирую звук и монтаж".into()));
    let signals = match media_signals::analyze(src.ffmpeg, src.input, src.audio_track, src.cancel) {
        Ok(s) => Some(s),
        Err(Error::Cancelled) => return Err(Error::Cancelled),
        Err(e) => {
            warnings.push(format!("сигналы звука и монтажа недоступны ({})", failed(e)));
            None
        }
    };

    on_event(ShortsEvent::Stage("Ищу кандидатов (Claude Haiku)".into()));
    let candidates = find_candidates(cues, duration, key, signals.as_ref())?;
    if candidates.is_empty() {
        return Ok(Selection { chosen: Vec::new(), rejected: Vec::new(), warning: None });
    }
    let keep = max_moments(duration);

    let rated = match rate_candidates(cues, &candidates, key, src, on_event) {
        Ok(r) => r,
        Err(Error::Cancelled) => return Err(Error::Cancelled),
        Err(e) => {
            warnings.push(format!("кадры не оценены ({}), отбор только по тексту", failed(e)));
            candidates.clone()
        }
    };
    let (chosen, rejected) = pick_best(cues, duration, &rated, keep);
    let warning = (!warnings.is_empty()).then(|| warnings.join("; "));
    Ok(Selection { chosen, rejected, warning })
}

/// Лучшие по сумме оценок: все, кто не ниже [`MIN_SCORE_SUM`], но не меньше половины
/// кандидатов (до трёх) и не больше `keep`. Возвращает выбранные (по времени, с повторной
/// подгонкой границ) и не вошедшие.
fn pick_best(cues: &[Cue], duration: f64, rated: &[Moment], keep: usize) -> (Vec<Moment>, Vec<Moment>) {
    let mut by_score: Vec<&Moment> = rated.iter().collect();
    by_score.sort_by(|a, b| b.score_sum().cmp(&a.score_sum()));
    let good = by_score.iter().filter(|m| m.score_sum() >= MIN_SCORE_SUM).count();
    let n = good.max((rated.len() / 2).min(3)).max(1).min(keep);
    let mut chosen: Vec<Moment> = by_score[..n.min(by_score.len())].iter().map(|m| (*m).clone()).collect();
    let mut rejected: Vec<Moment> = by_score[n.min(by_score.len())..].iter().map(|m| (*m).clone()).collect();
    chosen.sort_by_key(|m| m.first);
    rejected.sort_by_key(|m| m.first);
    (fit_moments(cues, duration, &chosen), rejected)
}

// ---------------------------------------------------------------------------
// Шаг 1: кандидаты по тексту и сигналам

/// Язык подписей: по алфавиту расшифровки.
fn caption_language(cues: &[Cue]) -> &'static str {
    let (mut cyr, mut lat) = (0usize, 0usize);
    for ch in cues.iter().flat_map(|c| c.text.chars()) {
        match ch {
            'а'..='я' | 'А'..='Я' | 'ё' | 'Ё' => cyr += 1,
            'a'..='z' | 'A'..='Z' => lat += 1,
            _ => {}
        }
    }
    if cyr > lat { "Russian" } else { "the language of the transcript" }
}

fn candidates_prompt(max: usize, lang: &str) -> String {
    format!(
        "\
You pick candidate moments of a video to post as separate TikTok / Reels / Shorts clips. \
A second pass will look at the frames, so offer more candidates than will be kept.

The user message is the full transcript as JSON: {{\"duration\", \"lines\": [{{\"id\", \"start\", \
\"end\", \"text\", \"loud\", \"cuts\"}}], \"no_speech\": [{{\"after_id\", \"start\", \"end\", \"loud\", \
\"cuts\"}}]}}, times in seconds. \"loud\" is \"high\" when the audio is much louder than usual \
(shouting, laughter, loud music) and \"low\" when it is much quieter; \"cuts\" counts shot \
changes. \"no_speech\" lists stretches without dialogue (music, action, silence) after line \
\"after_id\". Use the signals as hints: a loud stretch with many cuts can be a strong visual \
moment even without words, but a good clip still needs a story.

Choose moments that work on their own, without the rest of the video: a complete scene, \
a joke with its punchline, a conflict, a confession, an emotional peak, a strong quotable \
statement, an intense action or music sequence. A moment starts where the viewer is hooked \
right away (no slow setup) and ends on a payoff, never mid-thought or mid-conversation.

Rules:
- Each moment lasts between {min} and {max_len} seconds: from the start of its first line \
to the end of its last line. Stretches without speech between lines count toward the length.
- Moments do not overlap. List them in chronological order.
- Up to {max} candidates, fewer if the video does not have that many decent ones.
- score: 1–10, how well the moment works as a standalone clip judging by the text and signals.
- title: a short catchy caption for the post, at most 8 words.
- reason: one short sentence (at most 25 words) on why the moment works.
- Write title and reason in {lang}.",
        min = MIN_LEN,
        max_len = MAX_LEN,
    )
}

fn candidates_schema() -> Value {
    json!({
        "type": "object",
        "properties": {
            "moments": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "first_id": {"type": "integer"},
                        "last_id": {"type": "integer"},
                        "score": {"type": "integer"},
                        "title": {"type": "string"},
                        "reason": {"type": "string"}
                    },
                    "required": ["first_id", "last_id", "score", "title", "reason"],
                    "additionalProperties": false
                }
            }
        },
        "required": ["moments"],
        "additionalProperties": false
    })
}

fn r1(t: f64) -> f64 {
    (t * 10.0).round() / 10.0
}

/// Расшифровка для первого шага: реплики с сигналами и отрезки без слов.
fn transcript_json(cues: &[Cue], duration: f64, signals: Option<&Signals>) -> Value {
    let loud = |a: f64, b: f64| match signals.map(|s| s.loudness_of(a, b)) {
        Some(Loudness::High) => json!("high"),
        Some(Loudness::Low) => json!("low"),
        _ => Value::Null,
    };
    let cuts = |a: f64, b: f64| signals.map_or(Value::Null, |s| json!(s.cuts_in(a, b)));
    let lines: Vec<Value> = cues
        .iter()
        .enumerate()
        .map(|(i, c)| {
            json!({"id": i, "start": r1(c.start), "end": r1(c.end), "text": c.text.replace('\n', " "),
                   "loud": loud(c.start, c.end), "cuts": cuts(c.start, c.end)})
        })
        .collect();
    let mut no_speech = Vec::new();
    for i in 0..cues.len() {
        let (a, b) = (cues[i].end, cues.get(i + 1).map_or(duration, |c| c.start));
        if b - a >= NO_SPEECH_MIN {
            no_speech.push(json!({"after_id": i, "start": r1(a), "end": r1(b), "loud": loud(a, b), "cuts": cuts(a, b)}));
        }
    }
    json!({"duration": r1(duration), "lines": lines, "no_speech": no_speech})
}

fn find_candidates(cues: &[Cue], duration: f64, key: &str, signals: Option<&Signals>) -> Result<Vec<Moment>, Error> {
    let body = json!({
        "model": CLAUDE_MODEL,
        "max_tokens": 16000,
        "output_config": {
            "effort": "high",
            "format": {"type": "json_schema", "schema": candidates_schema()}
        },
        "system": candidates_prompt(max_candidates(duration), caption_language(cues)),
        "messages": [{"role": "user", "content": transcript_json(cues, duration, signals).to_string()}]
    });
    let picks = request(&body, key, parse_candidates)?;
    Ok(fit_moments(cues, duration, &picks))
}

/// POST с повтором, если модель зациклилась и ответ обрезан или не разбирается.
fn request<T>(body: &Value, key: &str, parse: fn(&Value) -> Result<T, String>) -> Result<T, Error> {
    let agent = agent();
    let mut last_error = String::new();
    for _ in 0..2 {
        let resp = call_claude(&agent, key, body).map_err(|e| Error::Failed(e.message))?;
        match response_json(&resp).and_then(|v| parse(&v)) {
            Ok(r) => return Ok(r),
            Err(e) => last_error = e,
        }
    }
    Err(Error::Failed(last_error))
}

/// JSON из текстовых блоков ответа (блоки thinking пропускаются).
fn response_json(resp: &Value) -> Result<Value, String> {
    match resp["stop_reason"].as_str() {
        Some("refusal") => return Err("Claude отказался выбирать моменты".into()),
        Some("max_tokens") => return Err("ответ Claude обрезан".into()),
        _ => {}
    }
    let text: String = resp["content"]
        .as_array()
        .into_iter()
        .flatten()
        .filter(|b| b["type"] == "text")
        .filter_map(|b| b["text"].as_str())
        .collect();
    serde_json::from_str(&text).map_err(|e| format!("непонятный ответ Claude: {e}"))
}

fn parse_candidates(v: &Value) -> Result<Vec<Moment>, String> {
    Ok(v["moments"]
        .as_array()
        .into_iter()
        .flatten()
        .filter_map(|m| {
            let a = m["first_id"].as_u64()? as usize;
            let b = m["last_id"].as_u64()? as usize;
            let s = |k: &str, max: usize| clean_text(m[k].as_str().unwrap_or(""), max);
            Some(Moment {
                start: 0.0,
                end: 0.0,
                first: a.min(b),
                last: a.max(b),
                title: s("title", 100),
                reason: s("reason", 300),
                score: m["score"].as_u64().unwrap_or(0).min(10),
                visual_score: None,
                visual: String::new(),
            })
        })
        .collect())
}

// ---------------------------------------------------------------------------
// Шаг 2: оценка по раскадровке

const RATE_PROMPT: &str = "\
You decide which candidate moments of a video to publish as standalone vertical \
TikTok / Reels / Shorts clips. The first user message part is JSON with the candidates: \
{\"candidates\": [{\"candidate\", \"start\", \"end\", \"title\", \"reason\", \"lines\": [{\"id\", \"start\", \
\"end\", \"text\"}]}]}. Then come storyboard sheets for each candidate: grids of frames taken at \
a fixed step, read left to right and top to bottom; the caption before each sheet gives the \
candidate, the time range and the step.

Rate every candidate from 1 to 10 on how well its picture works for a vertical clip: \
how strong the opening shots are as a hook, and how expressive the shots are (faces, \
emotion, reactions, movement versus static, dark or empty shots). Dialogue scenes are \
normal here: judge whether the shots carry the moment, not whether there is action. \
The story itself was already rated from the text.

You may tighten a candidate by choosing a later first_id or an earlier last_id from its own \
lines when the frames show the strong part is narrower, but keep it at least 60 seconds long; \
otherwise return its original first and last line ids.

visual: one short sentence (at most 20 words) about what is on screen, written in the \
language named in the JSON field \"language\".";

fn rate_schema() -> Value {
    json!({
        "type": "object",
        "properties": {
            "ratings": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "candidate": {"type": "integer"},
                        "score": {"type": "integer"},
                        "first_id": {"type": "integer"},
                        "last_id": {"type": "integer"},
                        "visual": {"type": "string"}
                    },
                    "required": ["candidate", "score", "first_id", "last_id", "visual"],
                    "additionalProperties": false
                }
            }
        },
        "required": ["ratings"],
        "additionalProperties": false
    })
}

/// Шаг раскадровки: 2 с, но не больше [`MAX_SHEETS`] листов на всех кандидатов.
fn storyboard_step(candidates: &[Moment]) -> f64 {
    let total: f64 = candidates.iter().map(|m| m.end - m.start).sum();
    let per_sheet = (SHEET_COLS * SHEET_ROWS) as f64;
    (total / (MAX_SHEETS as f64 * per_sheet)).ceil().max(STORYBOARD_STEP)
}

fn rate_candidates(
    cues: &[Cue],
    candidates: &[Moment],
    key: &str,
    src: &Source,
    on_event: &mut dyn FnMut(ShortsEvent),
) -> Result<Vec<Moment>, Error> {
    on_event(ShortsEvent::Stage("Смотрю кадры кандидатов".into()));
    let step = storyboard_step(candidates);
    let dir = src.tmp.join("storyboard");
    fs::create_dir_all(&dir).map_err(|e| Error::Failed(e.to_string()))?;

    let list: Vec<Value> = candidates
        .iter()
        .enumerate()
        .map(|(i, m)| {
            let lines: Vec<Value> = (m.first..=m.last)
                .map(|id| json!({"id": id, "start": r1(cues[id].start), "end": r1(cues[id].end), "text": cues[id].text.replace('\n', " ")}))
                .collect();
            json!({"candidate": i, "start": r1(m.start), "end": r1(m.end), "title": m.title, "reason": m.reason, "lines": lines})
        })
        .collect();
    let header = json!({"language": caption_language(cues), "candidates": list});
    let mut content = vec![json!({"type": "text", "text": header.to_string()})];
    let per_sheet = step * (SHEET_COLS * SHEET_ROWS) as f64;
    for (i, m) in candidates.iter().enumerate() {
        if src.cancel.is_some_and(|c| c.load(Ordering::Relaxed)) {
            return Err(Error::Cancelled);
        }
        on_event(ShortsEvent::Progress(i as f64 / candidates.len() as f64));
        let sheets = media_signals::storyboard(src.ffmpeg, src.input, m.start, m.end, step, &dir, &format!("c{i:02}"))?;
        for (k, sheet) in sheets.iter().enumerate() {
            let t0 = m.start + k as f64 * per_sheet;
            let t1 = (t0 + per_sheet).min(m.end);
            let caption = format!(
                "Candidate {i}, sheet {}/{}: {:.0}–{:.0} s, a frame every {step:.0} s.",
                k + 1,
                sheets.len(),
                t0,
                t1
            );
            let data = fs::read(sheet).map_err(|e| Error::Failed(e.to_string()))?;
            content.push(json!({"type": "text", "text": caption}));
            content.push(json!({"type": "image", "source": {
                "type": "base64", "media_type": "image/jpeg",
                "data": base64::engine::general_purpose::STANDARD.encode(data)
            }}));
        }
    }
    on_event(ShortsEvent::Progress(1.0));

    on_event(ShortsEvent::Stage("Выбираю лучшие моменты (Claude Haiku)".into()));
    let body = json!({
        "model": CLAUDE_MODEL,
        "max_tokens": 16000,
        "output_config": {
            "effort": "high",
            "format": {"type": "json_schema", "schema": rate_schema()}
        },
        "system": RATE_PROMPT,
        "messages": [{"role": "user", "content": content}]
    });
    let ratings = request(&body, key, parse_ratings)?;
    Ok(apply_ratings(candidates, &ratings))
}

/// (кандидат, оценка, первая реплика, последняя реплика, что на экране)
type Rating = (usize, u64, usize, usize, String);

fn parse_ratings(v: &Value) -> Result<Vec<Rating>, String> {
    let ratings: Vec<Rating> = v["ratings"]
        .as_array()
        .into_iter()
        .flatten()
        .filter_map(|r| {
            Some((
                r["candidate"].as_u64()? as usize,
                r["score"].as_u64()?.min(10),
                r["first_id"].as_u64()? as usize,
                r["last_id"].as_u64()? as usize,
                clean_text(r["visual"].as_str().unwrap_or(""), 200),
            ))
        })
        .collect();
    if ratings.is_empty() {
        return Err("Claude не оценил кандидатов".into());
    }
    Ok(ratings)
}

/// Оценки и уточнённые границы к кандидатам. Границы вне кандидата игнорируются;
/// неоценённый кандидат остаётся только с оценкой по тексту.
fn apply_ratings(candidates: &[Moment], ratings: &[Rating]) -> Vec<Moment> {
    candidates
        .iter()
        .enumerate()
        .map(|(i, c)| {
            let Some((_, score, a, b, visual)) = ratings.iter().find(|r| r.0 == i) else {
                return c.clone(); // не оценён по кадрам — остаётся оценка по тексту
            };
            let inside = c.first <= *a && a <= b && *b <= c.last;
            Moment {
                first: if inside { *a } else { c.first },
                last: if inside { *b } else { c.last },
                visual_score: Some(*score),
                visual: visual.clone(),
                ..c.clone()
            }
        })
        .collect()
}

// ---------------------------------------------------------------------------
// Границы

/// Страховка от зацикленной генерации: текст до утёкшего в строку JSON (`"}`, `",`) или
/// перевода строки, без повтора начала фразы, не длиннее `max` символов.
fn clean_text(s: &str, max: usize) -> String {
    let cut = ["\"}", "\",", "\n"].iter().filter_map(|p| s.find(p)).min().unwrap_or(s.len());
    let mut s = s[..cut].trim();
    let head: String = s.chars().take(20).collect();
    if head.chars().count() == 20 {
        if let Some(i) = s[head.len()..].find(&head) {
            s = s[..head.len() + i].trim();
        }
    }
    let mut out: String = s.chars().take(max).collect();
    if s.chars().count() > max {
        out = out.trim_end().to_string() + "…";
    }
    out
}

/// Подгоняет моменты по их `first`/`last`: границы по репликам с запасом, длина в
/// [`MIN_LEN`, `MAX_LEN`] (короткие расширяются соседними репликами, длинные
/// укорачиваются с конца), пересечения убираются.
fn fit_moments(cues: &[Cue], duration: f64, picks: &[Moment]) -> Vec<Moment> {
    if cues.is_empty() {
        return Vec::new();
    }
    let n = cues.len();
    // Начало и конец ролика, если он идёт с реплики `a` по реплику `b`.
    let start_of = |a: usize| {
        let floor = if a > 0 { cues[a - 1].end } else { 0.0 };
        (cues[a].start - PAD_BEFORE).max(floor).max(0.0)
    };
    let end_of = |b: usize| {
        let ceil = cues.get(b + 1).map_or(duration, |c| c.start);
        (cues[b].end + PAD_AFTER).min(ceil).min(duration)
    };

    let mut out: Vec<Moment> = Vec::new();
    let mut sorted: Vec<&Moment> = picks.iter().filter(|p| p.first < n).collect();
    sorted.sort_by_key(|p| p.first);
    for pick in sorted {
        let (mut a, mut b) = (pick.first, pick.last.min(n - 1));
        // Длинный — убираем реплики с конца.
        while b > a && end_of(b) - start_of(a) > MAX_LEN {
            b -= 1;
        }
        // Короткий — добавляем реплики после, затем до, пока влезает в MAX_LEN.
        while end_of(b) - start_of(a) < MIN_LEN && b + 1 < n && end_of(b + 1) - start_of(a) <= MAX_LEN {
            b += 1;
        }
        while end_of(b) - start_of(a) < MIN_LEN && a > 0 && end_of(b) - start_of(a - 1) <= MAX_LEN {
            a -= 1;
        }
        let (mut start, mut end) = (start_of(a), end_of(b));
        // Реплик не хватило (вокруг музыка) — добираем тишиной до MIN_LEN.
        if end - start < MIN_LEN {
            end = (start + MIN_LEN).min(duration);
            start = (end - MIN_LEN).max(0.0).min(start);
        }
        if end - start > MAX_LEN + 1e-6 {
            end = start + MAX_LEN; // одна реплика длиннее MAX_LEN
        }
        // Пересечение с предыдущим: сдвигаем начало, если момент остаётся достаточно длинным.
        if let Some(prev) = out.last() {
            if start < prev.end {
                if end - prev.end >= MIN_LEN {
                    start = prev.end;
                } else {
                    continue;
                }
            }
        }
        if end - start >= MIN_LEN.min(duration) - 1e-6 {
            out.push(Moment { start, end, first: a, last: b, ..pick.clone() });
        }
    }
    out
}

fn clock(t: f64) -> String {
    let s = t.max(0.0).round() as u64;
    if s >= 3600 {
        format!("{}:{:02}:{:02}", s / 3600, s / 60 % 60, s % 60)
    } else {
        format!("{}:{:02}", s / 60, s % 60)
    }
}

fn score_text(m: &Moment) -> String {
    match m.visual_score {
        Some(v) => format!("оценка {}/10 (текст {}, кадры {v})", m.score_sum() as f64 / 2.0, m.score),
        None => format!("оценка {}/10", m.score),
    }
}

/// Текст для `<имя>_моменты.txt`: номер ролика, время в исходнике, оценка, название,
/// причина и что на экране; в конце — кандидаты, которые не вошли.
pub fn moments_report(stem: &str, sel: &Selection) -> String {
    let mut out = String::new();
    for (i, m) in sel.chosen.iter().enumerate() {
        let score = score_text(m);
        let _ = writeln!(
            out,
            "{stem}_{:02}.mp4  {}–{} ({} с), {score}\n{}\n{}",
            i + 1,
            clock(m.start),
            clock(m.end),
            (m.end - m.start).round(),
            m.title,
            m.reason
        );
        if !m.visual.is_empty() {
            let _ = writeln!(out, "На экране: {}", m.visual);
        }
        out.push('\n');
    }
    if !sel.rejected.is_empty() {
        out.push_str("Не вошли:\n");
        for m in &sel.rejected {
            let _ = writeln!(out, "  {}–{}, {}: {}", clock(m.start), clock(m.end), score_text(m), m.title);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Реплики по 4 с каждые 5 с: 0–4, 5–9, …
    fn cues(n: usize) -> Vec<Cue> {
        (0..n)
            .map(|i| Cue { start: i as f64 * 5.0, end: i as f64 * 5.0 + 4.0, text: format!("{i}"), words: Vec::new() })
            .collect()
    }

    fn pick(a: usize, b: usize) -> Moment {
        Moment {
            start: 0.0,
            end: 0.0,
            first: a,
            last: b,
            title: "t".into(),
            reason: "r".into(),
            score: 5,
            visual_score: None,
            visual: String::new(),
        }
    }

    #[test]
    fn keeps_good_moment_with_padding() {
        // Реплики 2–20: 10 с … 104 с.
        let m = fit_moments(&cues(60), 300.0, &[pick(2, 20)]);
        assert_eq!(m.len(), 1);
        assert!((m[0].start - 9.6).abs() < 1e-9 && (m[0].end - 104.8).abs() < 1e-9, "{m:?}");
        assert_eq!((m[0].first, m[0].last), (2, 20));
    }

    #[test]
    fn extends_short_and_trims_long() {
        // 3 реплики (≈14 с) растягиваются до ≥ 60 с соседними репликами.
        let m = fit_moments(&cues(60), 300.0, &[pick(10, 12)]);
        let len = m[0].end - m[0].start;
        assert!((MIN_LEN..=MAX_LEN).contains(&len), "{m:?}");
        assert!((m[0].start - 49.6).abs() < 1e-9);
        assert_eq!(m[0].last, 21);
        // 50 реплик (≈250 с) укорачиваются до ≤ 180 с.
        let m = fit_moments(&cues(60), 300.0, &[pick(0, 49)]);
        assert!(m[0].end - m[0].start <= MAX_LEN, "{m:?}");
        assert!(m[0].end - m[0].start > MAX_LEN - 6.0);
    }

    #[test]
    fn resolves_overlaps_and_bad_ids() {
        let m = fit_moments(&cues(60), 300.0, &[pick(20, 40), pick(0, 15), pick(38, 55), pick(500, 600)]);
        assert!(m.windows(2).all(|w| w[0].end <= w[1].start), "{m:?}");
        assert!(m.iter().all(|x| x.end - x.start >= MIN_LEN && x.end - x.start <= MAX_LEN), "{m:?}");
        assert_eq!(m.len(), 3);
    }

    #[test]
    fn fills_with_silence_when_no_cues_around() {
        // Одна реплика 100–104 с посреди музыки.
        let c = vec![Cue { start: 100.0, end: 104.0, text: "а".into(), words: Vec::new() }];
        let m = fit_moments(&c, 400.0, &[pick(0, 0)]);
        assert!((m[0].end - m[0].start - MIN_LEN).abs() < 1e-9 && m[0].start <= 99.6, "{m:?}");
    }

    #[test]
    fn parses_candidates() {
        let v = json!({"moments":[{"first_id":7,"last_id":3,"score":12,"title":" Ссора ","reason":"Конфликт."}]});
        let c = parse_candidates(&v).unwrap();
        assert_eq!((c[0].first, c[0].last, c[0].score, c[0].title.as_str()), (3, 7, 10, "Ссора"));
        assert_eq!(max_moments(1170.0), 10);
        assert_eq!(max_candidates(1170.0), 20);
        assert_eq!(max_moments(30.0), 1);
        let err = response_json(&json!({"stop_reason": "max_tokens", "content": []}));
        assert!(err.is_err());
    }

    #[test]
    fn applies_ratings_and_picks_best() {
        let all = cues(200);
        let cands = fit_moments(&all, 1000.0, &[pick(0, 20), pick(40, 60), pick(80, 100), pick(120, 140)]);
        assert_eq!(cands.len(), 4);
        let ratings = vec![
            (0, 4, 0, 20, "темно".into()),
            (1, 9, 42, 60, "драка".into()),
            (2, 7, 70, 200, "вне кандидата".into()), // границы игнорируются
            // кандидат 3 не оценён
        ];
        // По тексту у всех 5: суммы 9, 14, 12; кандидат 3 без оценки кадров — 10.
        let rated = apply_ratings(&cands, &ratings);
        assert_eq!((rated[1].first, rated[1].visual_score), (42, Some(9)));
        assert_eq!((rated[2].first, rated[2].last), (cands[2].first, cands[2].last));
        assert_eq!(rated[3].visual_score, None);
        assert_eq!(rated[3].score_sum(), 10);
        // Оставить 2: лучшие по сумме, по времени; остальные — в не вошедших.
        let (best, rest) = pick_best(&all, 1000.0, &rated, 2);
        let sums: Vec<u64> = best.iter().map(Moment::score_sum).collect();
        assert_eq!(sums, [14, 12]);
        assert_eq!(rest.len(), 2);
        // Все ниже порога — всё равно половина кандидатов (до трёх).
        let low: Vec<Moment> = rated.iter().map(|m| Moment { score: 2, visual_score: Some(3), ..m.clone() }).collect();
        assert_eq!(pick_best(&all, 1000.0, &low, 5).0.len(), 2);
        assert_eq!(pick_best(&all, 1000.0, &low[..1], 5).0.len(), 1);
        assert_eq!(caption_language(&all), "the language of the transcript");
        let ru = vec![Cue { start: 0.0, end: 1.0, text: "Привет, Chris".into(), words: Vec::new() }];
        assert_eq!(caption_language(&ru), "Russian");
    }

    #[test]
    fn annotates_transcript_with_signals() {
        let c = vec![
            Cue { start: 0.0, end: 4.0, text: "а".into(), words: Vec::new() },
            Cue { start: 30.0, end: 34.0, text: "б".into(), words: Vec::new() },
        ];
        let mut loudness = vec![-30.0; 40];
        loudness[10..25].iter_mut().for_each(|d| *d = -5.0);
        let s = Signals { loudness, cuts: vec![12.0, 15.0, 31.0] };
        let v = transcript_json(&c, 40.0, Some(&s));
        assert_eq!(v["lines"][1]["cuts"], 1);
        assert_eq!(v["lines"][0]["loud"], Value::Null);
        assert_eq!(v["no_speech"][0]["after_id"], 0);
        assert_eq!(v["no_speech"][0]["loud"], "high");
        assert_eq!(v["no_speech"][0]["cuts"], 2);
        // Без сигналов поля пустые.
        assert_eq!(transcript_json(&c, 40.0, None)["lines"][0]["cuts"], Value::Null);
    }

    #[test]
    fn caps_storyboard_size() {
        let short = vec![Moment { start: 0.0, end: 120.0, ..pick(0, 0) }];
        assert_eq!(storyboard_step(&short), 2.0);
        // 40 кандидатов по 180 с: 7200 с / (90 × 16) = 5 с.
        let many: Vec<Moment> = (0..40).map(|_| Moment { start: 0.0, end: 180.0, ..pick(0, 0) }).collect();
        assert_eq!(storyboard_step(&many), 5.0);
    }

    #[test]
    fn cleans_looping_text() {
        let looped = "Мир возможностей или нет? Мир возможностей или нет? Мир возмож";
        assert_eq!(clean_text(looped, 100), "Мир возможностей или нет?");
        assert_eq!(clean_text("Ответ.\"}]}", 100), "Ответ.");
        assert_eq!(clean_text("абвгд", 3), "абв…");
        assert_eq!(clean_text("Повтор \"дешёвая еда\" смешит.", 100), "Повтор \"дешёвая еда\" смешит.");
    }

    #[test]
    fn report_lists_clips() {
        let m = Moment { start: 65.0, end: 190.0, title: "Т".into(), reason: "П".into(), score: 8, visual_score: Some(5), visual: "В".into(), ..pick(0, 0) };
        let other = Moment { start: 300.0, end: 400.0, title: "Х".into(), score: 3, ..pick(0, 0) };
        let sel = Selection { chosen: vec![m], rejected: vec![other], warning: None };
        assert_eq!(
            moments_report("ep", &sel),
            "ep_01.mp4  1:05–3:10 (125 с), оценка 6.5/10 (текст 8, кадры 5)\nТ\nП\nНа экране: В\n\n\
             Не вошли:\n  5:00–6:40, оценка 3/10: Х\n"
        );
    }
}
