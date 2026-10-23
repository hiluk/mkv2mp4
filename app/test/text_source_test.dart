import 'package:flutter_test/flutter_test.dart';
import 'package:mkv2mp4_app/src/rust/api/shorts.dart';
import 'package:mkv2mp4_app/src/shorts/shorts.dart';

TrackInfo track(int index, String? lang, {bool text = true, bool isDefault = false, String codec = 'subrip'}) =>
    TrackInfo(index: index, codec: codec, language: lang, title: null, isDefault: isDefault, isText: text);

MediaInfo media(List<TrackInfo> audio, List<TrackInfo> subs) =>
    MediaInfo(duration: 60, audio: audio, subtitles: subs);

void main() {
  final ru = track(0, 'rus', codec: 'aac', isDefault: true);

  test('субтитры на языке звука', () {
    final (sub, speech) = chooseTextSource(media([ru], [track(0, 'eng', isDefault: true), track(1, 'ru')]), ru);
    expect((sub?.index, speech), (1, false));
  });

  test('субтитры только на другом языке — распознаём речь, дорожка остаётся', () {
    final (sub, speech) = chooseTextSource(media([ru], [track(0, 'eng')]), ru);
    expect((sub?.index, speech), (0, true));
  });

  test('язык неизвестен — берём субтитры', () {
    expect(chooseTextSource(media([ru], [track(0, null)]), ru).$2, isFalse);
    final noLang = track(0, null, codec: 'aac');
    expect(chooseTextSource(media([noLang], [track(0, 'eng')]), noLang).$2, isFalse);
  });

  test('нет текстовых субтитров — речь; нет звука — ничего', () {
    expect(chooseTextSource(media([ru], [track(0, 'rus', text: false)]), ru), (null, true));
    expect(chooseTextSource(media([], [track(0, 'eng')]), null).$2, isFalse);
  });

  test('коды языков', () {
    expect(sameLanguage('rus', 'ru'), isTrue);
    expect(sameLanguage('ENG', 'eng'), isTrue);
    expect(sameLanguage('nor', 'rus'), isFalse);
  });
}
