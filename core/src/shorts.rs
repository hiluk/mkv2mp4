//! Нарезка видео на вертикальные ролики для TikTok с вшитыми субтитрами.
//!
//! Кадр 1080×1920: исходное видео целиком по центру, чёрные поля сверху и снизу,
//! субтитры крупным текстом на нижнем поле. Текст берётся из дорожки субтитров файла
//! или распознаётся из звука ([`crate::transcribe`]), разрезы ставятся в паузах между репликами.
//!
//! Наш ffmpeg собран без libass/freetype, поэтому текст рисуется здесь (cosmic-text)
//! в PNG-картинки полосы субтитров, которые ffmpeg накладывает поверх кадра.

use std::collections::HashMap;
use std::ffi::OsString;
use std::fmt::Write as _;
use std::fs::{self, File};
use std::io::BufWriter;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::AtomicBool;
use std::sync::Arc;

use cosmic_text::{Align, Attrs, Buffer, Color, Family, FontSystem, Metrics, Shaping, SwashCache, Weight};

use crate::highlights;
use crate::transcribe::{self, SpeechOptions};
use crate::{ffmpeg_info, parse_timestamp_us, run_ffmpeg_args, Error};

pub const FRAME_W: u32 = 1080;
pub const FRAME_H: u32 = 1920;
/// Минимальная высота полосы субтитров (если поля под видео меньше — полоса ляжет на видео).
const MIN_STRIP_H: u32 = 420;
/// Кодеки текстовых субтитров, которые можно превратить в текст.
const TEXT_SUBS: &[&str] = &["subrip", "srt", "ass", "ssa", "webvtt", "mov_text", "text"];

/// Аудио- или субтитровая дорожка.
#[derive(Debug, Clone, PartialEq)]
pub struct Track {
    /// Номер среди дорожек того же типа (для `-map 0:s:N` / `0:a:N`).
    pub index: u32,
    pub codec: String,
    pub language: Option<String>,
    pub title: Option<String>,
    pub is_default: bool,
}

impl Track {
    /// Можно ли получить из дорожки текст (не картинки PGS/VobSub).
    pub fn is_text(&self) -> bool {
        TEXT_SUBS.contains(&self.codec.as_str())
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct MediaInfo {
    pub duration: f64,
    /// Соотношение сторон кадра при показе (с учётом SAR).
    pub aspect: f64,
    pub audio: Vec<Track>,
    pub subtitles: Vec<Track>,
}

/// Реплика субтитров, время в секундах.
#[derive(Debug, Clone, PartialEq)]
pub struct Cue {
    pub start: f64,
    pub end: f64,
    pub text: String,
    /// Когда звучат слова: (доля текста по символам, время начала слова), по возрастанию.
    /// Доли, а не номера слов, чтобы точки пережили вычитку текста. Пусто — слова
    /// распределяются по длительности реплики пропорционально длине.
    pub words: Vec<(f64, f64)>,
}

/// Невидимая часть текста полосы субтитров: между `HIDE` и `SHOW`.
const HIDE: char = '\u{1}';
const SHOW: char = '\u{2}';
/// Подсвеченная часть текста: между `MARK` и `UNMARK`.
const MARK: char = '\u{3}';
const UNMARK: char = '\u{4}';

/// Шрифт субтитров (OFL, `fonts/TikTokSans-OFL.txt`).
const FONT: &[u8] = include_bytes!("../fonts/TikTokSans36pt-SemiBold.ttf");
const TEXT_COLOR: Color = Color::rgb(235, 235, 235);
const HIGHLIGHT_COLOR: Color = Color::rgb(200, 222, 130);

/// Как показывать текст реплики.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CaptionStyle {
    /// Страница текста целиком, слово, которое сейчас звучит, подсвечено.
    Highlight,
    /// Слова появляются по мере речи.
    Reveal,
    /// Слова появляются по мере речи, последнее (звучащее) подсвечено.
    RevealHighlight,
    /// Реплика целиком, как в субтитрах.
    Whole,
}

#[derive(Debug, Clone)]
pub enum ShortsEvent {
    Stage(String),
    /// Общий прогресс от 0.0 до 1.0.
    Progress(f64),
    /// Готов ролик `index` (с 1) из `total`.
    Clip { index: usize, total: usize, path: PathBuf },
    /// Нарезка продолжается, но что-то пошло не так (например, текст не вычитан).
    Warning(String),
}

pub struct ShortsOptions<'a> {
    pub ffmpeg: &'a Path,
    /// Номер дорожки субтитров среди субтитров; `None` — распознать речь.
    pub subtitle_track: Option<u32>,
    /// Номер аудиодорожки среди аудио.
    pub audio_track: u32,
    /// Максимальная длина ролика в секундах.
    pub max_len: f64,
    pub captions: CaptionStyle,
    /// Нарезать только лучшие моменты (их выбирает Claude), а не всё видео подряд.
    pub best_moments: bool,
    pub cancel: Option<&'a AtomicBool>,
}

// ---------------------------------------------------------------------------
// Разбор информации о файле

pub fn probe_media(ffmpeg: &Path, input: &Path) -> Result<MediaInfo, Error> {
    Ok(parse_media_info(&ffmpeg_info(ffmpeg, input)?))
}

