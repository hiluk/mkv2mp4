import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mkv2mp4_app/src/converter/converter.dart';
import 'package:mkv2mp4_app/src/converter/models.dart';
import 'package:mkv2mp4_app/src/rust/frb_generated.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Папка с тестовыми .mkv задаётся через --dart-define=TEST_DIR=...
const testDir = String.fromEnvironment('TEST_DIR');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  test('встроенный ffmpeg найден', () {
    final container = ProviderContainer();
    expect(container.read(ffmpegPathProvider), contains('Contents/Resources/ffmpeg'));
  });

  test('конвертирует папку с MKV', () async {
    final container = ProviderContainer();
    final notifier = container.read(converterProvider.notifier);
    final added = await notifier.addPaths([testDir]);
    expect(added, greaterThan(0));
    await notifier.start();
    final jobs = container.read(converterProvider).jobs;
    for (final j in jobs) {
      expect(j.status, JobStatus.done, reason: '${j.name}: ${j.message}');
      expect(File(j.output!).existsSync(), isTrue);
    }
  }, skip: testDir.isEmpty);
}
