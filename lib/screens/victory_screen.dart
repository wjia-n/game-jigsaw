import 'package:flutter/material.dart';
import '../engine/jigsaw_engine.dart';
import '../pictures.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';
import '../widgets/piece_painter.dart';
import 'game_screen.dart';
import 'menu_screen.dart';

/// Victory: the completed puzzle on the mat under full lamplight, a brass
/// stats plaque (time / moves / hints / stars), NEW RECORD badge, and
/// leather-card buttons (PLAY AGAIN / NEW PUZZLE / MENU).
class VictoryScreen extends StatefulWidget {
  final LibraryAudio audio;
  final JigsawSettings settings;
  final JigsawEngine engine;

  const VictoryScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.engine,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  bool _newRecord = false;
  int _stars = 1;

  LibraryThemeDef get _t => LibraryThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _finish();
  }

  Future<void> _finish() async {
    final e = widget.engine;
    final s = widget.settings;
    _stars = e.starRating();
    // Relaxed mode keeps no records; daily marks the day complete.
    if (e.mode == JigsawMode.relaxed) {
      await s.clearSave();
    } else if (e.mode == JigsawMode.daily) {
      final n = DateTime.now();
      final key =
          '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      await s.markDailyDone(key);
      await s.clearSave();
    } else {
      _newRecord = await s.recordWin(
        pieceCount: e.pieceCount,
        finalTimeMs: e.finalTimeMs,
        moves: e.moves,
        starCount: _stars,
      );
      await s.clearSave();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _glow.dispose();
    widget.engine.dispose();
    super.dispose();
  }

  void _playAgain() {
    widget.audio.gameStart();
    final e = widget.engine;
    final fresh = JigsawEngine(
      rows: e.rows,
      cols: e.cols,
      pictureId: e.pictureId,
      seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      mode: e.mode,
      pieceCount: e.pieceCount,
      snapRadiusFraction: e.snapRadiusFraction,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          engine: fresh,
          isNewGame: true,
        ),
      ),
    );
  }

  void _newPuzzle() {
    widget.audio.click();
    widget.audio.startMenuMusic();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
      (_) => false,
    );
  }

  void _toMenu() {
    widget.audio.click();
    widget.audio.startMenuMusic();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = widget.engine;
    final relaxed = e.mode == JigsawMode.relaxed;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.3,
                  colors: [
                    t.lampGlow
                        .withValues(alpha: 0.18 + _glow.value * 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 16),
                child: Column(
                  children: [
                    Text('PUZZLE COMPLETE',
                        style: Bibliophile.display(30, theme: t),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(PictureFolio.names[e.pictureId],
                        style: Bibliophile.body(15,
                            theme: t,
                            color: t.ivory.withValues(alpha: 0.75))),
                    if (_newRecord)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: t.accent.withValues(alpha: 0.25),
                          border: Border.all(color: t.accentLight),
                        ),
                        child: Text('✦ NEW RECORD ✦',
                            style: Bibliophile.label(15, theme: t)),
                      ),
                    const SizedBox(height: 14),
                    // Completed puzzle under the lamplight.
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: t.matDark,
                        border:
                            Border.all(color: t.accent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(0, 8),
                              blurRadius: 16),
                          BoxShadow(
                              color: t.lampGlow
                                  .withValues(alpha: 0.2 + _glow.value * 0.15),
                              blurRadius: 30),
                        ],
                      ),
                      child: _CompletedPuzzle(engine: e, theme: t),
                    ),
                    const SizedBox(height: 14),
                    // Brass stats plaque.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [t.woodMid, t.woodDark],
                        ),
                        border:
                            Border.all(color: t.accent, width: 2.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 3; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Text(
                                    i < _stars ? '★' : '☆',
                                    style: TextStyle(
                                      fontSize: 34,
                                      color: i < _stars
                                          ? t.accentLight
                                          : t.ivory.withValues(alpha: 0.3),
                                      shadows: [
                                        Shadow(
                                            color: Colors.black.withValues(
                                                alpha: 0.6),
                                            offset: const Offset(0, 2),
                                            blurRadius: 3),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _statRow(t, 'Time',
                              relaxed ? '—' : JigsawEngine.formatMs(e.finalTimeMs)),
                          _statRow(t, 'Moves', '${e.moves}'),
                          _statRow(t, 'Hints used', '${e.hintsUsed}'),
                          if (!relaxed)
                            _statRow(t, 'Pieces', '${e.pieceCount}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LeatherCardButton(
                        label: 'PLAY AGAIN',
                        theme: t,
                        onTap: _playAgain),
                    const SizedBox(height: 10),
                    LeatherCardButton(
                        label: 'NEW PUZZLE',
                        theme: t,
                        onTap: _newPuzzle),
                    const SizedBox(height: 10),
                    LeatherCardButton(
                        label: 'MENU', theme: t, onTap: _toMenu),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(LibraryThemeDef t, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Bibliophile.body(14,
                        theme: t,
                        color: t.ivory.withValues(alpha: 0.75)))),
            Text(value, style: Bibliophile.label(15, theme: t)),
          ],
        ),
      );
}

/// The finished picture rendered as one merged slab of pieces.
class _CompletedPuzzle extends StatelessWidget {
  final JigsawEngine engine;
  final LibraryThemeDef theme;
  const _CompletedPuzzle({required this.engine, required this.theme});

  @override
  Widget build(BuildContext context) {
    final e = engine;
    // Render at a fitted cell size; pieces tile exactly into the picture.
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final cw = w / e.cols;
        final ch = cw; // keep square cells
        final m = JigsawEngine.tabMargin * cw / JigsawEngine.cell;
        return SizedBox(
          width: w,
          height: ch * e.rows,
          child: Stack(
            children: [
              for (final p in e.pieces)
                Positioned(
                  // Snap every piece exactly to its target: the merged slab.
                  left: p.col * cw - m,
                  top: p.row * ch - m,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(cw + m * 2, ch + m * 2),
                      painter: _SlabPiecePainter(
                        engine: e,
                        pieceId: p.id,
                        cellW: cw,
                        cellH: ch,
                        margin: m,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SlabPiecePainter extends CustomPainter {
  final JigsawEngine engine;
  final int pieceId;
  final double cellW;
  final double cellH;
  final double margin;

  _SlabPiecePainter({
    required this.engine,
    required this.pieceId,
    required this.cellW,
    required this.cellH,
    required this.margin,
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
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(-(p.col * cellW - margin), -(p.row * cellH - margin));
    PictureFolio.painter(engine.pictureId)
        .paint(canvas, Size(engine.cols * cellW, engine.rows * cellH));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SlabPiecePainter old) =>
      old.pieceId != pieceId ||
      old.cellW != cellW ||
      old.cellH != cellH;
}
