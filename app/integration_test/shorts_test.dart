import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mkv2mp4_app/src/rust/frb_generated.dart';
import 'package:mkv2mp4_app/src/shorts/models.dart';
import 'package:mkv2mp4_app/src/shorts/shorts.dart';

/// MKV с текстовыми субтитрами: --dart-define=SHORTS_FILE=...
const file = String.fromEnvironment('SHORTS_FILE');

/// MKV с речью и без субтитров: --dart-define=SPEECH_FILE=...
const speechFile = String.fromEnvironment('SPEECH_FILE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  test('нарезает MKV на ролики', () async {
    final container = ProviderContainer();
    final notifier = container.read(shortsProvider.notifier);
    expect(await notifier.addPaths([file]), 1);

    var job = container.read(shortsProvider).jobs.single;
    expect(job.status, ShortsStatus.ready, reason: job.message);
    expect(job.info!.subtitles.length, 2);
    // Выбрана дорожка по умолчанию (eng srt) — переключаем на русскую ASS.
    notifier.setSubtitleTrack(file, 1);
    notifier.setMaxLen(45);

    await notifier.start();
    job = container.read(shortsProvider).jobs.single;
    expect(job.status, ShortsStatus.done, reason: job.message);
    expect(job.clipsTotal, 4);
    final mp4 = Directory(job.outputDir!)
        .listSync()
        .where((e) => e.path.endsWith('.mp4'))
        .toList();
    expect(mp4.length, 4);
  }, skip: file.isEmpty);

  test('распознаёт речь, если субтитров нет', () async {
    final container = ProviderContainer();
    final notifier = container.read(shortsProvider.notifier);
    expect(await notifier.addPaths([speechFile]), 1);

    var job = container.read(shortsProvider).jobs.single;
    expect(job.status, ShortsStatus.ready, reason: job.message);
    expect(job.speech, isTrue);
    notifier.setMaxLen(20);

    await notifier.start();
    job = container.read(shortsProvider).jobs.single;
    expect(job.status, ShortsStatus.done, reason: job.message);
    expect(job.clipsTotal, greaterThan(1));
    final txt = File('${job.outputDir}/${job.name.replaceAll('.mkv', '')}.txt');
    expect(txt.readAsStringSync(), contains('ролик'));
  }, skip: speechFile.isEmpty, timeout: const Timeout(Duration(minutes: 5)));
}