fn parse_media_info(text: &str) -> MediaInfo {
    let duration = text
        .lines()
        .find_map(|l| l.trim_start().strip_prefix("Duration: "))
        .and_then(|rest| rest.split(',').next())
        .and_then(parse_timestamp_us)
        .map_or(0.0, |us| us as f64 / 1e6);

    let mut aspect = 16.0 / 9.0;
    let mut have_video = false;
    let mut audio = Vec::new();
    let mut subtitles: Vec<Track> = Vec::new();
    // К какой дорожке относятся следующие строки Metadata (title).
    let mut last: Option<(bool, usize)> = None; // (is_subtitle, idx)

    for line in text.lines() {
        let t = line.trim_start();
        if t.starts_with("Stream #") {
            last = None;
            let Some((head, rest)) = t.split_once(": ") else { continue };
            let language = head
                .rsplit_once('(')
                .and_then(|(_, l)| l.strip_suffix(')'))
                .filter(|l| *l != "und")
                .map(str::to_string);
            let is_default = rest.contains("(default)");
            let codec_of = |r: &str| r.split([' ', ',', '(']).next().unwrap_or("").to_string();

            if let Some(r) = rest.strip_prefix("Video: ") {
                if !have_video && !rest.contains("attached pic") {
                    have_video = true;
                    if let Some(a) = parse_aspect(r) {
                        aspect = a;
                    }
                }
            } else if let Some(r) = rest.strip_prefix("Audio: ") {
                let index = audio.len() as u32;
                audio.push(Track { index, codec: codec_of(r), language, title: None, is_default });
                last = Some((false, audio.len() - 1));
            } else if let Some(r) = rest.strip_prefix("Subtitle: ") {
                let index = subtitles.len() as u32;
                subtitles.push(Track { index, codec: codec_of(r), language, title: None, is_default });
                last = Some((true, subtitles.len() - 1));
            }
        } else if let Some((key, value)) = t.split_once(':') {
            if key.trim() == "title" {
                let title = Some(value.trim().to_string()).filter(|v| !v.is_empty());
                match last {
                    Some((true, i)) => subtitles[i].title = title,
                    Some((false, i)) => audio[i].title = title,
                    None => {}
                }
            }
        }
    }
    MediaInfo { duration, aspect, audio, subtitles }
}

/// Из описания видеопотока: "h264 (High), yuv420p, 1920x1080 [SAR 1:1 DAR 16:9], ..."
fn parse_aspect(desc: &str) -> Option<f64> {
    if let Some(dar) = desc.split("DAR ").nth(1) {
        let dar: String = dar.chars().take_while(|c| c.is_ascii_digit() || *c == ':').collect();
        if let Some((a, b)) = dar.split_once(':') {
            let (a, b): (f64, f64) = (a.parse().ok()?, b.parse().ok()?);
            if a > 0.0 && b > 0.0 {
                return Some(a / b);
            }
        }
    }
    desc.split([',', ' ']).find_map(|tok| {
        let (w, h) = tok.split_once('x')?;
        let (w, h): (f64, f64) = (w.parse().ok()?, h.parse().ok()?);
        (w > 0.0 && h > 0.0).then(|| w / h)
    })
}

// ---------------------------------------------------------------------------
// Субтитры

/// Достаёт реплики из дорожки субтитров (ffmpeg переводит любые текстовые в SRT).
pub fn extract_cues(ffmpeg: &Path, input: &Path, track: u32) -> Result<Vec<Cue>, Error> {
    let output = Command::new(ffmpeg)
        .args(["-hide_banner", "-loglevel", "error", "-i"])
        .arg(input)
        .args(["-map", &format!("0:s:{track}"), "-f", "srt", "pipe:1"])
        .stdin(Stdio::null())
        .output()
        .map_err(|e| Error::FfmpegMissing(e.to_string()))?;
    if !output.status.success() {
        let err = String::from_utf8_lossy(&output.stderr);
        return Err(Error::Failed(format!(
            "не удалось прочитать субтитры: {}",
            err.trim().lines().last().unwrap_or("")
        )));
    }
    Ok(parse_srt(&String::from_utf8_lossy(&output.stdout)))
}

pub fn parse_srt(srt: &str) -> Vec<Cue> {
    let srt = srt.replace("\r\n", "\n");
    let mut cues = Vec::new();
    for block in srt.split("\n\n") {
        let mut lines = block.lines().skip_while(|l| !l.contains("-->"));
        let Some(timing) = lines.next() else { continue };
        let Some((a, b)) = timing.split_once("-->") else { continue };
        let (Some(start), Some(end)) = (parse_srt_time(a), parse_srt_time(b)) else { continue };
        let text = clean_text(&lines.collect::<Vec<_>>().join("\n"));
        if !text.is_empty() && end > start {
            cues.push(Cue { start, end, text, words: Vec::new() });
        }
    }
    cues.sort_by(|a, b| a.start.total_cmp(&b.start));
    cues
}

fn parse_srt_time(s: &str) -> Option<f64> {
    // "00:01:02,345" (могут быть координаты после времени)
    let s = s.split_whitespace().next()?.replace(',', ".");
    parse_timestamp_us(&s).map(|us| us as f64 / 1e6)
}

/// Убирает HTML-теги (<i>, <font>) и ASS-разметку ({\an8}), схлопывает пробелы.
fn clean_text(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut depth_tag = false;
    let mut depth_brace = false;
    for c in s.replace("\\N", "\n").replace("\\n", "\n").replace("\\h", " ").chars() {
        match c {
            '<' => depth_tag = true,
            '>' if depth_tag => depth_tag = false,
            '{' => depth_brace = true,
            '}' if depth_brace => depth_brace = false,
            _ if depth_tag || depth_brace => {}
            _ => out.push(c),
        }
    }
    out.lines()
        .map(|l| l.split_whitespace().collect::<Vec<_>>().join(" "))
        .filter(|l| !l.is_empty())
        .collect::<Vec<_>>()
        .join("\n")
}

