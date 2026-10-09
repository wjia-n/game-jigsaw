import 'package:flutter/material.dart';
import '../engine/jigsaw_engine.dart';
import '../pictures.dart';
import '../theme/bibliophile_themes.dart';

/// Builds the die-cut outline of a jigsaw piece in local coordinates.
/// Bounds: (0,0) .. (cellW + 2*margin, cellH + 2*margin); the printed cell
/// sits at (margin, margin).
Path buildPiecePath({
  required int row,
  required int col,
  required int rows,
  required int cols,
  required double cellW,
  required double cellH,
  required double margin,
  required List<List<int>> hTabs,
  required List<List<int>> vTabs,
}) {
  // +1 = tab bulges outward on that side.
  final top = row > 0 ? -vTabs[row - 1][col] : 0;
  final bottom = row < rows - 1 ? vTabs[row][col] : 0;
  final left = col > 0 ? -hTabs[row][col - 1] : 0;
  final right = col < cols - 1 ? hTabs[row][col] : 0;

  final x0 = 0.0, y0 = 0.0;
  final x1 = cellW + margin * 2, y1 = cellH + margin * 2;
  final ix0 = margin, iy0 = margin; // inner cell origin
  final path = Path();

  void side(Offset a, Offset b, Offset outward, int tab) {
    if (tab == 0) {
      path.lineTo(b.dx, b.dy);
      return;
    }
    final m = (a + b) / 2;
    final d = b - a;
    final len = d.distance;
    final u = d / len;
    final nn = outward * tab.toDouble();
    path.lineTo(m.dx - u.dx * 0.15 * len, m.dy - u.dy * 0.15 * len);
    path.cubicTo(
      m.dx - u.dx * 0.17 * len + nn.dx * 0.03 * len,
      m.dy - u.dy * 0.17 * len + nn.dy * 0.03 * len,
      m.dx - u.dx * 0.13 * len + nn.dx * 0.17 * len,
      m.dy - u.dy * 0.13 * len + nn.dy * 0.17 * len,
      m.dx + nn.dx * 0.20 * len,
      m.dy + nn.dy * 0.20 * len,
    );
    path.cubicTo(
      m.dx + u.dx * 0.13 * len + nn.dx * 0.17 * len,
      m.dy + u.dy * 0.13 * len + nn.dy * 0.17 * len,
      m.dx + u.dx * 0.17 * len + nn.dx * 0.03 * len,
      m.dy + u.dy * 0.17 * len + nn.dy * 0.03 * len,
      m.dx + u.dx * 0.15 * len,
      m.dy + u.dy * 0.15 * len,
    );
    path.lineTo(b.dx, b.dy);
  }

  path.moveTo(ix0, iy0);
  // Top side: from inner-top-left to inner-top-right, outward = up.
  side(Offset(ix0, iy0), Offset(ix0 + cellW, iy0), const Offset(0, -1), top);
  // Right side: outward = right.
  side(Offset(ix0 + cellW, iy0), Offset(ix0 + cellW, iy0 + cellH),
      const Offset(1, 0), right);
  // Bottom side: right to left, outward = down.
  side(Offset(ix0 + cellW, iy0 + cellH), Offset(ix0, iy0 + cellH),
      const Offset(0, 1), bottom);
  // Left side: bottom to top, outward = left.
  side(Offset(ix0, iy0 + cellH), Offset(ix0, iy0), const Offset(-1, 0), left);
  path.close();

  // The path above traces the inner cell; knobs extend past the bounds
  // origin, so shift everything by (+margin, +margin) is already accounted:
  // knobs that bulge outward go into the margin area. Nothing to do —
  // coordinates are already in bounds space.
  assert(x0 == 0 && y0 == 0 && x1 > 0 && y1 > 0);
  return path;
}

/// Paints one puzzle piece as extruded grayboard cardboard:
/// printed pastoral top face, dark side walls, contact shadow, bevel
/// highlight, and an optional gold-foil apprentice mark for edge pieces.
class PiecePainter extends CustomPainter {
  final JigsawEngine engine;
  final int pieceId;
  final double cellW;
  final double cellH;
  final double margin;
  final LibraryThemeDef theme;
  final bool showMark;
  final bool simple; // tray thumbnails skip shadows/bevels
  final bool lifted; // picked up: stronger shadow

