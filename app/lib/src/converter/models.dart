import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

enum JobStatus { waiting, running, done, skipped, cancelled, error }

@freezed
abstract class Job with _$Job {
  const Job._();

  const factory Job({
    required String input,
    @Default(JobStatus.waiting) JobStatus status,
    @Default(0) double progress,
    @Default('') String message,
    String? output,
  }) = _Job;

  String get name => input.split('/').last;

  bool get isFinished =>
      status != JobStatus.waiting && status != JobStatus.running;
}

@freezed
abstract class ConverterSettings with _$ConverterSettings {
  const factory ConverterSettings({
    /// Полное перекодирование вместо ремукса.
    @Default(false) bool reencode,
    @Default(false) bool overwrite,

    /// Папка для результатов; null — рядом с исходником.
    String? outDir,
  }) = _ConverterSettings;
}

@freezed
abstract class ConverterState with _$ConverterState {
  const ConverterState._();

  const factory ConverterState({
    @Default([]) List<Job> jobs,
    @Default(ConverterSettings()) ConverterSettings settings,
    @Default(false) bool running,
  }) = _ConverterState;

  bool get hasWaiting => jobs.any((j) => j.status == JobStatus.waiting);
}