// ---------------------------------------------------------------------------
// План нарезки

/// Интервалы речи: объединённые пересекающиеся реплики.
fn speech_blocks(cues: &[Cue]) -> Vec<(f64, f64)> {
    let mut blocks: Vec<(f64, f64)> = Vec::new();
    for c in cues {
        match blocks.last_mut() {
            Some(last) if c.start <= last.1 + 0.05 => last.1 = last.1.max(c.end),
            _ => blocks.push((c.start, c.end)),
        }
    }
    blocks
}

/// Делит `[0, duration]` на ролики не длиннее `max_len`, стараясь резать в паузах.
pub fn plan_clips(cues: &[Cue], duration: f64, max_len: f64) -> Vec<(f64, f64)> {
    let blocks = speech_blocks(cues);
    // Паузы между речью, включая начало и конец видео.
    let mut gaps = Vec::new();
    let mut prev_end = 0.0;
    for &(s, e) in &blocks {
        if s > prev_end {
            gaps.push((prev_end, s));
        }
        prev_end = f64::max(prev_end, e);
    }
    if duration > prev_end {
        gaps.push((prev_end, duration));
    }

    let mut clips = Vec::new();
    let mut start = 0.0;
    while duration - start > max_len {
        let limit = start + max_len;
        let cut = [max_len * 0.5, 1.0]
            .iter()
            .find_map(|&min_len| best_cut(&gaps, start + min_len, limit))
            .unwrap_or(limit);
        clips.push((start, cut));
        start = cut;
    }
    if duration - start > 0.5 || clips.is_empty() {
        clips.push((start, duration));
    } else if let Some(last) = clips.last_mut() {
        last.1 = duration;
    }
    clips
}

/// Самая поздняя точка внутри паузы в диапазоне `[lo, hi]`; режем чуть после конца фразы,
/// а если пауза (музыка) тянется дальше `hi` — на `hi`, чтобы не плодить пустые ролики.
fn best_cut(gaps: &[(f64, f64)], lo: f64, hi: f64) -> Option<f64> {
    gaps.iter()
        .rev()
        .filter(|&&(a, b)| b >= lo && a <= hi)
        .map(|&(a, b)| {
            let cut = if b > hi { hi } else { (a + 0.4).min((a + b) / 2.0) };
            cut.clamp(lo.max(a), hi.min(b))
        })
        .next()
}

/// Время, когда звучит место реплики на доле `frac` её текста.
fn time_at(cue: &Cue, frac: f64) -> f64 {
    let mut prev = (0.0, cue.start);
    for &(f, t) in cue.words.iter().chain(&[(1.0, cue.end)]) {
        if frac <= f {
            let span = f - prev.0;
            return if span <= 0.0 { t } else { prev.1 + (t - prev.1) * (frac - prev.0) / span };
        }
        prev = (f, t);
    }
    cue.end
}

/// Длина «страницы» при показе по словам: около двух строк на полосе субтитров.
const PAGE_CHARS: usize = 42;

/// Разбивает реплики на кадры по словам. Длинная реплика делится на страницы около двух
/// строк; на каждое слово страницы свой кадр: в [`CaptionStyle::Highlight`] оно подсвечено,
/// в [`CaptionStyle::Reveal`] видны слова до него, а остаток страницы скрыт,
/// в [`CaptionStyle::RevealHighlight`] — то и другое. Скрытый остаток всё равно участвует
/// в раскладке, поэтому строки не сдвигаются.
fn word_frames(cues: &[Cue], style: CaptionStyle) -> Vec<Cue> {
    struct Word {
        start: usize,
        end: usize,
        time: f64,
    }
    let mut out = Vec::new();
    for cue in cues {
        // Строки субтитров заново раскладываются по страницам, поэтому переносы из файла
        // становятся пробелами (число символов то же — доли в `words` не сдвигаются).
        let cue = &Cue { text: cue.text.replace('\n', " "), ..cue.clone() };
        let total = cue.text.chars().count().max(1) as f64;
        let mut words: Vec<Word> = Vec::new();
        let mut in_word = false;
        for (n, (b, ch)) in cue.text.char_indices().enumerate() {
            if ch.is_whitespace() {
                if in_word {
                    words.last_mut().expect("слово начато").end = b;
                }
                in_word = false;
            } else if !in_word {
                in_word = true;
                let time = time_at(cue, n as f64 / total);
                words.push(Word { start: b, end: cue.text.len(), time });
            }
        }
        if words.is_empty() {
            out.push(cue.clone());
            continue;
        }
        // Первое слово — с началом реплики, остальные не раньше предыдущего.
        let mut prev = cue.start;
        for (i, w) in words.iter_mut().enumerate() {
            w.time = if i == 0 { cue.start } else { w.time.clamp(prev, cue.end) };
            prev = w.time;
        }

        // Страницы: [первое слово, последнее слово).
        let mut pages = Vec::new();
        let mut first = 0;
        for i in 0..words.len() {
            let page_len = |last: usize| cue.text[words[first].start..words[last].end].chars().count();
            let sentence_end = cue.text[..words[i].end].ends_with(['.', '!', '?', '…']);
            let overflow = words.get(i + 1).is_some_and(|_| page_len(i + 1) > PAGE_CHARS);
            if i + 1 == words.len() || overflow || (sentence_end && page_len(i) >= PAGE_CHARS / 3) {
                pages.push((first, i + 1));
                first = i + 1;
            }
        }

        for (first, last) in pages {
            let page = &words[first..last];
            let page_end = words.get(last).map_or(cue.end, |w| w.time);
            for (i, w) in page.iter().enumerate() {
                let end = page.get(i + 1).map_or(page_end, |n| n.time);
                if end - w.time < 1e-3 {
                    continue; // слово прозвучало вместе со следующим
                }
                let before = &cue.text[page[0].start..w.start];
                let word = &cue.text[w.start..w.end];
                let rest = &cue.text[w.end..page[page.len() - 1].end];
                let text = match style {
                    CaptionStyle::Highlight => format!("{before}{MARK}{word}{UNMARK}{rest}"),
                    CaptionStyle::RevealHighlight if rest.is_empty() => {
                        format!("{before}{MARK}{word}{UNMARK}")
                    }
                    CaptionStyle::RevealHighlight => {
                        format!("{before}{MARK}{word}{UNMARK}{HIDE}{rest}{SHOW}")
                    }
                    _ if rest.is_empty() => format!("{before}{word}"),
                    _ => format!("{before}{word}{HIDE}{rest}{SHOW}"),
                };
                out.push(Cue { start: w.time, end, text, words: Vec::new() });
            }
        }
    }
    out
}

