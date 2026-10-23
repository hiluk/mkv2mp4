import 'package:flutter/material.dart';

/// Цвета интерфейса (палитра Matcha). Берутся через `context.palette`.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.raised,
    required this.sunk,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.error,
    required this.errorSoft,
  });

  /// Фон окна.
  final Color bg;

  /// Карточки и списки над фоном.
  final Color raised;

  /// Утопленные области: трек прогресса, подложка переключателя.
  final Color sunk;
  final Color text;
  final Color muted;

  /// Тонкие рамки и разделители.
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color ok;
  final Color okSoft;

  /// Предупреждения (не ошибки).
  final Color warn;
  final Color error;
  final Color errorSoft;

  static const light = Palette(
    bg: Color(0xFFF3F4EE),
    raised: Color(0xFFFAFBF6),
    sunk: Color(0xFFE7E9DE),
    text: Color(0xFF252821),
    muted: Color(0xFF737868),
    line: Color(0xFFDFE2D4),
    accent: Color(0xFF4F6B2A),
    accentSoft: Color(0xFFE3EBD2),
    onAccent: Color(0xFFF6FAEA),
    ok: Color(0xFF4F6B2A),
    okSoft: Color(0xFFE3EBD2),
    warn: Color(0xFF9A6A1C),
    error: Color(0xFFB0412E),
    errorSoft: Color(0xFFF5E1DC),
  );

  static const dark = Palette(
    bg: Color(0xFF1E201B),
    raised: Color(0xFF272A23),
    sunk: Color(0xFF171914),
    text: Color(0xFFE8EBE0),
    muted: Color(0xFF979C8B),
    line: Color(0xFF353A2F),
    accent: Color(0xFFC8DE82),
    accentSoft: Color(0xFF36402A),
    onAccent: Color(0xFF1E2412),
    ok: Color(0xFFA9C46A),
    okSoft: Color(0xFF2F3826),
    warn: Color(0xFFE0B465),
    error: Color(0xFFE88A76),
    errorSoft: Color(0xFF45291F),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      bg: l(bg, other.bg),
      raised: l(raised, other.raised),
      sunk: l(sunk, other.sunk),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      ok: l(ok, other.ok),
      okSoft: l(okSoft, other.okSoft),
      warn: l(warn, other.warn),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}

/// Заголовки с засечками.
const serifFamily = 'Source Serif 4';

TextStyle displayStyle(Palette p, {double size = 26}) => TextStyle(
      fontFamily: serifFamily,
      fontSize: size,
      height: 1.15,
      letterSpacing: -0.3,
      color: p.text,
      fontVariations: [const FontVariation('wght', 500), FontVariation('opsz', size)],
    );

/// Тема Flutter под палитру: системный шрифт, без «волн» и теней Material.
ThemeData buildTheme(Palette p, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final text = base.textTheme.apply(bodyColor: p.text, displayColor: p.text);
  return base.copyWith(
    extensions: [p],
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    colorScheme: base.colorScheme.copyWith(
      primary: p.accent,
      onPrimary: p.onAccent,
      surface: p.bg,
      onSurface: p.text,
      error: p.error,
    ),
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4),
    ),
    textSelectionTheme: TextSelectionThemeData(selectionColor: p.accentSoft),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(6)),
      textStyle: TextStyle(color: p.bg, fontSize: 12),
      waitDuration: const Duration(milliseconds: 500),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      activeTrackColor: p.accent,
      inactiveTrackColor: p.sunk,
      thumbColor: p.raised,
      overlayShape: SliderComponentShape.noOverlay,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7, elevation: 1.5),
      showValueIndicator: ShowValueIndicator.never,
      disabledActiveTrackColor: p.line,
      disabledInactiveTrackColor: p.sunk,
      disabledThumbColor: p.sunk,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAccent : p.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.sunk),
      trackOutlineColor: WidgetStateProperty.all(p.line),
      thumbIcon: WidgetStateProperty.all(null),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(p.line),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(6),
    ),
  );
}
