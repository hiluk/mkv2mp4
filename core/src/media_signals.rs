//! Сигналы из звука и монтажа для отбора моментов (громкость, склейки) и раскадровки
//! отрезков: листы 4×4 кадра, которые смотрит Claude.

use std::ffi::OsString;
use std::io::{BufRead, BufReader, Read};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;

use crate::Error;

/// Частота звука для замера громкости: для огибающей больше не нужно.
const RATE: usize = 8000;
/// Порог детектора смены сцены ffmpeg.
const SCENE_THRESHOLD: &str = "0.3";
/// Раскадровка: кадров в ряд и рядов на листе, ширина кадра.
pub const SHEET_COLS: usize = 4;
pub const SHEET_ROWS: usize = 4;
const FRAME_W: u32 = 240;

/// Громкость по секундам и моменты склеек.
#[derive(Debug, Clone, Default)]
pub struct Signals {
    /// Средняя громкость каждой секунды, дБ (−90 — тишина).
    pub loudness: Vec<f64>,
    /// Времена смены сцены, секунды по возрастанию.
    pub cuts: Vec<f64>,
}

/// Насколько громко на отрезке относительно видео в целом.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Loudness {
    Low,
    Normal,
    High,
}

impl Signals {
    fn median(&self) -> f64 {
        let mut v: Vec<f64> = self.loudness.iter().copied().filter(|&d| d > -80.0).collect();
        if v.is_empty() {
            return -90.0;
        }
        v.sort_by(f64::total_cmp);
        v[v.len() / 2]
    }

    /// Громкость отрезка `[a, b)` относительно медианы видео: громче на 6 дБ — `High`,
    /// тише на 10 дБ — `Low`.
    pub fn loudness_of(&self, a: f64, b: f64) -> Loudness {
        let (i, j) = (a.max(0.0) as usize, (b.ceil() as usize).min(self.loudness.len()));
        if i >= j {
            return Loudness::Normal;
        }
        // Средняя мощность, а не средние децибелы: короткий крик должен поднимать отрезок.
        let power: f64 = self.loudness[i..j].iter().map(|d| 10f64.powf(d / 10.0)).sum::<f64>() / (j - i) as f64;
        let db = 10.0 * power.max(1e-9).log10();
        let median = self.median();
        if db > median + 6.0 {
            Loudness::High
        } else if db < median - 10.0 {
            Loudness::Low
        } else {
            Loudness::Normal
        }
    }

    /// Число склеек на отрезке `[a, b)`.
    pub fn cuts_in(&self, a: f64, b: f64) -> usize {
        self.cuts.iter().filter(|&&t| t >= a && t < b).count()
    }
}

/// Громкость (по выбранной аудиодорожке) и склейки, параллельно.
pub fn analyze(ffmpeg: &Path, input: &Path, audio_track: u32, cancel: Option<&AtomicBool>) -> Result<Signals, Error> {
    let (f1, i1) = (ffmpeg.to_path_buf(), input.to_path_buf());
    let audio = thread::spawn(move || loudness(&f1, &i1, audio_track));
    let cuts = scene_cuts(ffmpeg, input, cancel)?;
    let loudness = audio.join().map_err(|_| Error::Failed("сбой замера громкости".into()))??;
    Ok(Signals { loudness, cuts })
}

fn loudness(ffmpeg: &Path, input: &Path, audio_track: u32) -> Result<Vec<f64>, Error> {
    let mut child = Command::new(ffmpeg)
        .args(["-hide_banner", "-loglevel", "error", "-i"])
        .arg(input)
        .args(["-map", &format!("0:a:{audio_track}"), "-ac", "1", "-ar", &RATE.to_string(), "-f", "s16le", "pipe:1"])
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| Error::FfmpegMissing(e.to_string()))?;
    let mut out = child.stdout.take().expect("stdout piped");
    let mut buf = vec![0u8; RATE * 2];
    let mut result = Vec::new();
    loop {
        // Ровно секунда звука (или остаток в конце).
        let mut filled = 0;
        while filled < buf.len() {
            match out.read(&mut buf[filled..]) {
                Ok(0) => break,
                Ok(n) => filled += n,
                Err(e) => return Err(Error::Failed(e.to_string())),
            }
        }
        if filled < 2 {
            break;
        }
        result.push(rms_db(&buf[..filled - filled % 2]));
        if filled < buf.len() {
            break;
        }
    }
    let _ = child.wait();
    Ok(result)
}

/// Среднеквадратичная громкость 16-битных отсчётов, дБ относительно полной шкалы.
fn rms_db(pcm: &[u8]) -> f64 {
    let n = pcm.len() / 2;
    let sum: f64 = pcm
        .chunks_exact(2)
        .map(|c| {
            let s = i16::from_le_bytes([c[0], c[1]]) as f64 / 32768.0;
            s * s
        })
        .sum();
    let rms = (sum / n.max(1) as f64).sqrt();
    (20.0 * rms.max(1e-9).log10()).max(-90.0)
}