/// Отрезки времени `[start, end]` с текстом, который на них показан ("" — пауза).
/// Время — относительно `start`.
fn timeline(cues: &[Cue], start: f64, end: f64) -> Vec<(f64, f64, String)> {
    let mut points = vec![start, end];
    for c in cues {
        for t in [c.start, c.end] {
            if t > start && t < end {
                points.push(t);
            }
        }
    }
    points.sort_by(f64::total_cmp);
    points.dedup_by(|a, b| (*a - *b).abs() < 0.01);

    let mut out: Vec<(f64, f64, String)> = Vec::new();
    for w in points.windows(2) {
        let (a, b) = (w[0], w[1]);
        let mid = (a + b) / 2.0;
        let mut texts: Vec<&str> = Vec::new();
        for c in cues.iter().filter(|c| c.start <= mid && c.end > mid) {
            if !texts.contains(&c.text.as_str()) {
                texts.push(&c.text);
            }
        }
        let text = texts.join("\n");
        match out.last_mut() {
            Some(last) if last.2 == text => last.1 = b - start,
            _ => out.push((a - start, b - start, text)),
        }
    }
    out
}

fn srt_time(t: f64) -> String {
    let ms = (t.max(0.0) * 1000.0).round() as u64;
    format!("{:02}:{:02}:{:02},{:03}", ms / 3_600_000, ms / 60_000 % 60, ms / 1000 % 60, ms % 1000)
}

/// SRT из реплик, попадающих в `[start, end]`, со сдвигом времени на `start`.
fn cues_to_srt(cues: &[Cue], start: f64, end: f64) -> String {
    let mut out = String::new();
    let mut n = 0;
    for c in cues.iter().filter(|c| c.end > start && c.start < end) {
        n += 1;
        let _ = write!(
            out,
            "{n}\n{} --> {}\n{}\n\n",
            srt_time(c.start.max(start) - start),
            srt_time(c.end.min(end) - start),
            c.text
        );
    }
    out
}

fn cues_to_text(cues: &[Cue]) -> String {
    let mut out = String::new();
    let mut prev = "";
    for c in cues {
        if c.text != prev {
            out.push_str(&c.text.replace('\n', " "));
            out.push('\n');
            prev = &c.text;
        }
    }
    out
}

// ---------------------------------------------------------------------------
// Отрисовка полосы субтитров

struct TextRenderer {
    fonts: FontSystem,
    cache: SwashCache,
    /// Имя семейства встроенного шрифта.
    family: String,
}

impl TextRenderer {
    fn new() -> Self {
        let mut fonts = FontSystem::new();
        let ids = fonts.db_mut().load_font_source(cosmic_text::fontdb::Source::Binary(Arc::new(FONT)));
        let family = ids
            .first()
            .and_then(|&id| fonts.db().face(id))
            .and_then(|f| f.families.first().map(|(name, _)| name.clone()))
            .unwrap_or_else(|| "Helvetica Neue".into());
        Self { fonts, cache: SwashCache::new(), family }
    }

