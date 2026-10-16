import 'dart:math';
import 'package:flutter/material.dart';

/// Built-in picture folio: original painted scenes for the puzzles.
/// Warm, readable at piece scale, no trademarked or AI-looking content,
/// no location words in any name.
///
/// Free: 0 Meadow Dawn, 1 Hearthside Library, 2 Botanical Folio,
/// 3 Cartographer's Study, 8 Tidepool Morning, 9 Summit Silence,
/// 10 Lantern Bazaar, 11 Red Barn Pasture, 12 Nebula Drift,
/// 13 Coral Garden, 14 Dune Caravan, 15 Fern Hollow.
/// PRO: 4 Oxford Quadrangle, 5 Antiquarian Vault, 6 Moonlit Orangery,
/// 7 Harvest Fair, 16 Ember Forge, 17 Clockwork Attic,
/// 18 Starlight Observatory, 19 Mushroom Grotto, 20 Kite Festival,
/// 21 Snowbound Cabin.
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
    'Tidepool Morning',
    'Summit Silence',
    'Lantern Bazaar',
    'Red Barn Pasture',
    'Nebula Drift',
    'Coral Garden',
    'Dune Caravan',
    'Fern Hollow',
    'Ember Forge',
    'Clockwork Attic',
    'Starlight Observatory',
    'Mushroom Grotto',
    'Kite Festival',
    'Snowbound Cabin',
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
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    true,
    true,
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
        8 => TidepoolPainter(),
        9 => SummitPainter(),
        10 => BazaarPainter(),
        11 => BarnPainter(),
        12 => NebulaPainter(),
        13 => CoralPainter(),
        14 => DunePainter(),
        15 => FernPainter(),
        16 => ForgePainter(),
        17 => ClockworkPainter(),
        18 => ObservatoryPainter(),
        19 => GrottoPainter(),
        20 => KitePainter(),
        21 => CabinPainter(),
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