fn scene_cuts(ffmpeg: &Path, input: &Path, cancel: Option<&AtomicBool>) -> Result<Vec<f64>, Error> {
    let filter = format!("scale=160:-2,select='gt(scene,{SCENE_THRESHOLD})',showinfo");
    let mut child = Command::new(ffmpeg)
        .args(["-hide_banner", "-nostats", "-i"])
        .arg(input)
        .args(["-an", "-sn", "-vf", &filter, "-threads", "8", "-f", "null", "-"])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| Error::FfmpegMissing(e.to_string()))?;
    let stderr = child.stderr.take().expect("stderr piped");
    let mut cuts = Vec::new();
    for line in BufReader::new(stderr).lines().map_while(Result::ok) {
        if cancel.is_some_and(|c| c.load(Ordering::Relaxed)) {
            let _ = child.kill();
            let _ = child.wait();
            return Err(Error::Cancelled);
        }
        if let Some(t) = parse_pts_time(&line) {
            cuts.push(t);
        }
    }
    let _ = child.wait();
    Ok(cuts)
}

/// "[Parsed_showinfo_2 …] n:  3 pts: 1234 pts_time:41.08 …" → 41.08
fn parse_pts_time(line: &str) -> Option<f64> {
    if !line.contains("showinfo") {
        return None;
    }
    line.split("pts_time:").nth(1)?.split_whitespace().next()?.parse().ok()
}

/// Листы раскадровки отрезка `[start, end]`: кадр каждые `step` секунд, по
/// [`SHEET_COLS`]×[`SHEET_ROWS`] на лист, слева направо и сверху вниз. JPEG в `dir`.
pub fn storyboard(
    ffmpeg: &Path,
    input: &Path,
    start: f64,
    end: f64,
    step: f64,
    dir: &Path,
    prefix: &str,
) -> Result<Vec<PathBuf>, Error> {
    let filter = format!("fps=1/{step},scale={FRAME_W}:-2,tile={SHEET_COLS}x{SHEET_ROWS}");
    let pattern = dir.join(format!("{prefix}_%02d.jpg"));
    let args: Vec<OsString> = ["-hide_banner", "-loglevel", "error", "-y", "-ss", &format!("{start:.3}"), "-t"]
        .iter()
        .map(OsString::from)
        .chain([format!("{:.3}", end - start).into(), "-i".into(), input.into()])
        .chain(["-an", "-sn", "-vf", &filter, "-q:v", "5"].iter().map(OsString::from))
        .chain([pattern.into()])
        .collect();
    let out = Command::new(ffmpeg)
        .args(&args)
        .stdin(Stdio::null())
        .output()
        .map_err(|e| Error::FfmpegMissing(e.to_string()))?;
    if !out.status.success() {
        let err = String::from_utf8_lossy(&out.stderr);
        return Err(Error::Failed(format!("раскадровка: {}", err.trim().lines().last().unwrap_or(""))));
    }
    let mut sheets: Vec<PathBuf> = std::fs::read_dir(dir)
        .map_err(|e| Error::Failed(e.to_string()))?
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| {
            p.file_name()
                .and_then(|n| n.to_str())
                .is_some_and(|n| n.starts_with(&format!("{prefix}_")) && n.ends_with(".jpg"))
        })
        .collect();
    sheets.sort();
    Ok(sheets)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn measures_rms() {
        let silence = vec![0u8; 1600];
        assert_eq!(rms_db(&silence), -90.0);
        // Полная шкала: отсчёты ±32767.
        let loud: Vec<u8> = (0..800).flat_map(|i| if i % 2 == 0 { 32767i16 } else { -32767 }.to_le_bytes()).collect();
        assert!(rms_db(&loud).abs() < 0.01);
    }

    #[test]
    fn rates_loudness_and_cuts() {
        let mut loudness = vec![-30.0; 100];
        loudness[50..55].iter_mut().for_each(|d| *d = -10.0);
        loudness[80..90].iter_mut().for_each(|d| *d = -60.0);
        let s = Signals { loudness, cuts: vec![1.0, 50.5, 51.0, 52.0, 99.0] };
        assert_eq!(s.loudness_of(48.0, 56.0), Loudness::High);
        assert_eq!(s.loudness_of(10.0, 20.0), Loudness::Normal);
        assert_eq!(s.loudness_of(80.0, 90.0), Loudness::Low);
        assert_eq!(s.cuts_in(50.0, 53.0), 3);
        assert_eq!(Signals::default().loudness_of(0.0, 10.0), Loudness::Normal);
    }

    #[test]
    fn parses_showinfo() {
        let line = "[Parsed_showinfo_2 @ 0x1] n:   3 pts:  41080 pts_time:41.08   duration:40";
        assert_eq!(parse_pts_time(line), Some(41.08));
        assert_eq!(parse_pts_time("frame=  10 fps=0.0 q=-0.0"), None);
    }
}
