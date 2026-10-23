import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/rust/frb_generated.dart';
import 'src/ui/app_shell.dart';
import 'src/ui/kit/palette.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key, this.themeMode = ThemeMode.system, this.initialMode = Mode.shorts});

  /// Тема по умолчанию следует настройке macOS.
  final ThemeMode themeMode;
  final Mode initialMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MKV2MP4',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTheme(Palette.light, Brightness.light),
      darkTheme: buildTheme(Palette.dark, Brightness.dark),
      home: AppShell(initialMode: initialMode),
    );
  }
}
