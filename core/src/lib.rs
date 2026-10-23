//! Ядро конвертации видео (MKV, AVI, MOV, WebM и др.) в MP4. Вся работа делается внешним ffmpeg;
//! здесь выбирается стратегия (ремукс или перекодирование) и читается прогресс.

use std::ffi::OsString;
use std::fmt;
use std::fs;
use std::io::{BufRead, BufReader, Read};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;

pub mod highlights;
pub mod media_signals;
pub mod shorts;
pub mod transcribe;

/// Аудиокодеки, которые QuickTime и плееры Apple воспроизводят из MP4.
const APPLE_AUDIO: &[&str] = &["aac", "mp3", "ac3", "eac3", "alac"];

#[derive(Debug)]
pub enum Error {
    /// ffmpeg не найден или не запускается.
    FfmpegMissing(String),
    /// Все способы конвертации завершились ошибкой; внутри — сообщение ffmpeg.
    Failed(String),
    /// Конвертацию отменили.
    Cancelled,
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::FfmpegMissing(e) => write!(f, "не удалось запустить ffmpeg: {e}"),
            Error::Failed(e) if e.is_empty() => write!(f, "ошибка конвертации"),
            Error::Failed(e) => write!(f, "ошибка конвертации: {e}"),
            Error::Cancelled => write!(f, "отменено"),
        }
    }
}

impl std::error::Error for Error {}

/// События во время конвертации.
#[derive(Debug, Clone)]
pub enum Event {
    /// Начата очередная попытка (описание способа).
    Attempt(String),
    /// Информационное сообщение.
    Info(String),
    /// Прогресс от 0.0 до 1.0.
    Progress(f64),
}

pub struct Options<'a> {
    /// Путь к ffmpeg.
    pub ffmpeg: &'a Path,
    /// Полное перекодирование видео вместо ремукса.
    pub reencode: bool,
    /// Если выставлен в true — конвертация прерывается.
    pub cancel: Option<&'a AtomicBool>,
}

/// Ищет ffmpeg: рядом с исполняемым файлом, в Resources бандла .app, затем в PATH.
pub fn find_ffmpeg() -> PathBuf {
    find_tool("ffmpeg", "MKV2MP4_FFMPEG")
}

/// Ищет внешнюю программу `name`: путь из переменной `env`, рядом с исполняемым файлом,
/// в Resources бандла .app, затем в PATH.
pub(crate) fn find_tool(name: &str, env: &str) -> PathBuf {
    if let Some(p) = std::env::var_os(env) {
        return PathBuf::from(p);
    }
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            for candidate in [dir.join(name), dir.join("../Resources").join(name)] {
                if candidate.is_file() {
                    return candidate.canonicalize().unwrap_or(candidate);
                }
            }
        }
    }
    PathBuf::from(name)
}

/// Запускается ли программа `tool` с аргументом `arg`.
pub fn check_tool(tool: &Path, arg: &str) -> bool {
    Command::new(tool)
        .arg(arg)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok()
}

pub fn check_ffmpeg(ffmpeg: &Path) -> Result<(), Error> {
    Command::new(ffmpeg)
        .arg("-version")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|_| ())
        .map_err(|e| Error::FfmpegMissing(format!("{} ({e})", ffmpeg.display())))
}

/// Расширения видеофайлов, которые принимаются на вход.
pub const VIDEO_EXTENSIONS: &[&str] = &[
    "mkv", "mp4", "m4v", "mov", "avi", "webm", "ts", "m2ts", "mts", "flv", "wmv", "mpg", "mpeg",
    "3gp", "ogv",
];

pub fn is_video(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .is_some_and(|e| VIDEO_EXTENSIONS.iter().any(|v| e.eq_ignore_ascii_case(v)))
}

/// Путь к .mp4: рядом с исходником или в `out_dir`.
pub fn output_path(input: &Path, out_dir: Option<&Path>) -> PathBuf {
    output_path_in_batch(input, out_dir, &[])
}

/// Путь к .mp4, который не совпадает ни с исходником, ни с другими файлами очереди
/// `batch`, ни с результатами файлов, стоящих в очереди раньше (в одной папке могут лежать
/// `a.avi`, `a.mov` и `a.mp4`). При совпадении к имени добавляется `_mp4`, `_mp4_2`, …
pub fn output_path_in_batch(input: &Path, out_dir: Option<&Path>, batch: &[PathBuf]) -> PathBuf {
    let key = |p: &Path| p.to_string_lossy().to_lowercase();
    let mut taken: Vec<String> = batch.iter().map(|p| key(p)).collect();
    taken.push(key(input));
    for other in batch {
        let out = free_output(other, out_dir, &taken);
        if key(other) == key(input) {
            return out;
        }
        taken.push(key(&out));
    }
    free_output(input, out_dir, &taken)
}

