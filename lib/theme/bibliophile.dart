import 'package:flutter/material.dart';
import 'bibliophile_themes.dart';

/// Bibliophile Puzzle Sanctuary — the Stitch-derived design system for Jigsaw.
/// Antiquarian scholar's study late at night: real walnut, linen mat,
/// brass/copper/silver, parchment, warm lamplight.
/// No neon, no cyberpunk, no generic Material look.
///
/// All widgets accept an optional [LibraryThemeDef]; they default to the
/// Bibliophile Classic theme so existing call sites keep working.
class Bibliophile {
  // Classic palette (from DESIGN.md) — kept for compatibility.
  static const walnutDark = Color(0xFF3B2A1E);
  static const walnutMid = Color(0xFF5A4330);
  static const walnutDeep = Color(0xFF0C0806);
  static const brass = Color(0xFFC9A227);
  static const brassLight = Color(0xFFE8C96A);
  static const brassDark = Color(0xFF8A6D1A);
  static const ivory = Color(0xFFF3E8CB);
  static const ivoryDim = Color(0xFFD9CDAE);
  static const baize = Color(0xFF2F5D43);
  static const amber = Color(0xFFE8A94E);
  static const shadow = Color(0xFF0C0806);

  static const displayFont = 'serif';

  static TextStyle display(double size,
          {Color? color, LibraryThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? brassLight,
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: shadow, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, LibraryThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.ivory ?? ivory,
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, LibraryThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? brassLight,
        letterSpacing: 0.8,
      );

  static ThemeData theme([LibraryThemeDef? t]) {
    t ??= LibraryThemes.byId('bibliophile');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.woodMid,
        onSurface: t.ivory,
        error: t.folio,
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.woodMid),
    );
  }
}