/// 8 — Beach at low tide: sun, surf band, wet sand, shells and starfish.
class TidepoolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(808);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF9FD0E8), Color(0xFFD8ECF2)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.78, h * 0.18), 44, const Color(0xFFFFE9A8));
    // surf band
    canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.18),
        Paint()..color = const Color(0xFF3E9AB0));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.08),
        Paint()..color = const Color(0xFF6EC2D4));
    final foam = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 9; i++) {
      final x = w * (0.04 + i * 0.11);
      canvas.drawLine(Offset(x, h * 0.585), Offset(x + 26, h * 0.575), foam);
    }
    // wet sand
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.6, w, h * 0.4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFE8D29A), Color(0xFFD4B878)],
        ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4)),
    );
    // shells
    for (int i = 0; i < 5; i++) {
      final sx = w * (0.12 + i * 0.19) + r.nextDouble() * 14;
      final sy = h * (0.68 + r.nextDouble() * 0.2);
      canvas.drawArc(Rect.fromCenter(center: Offset(sx, sy), width: 26, height: 18),
          pi, 0, false,
          Paint()
            ..color = const Color(0xFFF3E4C8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
    }
    // starfish
    final star = Paint()
      ..color = const Color(0xFFE07840)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final sc = Offset(w * 0.7, h * 0.8);
    for (int i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      canvas.drawLine(sc, sc + Offset(cos(a), sin(a)) * 20, star);
    }
    canvas.drawCircle(sc, 6, Paint()..color = const Color(0xFFE07840));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 9 — Snow-capped peaks above a pine valley.
class SummitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF7FA8D0), Color(0xFFE8F0F2)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.2, h * 0.2), 40, const Color(0xFFFFF2C8));
    // peaks
    final peaks = [(0.15, 0.52, 0.34), (0.5, 0.4, 0.44), (0.82, 0.55, 0.32)];
    for (final pk in peaks) {
      final cx = w * pk.$1, base = h * pk.$2, hw = w * pk.$3 / 2;
      canvas.drawPath(
          Path()
            ..moveTo(cx - hw, h * 0.78)
            ..lineTo(cx, base)
            ..lineTo(cx + hw, h * 0.78)
            ..close(),
          Paint()..color = const Color(0xFF5A6E8A));
      // snow cap
      final capH = (h * 0.78 - base) * 0.38;
      canvas.drawPath(
          Path()
            ..moveTo(cx - hw * 0.38, base + capH)
            ..lineTo(cx, base)
            ..lineTo(cx + hw * 0.38, base + capH)
            ..lineTo(cx + hw * 0.18, base + capH * 1.35)
            ..lineTo(cx, base + capH * 1.1)
            ..lineTo(cx - hw * 0.18, base + capH * 1.35)
            ..close(),
          Paint()..color = Colors.white);
    }
    // valley
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
        Paint()..color = const Color(0xFF3E6E44));
    // pines
    for (int i = 0; i < 7; i++) {
      final px = w * (0.06 + i * 0.14);
      final ph = h * 0.1;
      final py = h * 0.86;
      canvas.drawRect(Rect.fromLTWH(px - 3, py, 6, 12),
          Paint()..color = const Color(0xFF4A3220));
      for (int t = 0; t < 3; t++) {
        canvas.drawPath(
            Path()
              ..moveTo(px - 16 + t * 3, py - t * 10)
              ..lineTo(px, py - ph - t * 10)
              ..lineTo(px + 16 - t * 3, py - t * 10)
              ..close(),
            Paint()..color = const Color(0xFF2E5A34));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10 — Night market strung with glowing paper lanterns.
class BazaarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF141433), Color(0xFF2E1E4E)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.85, h * 0.14), 30, const Color(0xFFF0EAD8));
    // lantern strings
    final wire = Paint()
      ..color = const Color(0xFF0A0A18)
      ..strokeWidth = 3;
    final cols = [
      const Color(0xFFE84A4A),
      const Color(0xFFE8A94E),
      const Color(0xFFF3E8CB),
      const Color(0xFF4ED8A0)
    ];
    for (final sy in [0.22, 0.38]) {
      canvas.drawLine(Offset(0, h * sy), Offset(w, h * (sy + 0.08)), wire);
      for (int i = 0; i < 8; i++) {
        final x = w * (0.05 + i * 0.125);
        final y = h * (sy + (x / w) * 0.08) + 10;
        final c = cols[(i + (sy * 100).round()) % cols.length];
        canvas.drawCircle(Offset(x, y + 10), 13,
            Paint()..color = c.withValues(alpha: 0.3));
        canvas.drawCircle(Offset(x, y + 10), 9, Paint()..color = c);
        canvas.drawRect(Rect.fromLTWH(x - 4, y - 2, 8, 5),
            Paint()..color = const Color(0xFF5A3A22));
      }
    }
    // stall silhouettes
    for (int i = 0; i < 3; i++) {
      final sx = w * (0.08 + i * 0.3);
      canvas.drawRect(Rect.fromLTWH(sx, h * 0.66, w * 0.24, h * 0.22),
          Paint()..color = const Color(0xFF1E1428));
      for (int s = 0; s < 4; s++) {
        canvas.drawRect(
            Rect.fromLTWH(sx + s * w * 0.06, h * 0.58, w * 0.06, h * 0.08),
            Paint()
              ..color = (s % 2 == 0
                  ? const Color(0xFFB84A5A)
                  : const Color(0xFFF3E8CB))
                  .withValues(alpha: 0.9));
      }
      // warm window glow
      canvas.drawRect(Rect.fromLTWH(sx + w * 0.05, h * 0.72, w * 0.14, h * 0.08),
          Paint()..color = const Color(0xFFE8A94E).withValues(alpha: 0.75));
    }
    canvas.drawRect(Rect.fromLTWH(0, h * 0.88, w, h * 0.12),
        Paint()..color = const Color(0xFF100C1C));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 11 — Red barn, silo and pasture fence under a wide sky.
class BarnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF8FC0E0), Color(0xFFD8E8E8)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.16, h * 0.18), 42, const Color(0xFFFFE9A8));
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (final p in [(0.55, 0.14), (0.82, 0.26)]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w * p.$1, h * p.$2), width: 80, height: 22),
          cloud);
    }
    // pasture
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
        Paint()..color = const Color(0xFF6EA054));
    // silo
    canvas.drawRect(Rect.fromLTWH(w * 0.68, h * 0.34, w * 0.12, h * 0.3),
        Paint()..color = const Color(0xFF9AA0A8));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.74, h * 0.34), width: w * 0.12, height: 26),
        Paint()..color = const Color(0xFF7A8088));
    // barn
    final bx = w * 0.16, bw = w * 0.4;
    canvas.drawRect(Rect.fromLTWH(bx, h * 0.44, bw, h * 0.24),
        Paint()..color = const Color(0xFFA83A32));
    canvas.drawPath(
        Path()
          ..moveTo(bx - 10, h * 0.44)
          ..lineTo(bx + bw * 0.5, h * 0.28)
          ..lineTo(bx + bw + 10, h * 0.44)
          ..close(),
        Paint()..color = const Color(0xFF7A2822));
    // door with cross brace
    canvas.drawRect(Rect.fromLTWH(bx + bw * 0.36, h * 0.5, bw * 0.28, h * 0.18),
        Paint()..color = const Color(0xFFF3E8CB));
    final brace = Paint()
      ..color = const Color(0xFFA83A32)
      ..strokeWidth = 5;
    canvas.drawLine(Offset(bx + bw * 0.36, h * 0.5),
        Offset(bx + bw * 0.64, h * 0.68), brace);
    canvas.drawLine(Offset(bx + bw * 0.64, h * 0.5),
        Offset(bx + bw * 0.36, h * 0.68), brace);
    // hay bales
    for (final hb in [(0.1, 0.8), (0.88, 0.84)]) {
      canvas.drawCircle(Offset(w * hb.$1, h * hb.$2), 20,
          Paint()..color = const Color(0xFFE0B84E));
      canvas.drawCircle(Offset(w * hb.$1, h * hb.$2), 20,
          Paint()
            ..color = const Color(0xFFB8862E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    // fence
    final fence = Paint()
      ..color = const Color(0xFF6E4A2E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final x = w * (0.02 + i * 0.13);
      canvas.drawLine(Offset(x, h * 0.72), Offset(x, h * 0.9), fence);
    }
    canvas.drawLine(Offset(0, h * 0.76), Offset(w, h * 0.74), fence);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 12 — Deep space: ringed planet, nebula veils and a comet.
class NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(1212);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF0A0A20), Color(0xFF1E1440)],
        ).createShader(Offset.zero & size),
    );
    // nebula veils
    final veils = [
      (0.25, 0.3, 90.0, const Color(0xFF6E3AA0)),
      (0.75, 0.65, 110.0, const Color(0xFF2E6E9A)),
      (0.55, 0.15, 70.0, const Color(0xFF9A3A6E)),
    ];
    for (final v in veils) {
      canvas.drawCircle(Offset(w * v.$1, h * v.$2), v.$3,
          Paint()..color = v.$4.withValues(alpha: 0.28));
      canvas.drawCircle(Offset(w * v.$1, h * v.$2), v.$3 * 0.6,
          Paint()..color = v.$4.withValues(alpha: 0.22));
    }
    // stars
    for (int i = 0; i < 90; i++) {
      canvas.drawCircle(
          Offset(r.nextDouble() * w, r.nextDouble() * h),
          0.8 + r.nextDouble() * 1.8,
          Paint()..color = Colors.white.withValues(alpha: 0.5 + r.nextDouble() * 0.5));
    }
    // ringed planet
    final pc = Offset(w * 0.62, h * 0.58);
    canvas.drawOval(
        Rect.fromCenter(center: pc, width: 150, height: 44),
        Paint()
          ..color = const Color(0xFFE8C96A).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    canvas.drawCircle(pc, 44,
        Paint()
          ..shader = RadialGradient(colors: const [
            Color(0xFFF0D890),
            Color(0xFFB87830)
          ]).createShader(Rect.fromCircle(center: pc, radius: 44)));
    canvas.drawOval(
        Rect.fromCenter(center: pc, width: 150, height: 44),
        Paint()
          ..color = const Color(0xFFF3E4B8).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // comet
    final cc = Offset(w * 0.2, h * 0.22);
    canvas.drawLine(
        cc, cc + const Offset(-70, -44),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    _sunGlow(canvas, cc, 14, Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 13 — Underwater coral garden with fish and light rays.
class CoralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(1313);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF3E9AC0), Color(0xFF144A6E)],
        ).createShader(Offset.zero & size),
    );
    // light rays
    for (int i = 0; i < 4; i++) {
      final x = w * (0.12 + i * 0.24);
      canvas.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + 44, 0)
            ..lineTo(x - 30, h * 0.7)
            ..lineTo(x - 74, h * 0.7)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: 0.08));
    }
    // sand
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 1.02), width: w * 1.3, height: h * 0.3),
        Paint()..color = const Color(0xFFE0CE9A));
    // corals
    final branch = Paint()..strokeCap = StrokeCap.round;
    void coral(double x, double y, Color c, double s) {
      branch.color = c;
      branch.strokeWidth = 10 * s;
      canvas.drawLine(Offset(x, y), Offset(x, y - 46 * s), branch);
      branch.strokeWidth = 7 * s;
      canvas.drawLine(Offset(x, y - 30 * s), Offset(x - 22 * s, y - 58 * s), branch);
      canvas.drawLine(Offset(x, y - 36 * s), Offset(x + 24 * s, y - 62 * s), branch);
      canvas.drawCircle(Offset(x - 22 * s, y - 58 * s), 7 * s, Paint()..color = c);
      canvas.drawCircle(Offset(x + 24 * s, y - 62 * s), 7 * s, Paint()..color = c);
      canvas.drawCircle(Offset(x, y - 46 * s), 8 * s, Paint()..color = c);
    }

    coral(w * 0.18, h * 0.9, const Color(0xFFE86A8A), 1.1);
    coral(w * 0.42, h * 0.92, const Color(0xFFE89A4E), 0.9);
    coral(w * 0.68, h * 0.9, const Color(0xFF9A5AC0), 1.2);
    coral(w * 0.88, h * 0.92, const Color(0xFFE86A8A), 0.8);
    // fish
    final fishes = [
      (0.3, 0.3, const Color(0xFFE8C94E), 1.0),
      (0.62, 0.42, const Color(0xFF4ED8A0), 0.8),
      (0.78, 0.24, const Color(0xFFE86A5A), 0.9),
    ];
    for (final f in fishes) {
      final fx = w * f.$1, fy = h * f.$2, fs = f.$4;
      canvas.drawOval(Rect.fromCenter(center: Offset(fx, fy), width: 44 * fs, height: 22 * fs),
          Paint()..color = f.$3);
      canvas.drawPath(
          Path()
            ..moveTo(fx - 20 * fs, fy)
            ..lineTo(fx - 34 * fs, fy - 12 * fs)
            ..lineTo(fx - 34 * fs, fy + 12 * fs)
            ..close(),
          Paint()..color = f.$3);
      canvas.drawCircle(Offset(fx + 10 * fs, fy - 4 * fs), 2.5, Paint()..color = Colors.black87);
    }
    // bubbles
    for (int i = 0; i < 14; i++) {
      canvas.drawCircle(
          Offset(r.nextDouble() * w, r.nextDouble() * h * 0.7),
          2 + r.nextDouble() * 4,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 14 — Desert dunes with a tent and a palm oasis.
class DunePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFF2D89A), Color(0xFFE8A85E)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.5, h * 0.3), 52, const Color(0xFFFFE0A0));
    // birds
    final bird = Paint()
      ..color = const Color(0xFF5A3A22)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final b in [(0.2, 0.18), (0.3, 0.24), (0.78, 0.14)]) {
      final bx = w * b.$1, by = h * b.$2;
      canvas.drawPath(
          Path()
            ..moveTo(bx - 10, by)
            ..quadraticBezierTo(bx - 3, by - 8, bx, by)
            ..quadraticBezierTo(bx + 3, by - 8, bx + 10, by),
          bird);
    }
    // dune layers
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.62)
          ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.6, h * 0.62)
          ..quadraticBezierTo(w * 0.85, h * 0.7, w, h * 0.6)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFFE0B878));
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.78)
          ..quadraticBezierTo(w * 0.4, h * 0.66, w * 0.7, h * 0.8)
          ..quadraticBezierTo(w * 0.9, h * 0.86, w, h * 0.78)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFFD4A058));
    // tent
    final tx = w * 0.62;
    canvas.drawPath(
        Path()
          ..moveTo(tx - 52, h * 0.86)
          ..lineTo(tx, h * 0.6)
          ..lineTo(tx + 52, h * 0.86)
          ..close(),
        Paint()..color = const Color(0xFFB84A3E));
    canvas.drawPath(
        Path()
          ..moveTo(tx - 18, h * 0.86)
          ..lineTo(tx, h * 0.6)
          ..lineTo(tx + 18, h * 0.86)
          ..close(),
        Paint()..color = const Color(0xFFF3E8CB));
    canvas.drawLine(Offset(tx, h * 0.6), Offset(tx, h * 0.52),
        Paint()..color = const Color(0xFF5A3A22)..strokeWidth = 5);
    // oasis pool + palms
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.2, h * 0.88), width: 110, height: 30),
        Paint()..color = const Color(0xFF4E9AC0));
    for (final px in [0.13, 0.28]) {
      final x = w * px;
      canvas.drawLine(Offset(x, h * 0.88), Offset(x + 8, h * 0.66),
          Paint()..color = const Color(0xFF6E4A2E)..strokeWidth = 7..strokeCap = StrokeCap.round);
      for (int i = 0; i < 5; i++) {
        final a = pi * (0.15 + i * 0.175);
        canvas.drawLine(
            Offset(x + 8, h * 0.66),
            Offset(x + 8 + cos(a) * 30, h * 0.66 - sin(a) * 22),
            Paint()..color = const Color(0xFF3E7A3A)..strokeWidth = 6..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 15 — Deep forest hollow: trunks, fireflies and toadstools.
class FernPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(1515);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF1E3A24), Color(0xFF0E1E14)],
        ).createShader(Offset.zero & size),
    );
    // canopy blobs
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
          Offset(r.nextDouble() * w, r.nextDouble() * h * 0.3),
          30 + r.nextDouble() * 30,
          Paint()..color = const Color(0xFF2E5A34).withValues(alpha: 0.9));
    }
    // trunks
    for (final tx in [0.12, 0.38, 0.64, 0.9]) {
      final tw = 18 + (tx * 40) % 14;
      canvas.drawRect(Rect.fromLTWH(w * tx - tw / 2, h * 0.1, tw, h * 0.75),
          Paint()..color = const Color(0xFF3A2818));
      canvas.drawRect(Rect.fromLTWH(w * tx - tw / 2, h * 0.1, 5, h * 0.75),
          Paint()..color = const Color(0xFF5A4028).withValues(alpha: 0.7));
    }
    // forest floor
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
        Paint()..color = const Color(0xFF142A18));
    // fireflies
    for (int i = 0; i < 16; i++) {
      final fx = r.nextDouble() * w, fy = h * 0.25 + r.nextDouble() * h * 0.5;
      canvas.drawCircle(Offset(fx, fy), 7,
          Paint()..color = const Color(0xFFE8D86A).withValues(alpha: 0.25));
      canvas.drawCircle(Offset(fx, fy), 3,
          Paint()..color = const Color(0xFFF3E86A));
    }
    // toadstools
    for (final m in [(0.24, 1.0), (0.55, 0.75), (0.8, 1.15)]) {
      final mx = w * m.$1, ms = m.$2, my = h * 0.94;
      canvas.drawRect(Rect.fromLTWH(mx - 5 * ms, my - 26 * ms, 10 * ms, 26 * ms),
          Paint()..color = const Color(0xFFF3E8CB));
      canvas.drawPath(
          Path()
            ..moveTo(mx - 22 * ms, my - 22 * ms)
            ..quadraticBezierTo(mx, my - 52 * ms, mx + 22 * ms, my - 22 * ms)
            ..close(),
          Paint()..color = const Color(0xFFC04A3E));
      canvas.drawCircle(Offset(mx - 8 * ms, my - 32 * ms), 3.5 * ms, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(mx + 7 * ms, my - 28 * ms), 2.8 * ms, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 16 — Blacksmith's forge: brick arch, anvil and rising sparks.
class ForgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(1616);
    final w = size.width, h = size.height;
    _fillRect(canvas, size, const Color(0xFF1A100C));
    // forge arch
    final fx = w * 0.5, fw = w * 0.44;
    canvas.drawRect(Rect.fromLTWH(fx - fw / 2 - 14, h * 0.3, fw + 28, h * 0.5),
        Paint()..color = const Color(0xFF4A3226));
    canvas.drawPath(
        Path()
          ..moveTo(fx - fw / 2, h * 0.8)
          ..lineTo(fx - fw / 2, h * 0.48)
          ..quadraticBezierTo(fx, h * 0.3, fx + fw / 2, h * 0.48)
          ..lineTo(fx + fw / 2, h * 0.8)
          ..close(),
        Paint()..color = const Color(0xFF140C08));
    // fire glow
    _sunGlow(canvas, Offset(fx, h * 0.68), 60, const Color(0xFFFF8A2E));
    for (int i = 0; i < 6; i++) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(fx + (r.nextDouble() - 0.5) * fw * 0.7, h * (0.66 + r.nextDouble() * 0.1)),
              width: 20,
              height: 34),
          Paint()..color = const Color(0xFFFFD96A).withValues(alpha: 0.9));
    }
    // coals
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
          Offset(fx + (r.nextDouble() - 0.5) * fw * 0.7, h * 0.78),
          5 + r.nextDouble() * 5,
          Paint()..color = const Color(0xFF8A3A1E));
    }
    // anvil silhouette
    final ax = w * 0.5, ay = h * 0.88;
    canvas.drawPath(
        Path()
          ..moveTo(ax - 56, ay - 26)
          ..lineTo(ax + 40, ay - 26)
          ..lineTo(ax + 62, ay - 36)
          ..lineTo(ax + 62, ay - 16)
          ..lineTo(ax + 30, ay - 8)
          ..lineTo(ax + 14, ay)
          ..lineTo(ax - 14, ay)
          ..lineTo(ax - 30, ay - 8)
          ..close(),
        Paint()..color = const Color(0xFF2A2E36));
    canvas.drawRect(Rect.fromLTWH(ax - 12, ay, 24, 26),
        Paint()..color = const Color(0xFF2A2E36));
    // sparks
    for (int i = 0; i < 18; i++) {
      canvas.drawCircle(
          Offset(fx + (r.nextDouble() - 0.5) * w * 0.5, h * (0.1 + r.nextDouble() * 0.5)),
          1.5 + r.nextDouble() * 2,
          Paint()..color = const Color(0xFFFFB84E).withValues(alpha: 0.8));
    }
    // hanging horseshoe
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.12, h * 0.24), width: 44, height: 44),
        -pi * 0.75, pi * 1.5, false,
        Paint()
          ..color = const Color(0xFF6E7684)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 17 — Attic of brass gears and a great clock face.
class ClockworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _fillRect(canvas, size, const Color(0xFF3A2A1C));
    // wood planks
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(Offset(0, h * (0.08 + i * 0.16)), Offset(w, h * (0.08 + i * 0.16)),
          Paint()..color = const Color(0xFF2A1E14)..strokeWidth = 3);
    }
    void gear(Offset c, double rad, Color metal) {
      // teeth
      for (int i = 0; i < 12; i++) {
        final a = i * pi / 6;
        final p1 = c + Offset(cos(a), sin(a)) * (rad - 6);
        final p2 = c + Offset(cos(a), sin(a)) * (rad + 8);
        canvas.drawLine(p1, p2,
            Paint()..color = metal..strokeWidth = 10..strokeCap = StrokeCap.round);
      }
      canvas.drawCircle(c, rad, Paint()..color = metal);
      canvas.drawCircle(c, rad * 0.62, Paint()..color = const Color(0xFF3A2A1C));
      for (int i = 0; i < 5; i++) {
        final a = i * 2 * pi / 5;
        canvas.drawLine(c, c + Offset(cos(a), sin(a)) * rad * 0.62,
            Paint()..color = metal..strokeWidth = 10);
      }
      canvas.drawCircle(c, rad * 0.18, Paint()..color = metal);
    }

    gear(Offset(w * 0.28, h * 0.34), 62, const Color(0xFFB8862E));
    gear(Offset(w * 0.72, h * 0.42), 84, const Color(0xFF8A6A3A));
    gear(Offset(w * 0.42, h * 0.78), 52, const Color(0xFFD4A84E));
    // clock face
    final cc = Offset(w * 0.74, h * 0.42);
    canvas.drawCircle(cc, 52, Paint()..color = const Color(0xFFF3E8CB));
    canvas.drawCircle(cc, 52,
        Paint()..color = const Color(0xFF3A2A1C)..style = PaintingStyle.stroke..strokeWidth = 5);
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawLine(cc + Offset(cos(a), sin(a)) * 44, cc + Offset(cos(a), sin(a)) * 50,
          Paint()..color = const Color(0xFF3A2A1C)..strokeWidth = 3);
    }
    canvas.drawLine(cc, cc + const Offset(0, -30),
        Paint()..color = const Color(0xFF3A2A1C)..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawLine(cc, cc + const Offset(22, 8),
        Paint()..color = const Color(0xFF3A2A1C)..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawCircle(cc, 5, Paint()..color = const Color(0xFF8A2E2E));
    // lamp glow corner
    _sunGlow(canvas, Offset(w * 0.08, h * 0.9), 40, const Color(0xFFE8A94E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 18 — Observatory dome under a starry sky.
class ObservatoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(1818);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF0E1830), Color(0xFF24344E)],
        ).createShader(Offset.zero & size),
    );
    for (int i = 0; i < 70; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h * 0.7),
          0.8 + r.nextDouble() * 1.6, Paint()..color = Colors.white.withValues(alpha: 0.7));
    }
    _sunGlow(canvas, Offset(w * 0.16, h * 0.16), 34, const Color(0xFFF0EAD8));
    // hill
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.72)
          ..quadraticBezierTo(w * 0.5, h * 0.6, w, h * 0.74)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFF1A2A1E));
    // dome
    final dx = w * 0.5, dr = w * 0.26, base = h * 0.86;
    canvas.drawRect(Rect.fromLTWH(dx - dr, base - 40, dr * 2, 40),
        Paint()..color = const Color(0xFF8A94A0));
    canvas.drawPath(
        Path()
          ..moveTo(dx - dr, base - 40)
          ..arcTo(Rect.fromCenter(center: Offset(dx, base - 40), width: dr * 2, height: dr * 2), pi, -pi, false)
          ..close(),
        Paint()..color = const Color(0xFFAAB4C0));
    // slit + telescope
    canvas.drawRect(Rect.fromLTWH(dx - 16, base - 40 - dr + 10, 32, dr - 10),
        Paint()..color = const Color(0xFF0E1830));
    canvas.drawLine(Offset(dx, base - 40 - dr + 26), Offset(dx + 44, base - 40 - dr - 24),
        Paint()..color = const Color(0xFF3A4250)..strokeWidth = 14..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(dx, base - 40 - dr + 26), Offset(dx + 44, base - 40 - dr - 24),
        Paint()..color = const Color(0xFF6E7684)..strokeWidth = 8..strokeCap = StrokeCap.round);
    // windows
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(dx - dr + 18 + i * 34, base - 30, 20, 20),
          Paint()..color = const Color(0xFFE8C96A).withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 19 — Cave grotto with glowing mushrooms around a still pool.
class GrottoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(1919);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF141428), Color(0xFF0A0A18)],
        ).createShader(Offset.zero & size),
    );
    // cave walls
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(side < 0 ? 0 : w, 0)
            ..quadraticBezierTo(w * (0.5 + side * 0.42), h * 0.3, w * (0.5 + side * 0.36), h * 0.7)
            ..quadraticBezierTo(w * (0.5 + side * 0.3), h * 0.9, side < 0 ? 0 : w, h)
            ..lineTo(side < 0 ? 0 : w, 0)
            ..close(),
          Paint()..color = const Color(0xFF1E1E38));
    }
    // stalactites
    for (int i = 0; i < 6; i++) {
      final sx = w * (0.1 + i * 0.16);
      canvas.drawPath(
          Path()
            ..moveTo(sx - 14, 0)
            ..lineTo(sx + 14, 0)
            ..lineTo(sx, 40 + (i * 37 % 30))
            ..close(),
          Paint()..color = const Color(0xFF23233E));
    }
    // glowing mushrooms
    final shrooms = [
      (0.3, 0.78, const Color(0xFF4ED8E8), 1.1),
      (0.52, 0.84, const Color(0xFFE84ED8), 0.9),
      (0.7, 0.76, const Color(0xFF4ED8E8), 1.3),
      (0.42, 0.7, const Color(0xFF9A7AE8), 0.7),
    ];
    for (final s in shrooms) {
      final mx = w * s.$1, my = h * s.$2, ms = s.$4, mc = s.$3;
      _sunGlow(canvas, Offset(mx, my - 30 * ms), 26 * ms, mc);
      canvas.drawRect(Rect.fromLTWH(mx - 5 * ms, my - 28 * ms, 10 * ms, 30 * ms),
          Paint()..color = const Color(0xFFD8D0C0));
      canvas.drawPath(
          Path()
            ..moveTo(mx - 20 * ms, my - 24 * ms)
            ..quadraticBezierTo(mx, my - 52 * ms, mx + 20 * ms, my - 24 * ms)
            ..close(),
          Paint()..color = mc);
    }
    // pool with reflections
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.94), width: w * 0.7, height: h * 0.14),
        Paint()..color = const Color(0xFF1E3A5E));
    for (final s in shrooms) {
      canvas.drawRect(Rect.fromLTWH(w * s.$1 - 3, h * 0.9, 6, 26),
          Paint()..color = s.$3.withValues(alpha: 0.4));
    }
    // drifting spores
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h),
          1.5 + r.nextDouble() * 2,
          Paint()..color = const Color(0xFF9A7AE8).withValues(alpha: 0.6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 20 — Bright sky crowded with kites over a green hill.
class KitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF6EB8E8), Color(0xFFCFEAF2)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.82, h * 0.16), 40, const Color(0xFFFFF2C8));
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final p in [(0.2, 0.2), (0.62, 0.32)]) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(w * p.$1, h * p.$2), width: 96, height: 26), cloud);
    }
    // hill
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.82)
          ..quadraticBezierTo(w * 0.5, h * 0.72, w, h * 0.84)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFF5E9A4E));
    // kites
    final kites = [
      (0.24, 0.3, const Color(0xFFE84A5A), 1.0),
      (0.52, 0.22, const Color(0xFF4E9AE8), 1.2),
      (0.76, 0.38, const Color(0xFFE8A94E), 0.9),
      (0.4, 0.52, const Color(0xFF4ED8A0), 0.8),
    ];
    for (final k in kites) {
      final kx = w * k.$1, ky = h * k.$2, kc = k.$3, ks = k.$4;
      // string down to the hill
      canvas.drawLine(Offset(kx, ky + 26 * ks), Offset(kx - 30 * ks, h * 0.95),
          Paint()..color = const Color(0xFF5A4A3A)..strokeWidth = 2);
      // diamond sail
      canvas.drawPath(
          Path()
            ..moveTo(kx, ky - 26 * ks)
            ..lineTo(kx + 20 * ks, ky)
            ..lineTo(kx, ky + 26 * ks)
            ..lineTo(kx - 20 * ks, ky)
            ..close(),
          Paint()..color = kc);
      canvas.drawLine(Offset(kx, ky - 26 * ks), Offset(kx, ky + 26 * ks),
          Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 2);
      // tail with bows
      var tx = kx, ty = ky + 26 * ks;
      for (int i = 0; i < 3; i++) {
        final nx = tx + (i % 2 == 0 ? 10 : -10) * ks;
        final ny = ty + 18 * ks;
        canvas.drawLine(Offset(tx, ty), Offset(nx, ny),
            Paint()..color = const Color(0xFF5A4A3A)..strokeWidth = 2);
        canvas.drawCircle(Offset(nx, ny), 4 * ks, Paint()..color = kc);
        tx = nx;
        ty = ny;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 21 — Snowbound cabin with lit windows, smoke and pines.
class CabinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(2121);
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF8FA8D0), Color(0xFFD8DCE8)],
        ).createShader(Offset.zero & size),
    );
    _sunGlow(canvas, Offset(w * 0.84, h * 0.16), 32, const Color(0xFFF0EAD8));
    // snow ground
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.72)
          ..quadraticBezierTo(w * 0.5, h * 0.66, w, h * 0.74)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFFF0F4FA));
    // pines with snow
    for (final pt in [(0.1, 1.0), (0.88, 1.15), (0.76, 0.8)]) {
      final px = w * pt.$1, ps = pt.$2, py = h * 0.78;
      canvas.drawRect(Rect.fromLTWH(px - 4, py - 6, 8, 14),
          Paint()..color = const Color(0xFF4A3220));
      for (int t = 0; t < 3; t++) {
        canvas.drawPath(
            Path()
              ..moveTo(px - 24 * ps + t * 4, py - t * 16 * ps)
              ..lineTo(px, py - 40 * ps - t * 16 * ps)
              ..lineTo(px + 24 * ps - t * 4, py - t * 16 * ps)
              ..close(),
            Paint()..color = const Color(0xFF2E5A3E));
        canvas.drawLine(Offset(px - 20 * ps + t * 4, py - 6 - t * 16 * ps),
            Offset(px + 20 * ps - t * 4, py - 6 - t * 16 * ps),
            Paint()..color = Colors.white..strokeWidth = 4..strokeCap = StrokeCap.round);
      }
    }
    // cabin
    final cx = w * 0.5, cw = w * 0.4;
    canvas.drawRect(Rect.fromLTWH(cx - cw / 2, h * 0.5, cw, h * 0.26),
        Paint()..color = const Color(0xFF6E4A2E));
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(cx - cw / 2, h * (0.55 + i * 0.06)),
          Offset(cx + cw / 2, h * (0.55 + i * 0.06)),
          Paint()..color = const Color(0xFF5A3A22)..strokeWidth = 2);
    }
    // snow roof
    canvas.drawPath(
        Path()
          ..moveTo(cx - cw / 2 - 14, h * 0.5)
          ..lineTo(cx, h * 0.34)
          ..lineTo(cx + cw / 2 + 14, h * 0.5)
          ..lineTo(cx + cw / 2 + 6, h * 0.5)
          ..lineTo(cx, h * 0.4)
          ..lineTo(cx - cw / 2 - 6, h * 0.5)
          ..close(),
        Paint()..color = Colors.white);
    // chimney + smoke
    canvas.drawRect(Rect.fromLTWH(cx + cw * 0.24, h * 0.36, 22, 44),
        Paint()..color = const Color(0xFF8A6A4A));
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
          Offset(cx + cw * 0.24 + 11 + (i % 2) * 10, h * 0.32 - i * 22),
          (10 - i).toDouble(),
          Paint()..color = Colors.white.withValues(alpha: 0.55 - i * 0.1));
    }
    // lit windows + door
    for (final wx in [-0.28, 0.12]) {
      canvas.drawRect(Rect.fromLTWH(cx + cw * wx, h * 0.58, 30, 30),
          Paint()..color = const Color(0xFFFFD96A));
      canvas.drawRect(Rect.fromLTWH(cx + cw * wx, h * 0.58, 30, 30),
          Paint()..color = const Color(0xFF5A3A22)..style = PaintingStyle.stroke..strokeWidth = 4);
      canvas.drawLine(Offset(cx + cw * wx + 15, h * 0.58), Offset(cx + cw * wx + 15, h * 0.58 + 30),
          Paint()..color = const Color(0xFF5A3A22)..strokeWidth = 3);
    }
    canvas.drawRect(Rect.fromLTWH(cx - 18, h * 0.62, 36, h * 0.14),
        Paint()..color = const Color(0xFF3A2414));
    // snowfall
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h),
          1.5 + r.nextDouble() * 2, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
