import 'package:freezed_annotation/freezed_annotation.dart';

import '../rust/api/shorts.dart';

part 'models.freezed.dart';

enum ShortsStatus { loading, ready, running, done, cancelled, error }

@freezed
abstract class ShortsJob with _$ShortsJob {
  const ShortsJob._();

  const factory ShortsJob({
    required String input,
    MediaInfo? info,

    /// Номер выбранной дорожки субтитров (среди субтитров).
    int? subtitleTrack,

    /// Распознавать речь вместо субтитров из файла.
    @Default(false) bool speech,
    @Default(0) int audioTrack,
    @Default(ShortsStatus.loading) ShortsStatus status,
    @Default(0) double progress,
    @Default('') String message,

    /// Предупреждение, с которым нарезка всё же закончилась.
    @Default('') String warning,
    @Default(0) int clipsDone,
    @Default(0) int clipsTotal,
    String? outputDir,
  }) = _ShortsJob;

  String get name => input.split('/').last;

  /// Есть откуда взять текст.
  bool get hasSource => speech || subtitleTrack != null;

  bool get isFinished => switch (status) {
        ShortsStatus.done || ShortsStatus.cancelled || ShortsStatus.error => true,
        _ => false,
      };
}

@freezed
abstract class ShortsSettings with _$ShortsSettings {
  const factory ShortsSettings({
    /// Максимальная длина ролика, секунды.
    @Default(60) int maxLen,

    /// Только лучшие моменты (выбирает Claude), а не всё видео подряд.
    @Default(false) bool bestMoments,

    /// Как показывать текст.
    @Default(CaptionStyle.revealHighlight) CaptionStyle captions,

    /// Куда класть папки с роликами; null — рядом с исходником.
    String? outDir,
  }) = _ShortsSettings;
}

@freezed
abstract class ShortsState with _$ShortsState {
  const ShortsState._();

  const factory ShortsState({
    @Default([]) List<ShortsJob> jobs,
    @Default(ShortsSettings()) ShortsSettings settings,
    @Default(false) bool running,
  }) = _ShortsState;

  bool get hasReady => jobs.any((j) => j.status == ShortsStatus.ready);
}
