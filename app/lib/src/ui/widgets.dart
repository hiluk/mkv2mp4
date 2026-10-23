import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../rust/api/convert.dart' as rust;
import 'kit/controls.dart';
import 'kit/palette.dart';

/// Диалог выбора видеофайлов.
Future<List<String>> pickVideoFiles() async {
  final files = await openFiles(acceptedTypeGroups: [
    XTypeGroup(label: 'Видео', extensions: rust.videoExtensions()),
  ]);
  return files.map((f) => f.path).toList();
}

void revealInFinder(String path) => Process.run('open', ['-R', path]);

/// Зона для перетаскивания файлов. Без [child] показывает подсказку,
/// с [child] — карточку со списком.
class FileDropZone extends StatefulWidget {
  const FileDropZone({
    super.key,
    required this.enabled,
    required this.onPaths,
    required this.onTap,
    required this.hint,
    this.child,
  });

  final bool enabled;
  final ValueChanged<List<String>> onPaths;
  final VoidCallback onTap;
  final String hint;
  final Widget? child;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _dragging = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final empty = widget.child == null;
    final active = _dragging || (empty && _hover && widget.enabled);

    final decoration = BoxDecoration(
      color: _dragging ? p.accentSoft : (empty ? (active ? p.raised : Colors.transparent) : p.raised),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _dragging ? p.accent : p.line, width: _dragging ? 1.5 : 1),
    );

    final content = empty
        ? MouseRegion(
            cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: widget.enabled ? widget.onTap : null,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: p.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(CupertinoIcons.film, size: 26, color: p.accent),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.hint, textAlign: TextAlign.center, style: displayStyle(p, size: 19)),
                    const SizedBox(height: 6),
                    Text('или нажмите, чтобы выбрать',
                        style: TextStyle(color: p.muted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        : ClipRRect(borderRadius: BorderRadius.circular(12), child: widget.child);

    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (d) {
        setState(() => _dragging = false);
        widget.onPaths(d.files.map((f) => f.path).toList());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: decoration,
        child: content,
      ),
    );
  }
}

/// Список файлов с тонкими разделителями.
class FileList extends StatelessWidget {
  const FileList({super.key, required this.count, required this.itemBuilder});

  final int count;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: count,
      separatorBuilder: (_, _) => Divider(height: 1, thickness: 1, color: context.palette.line),
      itemBuilder: itemBuilder,
    );
  }
}

/// Строка файла: значок статуса, имя, подробности, прогресс и действие справа.
class FileRow extends StatelessWidget {
  const FileRow({
    super.key,
    required this.badge,
    required this.name,
    this.detail,
    this.controls,
    this.progress,
    this.status = '',
    this.statusTone = BadgeTone.neutral,
    this.warning = '',
    this.action,
  });

  final Widget badge;
  final String name;

  /// Приглушённый текст рядом с именем (длительность).
  final String? detail;

  /// Выбор дорожек и т. п. под именем.
  final Widget? controls;

  /// Не null — показывать полосу прогресса.
  final double? progress;
  final String status;
  final BadgeTone statusTone;
  final String warning;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final statusColor = statusTone == BadgeTone.error ? p.error : p.muted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: p.text),
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(width: 8),
                      Text(detail!, style: TextStyle(color: p.muted, fontSize: 12.5)),
                    ],
                  ],
                ),
                if (controls != null) ...[const SizedBox(height: 6), controls!],
                if (progress != null) ...[const SizedBox(height: 9), KitProgress(value: progress!)],
                if (status.isNotEmpty) ...[
                  SizedBox(height: progress != null ? 6 : 4),
                  Text(status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: statusColor)),
                ],
                if (warning.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(warning,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.warn)),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// Ряд настроек под списком: элементы с переносом.
class SettingsBar extends StatelessWidget {
  const SettingsBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 20,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
}

class LabeledSwitch extends StatelessWidget {
  const LabeledSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 38,
          height: 24,
          child: FittedBox(child: Switch(value: value, onChanged: onChanged)),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: context.palette.text)),
      ],
    );
    return tooltip == null ? row : Tooltip(message: tooltip!, child: row);
  }
}

/// «Сохранять: рядом с исходником / <папка>».
class OutDirPicker extends StatelessWidget {
  const OutDirPicker({
    super.key,
    required this.outDir,
    required this.onChanged,
    required this.enabled,
  });

  final String? outDir;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('Сохранять:'),
        const SizedBox(width: 2),
        KitButton.text(
          icon: CupertinoIcons.folder,
          label: outDir == null ? 'рядом с исходником' : outDir!.split('/').last,
          onPressed: enabled
              ? () async {
                  final dir = await getDirectoryPath();
                  if (dir != null) onChanged(dir);
                }
              : null,
        ),
        if (outDir != null)
          KitIconButton(
            tooltip: 'Сохранять рядом с исходником',
            icon: CupertinoIcons.xmark,
            onPressed: enabled ? () => onChanged(null) : null,
          ),
      ],
    );
  }
}

void showNothingFound(BuildContext context) => showToast(context, 'Не найдено новых видеофайлов');