    /// Белый жирный текст по центру чёрной полосы `w`×`h`, RGB.
    fn render(&mut self, text: &str, w: u32, h: u32) -> Vec<u8> {
        let mut pixels = vec![0u8; (w * h * 3) as usize];
        if text.is_empty() {
            return pixels;
        }
        let margin = 70.0;
        let attrs = Attrs::new().family(Family::Name(&self.family)).weight(Weight::SEMIBOLD);

        // Подбираем размер шрифта, чтобы текст влез по высоте.
        let mut size = 62.0;
        let (buffer, text_h) = loop {
            let metrics = Metrics::new(size, size * 1.25);
            let mut buffer = Buffer::new(&mut self.fonts, metrics);
            buffer.set_size(Some(w as f32 - 2.0 * margin), None);
            let hidden = attrs.clone().color(Color::rgba(0, 0, 0, 0));
            let marked = attrs.clone().color(HIGHLIGHT_COLOR);
            let spans = text_spans(text).into_iter().map(|(s, span)| {
                let a = match span {
                    Span::Normal => attrs.clone(),
                    Span::Hidden => hidden.clone(),
                    Span::Marked => marked.clone(),
                };
                (s, a)
            });
            buffer.set_rich_text(spans, &attrs, Shaping::Advanced, Some(Align::Center));
            buffer.shape_until_scroll(&mut self.fonts, false);
            let text_h: f32 = buffer.layout_runs().map(|r| r.line_height).sum();
            if text_h <= h as f32 * 0.85 || size <= 36.0 {
                break (buffer, text_h);
            }
            size -= 4.0;
        };

        let mut buffer = buffer;
        // Текст ближе к видео: по центру верхней части полосы.
        let off_x = margin as i32;
        let off_y = (((h as f32 * 0.8) - text_h) / 2.0).max(10.0) as i32;
        buffer.draw(&mut self.fonts, &mut self.cache, TEXT_COLOR, |x, y, gw, gh, color| {
            let a = color.a() as u32;
            if a == 0 {
                return;
            }
            for py in y..y + gh as i32 {
                for px in x..x + gw as i32 {
                    let (px, py) = (px + off_x, py + off_y);
                    if px < 0 || py < 0 || px >= w as i32 || py >= h as i32 {
                        continue;
                    }
                    let i = ((py as u32 * w + px as u32) * 3) as usize;
                    for (ch, c) in [color.r(), color.g(), color.b()].into_iter().enumerate() {
                        let old = pixels[i + ch] as u32;
                        pixels[i + ch] = ((c as u32 * a + old * (255 - a)) / 255) as u8;
                    }
                }
            }
        });
        pixels
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
enum Span {
    Normal,
    Hidden,
    Marked,
}

/// Куски текста с видом: скрыт (между `HIDE` и `SHOW`), подсвечен (между `MARK` и `UNMARK`);
/// маркеры выбрасываются.
fn text_spans(text: &str) -> Vec<(&str, Span)> {
    let mut spans = Vec::new();
    let mut span = Span::Normal;
    let mut rest = text;
    while let Some(i) = rest.find([HIDE, SHOW, MARK, UNMARK]) {
        if i > 0 {
            spans.push((&rest[..i], span));
        }
        span = match rest[i..].chars().next() {
            Some(HIDE) => Span::Hidden,
            Some(MARK) => Span::Marked,
            _ => Span::Normal,
        };
        rest = &rest[i + 1..];
    }
    if !rest.is_empty() {
        spans.push((rest, span));
    }
    spans
}

fn write_png(path: &Path, w: u32, h: u32, rgb: &[u8]) -> Result<(), Error> {
    let io = |e: std::io::Error| Error::Failed(format!("{}: {e}", path.display()));
    let file = File::create(path).map_err(io)?;
    let mut enc = png::Encoder::new(BufWriter::new(file), w, h);
    enc.set_color(png::ColorType::Rgb);
    enc.set_depth(png::BitDepth::Eight);
    enc.write_header()
        .and_then(|mut wr| wr.write_image_data(rgb))
        .map_err(|e| Error::Failed(format!("{}: {e}", path.display())))
}

// ---------------------------------------------------------------------------
// Сборка роликов

/// Высота видео в кадре и полоса субтитров (y, высота).
fn layout(aspect: f64) -> (u32, u32) {
    let video_h = ((FRAME_W as f64 / aspect).round() as u32).min(FRAME_H);
    let bar = (FRAME_H - video_h) / 2;
    let strip_h = bar.max(MIN_STRIP_H) & !1;
    (FRAME_H - strip_h, strip_h)
}

fn quote_concat(p: &Path) -> String {
    format!("'{}'", p.display().to_string().replace('\'', "'\\''"))
}

/// Нарезает `input` на ролики в папку `out_dir`. Возвращает пути готовых .mp4.
pub fn make_shorts(
    input: &Path,
    out_dir: &Path,
    opts: &ShortsOptions,
    on_event: &mut dyn FnMut(ShortsEvent),
) -> Result<Vec<PathBuf>, Error> {
    let io = |e: std::io::Error| Error::Failed(e.to_string());
    let stem = input.file_stem().and_then(|s| s.to_str()).unwrap_or("video").to_string();

    on_event(ShortsEvent::Stage("Читаю файл".into()));
    let info = probe_media(opts.ffmpeg, input)?;
    if info.duration <= 0.0 {
        return Err(Error::Failed("не удалось определить длительность видео".into()));
    }
    let tmp = TempDir::new()?;
    let cues = match opts.subtitle_track {
        Some(n) => {
            let track = info
                .subtitles
                .get(n as usize)
                .ok_or_else(|| Error::Failed("в файле нет выбранной дорожки субтитров".into()))?;
            if !track.is_text() {
                return Err(Error::Failed(format!(
                    "субтитры «{}» — картинки, а не текст; выберите текстовую дорожку",
                    track.codec
                )));
            }
            on_event(ShortsEvent::Stage("Извлекаю субтитры".into()));
            extract_cues(opts.ffmpeg, input, n)?
        }
        None => {
            if info.audio.len() <= opts.audio_track as usize {
                return Err(Error::Failed("в файле нет выбранной аудиодорожки".into()));
            }
            let speech = SpeechOptions {
                ffmpeg: opts.ffmpeg,
                audio_track: opts.audio_track,
                duration: info.duration,
                cancel: opts.cancel,
            };
            transcribe::transcribe(input, &tmp.0, &speech, on_event)?
        }
    };
    if cues.is_empty() {
        return Err(Error::Failed("в дорожке субтитров нет текста".into()));
    }

    fs::create_dir_all(out_dir).map_err(io)?;
    fs::write(out_dir.join(format!("{stem}.srt")), cues_to_srt(&cues, 0.0, f64::MAX)).map_err(io)?;
    fs::write(out_dir.join(format!("{stem}.txt")), cues_to_text(&cues)).map_err(io)?;

    let clips = if opts.best_moments {
        let src = highlights::Source {
            ffmpeg: opts.ffmpeg,
            input,
            audio_track: opts.audio_track,
            tmp: &tmp.0,
            cancel: opts.cancel,
        };
        best_moment_clips(&cues, info.duration, &stem, out_dir, &src, on_event)?
    } else {
        None
    }
    .unwrap_or_else(|| plan_clips(&cues, info.duration, opts.max_len));
    let clips_secs: f64 = clips.iter().map(|(a, b)| b - a).sum();
    let shown = match opts.captions {
        CaptionStyle::Whole => cues.clone(),
        style => word_frames(&cues, style),
    };
    let (strip_y, strip_h) = layout(info.aspect);
    let mut renderer = TextRenderer::new();

    let filter = format!(
        "[0:v]scale=iw*sar:ih,setsar=1,\
         scale={FRAME_W}:{FRAME_H}:force_original_aspect_ratio=decrease,\
         pad={FRAME_W}:{FRAME_H}:(ow-iw)/2:(oh-ih)/2:black[bg];\
         [bg][1:v]overlay=0:{strip_y}:eof_action=repeat,format=yuv420p,setsar=1[v]"
    );

    let total = clips.len();
    let mut done_secs = 0.0;
    let mut outputs = Vec::new();
    for (n, &(start, end)) in clips.iter().enumerate() {
        let len = end - start;
        on_event(ShortsEvent::Stage(format!("Ролик {} из {total}", n + 1)));

        // Картинки субтитров и список для concat-демуксера.
        let clip_tmp = tmp.0.join(format!("{n}"));
        fs::create_dir_all(&clip_tmp).map_err(io)?;
        let mut images: HashMap<String, PathBuf> = HashMap::new();
        let mut list = String::from("ffconcat version 1.0\n");
        let mut last_img = None;
        for (a, b, text) in timeline(&shown, start, end) {
            let img = match images.get(&text) {
                Some(p) => p.clone(),
                None => {
                    let p = clip_tmp.join(format!("{}.png", images.len()));
                    write_png(&p, FRAME_W, strip_h, &renderer.render(&text, FRAME_W, strip_h))?;
                    images.insert(text, p.clone());
                    p
                }
            };
            let _ = write!(list, "file {}\nduration {:.3}\n", quote_concat(&img), b - a);
            last_img = Some(img);
        }
        if let Some(img) = last_img {
            let _ = writeln!(list, "file {}", quote_concat(&img));
        }
        let list_path = clip_tmp.join("subs.ffconcat");
        fs::write(&list_path, list).map_err(io)?;

        let out = out_dir.join(format!("{stem}_{:02}.mp4", n + 1));
        let args: Vec<OsString> = [
            "-ss", &format!("{start:.3}"), "-t", &format!("{len:.3}"), "-i",
        ]
        .iter()
        .map(OsString::from)
        .chain([input.into()])
        .chain(["-f", "concat", "-safe", "0", "-i"].iter().map(OsString::from))
        .chain([list_path.into()])
        .chain(
            [
                "-filter_complex", &filter, "-map", "[v]",
                "-map", &format!("0:a:{}?", opts.audio_track),
                "-c:v", "h264_videotoolbox", "-q:v", "65", "-profile:v", "high",
                "-c:a", "aac", "-b:a", "192k", "-ac", "2",
                "-t", &format!("{len:.3}"), "-movflags", "+faststart",
            ]
            .iter()
            .map(OsString::from),
        )
        .chain([out.clone().into()])
        .collect();

        let total_secs = clips_secs;
        let done = done_secs;
        run_ffmpeg_args(
            opts.ffmpeg,
            &args,
            Some((len * 1e6) as u64),
            opts.cancel,
            &mut |p| on_event(ShortsEvent::Progress(((done + p * len) / total_secs).min(1.0))),
        )
        .inspect_err(|_| {
            let _ = fs::remove_file(&out);
        })?;

        fs::write(out.with_extension("srt"), cues_to_srt(&cues, start, end)).map_err(io)?;
        let _ = fs::remove_dir_all(&clip_tmp);
        done_secs += len;
        on_event(ShortsEvent::Progress((done_secs / clips_secs).min(1.0)));
        on_event(ShortsEvent::Clip { index: n + 1, total, path: out.clone() });
        outputs.push(out);
    }
    Ok(outputs)
}

/// Отрезки лучших моментов и `<имя>_моменты.txt` с их описанием. `None` — моменты не
/// получены (нет ключа, ошибка API): тогда нарезка идёт подряд, с предупреждением.
fn best_moment_clips(
    cues: &[Cue],
    duration: f64,
    stem: &str,
    out_dir: &Path,
    src: &highlights::Source,
    on_event: &mut dyn FnMut(ShortsEvent),
) -> Result<Option<Vec<(f64, f64)>>, Error> {
    let Some(key) = transcribe::Config::load().api_key else {
        on_event(ShortsEvent::Warning(
            "для лучших моментов нужен ANTHROPIC_API_KEY в .env, нарезано всё видео подряд".into(),
        ));
        return Ok(None);
    };
    let selection = match highlights::find_moments(cues, duration, &key, src, on_event) {
        Ok(sel) if !sel.chosen.is_empty() => {
            if let Some(w) = &sel.warning {
                on_event(ShortsEvent::Warning(w.clone()));
            }
            sel
        }
        Err(Error::Cancelled) => return Err(Error::Cancelled),
        Ok(_) => {
            on_event(ShortsEvent::Warning("Claude не нашёл подходящих моментов, нарезано всё видео подряд".into()));
            return Ok(None);
        }
        Err(e) => {
            let msg = match e {
                Error::Failed(m) => m,
                other => other.to_string(),
            };
            on_event(ShortsEvent::Warning(format!("не удалось выбрать моменты ({msg}), нарезано всё видео подряд")));
            return Ok(None);
        }
    };
    fs::write(out_dir.join(format!("{stem}_моменты.txt")), highlights::moments_report(stem, &selection))
        .map_err(|e| Error::Failed(e.to_string()))?;
    Ok(Some(selection.chosen.iter().map(|m| (m.start, m.end)).collect()))
}

/// Временная папка, которая удаляется вместе со всем содержимым.
struct TempDir(PathBuf);

impl TempDir {
    fn new() -> Result<Self, Error> {
        let path = std::env::temp_dir().join(format!("mkv2mp4-shorts-{}", std::process::id()));
        let _ = fs::remove_dir_all(&path);
        fs::create_dir_all(&path).map_err(|e| Error::Failed(format!("{}: {e}", path.display())))?;
        Ok(Self(path))
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

/// Папка для роликов: `<имя>_tiktok` рядом с исходником или в `out_root`.
pub fn shorts_dir(input: &Path, out_root: Option<&Path>) -> PathBuf {
    let stem = input.file_stem().and_then(|s| s.to_str()).unwrap_or("video");
    let parent = out_root.or(input.parent()).unwrap_or(Path::new("."));
    parent.join(format!("{stem}_tiktok"))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cue(start: f64, end: f64, text: &str) -> Cue {
        Cue { start, end, text: text.into(), words: Vec::new() }
    }

    #[test]
    fn parses_streams() {
        let info = parse_media_info(
            "  Duration: 00:02:30.00, start: 0.000000, bitrate: 1 kb/s
  Stream #0:0: Video: h264 (High), yuv420p(progressive), 1920x800 [SAR 1:1 DAR 12:5], 24 fps
  Stream #0:1(rus): Audio: aac (LC), 48000 Hz, stereo, fltp (default)
    Metadata:
      title           : Дубляж
  Stream #0:2(eng): Audio: opus, 48000 Hz, stereo
  Stream #0:3(rus): Subtitle: ass (ssa) (default)
    Metadata:
      title           : Полные
  Stream #0:4(eng): Subtitle: hdmv_pgs_subtitle (pgssub)
  Stream #0:5: Video: mjpeg (Baseline), yuvj420p, 600x900, 90k tbr (attached pic)
",
        );
        assert_eq!(info.duration, 150.0);
        assert!((info.aspect - 2.4).abs() < 1e-9);
        assert_eq!(info.audio.len(), 2);
        assert_eq!(info.audio[0].title.as_deref(), Some("Дубляж"));
        assert_eq!(info.audio[1].language.as_deref(), Some("eng"));
        assert_eq!(info.subtitles.len(), 2);
        assert_eq!(info.subtitles[0].title.as_deref(), Some("Полные"));
        assert!(info.subtitles[0].is_text() && info.subtitles[0].is_default);
        assert!(!info.subtitles[1].is_text());
        assert_eq!(info.subtitles[1].index, 1);
    }

    #[test]
    fn parses_srt_and_cleans_markup() {
        let cues = parse_srt(
            "1\r\n00:00:01,000 --> 00:00:02,500\r\n<i>Привет</i>,   мир\r\n\r\n\
             2\n00:00:03,000 --> 00:00:04,000 X1:0\n{\\an8}Вторая\\Nстрока\n\n3\n00:00:05,000 --> 00:00:05,000\nпусто\n",
        );
        assert_eq!(cues, vec![cue(1.0, 2.5, "Привет, мир"), cue(3.0, 4.0, "Вторая\nстрока")]);
    }

    #[test]
    fn cuts_in_pauses() {
        // Речь 0–28, пауза 28–31, речь 31–58, пауза 58–58.6, речь 58.6–90.
        let cues = [cue(0.0, 28.0, "a"), cue(31.0, 58.0, "b"), cue(58.6, 90.0, "c")];
        let clips = plan_clips(&cues, 100.0, 60.0);
        assert_eq!(clips.len(), 2);
        // Разрез в самой поздней паузе до 60 с: сразу после 58.0.
        assert!(clips[0].1 > 58.0 && clips[0].1 <= 58.6, "{clips:?}");
        assert_eq!(clips[1].1, 100.0);
        assert!(clips.iter().all(|(a, b)| b - a <= 60.0 + 1e-9));
    }

    #[test]
    fn long_music_pause_fills_clip() {
        // Речь до 10 с, музыка 10–200 с, речь 200–210 с: первый ролик тянется до 60 с.
        let cues = [cue(0.0, 10.0, "a"), cue(200.0, 210.0, "b")];
        let clips = plan_clips(&cues, 210.0, 60.0);
        assert_eq!(clips[0], (0.0, 60.0));
    }

    #[test]
    fn falls_back_to_hard_cut_without_pauses() {
        let cues = [cue(0.0, 200.0, "монолог")];
        let clips = plan_clips(&cues, 200.0, 60.0);
        assert_eq!(clips, vec![(0.0, 60.0), (60.0, 120.0), (120.0, 180.0), (180.0, 200.0)]);
    }

    #[test]
    fn short_video_is_one_clip() {
        assert_eq!(plan_clips(&[], 30.0, 60.0), vec![(0.0, 30.0)]);
    }

    #[test]
    fn timeline_merges_overlaps_and_gaps() {
        let cues = [cue(1.0, 3.0, "a"), cue(2.0, 4.0, "b"), cue(6.0, 7.0, "c")];
        let t = timeline(&cues, 0.5, 8.0);
        let texts: Vec<_> = t.iter().map(|x| x.2.as_str()).collect();
        assert_eq!(texts, ["", "a", "a\nb", "b", "", "c", ""]);
        assert_eq!(t[0].0, 0.0);
        assert!((t.last().unwrap().1 - 7.5).abs() < 1e-9);
    }

    #[test]
    fn clip_srt_is_shifted() {
        let cues = [cue(10.0, 12.0, "x"), cue(59.0, 62.0, "y")];
        assert_eq!(
            cues_to_srt(&cues, 50.0, 60.0),
            "1\n00:00:09,000 --> 00:00:10,000\ny\n\n"
        );
    }

    #[test]
    fn words_appear_as_spoken() {
        // Слова «Раз» в 1 с, «два» в 2 с (точка на доле 4/11), «три» — пропорционально.
        let c = Cue { words: vec![(0.0, 1.0), (4.0 / 11.0, 2.0)], ..cue(1.0, 4.0, "Раз два три") };
        let w = word_frames(&[c], CaptionStyle::Reveal);
        let texts: Vec<_> = w.iter().map(|c| c.text.as_str()).collect();
        assert_eq!(texts, ["Раз\u{1} два три\u{2}", "Раз два\u{1} три\u{2}", "Раз два три"]);
        assert_eq!((w[0].start, w[0].end, w[1].start), (1.0, 2.0, 2.0));
        assert!(w[2].start > 2.0 && w[2].start < 4.0 && w[2].end == 4.0);
        // Без точек — пропорционально длине.
        let w = word_frames(&[cue(0.0, 2.0, "аа\nбб")], CaptionStyle::Reveal);
        assert_eq!(w.len(), 2);
        assert_eq!(w[0].text, "аа\u{1} бб\u{2}");
        assert!((w[1].start - 1.2).abs() < 1e-9);
    }

    #[test]
    fn long_cue_is_split_into_pages() {
        let text = "Первая короткая фраза. Вторая фраза подлиннее, чтобы не влезть на одну страницу целиком";
        let w = word_frames(&[cue(0.0, 10.0, text)], CaptionStyle::Reveal);
        let pages: Vec<_> = w.iter().filter(|c| !c.text.contains(HIDE)).map(|c| c.text.as_str()).collect();
        assert_eq!(
            pages,
            ["Первая короткая фраза.", "Вторая фраза подлиннее, чтобы не влезть на", "одну страницу целиком"]
        );
        assert!(w.windows(2).all(|p| p[0].end <= p[1].start + 1e-9));
        assert_eq!(w.last().unwrap().end, 10.0);
    }

    #[test]
    fn highlights_spoken_word() {
        let w = word_frames(&[cue(0.0, 3.0, "Он не нравится.")], CaptionStyle::Highlight);
        let texts: Vec<_> = w.iter().map(|c| c.text.as_str()).collect();
        assert_eq!(
            texts,
            ["\u{3}Он\u{4} не нравится.", "Он \u{3}не\u{4} нравится.", "Он не \u{3}нравится.\u{4}"]
        );
        assert_eq!(w.last().unwrap().end, 3.0);

        let w = word_frames(&[cue(0.0, 3.0, "Он не нравится.")], CaptionStyle::RevealHighlight);
        let texts: Vec<_> = w.iter().map(|c| c.text.as_str()).collect();
        assert_eq!(
            texts,
            [
                "\u{3}Он\u{4}\u{1} не нравится.\u{2}",
                "Он \u{3}не\u{4}\u{1} нравится.\u{2}",
                "Он не \u{3}нравится.\u{4}"
            ]
        );
        assert_eq!(text_spans(texts[1]).iter().map(|s| s.1).collect::<Vec<_>>(), [Span::Normal, Span::Marked, Span::Hidden]);
    }

    #[test]
    fn splits_spans() {
        use Span::*;
        assert_eq!(text_spans("а\u{1} б\u{2}\nв"), [("а", Normal), (" б", Hidden), ("\nв", Normal)]);
        assert_eq!(text_spans("а \u{3}б\u{4} в"), [("а ", Normal), ("б", Marked), (" в", Normal)]);
        assert_eq!(text_spans("просто"), [("просто", Normal)]);
    }

    #[test]
    fn embedded_font_loads() {
        assert_eq!(TextRenderer::new().family, "TikTok Sans");
    }

    #[test]
    fn layout_puts_strip_under_video() {
        // 16:9 → видео 608 px, поля по 656.
        assert_eq!(layout(16.0 / 9.0), (1264, 656));
        // Вертикальное видео: полей нет, полоса минимальной высоты поверх низа.
        assert_eq!(layout(9.0 / 16.0), (1500, 420));
    }
}
