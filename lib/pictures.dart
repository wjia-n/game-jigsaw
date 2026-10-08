import 'package:flutter/material.dart';

/// Three original generated pictures, painted fresh every run.
/// Each paints a pretty scene into whatever size it's given.

class SunsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF2B1B4E), Color(0xFFB23A72), Color(0xFFFF9A5A)],
        ).createShader(Offset.zero & size),
    );
    // clouds
    final cloud = Paint()..color = const Color(0xFFFFC7A3).withValues(alpha: 0.55);
    for (final c in [(0.2, 0.22, 90.0), (0.65, 0.3, 120.0), (0.45, 0.14, 70.0)]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * c.$1, h * c.$2),
            width: c.$3 * w / 300, height: 22 * h / 300),
        cloud,
      );
    }
    // sun + glow
    final sunC = Offset(w * 0.5, h * 0.62);
    canvas.drawCircle(sunC, 60 * w / 300,
        Paint()..color = const Color(0xFFFFE29A).withValues(alpha: 0.35));
    canvas.drawCircle(
        sunC, 38 * w / 300, Paint()..color = const Color(0xFFFFF3B0));
    // sea
    final seaTop = h * 0.66;
    canvas.drawRect(
      Rect.fromLTWH(0, seaTop, w, h - seaTop),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF7A2E6D), Color(0xFF1E2A5A)],
        ).createShader(Rect.fromLTWH(0, seaTop, w, h - seaTop)),
    );
    // sun reflection
    final refl = Paint()..color = const Color(0xFFFFD97A).withValues(alpha: 0.7);
    for (int i = 0; i < 5; i++) {
      final y = seaTop + 8 + i * 12 * h / 300;
      final ww = (70 - i * 10) * w / 300;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(w * 0.5, y), width: ww, height: 5),
            const Radius.circular(3)),
        refl,
      );
    }
    // birds
    final bird = Paint()
      ..color = const Color(0xFF2B1B4E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final b in [(0.25, 0.35), (0.33, 0.3), (0.72, 0.42)]) {
      final x = w * b.$1, y = h * b.$2;
      final p = Path()
        ..moveTo(x - 12, y)
        ..quadraticBezierTo(x - 4, y - 8, x, y)
        ..quadraticBezierTo(x + 4, y - 8, x + 12, y);
      canvas.drawPath(p, bird);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF3A7BD5), Color(0xFFBDE3FF)],
        ).createShader(Offset.zero & size),
    );
    // sun
    canvas.drawCircle(Offset(w * 0.82, h * 0.18), 26 * w / 300,
        Paint()..color = const Color(0xFFFFF6C9));
    // mountains (back to front)
    void mountain(double cx, double baseY, double halfW, double peakY,
        Color color) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - halfW, baseY)
          ..lineTo(cx, peakY)
          ..lineTo(cx + halfW, baseY)
          ..close(),
        Paint()..color = color,
      );
      // snow cap
      final t = 0.32;
      canvas.drawPath(
        Path()
          ..moveTo(cx - halfW * t, peakY + (baseY - peakY) * t)
          ..lineTo(cx, peakY)
          ..lineTo(cx + halfW * t, peakY + (baseY - peakY) * t)
          ..lineTo(cx + halfW * t * 0.4, peakY + (baseY - peakY) * t * 1.5)
          ..lineTo(cx, peakY + (baseY - peakY) * t * 1.25)
          ..lineTo(cx - halfW * t * 0.4, peakY + (baseY - peakY) * t * 1.5)
          ..close(),
        Paint()..color = Colors.white,
      );
    }

    final baseY = h * 0.72;
    mountain(w * 0.2, baseY, w * 0.28, h * 0.3, const Color(0xFF6B8EAE));
    mountain(w * 0.55, baseY, w * 0.34, h * 0.18, const Color(0xFF4A6FA5));
    mountain(w * 0.85, baseY, w * 0.24, h * 0.36, const Color(0xFF5B7FA6));
    // lake
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, w, h - baseY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF9FD4FF), Color(0xFF2E5E8C)],
        ).createShader(Rect.fromLTWH(0, baseY, w, h - baseY)),
    );
    // reflections
    final refl = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.55, baseY + 18), width: w * 0.3, height: 6),
            const Radius.circular(3)),
        refl);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.2, baseY + 34), width: w * 0.2, height: 5),
            const Radius.circular(3)),
        refl);
    // pine trees
    void pine(double x, double y, double s) {
      final trunk = Paint()..color = const Color(0xFF5A3A22);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: s * 0.14, height: s * 0.4), trunk);
      final leaf = Paint()..color = const Color(0xFF2E6B3E);
      for (int i = 0; i < 3; i++) {
        final yy = y - s * 0.15 - i * s * 0.22;
        final ww = s * (0.5 - i * 0.11);
        canvas.drawPath(
          Path()
            ..moveTo(x - ww, yy)
            ..lineTo(x, yy - s * 0.3)
            ..lineTo(x + ww, yy)
            ..close(),
          leaf,
        );
      }
    }

    pine(w * 0.08, baseY + h * 0.16, 46);
    pine(w * 0.93, baseY + h * 0.13, 38);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BeachPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF4FC3F7), Color(0xFFDFF9FF)],
        ).createShader(Offset.zero & size),
    );
    // sun
    canvas.drawCircle(Offset(w * 0.2, h * 0.2), 30 * w / 300,
        Paint()..color = const Color(0xFFFFF176));
    // sea
    final seaTop = h * 0.45;
    canvas.drawRect(
      Rect.fromLTWH(0, seaTop, w, h * 0.25),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF26C6DA), Color(0xFF0288D1)],
        ).createShader(Rect.fromLTWH(0, seaTop, w, h * 0.25)),
    );
    // waves
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final y = seaTop + 14 + i * 16 * h / 300;
      final p = Path();
      for (double x = 10; x < w - 10; x += 36) {
        p.moveTo(x, y);
        p.quadraticBezierTo(x + 9, y - 8, x + 18, y);
        p.quadraticBezierTo(x + 27, y + 8, x + 36, y);
      }
      canvas.drawPath(p, wave);
    }
    // sand
    final sandTop = h * 0.7;
    canvas.drawRect(
      Rect.fromLTWH(0, sandTop, w, h - sandTop),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFFFE0A3), Color(0xFFF5C86B)],
        ).createShader(Rect.fromLTWH(0, sandTop, w, h - sandTop)),
    );
    // palm tree
    final trunkPaint = Paint()
      ..color = const Color(0xFF8D5A2B)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final tx = w * 0.78, ty = sandTop + 10;
    canvas.drawPath(
      Path()
        ..moveTo(tx, ty + 60)
        ..quadraticBezierTo(tx + 10, ty, tx + 34, ty - 44),
      trunkPaint,
    );
    final top = Offset(tx + 34, ty - 44);
    final frond = Paint()
      ..color = const Color(0xFF43A047)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    for (final a in [-0.4, 0.15, 0.7, 1.25, 1.8, 2.4, 2.95]) {
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + 34 * a.clamp(-1, 1) * 1.4,
            top.dy - 26,
            top.dx + 52 * a.clamp(-1, 1) * 1.2,
            top.dy + 6,
          ),
        frond,
      );
    }
    // coconuts
    canvas.drawCircle(top + const Offset(-6, 8), 7, Paint()..color = const Color(0xFF6D4C41));
    canvas.drawCircle(top + const Offset(8, 10), 7, Paint()..color = const Color(0xFF6D4C41));
    // beach ball
    final bx = w * 0.25, by = sandTop + h * 0.14, br = 26.0;
    canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.white);
    const segs = [Colors.red, Colors.blue, Colors.yellow];
    for (int i = 0; i < segs.length; i++) {
      canvas.drawArc(Rect.fromCircle(center: Offset(bx, by), radius: br),
          i * 2.1, 1.9, true, Paint()..color = segs[i]);
    }
    canvas.drawCircle(Offset(bx, by), 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
