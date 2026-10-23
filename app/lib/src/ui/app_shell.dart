import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../converter/converter.dart';
import 'convert_page.dart';
import 'kit/controls.dart';
import 'kit/palette.dart';
import 'shorts_page.dart';

/// Главный экран — ролики; конвертация в MP4 — дополнительный, открывается из меню.
enum Mode { shorts, convert }

/// Высота прозрачного заголовка окна macOS (там «светофор»).
const _titleBarHeight = 28.0;

const _convertShortcut = SingleActivator(LogicalKeyboardKey.keyM, meta: true, shift: true);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialMode = Mode.shorts});

  final Mode initialMode;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late Mode _mode = widget.initialMode;

  void _show(Mode m) => setState(() => _mode = m);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ffmpeg = ref.watch(ffmpegPathProvider);
    final (title, subtitle) = switch (_mode) {
      Mode.shorts => ('Ролики для TikTok', 'Нарезка 9:16 с субтитрами из файла или из речи'),
      Mode.convert => ('Конвертация в MP4', 'MKV, AVI, MOV, WebM и другие — быстро и без потери качества'),
    };

    return PlatformMenuBar(
      menus: [
        const PlatformMenu(label: 'MKV2MP4', menus: [
          PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.servicesSubmenu),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hideOtherApplications),
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.showAllApplications),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ]),
        ]),
        PlatformMenu(label: 'Файл', menus: [
          PlatformMenuItem(label: 'Ролики для TikTok', onSelected: () => _show(Mode.shorts)),
          PlatformMenuItem(
            label: 'Конвертация в MP4…',
            shortcut: _convertShortcut,
            onSelected: () => _show(Mode.convert),
          ),
        ]),
        const PlatformMenu(label: 'Окно', menus: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.minimizeWindow),
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.zoomWindow),
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.toggleFullScreen),
        ]),
      ],
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, _titleBarHeight + 6, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_mode == Mode.convert)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Transform.translate(
                              offset: const Offset(-10, 0),
                              child: KitButton.text(
                                icon: CupertinoIcons.chevron_left,
                                label: 'К роликам',
                                onPressed: () => _show(Mode.shorts),
                              ),
                            ),
                          ),
                        Text(title, style: displayStyle(p)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: p.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (_mode == Mode.shorts)
                    KitMenuButton(
                      icon: CupertinoIcons.ellipsis,
                      tooltip: 'Ещё',
                      actions: [
                        MenuAction('Конвертация в MP4', () => _show(Mode.convert), shortcut: '⇧⌘M'),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (ffmpeg == null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.errorSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle, size: 16, color: p.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ffmpeg не найден. Пересоберите приложение: ffmpeg должен лежать в Contents/Resources.',
                          style: TextStyle(color: p.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: switch (_mode) {
                  Mode.shorts => const ShortsPage(),
                  Mode.convert => const ConvertPage(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
