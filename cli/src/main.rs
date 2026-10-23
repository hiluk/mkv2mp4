use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::exit;

use mkv2mp4_core::shorts::{self, CaptionStyle, ShortsEvent, ShortsOptions};
use mkv2mp4_core::transcribe;
use mkv2mp4_core::{self as core, Event, Options};

const USAGE: &str = "\
mkv2mp4 — конвертирует видео (MKV, AVI, MOV, WebM и др.) в MP4 через ffmpeg

Использование:
    mkv2mp4 [ОПЦИИ] <видеофайл | папка>...

Опции:
    -o, --out-dir <DIR>  Куда класть .mp4 (по умолчанию — рядом с исходником)
    -f, --force          Перезаписывать существующие .mp4
    -r, --reencode       Полное перекодирование (H.264 + AAC) вместо быстрого ремукса
    -R, --recursive      Искать видео в подпапках
    -s, --shorts         Нарезать на ролики 9:16 для TikTok с субтитрами из файла
        --max-len <SEC>  Максимальная длина ролика (по умолчанию 60)
        --best           Только лучшие моменты по 60–180 с (выбирает Claude Haiku, нужен ключ)
        --sub <N>        Номер дорожки субтитров (по умолчанию 0)
        --speech         Не брать субтитры из файла, а распознать речь (Whisper + Claude Haiku)
        --captions <STYLE>  Как показывать текст: reveal-highlight — слова по мере речи
                         с подсветкой звучащего (по умолчанию), highlight — подсвечивать
                         звучащее слово, reveal — слова по мере речи, whole — реплику целиком
        --audio <N>      Номер аудиодорожки (по умолчанию 0)
    -h, --help           Показать эту справку

ffmpeg ищется рядом с программой, затем в PATH; путь можно задать в MKV2MP4_FFMPEG.
whisper-cli ищется так же (MKV2MP4_WHISPER). Ключ ANTHROPIC_API_KEY, язык WHISPER_LANGUAGE
и модель WHISPER_MODEL берутся из окружения, ./.env или
~/Library/Application Support/MKV2MP4/.env (создаётся при первом --speech).
";

struct Args {
    inputs: Vec<PathBuf>,
    out_dir: Option<PathBuf>,
    force: bool,
    reencode: bool,
    recursive: bool,
    shorts: bool,
    max_len: f64,
    sub: u32,
    speech: bool,
    captions: CaptionStyle,
    best: bool,
    audio: u32,
}

fn parse_value<T: std::str::FromStr>(opt: &str, v: Option<String>) -> T {
    v.and_then(|v| v.parse().ok())
        .unwrap_or_else(|| die(&format!("после {opt} нужно число")))
}

fn parse_args() -> Args {
    let mut opts = Args {
        inputs: Vec::new(),
        out_dir: None,
        force: false,
        reencode: false,
        recursive: false,
        shorts: false,
        max_len: 60.0,
        sub: 0,
        speech: false,
        captions: CaptionStyle::RevealHighlight,
        best: false,
        audio: 0,
    };
    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                exit(0);
            }
            "-f" | "--force" => opts.force = true,
            "-r" | "--reencode" => opts.reencode = true,
            "-R" | "--recursive" => opts.recursive = true,
            "-s" | "--shorts" => opts.shorts = true,
            "--max-len" => opts.max_len = parse_value(&arg, args.next()),
            "--sub" => opts.sub = parse_value(&arg, args.next()),
            "--speech" => opts.speech = true,
            "--best" => opts.best = true,
            "--captions" => {
                opts.captions = match args.next().as_deref() {
                    Some("highlight") => CaptionStyle::Highlight,
                    Some("reveal") => CaptionStyle::Reveal,
                    Some("reveal-highlight") => CaptionStyle::RevealHighlight,
                    Some("whole") => CaptionStyle::Whole,
                    _ => die("после --captions нужно highlight, reveal, reveal-highlight или whole"),
                }
            }
            "--audio" => opts.audio = parse_value(&arg, args.next()),
            "-o" | "--out-dir" => match args.next() {
                Some(dir) => opts.out_dir = Some(PathBuf::from(dir)),
                None => die("после -o/--out-dir нужен путь к папке"),
            },
            s if s.starts_with('-') && s.len() > 1 => die(&format!("неизвестная опция: {s}")),
            _ => opts.inputs.push(PathBuf::from(arg)),
        }
    }
    if opts.inputs.is_empty() {
        eprint!("{USAGE}");
        exit(2);
    }
    opts
}

fn die(msg: &str) -> ! {
    eprintln!("ошибка: {msg}");
    exit(2);
}

