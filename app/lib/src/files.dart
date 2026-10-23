import 'dart:io';

import 'rust/api/convert.dart' as rust;

/// Разворачивает файлы и папки (рекурсивно) в отсортированный список видеофайлов.
Future<List<String>> findVideos(Iterable<String> paths) async {
  final found = <String>[];
  for (final path in paths) {
    if (await FileSystemEntity.isDirectory(path)) {
      await for (final e in Directory(path).list(recursive: true)) {
        if (e is File && rust.isVideo(path: e.path)) found.add(e.path);
      }
    } else if (rust.isVideo(path: path)) {
      found.add(path);
    }
  }
  return found..sort();
}