/// Walnut wood-grain background with a warm vignette, theme-aware.
class WoodBackdrop extends StatelessWidget {
  final Widget child;
  final LibraryThemeDef? theme;
  const WoodBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? LibraryThemes.byId('classic');
    return Container(
      decoration: BoxDecoration(color: t.woodDark),
      child: CustomPaint(
        painter: _WoodGrainPainter(t),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  final LibraryThemeDef t;
  _WoodGrainPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.15,
      colors: [
        t.woodMid.withValues(alpha: 0.55),
        t.woodDark.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
    final grain = Paint()
      ..color = t.woodDeep.withValues(alpha: 0.16)
      ..strokeWidth = 2.5;
    for (int i = 0; i < 14; i++) {
      final x = size.width * (i + 0.5) / 14;
      final wobble = (i % 3 - 1) * 8.0;
      canvas.drawLine(
        Offset(x + wobble, 0),
        Offset(x - wobble, size.height),
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky wooden button with metal trim — looks physically pressable.
class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final LibraryThemeDef? theme;

  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 240,
    this.fontSize = 19,
    this.theme,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? LibraryThemes.byId('classic');
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [t.woodMid, t.woodDark, t.woodDeep]
                : [
                    t.woodDeep.withValues(alpha: 0.7),
                    t.woodDeep.withValues(alpha: 0.5)
                  ],
          ),
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: t.accentLight.withValues(alpha: _pressed ? 0.05 : 0.22),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Bibliophile.display(widget.fontSize,
              theme: t,
              color: enabled
                  ? t.ivory
                  : t.ivory.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

/// An engraved metal plaque for titles.
class BrassPlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final LibraryThemeDef? theme;
  const BrassPlaque(
      {super.key, required this.title, this.subtitle, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? LibraryThemes.byId('classic');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.woodDeep, t.woodDark],
        ),
        border: Border.all(color: t.accent, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 12),
          BoxShadow(
              color: t.accentLight.withValues(alpha: 0.7),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: Bibliophile.display(30, theme: t),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: Bibliophile.body(14,
                    theme: t, color: t.ivory.withValues(alpha: 0.75)),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// A metal lever toggle for settings.
class BrassStudToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final LibraryThemeDef? theme;
  const BrassStudToggle(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? LibraryThemes.byId('classic');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? t.accentDark : t.woodDeep,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wooden-bead volume slider on a metal rail.
class BeadSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final LibraryThemeDef? theme;
  const BeadSlider(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? LibraryThemes.byId('classic');
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.woodDeep,
        thumbShape: _BeadThumb(t),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BeadThumb extends SliderComponentShape {
  final LibraryThemeDef t;
  const _BeadThumb(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2),
        12,
        Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [t.accentLight, t.accent, t.accentDark],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final LibraryThemeDef? theme;
  const SettingRow(
      {super.key, required this.label, required this.control, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? LibraryThemes.byId('classic');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.woodDeep.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Bibliophile.body(16, theme: t))),
          control,
        ],
      ),
    );
  }
}

/// A stitched saddle-leather library card button with gold-embossed text and
/// brass grommets, from the Stitch "Bibliophile Puzzle Sanctuary" system.
/// Pressed state travels 2px downward with a shrinking shadow.
class LeatherCardButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final LibraryThemeDef? theme;

  const LeatherCardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 260,
    this.fontSize = 18,
    this.theme,
  });

  @override
  State<LeatherCardButton> createState() => _LeatherCardButtonState();
}

class _LeatherCardButtonState extends State<LeatherCardButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? LibraryThemes.byId('bibliophile');
    final enabled = widget.onTap != null;
    final leather = Color.lerp(t.woodMid, t.ink, 0.25)!;
    final leatherDark = Color.lerp(t.woodDeep, t.ink, 0.35)!;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [leather, leatherDark]
                : [
                    leatherDark.withValues(alpha: 0.6),
                    leatherDark.withValues(alpha: 0.4)
                  ],
          ),
          // Stitched border: dashed line painter would be ideal; use a thin
          // inner highlight plus outer brass edge to suggest the saddle stitch.
          border: Border.all(
              color: enabled
                  ? t.accent.withValues(alpha: 0.85)
                  : t.accent.withValues(alpha: 0.35),
              width: 2),
          boxShadow: [
            BoxShadow(
              color: t.accentLight.withValues(alpha: _pressed ? 0.04 : 0.18),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brass grommets at each end.
            _grommet(t, enabled),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: Bibliophile.label(widget.fontSize, theme: t).copyWith(
                  color: enabled
                      ? t.accentLight
                      : t.accentLight.withValues(alpha: 0.4),
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(0, 1),
                        blurRadius: 2),
                    Shadow(
                        color: t.accentLight.withValues(alpha: 0.25),
                        offset: const Offset(0, -1),
                        blurRadius: 1),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _grommet(t, enabled),
          ],
        ),
      ),
    );
  }

  Widget _grommet(LibraryThemeDef t, bool enabled) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 1.0,
            colors: enabled
                ? [t.accentLight, t.accent, t.accentDark]
                : [
                    t.accentDark.withValues(alpha: 0.5),
                    t.accentDark.withValues(alpha: 0.3)
                  ],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(0, 1),
                blurRadius: 2),
          ],
        ),
      );
}

/// Warm banker's-lamp glow pool overlay: amber light with gentle falloff into
/// a cozy vignette, from the Stitch design system.
class LampGlow extends StatelessWidget {
  final Widget child;
  final LibraryThemeDef? theme;
  const LampGlow({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? LibraryThemes.byId('bibliophile');
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.55),
                  radius: 1.35,
                  colors: [
                    t.lampGlow.withValues(alpha: 0.22),
                    t.lampGlow.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small circular brass icon button (pause, hint, zoom…), per the game-board
/// layout in DESIGN.md.
class BrassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool dimmed;
  final LibraryThemeDef? theme;

  const BrassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.dimmed = false,
    this.theme,
  });

  @override
  State<BrassIconButton> createState() => _BrassIconButtonState();
}

class _BrassIconButtonState extends State<BrassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? LibraryThemes.byId('bibliophile');
    final enabled = widget.onTap != null && !widget.dimmed;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 1.1,
            colors: enabled
                ? [t.accentLight, t.accent, t.accentDark]
                : [t.woodMid, t.woodDeep],
          ),
          border: Border.all(
              color: t.accentDark.withValues(alpha: 0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: Offset(0, _pressed ? 2 : 5),
              blurRadius: _pressed ? 4 : 9,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: enabled
              ? t.woodDeep
              : t.ivory.withValues(alpha: 0.4),
          size: widget.size * 0.46,
        ),
      ),
    );
  }
}
