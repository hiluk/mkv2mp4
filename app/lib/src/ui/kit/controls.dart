import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'palette.dart';

/// Состояние наведения и нажатия для своих кнопок.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.builder});

  final VoidCallback? onTap;
  final Widget Function(bool hover, bool down) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = _down = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: widget.builder(enabled && _hover, enabled && _down),
      ),
    );
  }
}

enum ButtonKind { primary, outline, text }

class KitButton extends StatelessWidget {
  const KitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = ButtonKind.outline,
  });

  const KitButton.primary({super.key, required this.label, required this.onPressed, this.icon})
      : kind = ButtonKind.primary;

  const KitButton.text({super.key, required this.label, required this.onPressed, this.icon})
      : kind = ButtonKind.text;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    return _Pressable(
      onTap: onPressed,
      builder: (hover, down) {
        final (bg, fg, border) = switch (kind) {
          ButtonKind.primary => (
              enabled ? Color.lerp(p.accent, p.text, down ? .18 : hover ? .08 : 0)! : p.sunk,
              enabled ? p.onAccent : p.muted,
              Colors.transparent,
            ),
          ButtonKind.outline => (
              down ? p.sunk : hover ? p.raised : Colors.transparent,
              enabled ? p.text : p.muted.withAlpha(110),
              p.line,
            ),
          ButtonKind.text => (
              down ? p.sunk : hover ? p.raised : Colors.transparent,
              enabled ? p.muted : p.muted.withAlpha(110),
              Colors.transparent,
            ),
        };
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: kind == ButtonKind.text ? 10 : 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: kind == ButtonKind.primary ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class KitIconButton extends StatelessWidget {
  const KitIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onTap: onPressed,
        builder: (hover, down) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: down ? p.sunk : hover ? p.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon,
              size: 16, color: onPressed == null ? p.muted.withAlpha(90) : hover ? p.text : p.muted),
        ),
      ),
    );
  }
}

/// Переключатель режимов: подложка с выделенным сегментом.
class KitSegmented<T> extends StatelessWidget {
  const KitSegmented({super.key, required this.value, required this.items, required this.onChanged});

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.sunk, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in items)
            _Pressable(
              onTap: v == value ? null : () => onChanged(v),
              builder: (hover, _) {
                final on = v == value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: on ? p.raised : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: on
                        ? [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 2, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                      color: on || hover ? p.text : p.muted,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class SelectItem<T> {
  const SelectItem(this.value, this.label, {this.enabled = true});

  final T value;
  final String label;
  final bool enabled;
}

/// Выпадающий список: компактная кнопка и всплывающее меню под ней.
class KitSelect<T> extends StatefulWidget {
  const KitSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.placeholder = '—',
    this.icon,
  });

  final T? value;
  final List<SelectItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String placeholder;
  final IconData? icon;

  @override
  State<KitSelect<T>> createState() => _KitSelectState<T>();
}

class _KitSelectState<T> extends State<KitSelect<T>> {
  final _link = LayerLink();
  final _menu = OverlayPortalController();

  void _pick(T v) {
    _menu.hide();
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = widget.items.where((i) => i.value == widget.value).firstOrNull;
    final enabled = widget.onChanged != null;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: (_) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _menu.hide),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomLeft,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: _Menu<T>(items: widget.items, value: widget.value, onPick: _pick),
              ),
            ),
          ],
        ),
        child: _Pressable(
          onTap: enabled ? _menu.toggle : null,
          builder: (hover, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 26,
            padding: const EdgeInsets.only(left: 8, right: 4),
            decoration: BoxDecoration(
              color: hover ? p.raised : p.bg,
              border: Border.all(color: p.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: p.muted),
                  const SizedBox(width: 5),
                ],
                Text(
                  current?.label ?? widget.placeholder,
                  style: TextStyle(fontSize: 12.5, color: enabled ? p.text : p.muted),
                ),
                const SizedBox(width: 2),
                Icon(CupertinoIcons.chevron_up_chevron_down, size: 12, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Menu<T> extends StatelessWidget {
  const _Menu({required this.items, required this.value, required this.onPick});

  final List<SelectItem<T>> items;
  final T? value;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 420),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.raised,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              _Pressable(
                onTap: item.enabled ? () => onPick(item.value) : null,
                builder: (hover, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: hover ? p.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: item.value == value
                            ? Icon(CupertinoIcons.checkmark_alt, size: 14, color: p.accent)
                            : null,
                      ),
                      Flexible(
                        child: Text(
                          item.label,
                          style: TextStyle(fontSize: 13, color: item.enabled ? p.text : p.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MenuAction {
  const MenuAction(this.label, this.onSelected, {this.shortcut});

  final String label;
  final VoidCallback onSelected;

  /// Подсказка справа, например «⇧⌘M».
  final String? shortcut;
}

/// Кнопка-иконка со всплывающим меню действий.
class KitMenuButton extends StatefulWidget {
  const KitMenuButton({super.key, required this.icon, required this.tooltip, required this.actions});

  final IconData icon;
  final String tooltip;
  final List<MenuAction> actions;

  @override
  State<KitMenuButton> createState() => _KitMenuButtonState();
}

class _KitMenuButtonState extends State<KitMenuButton> {
  final _link = LayerLink();
  final _menu = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: (_) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _menu.hide),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 220),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: p.raised,
                    border: Border.all(color: p.line),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final a in widget.actions)
                          _Pressable(
                            onTap: () {
                              _menu.hide();
                              a.onSelected();
                            },
                            builder: (hover, _) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: hover ? p.accentSoft : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(a.label, style: TextStyle(fontSize: 13, color: p.text))),
                                  if (a.shortcut != null) ...[
                                    const SizedBox(width: 16),
                                    Text(a.shortcut!, style: TextStyle(fontSize: 12, color: p.muted)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: KitIconButton(icon: widget.icon, tooltip: widget.tooltip, onPressed: _menu.toggle),
      ),
    );
  }
}

/// Тонкая полоса прогресса.
class KitProgress extends StatelessWidget {
  const KitProgress({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 4,
        width: double.infinity,
        color: p.sunk,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(3)),
          ),
        ),
      ),
    );
  }
}

enum BadgeTone { neutral, accent, ok, error }

/// Значок статуса в мягком квадрате.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.icon, this.tone = BadgeTone.neutral});

  final IconData icon;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      BadgeTone.neutral => (p.sunk, p.muted),
      BadgeTone.accent => (p.accentSoft, p.accent),
      BadgeTone.ok => (p.okSoft, p.ok),
      BadgeTone.error => (p.errorSoft, p.error),
    };
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, size: 14, color: fg),
    );
  }
}

/// Подпись к настройке: «Текст:» приглушённым цветом.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 12.5, color: context.palette.muted));
}

/// Короткое уведомление внизу окна.
void showToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final p = context.palette;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      bottom: 72,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 180),
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: p.text,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Text(
              message,
              style: TextStyle(color: p.bg, fontSize: 13, decoration: TextDecoration.none),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2400), entry.remove);
}