fn free_output(input: &Path, out_dir: Option<&Path>, taken: &[String]) -> PathBuf {
    let name = input.with_extension("mp4");
    let out = match out_dir {
        Some(dir) => dir.join(name.file_name().expect("у файла есть имя")),
        None => name,
    };
    let is_taken = |p: &Path| taken.contains(&p.to_string_lossy().to_lowercase());
    if !is_taken(&out) {
        return out;
    }
    let stem = input.file_stem().and_then(|s| s.to_str()).unwrap_or("video");
    (1..)
        .map(|n| {
            let suffix = if n == 1 { String::new() } else { format!("_{n}") };
            out.with_file_name(format!("{stem}_mp4{suffix}.mp4"))
        })
        .find(|p| !is_taken(p))
        .expect("бесконечный ряд имён")
}

/// Сведения о файле из вывода `ffmpeg -i`.
struct Probe {
    duration_us: Option<u64>,
    audio_codecs: Vec<String>,
}

fn probe(ffmpeg: &Path, input: &Path) -> Result<Probe, Error> {
    let text = ffmpeg_info(ffmpeg, input)?;

    // "  Duration: 01:02:03.45, start: ..."
    let duration_us = text
        .lines()
        .find_map(|l| l.trim_start().strip_prefix("Duration: "))
        .and_then(|rest| rest.split(',').next())
        .and_then(parse_timestamp_us);

    // "  Stream #0:1(rus): Audio: aac (LC), 48000 Hz, stereo"
    let audio_codecs = text
        .lines()
        .filter(|l| l.trim_start().starts_with("Stream #"))
        .filter_map(|l| l.split_once(": Audio: ").map(|(_, rest)| rest))
        .filter_map(|rest| rest.split([' ', ',', '(']).next())
        .filter(|c| !c.is_empty())
        .map(str::to_string)
        .collect();

    Ok(Probe { duration_us, audio_codecs })
}

/// "01:02:03.45" → микросекунды.
pub(crate) fn parse_timestamp_us(s: &str) -> Option<u64> {
    let mut parts = s.trim().split(':');
    let h: f64 = parts.next()?.parse().ok()?;
    let m: f64 = parts.next()?.parse().ok()?;
    let sec: f64 = parts.next()?.parse().ok()?;
    Some(((h * 3600.0 + m * 60.0 + sec) * 1_000_000.0) as u64)
}

fn strings(args: &[&str]) -> Vec<String> {
    args.iter().map(|s| s.to_string()).collect()
}

/// Для каждой аудиодорожки: совместимую копируем, остальные перекодируем в AAC.
fn audio_args(codecs: &[String], on_event: &mut dyn FnMut(Event)) -> Vec<String> {
    let mut args = Vec::new();
    for (i, codec) in codecs.iter().enumerate() {
        if APPLE_AUDIO.contains(&codec.as_str()) {
            args.extend([format!("-c:a:{i}"), "copy".into()]);
        } else {
            on_event(Event::Info(format!(
                "аудиодорожка {i}: {codec} → AAC (для совместимости с macOS)"
            )));
            args.extend([format!("-c:a:{i}"), "aac".into(), format!("-b:a:{i}"), "192k".into()]);
        }
    }
    args
}

/// Конвертирует один файл. Существующий `output` перезаписывается.
pub fn convert(
    input: &Path,
    output: &Path,
    opts: &Options,
    on_event: &mut dyn FnMut(Event),
) -> Result<(), Error> {
    let info = probe(opts.ffmpeg, input)?;

    // Попытки от самой быстрой к самой надёжной.
    let attempts: Vec<(&str, Vec<String>)> = if opts.reencode {
        vec![(
            "перекодирование H.264/AAC",
            strings(&[
                "-map", "0:v:0", "-map", "0:a?", "-c:v", "h264_videotoolbox", "-q:v", "65",
                "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
            ]),
        )]
    } else {
        let audio = audio_args(&info.audio_codecs, on_event);
        let with = |base: &[&str], extra: &[&str]| {
            let mut v = strings(base);
            v.extend(audio.iter().cloned());
            v.extend(strings(extra));
            v
        };
        vec![
            (
                "ремукс (видео и субтитры без перекодирования)",
                with(&["-map", "0:v", "-map", "0:a?", "-map", "0:s?", "-c", "copy"], &["-c:s", "mov_text"]),
            ),
            (
                "ремукс без субтитров",
                with(&["-map", "0:v", "-map", "0:a?", "-c", "copy"], &[]),
            ),
            (
                "видео без изменений, всё аудио → AAC",
                strings(&[
                    "-map", "0:v", "-map", "0:a?", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
                ]),
            ),
        ]
    };

    let mut last_error = String::new();
    for (label, args) in &attempts {
        on_event(Event::Attempt(label.to_string()));
        on_event(Event::Progress(0.0));
        match run_ffmpeg(input, output, args, &info, opts, on_event) {
            Ok(()) => {
                on_event(Event::Progress(1.0));
                return Ok(());
            }
            Err(Error::Failed(msg)) => {
                let _ = fs::remove_file(output);
                last_error = msg;
            }
            Err(e) => {
                let _ = fs::remove_file(output);
                return Err(e);
            }
        }
    }
    Err(Error::Failed(last_error))
}

