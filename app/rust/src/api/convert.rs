use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};

use mkv2mp4_core::{self as core, Event, Options};

use crate::frb_generated::StreamSink;

pub(crate) static CANCEL: AtomicBool = AtomicBool::new(false);

/// Событие конвертации для Dart.
pub enum ConvertEvent {
    /// Начат очередной способ конвертации.
    Attempt { label: String },
    Info { message: String },
    /// Прогресс от 0.0 до 1.0.
    Progress { value: f64 },
    Done { output: String },
    /// .mp4 уже существует, конвертация пропущена.
    Skipped { output: String },
    Cancelled,
    Error { message: String },
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// Путь к ffmpeg, если он доступен, иначе None.
#[flutter_rust_bridge::frb(sync)]
pub fn ffmpeg_path() -> Option<String> {
    let ffmpeg = core::find_ffmpeg();
    core::check_ffmpeg(&ffmpeg).ok()?;
    Some(ffmpeg.display().to_string())
}

/// Расширения видео, которые принимаются на вход (для диалога выбора файлов).
#[flutter_rust_bridge::frb(sync)]
pub fn video_extensions() -> Vec<String> {
    core::VIDEO_EXTENSIONS.iter().map(|e| e.to_string()).collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn is_video(path: String) -> bool {
    core::is_video(Path::new(&path))
}

/// Куда будет записан результат: рядом с исходником или в `out_dir`, не поверх других
/// файлов очереди `batch`.
#[flutter_rust_bridge::frb(sync)]
pub fn output_path_for(input: String, out_dir: Option<String>, batch: Vec<String>) -> String {
    let out_dir = out_dir.map(PathBuf::from);
    let batch: Vec<PathBuf> = batch.into_iter().map(PathBuf::from).collect();
    core::output_path_in_batch(Path::new(&input), out_dir.as_deref(), &batch)
        .display()
        .to_string()
}

/// Прерывает текущую конвертацию или нарезку.
#[flutter_rust_bridge::frb(sync)]
pub fn cancel() {
    CANCEL.store(true, Ordering::Relaxed);
}

/// Конвертирует один файл, отправляя события в `sink`. Поток закрывается по завершении.
/// `batch` — все файлы очереди: результат не запишется поверх любого из них.
pub fn convert_file(
    input: String,
    out_dir: Option<String>,
    reencode: bool,
    overwrite: bool,
    batch: Vec<String>,
    sink: StreamSink<ConvertEvent>,
) {
    CANCEL.store(false, Ordering::Relaxed);
    let input = PathBuf::from(input);
    let out_dir = out_dir.map(PathBuf::from);
    let batch: Vec<PathBuf> = batch.into_iter().map(PathBuf::from).collect();
    let output = core::output_path_in_batch(&input, out_dir.as_deref(), &batch);
    let out_str = output.display().to_string();

    if output.exists() && !overwrite {
        let _ = sink.add(ConvertEvent::Skipped { output: out_str });
        return;
    }
    if let Some(dir) = &out_dir {
        if let Err(e) = std::fs::create_dir_all(dir) {
            let _ = sink.add(ConvertEvent::Error { message: format!("не удалось создать папку: {e}") });
            return;
        }
    }

    let ffmpeg = core::find_ffmpeg();
    let opts = Options { ffmpeg: &ffmpeg, reencode, cancel: Some(&CANCEL) };
    let mut on_event = |e: Event| {
        let _ = sink.add(match e {
            Event::Attempt(label) => ConvertEvent::Attempt { label },
            Event::Info(message) => ConvertEvent::Info { message },
            Event::Progress(value) => ConvertEvent::Progress { value },
        });
    };
    let result = core::convert(&input, &output, &opts, &mut on_event);
    let _ = sink.add(match result {
        Ok(()) => ConvertEvent::Done { output: out_str },
        Err(core::Error::Cancelled) => ConvertEvent::Cancelled,
        Err(e) => ConvertEvent::Error { message: e.to_string() },
    });
}
