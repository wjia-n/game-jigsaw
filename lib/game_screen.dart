import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'pictures.dart';

/// Jigsaw — relaxing jigsaws with three generated pictures,
/// real jigsaw tabs, drag & snap, progress %, win celebration.
class JigsawScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const JigsawScreen({super.key, required this.players, required this.callbacks});

  @override
  State<JigsawScreen> createState() => _JigsawScreenState();
}

class _Piece {
  final int r, c;
  Offset pos;
  bool placed;
  _Piece(this.r, this.c, this.pos, this.placed);
}

class _JigsawScreenState extends State<JigsawScreen> {
  // setup
  bool started = false;
  int picIdx = 0;
  int pieceCount = 12;

  // play
  int cols = 4, rows = 3;
  late List<List<int>> hTabs; // [r][c]: edge (r,c)-(r,c+1), +1 bulges right
  late List<List<int>> vTabs; // [r][c]: edge (r,c)-(r+1,c), +1 bulges down
  final List<_Piece> pieces = [];
  _Piece? dragging;
  Offset frameOrigin = Offset.zero;
  double frameW = 0, frameH = 0;
  bool areaInit = false;
  bool celebrating = false;
  bool over = false;
  DateTime? t0;

  CustomPainter get _painter => switch (picIdx) {
        0 => SunsetPainter(),
        1 => MountainsPainter(),
        _ => BeachPainter(),
      };
  String get _picName => ['Sunset Glow 🌅', 'Mountain Air 🏔️', 'Beach Day 🏖️'][picIdx];

  double get _pw => frameW / cols;
  double get _ph => frameH / rows;
  double get _pad => min(_pw, _ph) * 0.32;
  int get placedCount => pieces.where((p) => p.placed).length;

  Offset _target(_Piece p) =>
      frameOrigin + Offset(p.c * _pw - _pad, p.r * _ph - _pad);

