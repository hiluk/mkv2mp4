import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mkv2mp4_app/main.dart';
import 'package:mkv2mp4_app/src/converter/converter.dart';
import 'package:mkv2mp4_app/src/converter/models.dart';
import 'package:mkv2mp4_app/src/rust/api/shorts.dart';
import 'package:mkv2mp4_app/src/rust/frb_generated.dart';
import 'package:mkv2mp4_app/src/shorts/models.dart';
import 'package:mkv2mp4_app/src/shorts/shorts.dart';
import 'package:mkv2mp4_app/src/ui/app_shell.dart';

/// Куда сохранить PNG: --dart-define=SHOT_DIR=...
const shotDir = String.fromEnvironment('SHOT_DIR');

class _FakeShorts extends Shorts {
  @override
  ShortsState build() {
    const ru = TrackInfo(index: 0, codec: 'aac', language: 'rus', title: 'Русский', isDefault: true, isText: false);
    const en = TrackInfo(index: 1, codec: 'aac', language: 'eng', title: 'English', isDefault: false, isText: false);
    const srt = TrackInfo(index: 0, codec: 'subrip', language: 'rus', title: null, isDefault: true, isText: true);
    return const ShortsState(jobs: [
      ShortsJob(
        input: '/Movies/speech_test.mkv',
        info: MediaInfo(duration: 82, audio: [ru, en], subtitles: []),
        speech: true,
        status: ShortsStatus.running,
        progress: 0.42,
        message: 'Распознаю речь (Whisper)',
      ),
      ShortsJob(
        input: '/Movies/interview.mkv',
        info: MediaInfo(duration: 724, audio: [ru], subtitles: [srt]),
        subtitleTrack: 0,
        status: ShortsStatus.done,
        message: 'Готово: 13 роликов',
        outputDir: '/Movies/interview_tiktok',
        warning: 'Claude не вычитал 1 из 3 фрагментов текста (API 529: Overloaded)',
      ),
      ShortsJob(
        input: '/Movies/vlog_episode_04.mkv',
        info: MediaInfo(duration: 1395, audio: [ru], subtitles: [srt]),
        subtitleTrack: 0,
        status: ShortsStatus.ready,
      ),
    ], running: true, settings: ShortsSettings(bestMoments: true));
  }
}

class _FakeConverter extends Converter {
  @override
  ConverterState build() => const ConverterState(jobs: [
        Job(input: '/Movies/film.mkv', status: JobStatus.done, message: 'Готово', output: '/Movies/film.mp4'),
        Job(
          input: '/Movies/series_s01e02.mkv',
          status: JobStatus.running,
          progress: 0.67,
          message: 'ремукс (видео и субтитры без перекодирования)',
        ),
        Job(input: '/Movies/series_s01e03.mkv'),
        Job(
          input: '/Movies/broken.mkv',
          status: JobStatus.error,
          message: 'ошибка конвертации: Invalid data found when processing input',
        ),
      ]);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  Future<void> shot(WidgetTester tester, String name, Widget app, {List overrides = const []}) async {
    tester.view.physicalSize = const Size(1800, 1240);
    tester.view.devicePixelRatio = 2;
    // Убираем прошлое окно целиком: меню macOS (PlatformMenuBar) может быть только одно.
    await tester.pumpWidget(const SizedBox());
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        speechConfigProvider.overrideWith((ref) async =>
            const SpeechConfig(envFile: '/tmp/.env', hasApiKey: true, whisperAvailable: true)),
        ffmpegPathProvider.overrideWith((ref) => '/ffmpeg'),
        ...overrides,
      ],
      child: RepaintBoundary(key: key, child: app),
    ));
    await tester.pumpAndSettle();
    await binding.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shotDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('скриншоты ${mode.name}', (tester) async {
      await shot(tester, 'shorts_${mode.name}', App(themeMode: mode, initialMode: Mode.shorts),
          overrides: [shortsProvider.overrideWith(_FakeShorts.new)]);
      await shot(tester, 'convert_${mode.name}', App(themeMode: mode, initialMode: Mode.convert),
          overrides: [converterProvider.overrideWith(_FakeConverter.new)]);
      await shot(tester, 'empty_${mode.name}', App(themeMode: mode, initialMode: Mode.shorts));
    }, skip: shotDir.isEmpty);
  }
}
