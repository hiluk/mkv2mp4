import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../files.dart';
import '../rust/api/convert.dart' as rust;
import 'models.dart';

part 'converter.g.dart';

/// Путь к встроенному ffmpeg или null, если его нет.
@Riverpod(keepAlive: true)
String? ffmpegPath(Ref ref) => rust.ffmpegPath();

@Riverpod(keepAlive: true)
class Converter extends _$Converter {
  @override
  ConverterState build() => const ConverterState();

  /// Добавляет файлы и папки (рекурсивно); возвращает число добавленных видео.
  Future<int> addPaths(Iterable<String> paths) async {
    final found = await findVideos(paths);
    final known = state.jobs.map((j) => j.input).toSet();
    final added = found.where(known.add).map((p) => Job(input: p)).toList();
    state = state.copyWith(jobs: [...state.jobs, ...added]);
    return added.length;
  }

  void setReencode(bool v) =>
      state = state.copyWith.settings(reencode: v);

  void setOverwrite(bool v) =>
      state = state.copyWith.settings(overwrite: v);

  void setOutDir(String? dir) =>
      state = state.copyWith.settings(outDir: dir);

  void remove(String input) => state = state.copyWith(
        jobs: state.jobs.where((j) => j.input != input).toList(),
      );

  void retry(String input) => _update(
        input,
        (j) => j.copyWith(status: JobStatus.waiting, progress: 0, message: ''),
      );

  void clearFinished() => state = state.copyWith(
        jobs: state.jobs.where((j) => !j.isFinished).toList(),
      );

  /// Конвертирует по очереди все ожидающие файлы.
  Future<void> start() async {
    if (state.running) return;
    state = state.copyWith(running: true);
    final settings = state.settings;
    while (state.running) {
      final next = state.jobs
          .where((j) => j.status == JobStatus.waiting)
          .firstOrNull;
      if (next == null) break;
      await _convert(next.input, settings);
    }
    state = state.copyWith(running: false);
  }

  void cancel() {
    state = state.copyWith(running: false);
    rust.cancel();
  }

  Future<void> _convert(String input, ConverterSettings settings) async {
    _update(input, (j) => j.copyWith(status: JobStatus.running, progress: 0, message: ''));
    final events = rust.convertFile(
      input: input,
      outDir: settings.outDir,
      reencode: settings.reencode,
      overwrite: settings.overwrite,
      batch: [for (final j in state.jobs) j.input],
    );
    await for (final e in events) {
      _update(input, (j) => _apply(j, e));
    }
    // Поток закрылся без итогового события — считаем ошибкой.
    _update(
      input,
      (j) => j.status == JobStatus.running
          ? j.copyWith(status: JobStatus.error, message: 'конвертация прервалась')
          : j,
    );
  }

  static Job _apply(Job job, rust.ConvertEvent e) => switch (e) {
        rust.ConvertEvent_Attempt(:final label) => job.copyWith(message: label),
        rust.ConvertEvent_Info(:final message) => job.copyWith(message: message),
        rust.ConvertEvent_Progress(:final value) => job.copyWith(progress: value),
        rust.ConvertEvent_Done(:final output) => job.copyWith(
            status: JobStatus.done,
            progress: 1,
            output: output,
            message: 'Готово',
          ),
        rust.ConvertEvent_Skipped(:final output) => job.copyWith(
            status: JobStatus.skipped,
            output: output,
            message: 'MP4 уже существует — пропущено',
          ),
        rust.ConvertEvent_Cancelled() =>
          job.copyWith(status: JobStatus.cancelled, message: 'Отменено'),
        rust.ConvertEvent_Error(:final message) =>
          job.copyWith(status: JobStatus.error, message: message),
      };

  void _update(String input, Job Function(Job) f) => state = state.copyWith(
        jobs: [for (final j in state.jobs) j.input == input ? f(j) : j],
      );
}