fn collect_videos(dir: &Path, recursive: bool, out: &mut Vec<PathBuf>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(e) => {
            eprintln!("не удалось прочитать {}: {e}", dir.display());
            return;
        }
    };
    let mut paths: Vec<PathBuf> = entries.filter_map(|e| e.ok().map(|e| e.path())).collect();
    paths.sort();
    for path in paths {
        if path.is_dir() {
            if recursive {
                collect_videos(&path, recursive, out);
            }
        } else if core::is_video(&path) {
            out.push(path);
        }
    }
}

fn main() {
    let args = parse_args();

    let ffmpeg = core::find_ffmpeg();
    if core::check_ffmpeg(&ffmpeg).is_err() {
        die("ffmpeg не найден. Положите его рядом с программой или установите: brew install ffmpeg");
    }

    if let Some(dir) = &args.out_dir {
        if let Err(e) = fs::create_dir_all(dir) {
            die(&format!("не удалось создать {}: {e}", dir.display()));
        }
    }

    let mut files = Vec::new();
    for input in &args.inputs {
        if input.is_dir() {
            collect_videos(input, args.recursive, &mut files);
        } else if input.is_file() {
            files.push(input.clone());
        } else {
            eprintln!("пропускаю {}: не существует", input.display());
        }
    }
    if files.is_empty() {
        die("не найдено ни одного видеофайла");
    }

    if args.shorts {
        run_shorts(&args, &ffmpeg, &files);
        return;
    }

    let opts = Options { ffmpeg: &ffmpeg, reencode: args.reencode, cancel: None };
    let (mut ok, mut skipped, mut failed) = (0, 0, 0);
    for (n, input) in files.iter().enumerate() {
        let output = core::output_path_in_batch(input, args.out_dir.as_deref(), &files);
        println!("[{}/{}] {} → {}", n + 1, files.len(), input.display(), output.display());
        if output.exists() && !args.force {
            println!("  уже существует, пропускаю (используйте --force)");
            skipped += 1;
            continue;
        }
        let mut on_event = |e: Event| match e {
            Event::Attempt(label) => println!("\r\x1b[K  → {label}"),
            Event::Info(msg) => println!("  {msg}"),
            Event::Progress(p) => {
                print!("\r  {:>3}%", (p * 100.0).round() as u32);
                let _ = io::stdout().flush();
            }
        };
        match core::convert(input, &output, &opts, &mut on_event) {
            Ok(()) => {
                println!("\r\x1b[K  ✓ готово");
                ok += 1;
            }
            Err(e) => {
                println!();
                eprintln!("  ✗ {e}");
                failed += 1;
            }
        }
    }

    println!("\nУспешно: {ok}, пропущено: {skipped}, ошибок: {failed}");
    if failed > 0 {
        exit(1);
    }
}

fn run_shorts(args: &Args, ffmpeg: &Path, files: &[PathBuf]) {
    if args.speech {
        match transcribe::ensure_env_file() {
            Ok(path) if transcribe::Config::load().api_key.is_none() => {
                println!("Ключ Claude не задан: впишите ANTHROPIC_API_KEY в {}", path.display())
            }
            Ok(_) => {}
            Err(e) => eprintln!("{e}"),
        }
    }
    let opts = ShortsOptions {
        ffmpeg,
        subtitle_track: (!args.speech).then_some(args.sub),
        audio_track: args.audio,
        max_len: args.max_len,
        captions: args.captions,
        best_moments: args.best,
        cancel: None,
    };
    let mut failed = 0;
    for (n, input) in files.iter().enumerate() {
        let out_dir = shorts::shorts_dir(input, args.out_dir.as_deref());
        println!("[{}/{}] {} → {}/", n + 1, files.len(), input.display(), out_dir.display());
        let mut stage = String::new();
        let mut on_event = |e: ShortsEvent| match e {
            ShortsEvent::Stage(s) => {
                print!("\r\x1b[K  {s}");
                stage = s;
            }
            ShortsEvent::Progress(p) => {
                print!("\r\x1b[K  {stage}: {:>3}%", (p * 100.0).round() as u32);
                let _ = io::stdout().flush();
            }
            ShortsEvent::Clip { index, total, path } => {
                println!("\r\x1b[K  ✓ {index}/{total}: {}", path.display())
            }
            ShortsEvent::Warning(msg) => println!("\r\x1b[K  ! {msg}"),
        };
        if let Err(e) = shorts::make_shorts(input, &out_dir, &opts, &mut on_event) {
            println!();
            eprintln!("  ✗ {e}");
            failed += 1;
        }
    }
    if failed > 0 {
        exit(1);
    }
}
