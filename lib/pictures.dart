import 'dart:math';
import 'package:flutter/material.dart';

/// Built-in picture folio: original painted scenes for the puzzles.
/// All scenes live in the cozy pastoral/library world — warm, readable at
/// piece scale, no trademarked or AI-looking content.
///
/// Free: 0 Meadow Dawn, 1 Hearthside Library, 2 Botanical Folio,
/// 3 Cartographer's Study. PRO: 4 Oxford Quadrangle, 5 Antiquarian Vault,
/// 6 Moonlit Orangery, 7 Harvest Fair.
class PictureFolio {
  static const List<String> names = [
    'Meadow Dawn',
    'Hearthside Library',
    'Botanical Folio',
    "Cartographer's Study",
    'Oxford Quadrangle',
    'Antiquarian Vault',
    'Moonlit Orangery',
    'Harvest Fair',
  ];

  static const List<bool> isPro = [
    false,
    false,
    false,
    false,
    true,
    true,
    true,
    true,
  ];

  static CustomPainter painter(int id) => switch (id) {
        1 => HearthsidePainter(),
        2 => BotanicalPainter(),
        3 => CartographerPainter(),
        4 => QuadranglePainter(),
        5 => VaultPainter(),
        6 => OrangeryPainter(),
        7 => HarvestPainter(),
        _ => MeadowPainter(),
      };
}

/// Shared helpers for scene painters.
void _fillRect(Canvas c, Size s, Color color) =>
    c.drawRect(Offset.zero & s, Paint()..color = color);

void _sunGlow(Canvas c, Offset center, double r, Color color) {
  c.drawCircle(center, r, Paint()..color = color.withValues(alpha: 0.25));
  c.drawCircle(center, r * 0.6, Paint()..color = color.withValues(alpha: 0.4));
  c.drawCircle(center, r * 0.35, Paint()..color = color);
}