  PiecePainter({
    required this.engine,
    required this.pieceId,
    required this.cellW,
    required this.cellH,
    required this.margin,
    required this.theme,
    this.showMark = false,
    this.simple = false,
    this.lifted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = engine.piece(pieceId);
    final path = buildPiecePath(
      row: p.row,
      col: p.col,
      rows: engine.rows,
      cols: engine.cols,
      cellW: cellW,
      cellH: cellH,
      margin: margin,
      hTabs: engine.hTabs,
      vTabs: engine.vTabs,
    );

    // 1. Contact shadow.
    if (!simple) {
      final sh = lifted ? 10.0 : 5.0;
      canvas.drawPath(
          path.shift(Offset(2, sh)),
          Paint()
            ..color = Colors.black.withValues(alpha: lifted ? 0.5 : 0.38)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // 2. Grayboard side wall (extrusion).
    if (!simple) {
      canvas.drawPath(
          path.shift(const Offset(0, 3)),
          Paint()..color = const Color(0xFF6E5A44));
    }

    // 3. Printed top face: clip to the piece, paint the scene shifted so
    // this piece shows its own region of the picture.
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(-(p.col * cellW - margin), -(p.row * cellH - margin));
    PictureFolio.painter(engine.pictureId)
        .paint(canvas, Size(engine.cols * cellW, engine.rows * cellH));
    canvas.restore();

    // 4. Cardboard edge: thin dark rim + top bevel highlight.
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    if (!simple) {
      canvas.drawPath(
          path.shift(const Offset(0, -1)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    // 5. Apprentice mark: faint gold-foil dot on the back edge of edge
    // pieces (RULES.md Section 7).
    if (showMark && p.isEdgeOf(engine.rows, engine.cols)) {
      final dotC = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(
          dotC, 4.5, Paint()..color = theme.accentLight.withValues(alpha: 0.85));
      canvas.drawCircle(
          dotC,
          4.5,
          Paint()
            ..color = theme.accentDark.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter old) =>
      old.pieceId != pieceId ||
      old.cellW != cellW ||
      old.cellH != cellH ||
      old.showMark != showMark ||
      old.lifted != lifted ||
      old.theme != theme;
}

/// Ghost preview: translucent lamplight outline of where the dragged piece
/// would snap, drawn at the engine's ghost target.
class GhostPainter extends CustomPainter {
  final JigsawEngine engine;
  final int pieceId;
  final double cellW;
  final double cellH;
  final double margin;
  final LibraryThemeDef theme;

  GhostPainter({
    required this.engine,
    required this.pieceId,
    required this.cellW,
    required this.cellH,
    required this.margin,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = engine.piece(pieceId);
    final path = buildPiecePath(
      row: p.row,
      col: p.col,
      rows: engine.rows,
      cols: engine.cols,
      cellW: cellW,
      cellH: cellH,
      margin: margin,
      hTabs: engine.hTabs,
      vTabs: engine.vTabs,
    );
    canvas.drawPath(
        path,
        Paint()
          ..color = theme.lampGlow.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = theme.lampGlow.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant GhostPainter old) =>
      old.pieceId != pieceId || old.theme != theme;
}

/// Lamplight hint ring drawn around a highlighted tray piece.
class HintRingPainter extends CustomPainter {
  final Color glow;
  HintRingPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 + 6;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = glow.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(
        c,
        r - 3,
        Paint()
          ..color = glow.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant HintRingPainter old) => old.glow != glow;
}

/// A single piece widget with its own repaint boundary.
class PieceWidget extends StatelessWidget {
  final JigsawEngine engine;
  final int pieceId;
  final double cellW;
  final double cellH;
  final double margin;
  final LibraryThemeDef theme;
  final bool showMark;
  final bool simple;
  final bool lifted;

  const PieceWidget({
    super.key,
    required this.engine,
    required this.pieceId,
    required this.cellW,
    required this.cellH,
    required this.margin,
    required this.theme,
    this.showMark = false,
    this.simple = false,
    this.lifted = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(cellW + margin * 2, cellH + margin * 2),
        painter: PiecePainter(
          engine: engine,
          pieceId: pieceId,
          cellW: cellW,
          cellH: cellH,
          margin: margin,
          theme: theme,
          showMark: showMark,
          simple: simple,
          lifted: lifted,
        ),
      ),
    );
  }
}
