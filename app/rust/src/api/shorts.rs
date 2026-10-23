use std::path::{Path, PathBuf};
use std::sync::atomic::Ordering;

use mkv2mp4_core::{self as core, shorts, transcribe};

use super::convert::CANCEL;
use crate::frb_generated::StreamSink;

/// Дорожка аудио или субтитров.
pub struct TrackInfo {
    /// Номер среди дорожек того же типа.
    pub index: u32,
    pub codec: String,
    pub language: Option<String>,
    pub title: Option<String>,
    pub is_default: bool,
    /// Для субтитров: текстовые (а не картинки).
    pub is_text: bool,
}

pub struct MediaInfo {
    pub duration: f64,
    pub audio: Vec<TrackInfo>,
    pub subtitles: Vec<TrackInfo>,
}

pub enum ShortsEvent {
    Stage { message: String },
    /// Общий прогресс от 0.0 до 1.0.
    Progress { value: f64 },
    Clip { index: u32, total: u32, path: String },
    /// Нарезка продолжается, но что-то пошло не так (например, текст не вычитан).
    Warning { message: String },
    Done { dir: String, clips: u32 },
    Cancelled,
    Error { message: String },
}

fn track(t: shorts::Track) -> TrackInfo {
    TrackInfo {
        is_text: t.is_text(),
        index: t.index,
        codec: t.codec,
        language: t.language,
        title: t.title,
        is_default: t.is_default,
    }
}

/// Длительность и дорожки файла.
pub fn probe_media(path: String) -> Result<MediaInfo, String> {
    let info = shorts::probe_media(&core::find_ffmpeg(), Path::new(&path)).map_err(|e| e.to_string())?;
    Ok(MediaInfo {
        duration: info.duration,
        audio: info.audio.into_iter().map(track).collect(),
        subtitles: info.subtitles.into_iter().map(track).collect(),
    })
}

/// Папка, куда лягут ролики: `<имя>_tiktok` рядом с исходником или в `out_root`.
#[flutter_rust_bridge::frb(sync)]
pub fn shorts_dir_for(input: String, out_root: Option<String>) -> String {
    let out_root = out_root.map(PathBuf::from);
    shorts::shorts_dir(Path::new(&input), out_root.as_deref()).display().to_string()
}

/// Как показывать текст реплики.
pub enum CaptionStyle {
    /// Страница текста целиком, звучащее слово подсвечено.
    Highlight,
    /// Слова появляются по мере речи.
    Reveal,
    /// Слова появляются по мере речи, звучащее подсвечено.
    RevealHighlight,
    /// Реплика целиком.
    Whole,
}

/// Настройки распознавания речи.
pub struct SpeechConfig {
    /// Путь к .env (создаётся с пустым ключом, если его не было).
    pub env_file: String,
    /// В .env или окружении задан ANTHROPIC_API_KEY.
    pub has_api_key: bool,
    /// whisper-cli найден.
    pub whisper_available: bool,
}

/// Читает .env заново (ключ могли вписать, пока приложение открыто).
pub fn speech_config() -> Result<SpeechConfig, String> {
    let env_file = transcribe::ensure_env_file().map_err(|e| e.to_string())?;
    Ok(SpeechConfig {
        env_file: env_file.display().to_string(),
        has_api_key: transcribe::Config::load().api_key.is_some(),
        whisper_available: core::check_tool(&transcribe::find_whisper(), "--help"),
    })
}

/// Нарезает файл на ролики для TikTok, отправляя события в `sink`.
/// `subtitle_track` — дорожка субтитров; `None` — распознать речь.

pub fn make_shorts(
    input: String,
    out_root: Option<String>,
    subtitle_track: Option<u32>,
    audio_track: u32,
    max_len: f64,
    captions: CaptionStyle,
    best_moments: bool,
    sink: StreamSink<ShortsEvent>,
) {
    CANCEL.store(false, Ordering::Relaxed);
    let input = PathBuf::from(input);
    let out_root = out_root.map(PathBuf::from);
    let dir = shorts::shorts_dir(&input, out_root.as_deref());
    let ffmpeg = core::find_ffmpeg();
    let opts = shorts::ShortsOptions {
        ffmpeg: &ffmpeg,
        subtitle_track,
        audio_track,
        max_len,
        captions: match captions {
            CaptionStyle::Highlight => shorts::CaptionStyle::Highlight,
            CaptionStyle::Reveal => shorts::CaptionStyle::Reveal,
            CaptionStyle::RevealHighlight => shorts::CaptionStyle::RevealHighlight,
            CaptionStyle::Whole => shorts::CaptionStyle::Whole,
        },
        best_moments,
        cancel: Some(&CANCEL),
    };
    let mut on_event = |e: shorts::ShortsEvent| {
        let _ = sink.add(match e {
            shorts::ShortsEvent::Stage(message) => ShortsEvent::Stage { message },
            shorts::ShortsEvent::Progress(value) => ShortsEvent::Progress { value },
            shorts::ShortsEvent::Clip { index, total, path } => ShortsEvent::Clip {
                index: index as u32,
                total: total as u32,
                path: path.display().to_string(),
            },
            shorts::ShortsEvent::Warning(message) => ShortsEvent::Warning { message },
        });
    };
    let result = shorts::make_shorts(&input, &dir, &opts, &mut on_event);
    let _ = sink.add(match result {
        Ok(clips) => ShortsEvent::Done { dir: dir.display().to_string(), clips: clips.len() as u32 },
        Err(core::Error::Cancelled) => ShortsEvent::Cancelled,
        Err(e) => ShortsEvent::Error { message: e.to_string() },
    });
}