/// 0 — Sunrise over a meadow: tree, fence, drifting clouds.
class MeadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(101);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF8FB8D8),
            Color(0xFFE8C98A),
            Color(0xFFF0A95E),
          ],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.62, h * 0.42), 60 * w / 300,
        const Color(0xFFFFE9A8));
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (final p in [(0.2, 0.18), (0.72, 0.12), (0.45, 0.28)]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w * p.$1, h * p.$2),
              width: 90 * w / 300,
              height: 24 * h / 300),
          cloud);
    }
    // meadow
    final hillTop = h * 0.58;
    canvas.drawRect(
      Rect.fromLTWH(0, hillTop, w, h - hillTop),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF7AA85C), Color(0xFF3F6E38)],
        ).createShader(Rect.fromLTWH(0, hillTop, w, h - hillTop)),
    );
    // fence
    final fence = Paint()
      ..color = const Color(0xFF6E4A2E)
      ..strokeWidth = 5 * w / 300
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final x = w * (0.08 + i * 0.17);
      canvas.drawLine(Offset(x, hillTop + 6), Offset(x, h * 0.86), fence);
    }
    canvas.drawLine(Offset(0, hillTop + 16 * h / 300),
        Offset(w, hillTop + 10 * h / 300), fence);
    canvas.drawLine(Offset(0, hillTop + 40 * h / 300),
        Offset(w, hillTop + 34 * h / 300), fence);
    // tree
    canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.32, 14 * w / 300, h * 0.34),
        Paint()..color = const Color(0xFF5A3A22));
    canvas.drawCircle(
        Offset(w * 0.16, h * 0.3), 46 * w / 300,
        Paint()..color = const Color(0xFF3E7A3A));
    canvas.drawCircle(
        Offset(w * 0.24, h * 0.36), 34 * w / 300,
        Paint()..color = const Color(0xFF4E8E44));
    // sheep dots
    for (int i = 0; i < 4; i++) {
      final x = w * (0.5 + i * 0.12) + r.nextDouble() * 8;
      final y = h * 0.78 + r.nextDouble() * h * 0.08;
      canvas.drawCircle(Offset(x, y), 9 * w / 300,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
      canvas.drawCircle(
          Offset(x + 8 * w / 300, y - 4), 4 * w / 300,
          Paint()..color = const Color(0xFF3A2E22));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 1 — A cozy fireplace with bookshelves on both sides.
class HearthsidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _fillRect(canvas, size, const Color(0xFF4A2E1C));
    // bookshelves
    for (final side in [0.0, 0.72]) {
      final bx = w * side;
      canvas.drawRect(Rect.fromLTWH(bx, 0, w * 0.28, h),
          Paint()..color = const Color(0xFF3A2414));
      for (int shelf = 0; shelf < 4; shelf++) {
        final sy = h * (0.06 + shelf * 0.24);
        for (int b = 0; b < 7; b++) {
          final cols = [
            const Color(0xFF8A2E2E),
            const Color(0xFF2E5A8A),
            const Color(0xFF3E7A3A),
            const Color(0xFFB8862E),
            const Color(0xFF6E3A7A)
          ];
          canvas.drawRect(
              Rect.fromLTWH(bx + 6 + b * (w * 0.036), sy, w * 0.03, h * 0.16),
              Paint()..color = cols[(b + shelf) % cols.length]);
        }
        canvas.drawRect(Rect.fromLTWH(bx, sy + h * 0.16, w * 0.28, 8),
            Paint()..color = const Color(0xFF5A3A22));
      }
    }
    // fireplace
    final fx = w * 0.34, fw = w * 0.32;
    canvas.drawRect(
        Rect.fromLTWH(fx - 10, h * 0.28, fw + 20, h * 0.6),
        Paint()..color = const Color(0xFF6E6A66));
    canvas.drawRect(Rect.fromLTWH(fx, h * 0.36, fw, h * 0.52),
        Paint()..color = const Color(0xFF140A06));
    // flames
    _sunGlow(canvas, Offset(fx + fw / 2, h * 0.72), 44 * w / 300,
        const Color(0xFFFF9A3E));
    for (int i = 0; i < 5; i++) {
      final fxOff = fx + fw * (0.25 + i * 0.13);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(fxOff, h * (0.74 - (i % 3) * 0.04)),
              width: 16 * w / 300,
              height: 44 * h / 300),
          Paint()..color = const Color(0xFFFFD96A));
    }
    // logs
    canvas.drawRect(Rect.fromLTWH(fx + fw * 0.2, h * 0.8, fw * 0.6, 12),
        Paint()..color = const Color(0xFF3A2414));
    // mantel + rug
    canvas.drawRect(Rect.fromLTWH(fx - 16, h * 0.24, fw + 32, 16),
        Paint()..color = const Color(0xFF5A3A22));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.96),
            width: w * 0.7,
            height: h * 0.1),
        Paint()..color = const Color(0xFF8A2E2E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2 — Botanical print: flowers and leaves on parchment.
class BotanicalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(202);
    final w = size.width, h = size.height;
    _fillRect(canvas, size, const Color(0xFFF0E6CC));
    // subtle paper texture
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
          Offset(r.nextDouble() * w, r.nextDouble() * h), 1.5,
          Paint()..color = const Color(0xFFD9CDAE).withValues(alpha: 0.5));
    }
    // stems and flowers
    final flowers = [
      (0.25, 0.35, const Color(0xFFB84A5A), 26.0),
      (0.7, 0.28, const Color(0xFF8A4A9A), 30.0),
      (0.5, 0.62, const Color(0xFFD98A2E), 24.0),
      (0.82, 0.68, const Color(0xFF4A8A9A), 22.0),
      (0.18, 0.75, const Color(0xFFB84A5A), 20.0),
    ];
    final stem = Paint()
      ..color = const Color(0xFF3E6E38)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final f in flowers) {
      final cx = w * f.$1, cy = h * f.$2, r = f.$4 * w / 300;
      canvas.drawLine(Offset(cx, cy + r), Offset(cx, h * 0.95), stem);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - r * 0.8, cy + r * 1.6),
              width: r * 1.2,
              height: r * 0.5),
          Paint()..color = const Color(0xFF4E8E44));
      for (int p = 0; p < 6; p++) {
        final a = p * pi / 3;
        canvas.drawCircle(Offset(cx + cos(a) * r * 0.75, cy + sin(a) * r * 0.75),
            r * 0.5, Paint()..color = f.$3);
      }
      canvas.drawCircle(
          Offset(cx, cy), r * 0.45, Paint()..color = const Color(0xFFF3E8CB));
    }
    // frame
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFF3E5C43)..style = PaintingStyle.stroke..strokeWidth = 10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3 — An old cartographer's map with compass rose and sea monsters' coast.
class CartographerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(303);
    final w = size.width, h = size.height;
    _fillRect(canvas, size, const Color(0xFFE4D0A0));
    // aged blotches
    for (int i = 0; i < 14; i++) {
      canvas.drawCircle(
          Offset(r.nextDouble() * w, r.nextDouble() * h),
          10 + r.nextDouble() * 26,
          Paint()
            ..color = const Color(0xFFC8A86A).withValues(alpha: 0.25));
    }
    // continent blob
    final land = Path()
      ..moveTo(w * 0.15, h * 0.3)
      ..cubicTo(w * 0.35, h * 0.1, w * 0.6, h * 0.2, w * 0.7, h * 0.4)
      ..cubicTo(w * 0.78, h * 0.6, w * 0.6, h * 0.75, w * 0.4, h * 0.7)
      ..cubicTo(w * 0.2, h * 0.65, w * 0.05, h * 0.5, w * 0.15, h * 0.3)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF9AA85C));
    canvas.drawPath(
        land,
        Paint()
          ..color = const Color(0xFF6E3A22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // mountain range
    for (int i = 0; i < 5; i++) {
      final mx = w * (0.3 + i * 0.07);
      canvas.drawPath(
          Path()
            ..moveTo(mx - 18, h * 0.45)
            ..lineTo(mx, h * 0.32)
            ..lineTo(mx + 18, h * 0.45)
            ..close(),
          Paint()..color = const Color(0xFF6E5A4A));
    }
    // compass rose
    final cc = Offset(w * 0.8, h * 0.78);
    canvas.drawCircle(cc, 30, Paint()..color = const Color(0xFF3A2A1A));
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
          cc,
          cc + Offset(cos(a), sin(a)) * 26,
          Paint()
            ..color = const Color(0xFFE8C96A)
            ..strokeWidth = 3);
    }
    // dashed voyage route
    final route = Paint()
      ..color = const Color(0xFF8A2E2E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final rp = Path()
      ..moveTo(w * 0.1, h * 0.85)
      ..quadraticBezierTo(w * 0.4, h * 0.95, w * 0.75, h * 0.8);
    // manual dashes
    final metric = rp.computeMetrics().first;
    final routeLen = metric.length;
    for (double t = 0; t < 1; t += 0.08) {
      final tangent = metric.getTangentForOffset(routeLen * t);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3, Paint()..color = route.color);
      }
    }
    // border
    canvas.drawRect(
        Rect.fromLTWH(8, 8, w - 16, h - 16),
        Paint()
          ..color = const Color(0xFF6E3A22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4 — Oxford quadrangle: college courtyard at golden hour.
class QuadranglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF8FA8C8), Color(0xFFF0C880)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.5, h * 0.42), 46, const Color(0xFFFFE0A0));
    // college blocks
    final stone = Paint()..color = const Color(0xFFC8B088);
    final stoneDark = Paint()..color = const Color(0xFF8A7458);
    for (final b in [(0.0, 0.5), (0.62, 0.5)]) {
      final bx = w * b.$1, bw = w * b.$2;
      canvas.drawRect(Rect.fromLTWH(bx, h * 0.3, bw, h * 0.4), stone);
      canvas.drawRect(Rect.fromLTWH(bx, h * 0.3, bw, h * 0.06), stoneDark);
      for (int i = 0; i < 5; i++) {
        final wx = bx + bw * (0.08 + i * 0.2);
        canvas.drawRect(Rect.fromLTWH(wx, h * 0.42, w * 0.06, h * 0.14),
            Paint()..color = const Color(0xFF3A4A5A));
      }
      // spire
      final sx = bx + bw * 0.5;
      canvas.drawPath(
          Path()
            ..moveTo(sx - 14, h * 0.3)
            ..lineTo(sx, h * 0.08)
            ..lineTo(sx + 14, h * 0.3)
            ..close(),
          stoneDark);
    }
    // lawn
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
        Paint()..color = const Color(0xFF4E7A3E));
    // path
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.44, h * 0.7)
          ..lineTo(w * 0.56, h * 0.7)
          ..lineTo(w * 0.64, h)
          ..lineTo(w * 0.36, h)
          ..close(),
        Paint()..color = const Color(0xFFD9CDAE));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5 — Antiquarian vault: towering bookshelves under a skylight.
class VaultPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _fillRect(canvas, size, const Color(0xFF2A1C10));
    // skylight beam
    canvas.drawRect(
      Rect.fromLTWH(w * 0.3, 0, w * 0.4, h),
      Paint()..color = const Color(0xFFE8C96A).withValues(alpha: 0.12),
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.32, 0, w * 0.36, h * 0.06),
        Paint()..color = const Color(0xFFE8C96A));
    final cols = [
      const Color(0xFF8A2E2E),
      const Color(0xFF2E5A8A),
      const Color(0xFF3E7A3A),
      const Color(0xFFB8862E),
      const Color(0xFF6E3A7A),
      const Color(0xFF4A6A7A)
    ];
    for (int shelf = 0; shelf < 5; shelf++) {
      final sy = h * (0.1 + shelf * 0.18);
      // shelf board
      canvas.drawRect(Rect.fromLTWH(0, sy + h * 0.13, w, 7),
          Paint()..color = const Color(0xFF5A3A22));
      for (int b = 0; b < 16; b++) {
        final bw = w * 0.055;
        final bh = h * (0.10 + (b * 37 + shelf * 11) % 4 * 0.008);
        canvas.drawRect(Rect.fromLTWH(6 + b * (bw + 3), sy + h * 0.13 - bh,
            bw, bh), Paint()..color = cols[(b + shelf) % cols.length]);
      }
    }
    // ladder
    final lad = Paint()
      ..color = const Color(0xFF7A5230)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.78, 0), Offset(w * 0.7, h), lad);
    canvas.drawLine(Offset(w * 0.92, 0), Offset(w * 0.84, h), lad);
    for (int i = 0; i < 8; i++) {
      final y = h * (0.06 + i * 0.12);
      canvas.drawLine(Offset(w * (0.79 - i * 0.01), y),
          Offset(w * (0.93 - i * 0.01), y), lad);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6 — Moonlit orangery: glasshouse at night with glowing plants.
class OrangeryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF101C30), Color(0xFF1E3A4A)],
        ).createShader(Offset.zero & size),
    );
    // moon
    _sunGlow(canvas, Offset(w * 0.8, h * 0.16), 34, const Color(0xFFF0EAD8));
    // glasshouse frame
    final frame = Paint()
      ..color = const Color(0xFF0A0F18)
      ..strokeWidth = 8;
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.3, w * 0.84, h * 0.55),
        Paint()..color = const Color(0xFF2A4A3E).withValues(alpha: 0.55));
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.3, w * 0.84, h * 0.55),
        frame..style = PaintingStyle.stroke);
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(w * (0.08 + i * 0.168), h * 0.3),
          Offset(w * (0.08 + i * 0.168), h * 0.85), frame);
    }
    canvas.drawLine(Offset(w * 0.08, h * 0.57), Offset(w * 0.92, h * 0.57),
        frame);
    // glowing plants
    for (int i = 0; i < 6; i++) {
      final px = w * (0.14 + i * 0.13);
      final ph = h * (0.2 + (i * 53 % 5) * 0.03);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(px, h * 0.8 - ph / 2),
              width: 26,
              height: ph),
          Paint()..color = const Color(0xFF3E8E5A).withValues(alpha: 0.85));
      canvas.drawCircle(
          Offset(px, h * 0.8 - ph),
          6,
          Paint()..color = const Color(0xFFE8C96A).withValues(alpha: 0.9));
    }
    // floor
    canvas.drawRect(Rect.fromLTWH(0, h * 0.85, w, h * 0.15),
        Paint()..color = const Color(0xFF1A2E26));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7 — Harvest fair: bunting, stalls and a ferris silhouette at dusk.
class HarvestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF5A3A6E), Color(0xFFE89A5A), Color(0xFFF0C060)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.5, h * 0.52), 40, const Color(0xFFFFD98A));
    // ferris silhouette
    final fw = Paint()
      ..color = const Color(0xFF2A1E3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final fc = Offset(w * 0.72, h * 0.42);
    canvas.drawCircle(fc, 56, fw);
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(fc, fc + Offset(cos(a), sin(a)) * 56, fw);
    }
    canvas.drawLine(fc, Offset(fc.dx - 34, h * 0.8), fw);
    canvas.drawLine(fc, Offset(fc.dx + 34, h * 0.8), fw);
    // stalls
    for (int i = 0; i < 3; i++) {
      final sx = w * (0.06 + i * 0.22);
      canvas.drawRect(Rect.fromLTWH(sx, h * 0.62, w * 0.18, h * 0.2),
          Paint()..color = const Color(0xFF6E4A2E));
      canvas.drawPath(
          Path()
            ..moveTo(sx - 8, h * 0.62)
            ..lineTo(sx + w * 0.09, h * 0.5)
            ..lineTo(sx + w * 0.18 + 8, h * 0.62)
            ..close(),
          Paint()
            ..color = (i % 2 == 0
                ? const Color(0xFFB84A5A)
                : const Color(0xFFF3E8CB)));
    }
    // bunting
    final bun = Paint()
      ..color = const Color(0xFF2A1E3A)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, h * 0.12), Offset(w, h * 0.2), bun);
    final bcols = [
      const Color(0xFFB84A5A),
      const Color(0xFFE8A94E),
      const Color(0xFF4E8E5A),
      const Color(0xFF4A6A9A)
    ];
    for (int i = 0; i < 12; i++) {
      final x = w * (i + 0.5) / 12;
      final y = h * (0.12 + (x / w) * 0.08) + 14;
      canvas.drawPath(
          Path()
            ..moveTo(x - 7, y - 12)
            ..lineTo(x + 7, y - 12)
            ..lineTo(x, y)
            ..close(),
          Paint()..color = bcols[i % bcols.length]);
    }
    // ground
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
        Paint()..color = const Color(0xFF3E5A34));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
