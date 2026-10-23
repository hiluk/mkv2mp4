import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../files.dart';
import '../rust/api/convert.dart' as convert;
import '../rust/api/shorts.dart' as rust;
import 'models.dart';

part 'shorts.g.dart';

/// Настройки распознавания речи (.env); `ref.invalidate` перечитывает файл.
@riverpod
Future<rust.SpeechConfig> speechConfig(Ref ref) => rust.speechConfig();

/// Откуда брать текст: дорожка субтитров и/или распознавание речи.
/// Предпочитаются субтитры на языке звука. Если текстовые субтитры есть, но все на
/// другом языке (русская озвучка, английские субтитры), распознаём речь, а дорожка
/// остаётся выбранной, чтобы на неё можно было переключиться.
(rust.TrackInfo?, bool) chooseTextSource(rust.MediaInfo info, rust.TrackInfo? audio) {
  final text = info.subtitles.where((t) => t.isText).toList();
  rust.TrackInfo? pick(Iterable<rust.TrackInfo> ts) =>
      ts.where((t) => t.isDefault).firstOrNull ?? ts.firstOrNull;
  if (audio == null) return (pick(text), false);
  final lang = audio.language;
  if (lang != null && text.isNotEmpty) {
    final same = text.where((t) => t.language != null && sameLanguage(t.language!, lang));
    if (same.isNotEmpty) return (pick(same), false);
    if (text.every((t) => t.language != null)) return (pick(text), true);
  }
  final sub = pick(text);
  return (sub, sub == null);
}

/// "rus" и "ru" — один язык.
bool sameLanguage(String a, String b) {
  a = a.toLowerCase();
  b = b.toLowerCase();
  return a == b || (a.length >= 2 && b.length >= 2 && (a.startsWith(b) || b.startsWith(a)));
}

@Riverpod(keepAlive: true)
class Shorts extends _$Shorts {
  @override
  ShortsState build() => const ShortsState();

  /// Номер «дорожки» в списке субтитров, означающий распознавание речи.
  static const speechTrack = -1;

  /// Добавляет файлы и папки; возвращает число добавленных видео.
  Future<int> addPaths(Iterable<String> paths) async {
    final found = await findVideos(paths);
    final known = state.jobs.map((j) => j.input).toSet();
    final added = found.where(known.add).toList();
    state = state.copyWith(jobs: [
      ...state.jobs,
      for (final p in added) ShortsJob(input: p),
    ]);
    await Future.wait(added.map(_probe));
    return added.length;
  }

  Future<void> _probe(String input) async {
    try {
      final info = await rust.probeMedia(path: input);
      final audio = info.audio.where((t) => t.isDefault).firstOrNull ??
          info.audio.firstOrNull;
      final (sub, speech) = chooseTextSource(info, audio);
      _update(
        input,
        (j) => j.copyWith(
          info: info,
          subtitleTrack: sub?.index,
          speech: speech,
          audioTrack: audio?.index ?? 0,
          status: sub == null && !speech ? ShortsStatus.error : ShortsStatus.ready,
          message: sub == null && !speech ? 'В файле нет ни текстовых субтитров, ни звука' : '',
        ),
      );
    } catch (e) {
      _update(input, (j) => j.copyWith(status: ShortsStatus.error, message: '$e'));
    }
  }

  /// [speechTrack] — распознавать речь.
  void setSubtitleTrack(String input, int track) => _update(
        input,
        (j) => track == speechTrack
            ? j.copyWith(speech: true)
            : j.copyWith(speech: false, subtitleTrack: track),
      );

  void setAudioTrack(String input, int track) =>
      _update(input, (j) => j.copyWith(audioTrack: track));

  void setMaxLen(int seconds) =>
      state = state.copyWith.settings(maxLen: seconds);

  void setOutDir(String? dir) => state = state.copyWith.settings(outDir: dir);

  void setBestMoments(bool value) =>
      state = state.copyWith.settings(bestMoments: value);

  void setCaptions(rust.CaptionStyle value) =>
      state = state.copyWith.settings(captions: value);

  void remove(String input) => state = state.copyWith(
        jobs: state.jobs.where((j) => j.input != input).toList(),
      );

  /// Возвращает файл в очередь (если есть откуда взять текст).
  void retry(String input) => _update(
        input,
        (j) => !j.hasSource
            ? j
            : j.copyWith(
                status: ShortsStatus.ready,
                progress: 0,
                message: '',
                warning: '',
                clipsDone: 0,
                clipsTotal: 0,
              ),
      );

  void clearFinished() => state = state.copyWith(
        jobs: state.jobs.where((j) => !j.isFinished).toList(),
      );

  Future<void> start() async {
    if (state.running) return;
    state = state.copyWith(running: true);
    final settings = state.settings;
    while (state.running) {
      final next =
          state.jobs.where((j) => j.status == ShortsStatus.ready).firstOrNull;
      if (next == null) break;
      await _run(next, settings);
    }
    state = state.copyWith(running: false);
  }

  void cancel() {
    state = state.copyWith(running: false);
    convert.cancel();
  }

  Future<void> _run(ShortsJob job, ShortsSettings settings) async {
    final input = job.input;
    _update(
      input,
      (j) => j.copyWith(
          status: ShortsStatus.running, progress: 0, message: '', warning: ''),
    );
    final events = rust.makeShorts(
      input: input,
      outRoot: settings.outDir,
      subtitleTrack: job.speech ? null : job.subtitleTrack,
      audioTrack: job.audioTrack,
      maxLen: settings.maxLen.toDouble(),
      captions: settings.captions,
      bestMoments: settings.bestMoments,
    );
    await for (final e in events) {
      _update(input, (j) => _apply(j, e));
    }
    _update(
      input,
      (j) => j.status == ShortsStatus.running
          ? j.copyWith(status: ShortsStatus.error, message: 'нарезка прервалась')
          : j,
    );
  }

  static ShortsJob _apply(ShortsJob job, rust.ShortsEvent e) => switch (e) {
        rust.ShortsEvent_Stage(:final message) => job.copyWith(message: message),
        rust.ShortsEvent_Progress(:final value) => job.copyWith(progress: value),
        rust.ShortsEvent_Clip(:final index, :final total) =>
          job.copyWith(clipsDone: index, clipsTotal: total),
        rust.ShortsEvent_Warning(:final message) => job.copyWith(
            warning: job.warning.isEmpty ? message : '${job.warning}\n$message'),
        rust.ShortsEvent_Done(:final dir, :final clips) => job.copyWith(
            status: ShortsStatus.done,
            progress: 1,
            outputDir: dir,
            message: 'Готово: ${_clips(clips)}',
          ),
        rust.ShortsEvent_Cancelled() =>
          job.copyWith(status: ShortsStatus.cancelled, message: 'Отменено'),
        rust.ShortsEvent_Error(:final message) =>
          job.copyWith(status: ShortsStatus.error, message: message),
      };

  static String _clips(int n) {
    final m10 = n % 10, m100 = n % 100;
    final word = m10 == 1 && m100 != 11
        ? 'ролик'
        : m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)
            ? 'ролика'
            : 'роликов';
    return '$n $word';
  }

  void _update(String input, ShortsJob Function(ShortsJob) f) =>
      state = state.copyWith(
        jobs: [for (final j in state.jobs) j.input == input ? f(j) : j],
      );
}