  void _startGame() {
    Sfx.click();
    cols = pieceCount == 12 ? 4 : (pieceCount == 24 ? 6 : 8);
    rows = pieceCount == 12 ? 3 : (pieceCount == 24 ? 4 : 6);
    final rng = Random();
    hTabs = List.generate(rows, (_) => List.generate(cols - 1, (_) => rng.nextBool() ? 1 : -1));
    vTabs = List.generate(rows - 1, (_) => List.generate(cols, (_) => rng.nextBool() ? 1 : -1));
    pieces.clear();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        pieces.add(_Piece(r, c, Offset.zero, false));
      }
    }
    areaInit = false;
    celebrating = false;
    over = false;
    t0 = DateTime.now();
    setState(() => started = true);
  }

  void _initArea(Size area) {
    frameH = area.height * 0.44;
    frameW = frameH * 4 / 3;
    if (frameW > area.width - 24) {
      frameW = area.width - 24;
      frameH = frameW * 3 / 4;
    }
    frameOrigin = Offset((area.width - frameW) / 2, 10);
    // scatter pieces on a jittered grid in the tray below the frame
    final trayTop = frameOrigin.dy + frameH + 18;
    final trayH = area.height - trayTop - 8;
    final pw = _pw + 2 * _pad, ph = _ph + 2 * _pad;
    final perRow = max(1, (area.width / (pw * 1.15)).floor());
    final order = [...pieces]..shuffle(Random());
    for (int i = 0; i < order.length; i++) {
      final gr = i ~/ perRow, gc = i % perRow;
      final inRow = min(perRow, order.length - gr * perRow);
      final rowW = inRow * pw * 1.15;
      final x0 = (area.width - rowW) / 2 + gc * pw * 1.15;
      final y0 = trayTop + gr * ph * 1.12;
      final jx = (Random().nextDouble() - 0.5) * pw * 0.3;
      final jy = (Random().nextDouble() - 0.5) * ph * 0.25;
      order[i].pos = Offset(
        x0.clamp(0.0, max(0.0, area.width - pw)) + jx.clamp(-8.0, 8.0),
        (y0 + jy).clamp(trayTop, max(trayTop, trayTop + trayH - ph)),
      );
    }
    areaInit = true;
  }

  void _grab(_Piece p) {
    Sfx.tap();
    setState(() {
      dragging = p;
      pieces.remove(p);
      pieces.add(p);
    });
  }

  void _dragPiece(_Piece p, Offset delta) {
    setState(() {
      p.pos += delta;
    });
  }

  void _drop(_Piece p) {
    dragging = null;
    final t = _target(p);
    if ((p.pos - t).distance < 30) {
      setState(() {
        p.pos = t;
        p.placed = true;
      });
      Sfx.move();
      widget.players.first.score += 5;
      widget.callbacks.refreshHud();
      if (placedCount == pieces.length) _win();
    } else {
      Sfx.tap();
      setState(() {});
    }
  }

  void _win() {
    if (over) return;
    over = true;
    Sfx.win();
    final secs = DateTime.now().difference(t0 ?? DateTime.now()).inSeconds;
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    widget.players.first.score += pieceCount * 2;
    widget.callbacks.refreshHud();
    setState(() => celebrating = true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      widget.callbacks.finish(
        headline: 'Puzzle complete! 🧩🎉',
        subline:
            '$_picName in $pieceCount pieces, finished in $mm:$ss. Certified puzzle wizard!',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (!started) return _setup(t);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pieces.isEmpty ? 0 : placedCount / pieces.length,
                    minHeight: 10,
                    backgroundColor: t.surface,
                    valueColor: AlwaysStoppedAnimation(t.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${pieces.isEmpty ? 0 : (placedCount / pieces.length * 100).round()}%',
                  style: TextStyle(color: t.text, fontWeight: FontWeight.w800)),
              IconButton(
                tooltip: 'New puzzle',
                icon: const Icon(Icons.refresh),
                color: t.muted,
                onPressed: () {
                  Sfx.tap();
                  setState(() => started = false);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final area = Size(constraints.maxWidth, constraints.maxHeight);
              if (!areaInit && pieces.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !areaInit) setState(() => _initArea(area));
                });
              }
              return Stack(
                children: [
                  // frame guide
                  Positioned(
                    left: frameOrigin.dx,
                    top: frameOrigin.dy,
                    width: frameW,
                    height: frameH,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: t.primary.withValues(alpha: 0.5), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Opacity(
                          opacity: 0.28,
                          child: CustomPaint(painter: _painter),
                        ),
                      ),
                    ),
                  ),
                  for (final p in pieces) _pieceWidget(p, t),
                  if (celebrating)
                    Positioned.fill(
                      child: Container(
                        color: t.background.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: t.radius,
                            border: Border.all(
                                color: t.primary.withValues(alpha: 0.4),
                                width: 2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 56)),
                              const SizedBox(height: 8),
                              Text('Puzzle complete!',
                                  style: TextStyle(
                                      color: t.text,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22)),
                              Text('You absolute legend 🧩',
                                  style: TextStyle(color: t.muted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pieceWidget(_Piece p, GameTheme t) {
    final pw = _pw, ph = _ph, pad = _pad;
    final top = p.r == 0 ? 0 : -vTabs[p.r - 1][p.c];
    final bottom = p.r == rows - 1 ? 0 : vTabs[p.r][p.c];
    final left = p.c == 0 ? 0 : -hTabs[p.r][p.c - 1];
    final right = p.c == cols - 1 ? 0 : hTabs[p.r][p.c];
    return Positioned(
      left: p.pos.dx,
      top: p.pos.dy,
      child: GestureDetector(
        onPanStart: p.placed ? null : (_) => _grab(p),
        onPanUpdate: p.placed ? null : (d) => _dragPiece(p, d.delta),
        onPanEnd: p.placed ? null : (_) => _drop(p),
        child: AnimatedScale(
          scale: dragging == p ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: pw + 2 * pad,
            height: ph + 2 * pad,
            child: ClipPath(
              clipper: _PieceClipper(
                  top: top, right: right, bottom: bottom, left: left,
                  pad: pad, w: pw, h: ph),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: pad - p.c * pw,
                    top: pad - p.r * ph,
                    child: SizedBox(
                      width: frameW,
                      height: frameH,
                      child: CustomPaint(painter: _painter),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setup(GameTheme t) {
    const pics = ['🌅', '🏔️', '🏖️'];
    const names = ['Sunset Glow', 'Mountain Air', 'Beach Day'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick your picture 🎨',
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
                    child: GestureDetector(
                      onTap: () {
                        Sfx.tap();
                        setState(() => picIdx = i);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: t.radius,
                          border: Border.all(
                            color: picIdx == i
                                ? t.primary
                                : t.primary.withValues(alpha: 0.2),
                            width: picIdx == i ? 3 : 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 4 / 3,
                                child: CustomPaint(
                                  painter: i == 0
                                      ? SunsetPainter()
                                      : i == 1
                                          ? MountainsPainter()
                                          : BeachPainter(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text('${pics[i]} ${names[i]}',
                                    style: TextStyle(
                                        color: t.text,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('How many pieces? 🧩',
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final n in [12, 24, 48])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text('$n',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      selected: pieceCount == n,
                      onSelected: (_) {
                        Sfx.tap();
                        setState(() => pieceCount = n);
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pieceCount == 12
                ? 'Chill mode: a breezy little puzzle ☕'
                : pieceCount == 24
                    ? 'Classic mode: the sweet spot 🎯'
                    : 'Beast mode: 48 pieces of pure glory 🔥',
            style: TextStyle(color: t.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          WajihaButton(
              label: 'Start puzzling', emoji: '🧩', onTap: _startGame),
          const SizedBox(height: 12),
          Text(
            'Drag pieces onto the frame — they snap in with a happy little buzz when close. No timer, no stress. ✨',
            style: TextStyle(color: t.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Classic jigsaw piece shape: rectangle with knob/dent tabs.
/// Tab values: +1 outie (knob sticks out), -1 innie (dent), 0 flat.
class _PieceClipper extends CustomClipper<Path> {
  final int top, right, bottom, left;
  final double pad, w, h;
  const _PieceClipper(
      {required this.top,
      required this.right,
      required this.bottom,
      required this.left,
      required this.pad,
      required this.w,
      required this.h});

  @override
  Path getClip(Size size) {
    final path = Path();
    final tl = Offset(pad, pad);
    final tr = Offset(pad + w, pad);
    final br = Offset(pad + w, pad + h);
    final bl = Offset(pad, pad + h);
    path.moveTo(tl.dx, tl.dy);
    _edge(path, tl, tr, top, const Offset(0, -1));
    _edge(path, tr, br, right, const Offset(1, 0));
    _edge(path, br, bl, bottom, const Offset(0, 1));
    _edge(path, bl, tl, left, const Offset(-1, 0));
    path.close();
    return path;
  }

  void _edge(Path path, Offset a, Offset b, int tab, Offset outward) {
    if (tab == 0) {
      path.lineTo(b.dx, b.dy);
      return;
    }
    final d = b - a;
    final ts = (w < h ? w : h) * 0.24;
    final n = outward * tab.toDouble();
    final s = a + d * 0.36;
    final e = a + d * 0.64;
    final tip = a + d * 0.5 + n * ts;
    path.lineTo(s.dx, s.dy);
    path.cubicTo(
        (s + n * ts * 0.55).dx,
        (s + n * ts * 0.55).dy,
        (tip - d * 0.16 + n * ts * 0.12).dx,
        (tip - d * 0.16 + n * ts * 0.12).dy,
        tip.dx,
        tip.dy);
    path.cubicTo(
        (tip + d * 0.16 + n * ts * 0.12).dx,
        (tip + d * 0.16 + n * ts * 0.12).dy,
        (e + n * ts * 0.55).dx,
        (e + n * ts * 0.55).dy,
        e.dx,
        e.dy);
    path.lineTo(b.dx, b.dy);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