fn run_ffmpeg(
    input: &Path,
    output: &Path,
    codec_args: &[String],
    info: &Probe,
    opts: &Options,
    on_event: &mut dyn FnMut(Event),
) -> Result<(), Error> {
    let mut args: Vec<OsString> = vec!["-i".into(), input.into()];
    args.extend(codec_args.iter().map(OsString::from));
    args.extend(["-movflags".into(), "+faststart".into(), output.into()]);
    run_ffmpeg_args(opts.ffmpeg, &args, info.duration_us, opts.cancel, &mut |p| {
        on_event(Event::Progress(p))
    })
}

/// Запускает ffmpeg с аргументами `args` (без общих флагов вывода), читает прогресс
/// относительно `duration_us` и прерывает процесс, если выставлен `cancel`.
pub(crate) fn run_ffmpeg_args(
    ffmpeg: &Path,
    args: &[OsString],
    duration_us: Option<u64>,
    cancel: Option<&AtomicBool>,
    on_progress: &mut dyn FnMut(f64),
) -> Result<(), Error> {
    let mut child = Command::new(ffmpeg)
        .args(["-hide_banner", "-loglevel", "error", "-nostats", "-progress", "pipe:1", "-y"])
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| Error::FfmpegMissing(e.to_string()))?;

    // stderr читаем в отдельном потоке, чтобы ffmpeg не заблокировался на полном буфере.
    let mut stderr = child.stderr.take().expect("stderr piped");
    let stderr_thread = thread::spawn(move || {
        let mut s = String::new();
        let _ = stderr.read_to_string(&mut s);
        s
    });

    let stdout = child.stdout.take().expect("stdout piped");
    let mut cancelled = false;
    for line in BufReader::new(stdout).lines().map_while(Result::ok) {
        if cancel.is_some_and(|c| c.load(Ordering::Relaxed)) {
            let _ = child.kill();
            cancelled = true;
            break;
        }
        if let (Some(us), Some(total)) = (line.strip_prefix("out_time_us="), duration_us) {
            if let Ok(us) = us.parse::<u64>() {
                if total > 0 {
                    on_progress((us as f64 / total as f64).clamp(0.0, 1.0));
                }
            }
        }
    }

    let status = child.wait().map_err(|e| Error::Failed(e.to_string()))?;
    let stderr = stderr_thread.join().unwrap_or_default();
    if cancelled {
        return Err(Error::Cancelled);
    }
    if status.success() {
        Ok(())
    } else {
        Err(Error::Failed(stderr.trim().lines().last().unwrap_or("").to_string()))
    }
}

/// Текстовый вывод `ffmpeg -i` (описание потоков, длительность).
pub(crate) fn ffmpeg_info(ffmpeg: &Path, input: &Path) -> Result<String, Error> {
    let output = Command::new(ffmpeg)
        .args(["-hide_banner", "-i"])
        .arg(input)
        .stdin(Stdio::null())
        .output()
        .map_err(|e| Error::FfmpegMissing(e.to_string()))?;
    Ok(String::from_utf8_lossy(&output.stderr).into_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_timestamp() {
        assert_eq!(parse_timestamp_us("00:00:03.00"), Some(3_000_000));
        assert_eq!(parse_timestamp_us("01:02:03.5"), Some(3_723_500_000));
        assert_eq!(parse_timestamp_us("N/A"), None);
    }

    #[test]
    fn output_next_to_input_or_in_dir() {
        assert_eq!(output_path(Path::new("/a/b.mkv"), None), PathBuf::from("/a/b.mp4"));
        assert_eq!(
            output_path(Path::new("/a/b.MKV"), Some(Path::new("/out"))),
            PathBuf::from("/out/b.mp4")
        );
        // MP4 рядом с собой не перезаписывается, в другую папку — с тем же именем.
        assert_eq!(output_path(Path::new("/a/b.MP4"), None), PathBuf::from("/a/b_mp4.mp4"));
        // b.avi рядом с b.mp4 из той же очереди не затирает его.
        // В очереди b.avi, b.mov, b.mp4: у каждого свой результат, исходники не затираются.
        let batch = [PathBuf::from("/a/b.avi"), PathBuf::from("/a/b.mov"), PathBuf::from("/a/b.mp4")];
        let outs: Vec<PathBuf> = batch.iter().map(|i| output_path_in_batch(i, None, &batch)).collect();
        assert_eq!(outs, [PathBuf::from("/a/b_mp4.mp4"), PathBuf::from("/a/b_mp4_2.mp4"), PathBuf::from("/a/b_mp4_3.mp4")]);
        assert_eq!(output_path_in_batch(Path::new("/a/c.avi"), None, &batch), PathBuf::from("/a/c.mp4"));
        assert_eq!(output_path(Path::new("/a/b.mp4"), Some(Path::new("/out"))), PathBuf::from("/out/b.mp4"));
    }

    #[test]
    fn accepts_video_formats() {
        for f in ["a.mkv", "b.MOV", "c.webm", "d.avi", "e.mp4", "f.m2ts"] {
            assert!(is_video(Path::new(f)), "{f}");
        }
        for f in ["a.srt", "b.txt", "c", "d.mp3"] {
            assert!(!is_video(Path::new(f)), "{f}");
        }
    }
}
