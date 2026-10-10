import 'package:flutter/material.dart';
import '../engine/jigsaw_engine.dart';
import '../pictures.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/bibliophile.dart';
import '../theme/bibliophile_themes.dart';
import '../widgets/piece_painter.dart';
import 'victory_screen.dart';

/// The puzzle table: leather-bound top plaque, central baize mat with the
/// in-progress puzzle, wooden tray rail of loose pieces at the bottom,
/// and circular brass icon buttons (pause, hint, reference, zoom).
class GameScreen extends StatefulWidget {
  final LibraryAudio audio;
  final JigsawSettings settings;
  final JigsawEngine engine;
  final bool isNewGame;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.engine,
    required this.isNewGame,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  JigsawEngine get _e => widget.engine;
  LibraryThemeDef get _t => LibraryThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  // View transform (mat units -> screen).
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _pan = Offset.zero;

  // Gesture state machine.
  bool _pieceDragging = false;
  bool _matPanning = false;
  bool _pinching = false;
  Offset _lastFocal = Offset.zero;
  double _lastScale = 1.0;

  // Feedback overlays.
  final List<_Flash> _flashes = [];
  int? _hintPieceId;
  String? _toast;
  bool _showPause = false;
  bool _celebrating = false;
  late final AnimationController _hintPulse;
  late final AnimationController _toastCtrl;

  final _trayScroll = ScrollController();
  final _matKey = GlobalKey();
  final _trayKey = GlobalKey();
  bool _engineHandedOff = false;
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hintPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _toastCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    final e = _e;
    // Throttle: the plaque label only changes once per second, so skip
    // rebuilds of the ~200 piece widgets on the other ticks.
    e.onTick = () {
      final s = _e.elapsedMs ~/ 1000;
      if (s != _lastTickSecond) {
        _lastTickSecond = s;
        if (mounted) setState(() {});
      }
    };
    e.onSnap = _onSnap;
    e.onFrameComplete = _onFrameComplete;
    e.onVictory = _onVictory;
    e.onTimeUp = _onTimeUp;
    e.onAutosave = _autosave;
    e.start();
    widget.audio.startGameMusic();
    if (widget.isNewGame) {
      // Fresh puzzle: clear any stale save; the new game saves on first snap.
      widget.settings.clearSave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintPulse.dispose();
    _toastCtrl.dispose();
    _trayScroll.dispose();
    if (!_engineHandedOff) _e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _e.onAppPaused();
      _autosave();
    } else if (state == AppLifecycleState.resumed) {
      _e.onAppResumed();
    }
  }

  // ------------------------------------------------------------- engine UI
  void _onSnap() {
    widget.audio.snap();
  }

  void _showSnapFlash(Offset at) {
    if (at == Offset.zero) return;
    final f = _Flash(pos: at, t: _t);
    _flashes.add(f);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _flashes.remove(f);
      setState(() {});
    });
  }

  void _onFrameComplete() {
    widget.audio.frameComplete();
    _toast = 'The frame is complete!';
    _toastCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _toastCtrl.reverse();
    });
  }

  void _onVictory() {
    widget.audio.win();
    _autosave();
    _engineHandedOff = true; // victory screen owns the engine now
    setState(() => _celebrating = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VictoryScreen(
            audio: widget.audio,
            settings: widget.settings,
            engine: _e,
          ),
        ),
      );
    });
  }

  void _onTimeUp() {
    widget.audio.timeUp();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TimeUpDialog(
        theme: _t,
        onKeep: () {
          Navigator.of(context).pop();
          _e.continueAfterTimeUp();
          widget.audio.click();
        },
        onQuit: () {
          Navigator.of(context).pop();
          _quitToMenu();
        },
      ),
    );
  }

  void _autosave() {
    if (_e.phase == JigsawPhase.playing ||
        _e.phase == JigsawPhase.paused) {
      widget.settings.writeSave(_e.encode());
    }
  }

  void _quitToMenu() {
    _autosave();
    widget.audio.click();
    widget.audio.startMenuMusic();
    Navigator.of(context).pop();
  }

  // -------------------------------------------------------------- gestures
  Offset _toMat(Offset screen) {
    final box = _matKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    return (screen - origin - _pan) / _scale;
  }

  int? _hitPiece(Offset mat) {
    // Topmost = last in drop order.
    final list = _e.matPieces;
    for (int i = list.length - 1; i >= 0; i--) {
      final p = list[i];
      final bounds = Rect.fromLTWH(
          p.x, p.y, JigsawEngine.cell + JigsawEngine.tabMargin * 2,
          JigsawEngine.cell + JigsawEngine.tabMargin * 2);
      if (bounds.contains(mat)) return p.id;
    }
    return null;
  }

  void _onScaleStart(ScaleStartDetails d) {
    if (_e.phase != JigsawPhase.playing || _showPause) return;
    if (d.pointerCount == 2) {
      if (_pieceDragging) {
        _e.cancelDrag();
        setState(() {});
      }
      _pinching = true;
      _pieceDragging = false;
      _matPanning = false;
      _lastFocal = d.focalPoint;
      _lastScale = _scale;
    } else {
      final mat = _toMat(d.focalPoint);
      final hit = _hitPiece(mat);
      if (hit != null) {
        final ids = _e.beginDrag(hit);
        if (ids.isNotEmpty) {
          _pieceDragging = true;
          _lastFocal = d.focalPoint;
          widget.audio.pickup();
          setState(() {});
        }
      } else {
        _matPanning = true;
        _lastFocal = d.focalPoint;
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_e.phase != JigsawPhase.playing || _showPause) return;
    if (_pinching || d.pointerCount == 2) {
      _pinching = true;
      // Pinch zoom around the focal point + two-finger pan.
      final newScale =
          (_lastScale * d.scale).clamp(_baseScale * 0.6, _baseScale * 4);
      final box = _matKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
      final focalInMat = (d.focalPoint - origin - _pan) / _scale;
      _scale = newScale;
      _pan = d.focalPoint - origin - focalInMat * _scale;
      setState(() {});
    } else if (_pieceDragging) {
      final deltaScreen = d.focalPoint - _lastFocal;
      _lastFocal = d.focalPoint;
      _e.updateDrag(deltaScreen / _scale);
      // Ghost preview state refreshes via setState on the cheap.
      setState(() {});
    } else if (_matPanning) {
      _pan += d.focalPoint - _lastFocal;
      _lastFocal = d.focalPoint;
      setState(() {});
    }
    // Keep the last focal fresh for single-pointer moves.
    if (!_pinching) _lastFocal = d.focalPoint;
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_pinching) {
      _pinching = false;
      return;
    }
    if (_pieceDragging) {
      _pieceDragging = false;
      // Dropping over the wooden tray rail returns the piece/cluster
      // to the tray (RULES.md Section 4).
      final toTray = _overTray(_lastFocal);
      final bounds = Rect.fromLTWH(
          0, 0, _e.puzzleW, _e.puzzleH);
      final r = _e.endDrag(
        matBounds: bounds,
        droppedOnTray: toTray,
      );
      if (r.returnedToTray) {
        widget.audio.place();
      } else if (r.outOfBounds) {
        widget.audio.invalid();
      } else if (r.snapped) {
        _showSnapFlash(r.snapFlashAt);
      } else if (r.noFit) {
        widget.audio.place();
      }
      setState(() {});
    }
    _matPanning = false;
  }

  /// True when a screen point lies over the wooden tray rail.
  bool _overTray(Offset screenPos) {
    final box = _trayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    return (box.localToGlobal(Offset.zero) & box.size).contains(screenPos);
  }

  /// A tray piece was dropped onto the mat (DragTarget).
  void _dropFromTray(int pieceId, Offset screenPos) {
    if (_e.phase != JigsawPhase.playing || _showPause) return;
    final mat = _toMat(screenPos);
    final ids = _e.beginDrag(pieceId);
    if (ids.isEmpty) return;
    final p = _e.piece(pieceId);
    // Move the piece so its center lands at the drop point.
    final target = mat -
        const Offset(JigsawEngine.cell / 2, JigsawEngine.cell / 2) -
        const Offset(JigsawEngine.tabMargin, JigsawEngine.tabMargin);
    _e.updateDrag(target - Offset(p.x, p.y));
    final bounds = Rect.fromLTWH(0, 0, _e.puzzleW, _e.puzzleH);
    // Tray rail check: if dropped over the tray area, return to tray.
    final r = _e.endDrag(
      matBounds: bounds,
      droppedOnTray: false,
    );
    if (r.outOfBounds) {
      widget.audio.invalid();
    } else if (r.snapped) {
      _showSnapFlash(r.snapFlashAt);
    } else if (r.noFit) {
      widget.audio.place();
    }
    setState(() {});
  }

  void _useHint() {
    final id = _e.useHint();
    if (id == null) {
      widget.audio.invalid();
      return;
    }
    widget.audio.hint();
    setState(() => _hintPieceId = id);
    // Scroll the tray to the highlighted piece.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final idx = _e.trayPieces.indexWhere((p) => p.id == id);
      if (idx >= 0 && _trayScroll.hasClients) {
        _trayScroll.animateTo(
          (idx * 76.0).clamp(0.0, _trayScroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
    // Clear the highlight when the piece leaves the tray.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _hintPieceId == id) setState(() => _hintPieceId = null);
    });
  }

  void _togglePause() {
    widget.audio.click();
    if (_e.phase == JigsawPhase.playing) {
      _e.pauseGame();
      setState(() => _showPause = true);
    } else if (_e.phase == JigsawPhase.paused) {
      _resume();
    }
  }

  void _resume() {
    widget.audio.click();
    _e.resumeGame();
    setState(() => _showPause = false);
  }

  void _restart() {
    widget.audio.click();
    final e = _e;
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

  // ------------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: LampGlow(
        theme: t,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topPlaque(t),
                    Expanded(child: _matArea(t)),
                    _trayRail(t),
                  ],
                ),
                if (_showPause) _pauseOverlay(t),
                if (_celebrating) _celebrationOverlay(t),
                if (_toast != null)
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _toastCtrl,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: t.woodDeep.withValues(alpha: 0.92),
                            border: Border.all(color: t.accent, width: 2),
                          ),
                          child: Text(_toast!,
                              style: Bibliophile.label(15, theme: t)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topPlaque(LibraryThemeDef t) {
    final e = _e;
    final timedOut = e.mode == JigsawMode.timed;
    final timeText = timedOut
        ? JigsawEngine.formatMs(e.timeLeftMs)
        : JigsawEngine.formatMs(
            e.mode == JigsawMode.relaxed ? 0 : e.elapsedMs);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.woodMid, t.woodDark],
        ),
        border: Border.all(color: t.accent, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(0, 5),
              blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(PictureFolio.names[e.pictureId],
                    style: Bibliophile.display(17, theme: t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.timer,
                        size: 14,
                        color: t.ivory.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      e.mode == JigsawMode.relaxed ? 'relaxed' : timeText,
                      style: Bibliophile.body(13,
                          theme: t,
                          color: (timedOut && e.timeLeftMs < 60000)
                              ? t.lampGlow
                              : t.ivory.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.pie_chart,
                        size: 14,
                        color: t.ivory.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('${(e.completion * 100).round()}%',
                        style: Bibliophile.body(13,
                            theme: t,
                            color: t.ivory.withValues(alpha: 0.85))),
                  ],
                ),
              ],
            ),
          ),
          BrassIconButton(
              icon: Icons.pause, size: 46, theme: t, onTap: _togglePause),
          const SizedBox(width: 8),
          Stack(
            children: [
              BrassIconButton(
                icon: Icons.lightbulb_outline,
                size: 46,
                theme: t,
                dimmed: e.hintsLeft <= 0,
                onTap: e.hintsLeft <= 0 ? null : _useHint,
              ),
              if (e.mode != JigsawMode.relaxed)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.woodDeep,
                      border: Border.all(color: t.accent, width: 1.5),
                    ),
                    child: Text('${e.hintsLeft}',
                        style: Bibliophile.label(10, theme: t)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          BrassIconButton(
            icon: widget.settings.showReference
                ? Icons.image
                : Icons.image_not_supported_outlined,
            size: 46,
            theme: t,
            onTap: () {
              widget.audio.click();
              widget.settings
                  .setShowReference(!widget.settings.showReference);
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
          BrassIconButton(
              icon: Icons.zoom_out_map,
              size: 46,
              theme: t,
              onTap: () {
                widget.audio.click();
                setState(() {
                  _scale = _baseScale;
                  _pan = Offset.zero;
                });
              }),
        ],
      ),
    );
  }

  Widget _matArea(LibraryThemeDef t) {
    final e = _e;
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaW = constraints.maxWidth;
        final areaH = constraints.maxHeight;
        // Fit the puzzle on first layout.
        if (_baseScale == 1.0 && _pan == Offset.zero) {
          _baseScale =
              (areaW / e.puzzleW < areaH / e.puzzleH
                      ? areaW / e.puzzleW
                      : areaH / e.puzzleH) *
                  0.94;
          _scale = _baseScale;
          _pan = Offset(
            (areaW - e.puzzleW * _scale) / 2,
            (areaH - e.puzzleH * _scale) / 2,
          );
        }
        final ghost = _pieceDragging ? e.ghostPreview() : null;
        return Container(
          key: _matKey,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: t.woodDeep.withValues(alpha: 0.55),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Single gesture arena for the whole table: piece drags,
              // mat pan and pinch zoom are disambiguated in the callbacks.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: DragTarget<int>(
                    onWillAcceptWithDetails: (_) =>
                        e.phase == JigsawPhase.playing && !_showPause,
                    onAcceptWithDetails: (d) =>
                        _dropFromTray(d.data, d.offset),
                    builder: (_, _, _) => Stack(
                      children: [
                        // The linen mat with stitched border + brass corners.
                        Transform(
                          transform: Matrix4.identity()
                            ..translateByDouble(_pan.dx, _pan.dy, 0, 1)
                            ..scaleByDouble(_scale, _scale, _scale, 1),
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: e.puzzleW,
                            height: e.puzzleH,
                            child: CustomPaint(
                              painter: _MatPainter(theme: t),
                            ),
                          ),
                        ),
                        // Pieces (same transform).
                        Transform(
                          transform: Matrix4.identity()
                            ..translateByDouble(_pan.dx, _pan.dy, 0, 1)
                            ..scaleByDouble(_scale, _scale, _scale, 1),
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: e.puzzleW,
                            height: e.puzzleH,
                            child: Stack(
                              children: [
                                for (final p in e.matPieces)
                                  Positioned(
                                    left: p.x,
                                    top: p.y,
                                    child: PieceWidget(
                                      engine: e,
                                      pieceId: p.id,
                                      cellW: JigsawEngine.cell,
                                      cellH: JigsawEngine.cell,
                                      margin: JigsawEngine.tabMargin,
                                      theme: t,
                                      lifted: _pieceDragging &&
                                          e.dragIds.contains(p.id),
                                    ),
                                  ),
                                // Ghost preview of the snap target.
                                if (ghost != null && _pieceDragging)
                                  Positioned(
                                    left: ghost.dx,
                                    top: ghost.dy,
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: const Size(
                                            JigsawEngine.cell +
                                                JigsawEngine.tabMargin * 2,
                                            JigsawEngine.cell +
                                                JigsawEngine.tabMargin * 2),
                                        painter: GhostPainter(
                                          engine: e,
                                          pieceId: e.dragIds.first,
                                          cellW: JigsawEngine.cell,
                                          cellH: JigsawEngine.cell,
                                          margin: JigsawEngine.tabMargin,
                                          theme: t,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Snap flash rings.
                                for (final f in _flashes)
                                  Positioned(
                                    left: f.pos.dx - 30,
                                    top: f.pos.dy - 30,
                                    child: _SnapFlash(theme: t),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Reference thumbnail (framed, toggleable).
              if (widget.settings.showReference)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: t.woodDeep,
                      border: Border.all(color: t.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RepaintBoundary(
                      child: CustomPaint(
                          painter: _ThumbPainter(e.pictureId)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _trayRail(LibraryThemeDef t) {
    final e = _e;
    final tray = e.trayPieces;
    // Tray piece size: fit ~5 across, min 48px touch target (RULES.md 12).
    const tile = 76.0;
    return Container(
      key: _trayKey,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.woodMid, t.woodDark],
        ),
        border: Border.all(color: t.accent, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(0, -3),
              blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${tray.length} pieces in the tray — drag one onto the mat',
              style: Bibliophile.body(11,
                  theme: t, color: t.ivory.withValues(alpha: 0.65)),
            ),
          ),
          SizedBox(
            height: tile + 18,
            child: tray.isEmpty
                ? Center(
                    child: Text('Tray empty — every piece is on the mat!',
                        style: Bibliophile.body(13, theme: t)),
                  )
                : ListView.builder(
                    controller: _trayScroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    itemCount: tray.length,
                    itemBuilder: (_, i) {
                      final p = tray[i];
                      final highlighted = _hintPieceId == p.id;
                      final w = _TrayPiece(
                        engine: e,
                        pieceId: p.id,
                        theme: t,
                        size: tile,
                        highlighted: highlighted,
                        pulse: _hintPulse,
                        showMark:
                            widget.settings.marksFor(e.pieceCount),
                      );
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 6),
                        child: Draggable<int>(
                          data: p.id,
                          feedback: Material(
                            color: Colors.transparent,
                            child: PieceWidget(
                              engine: e,
                              pieceId: p.id,
                              cellW: JigsawEngine.cell,
                              cellH: JigsawEngine.cell,
                              margin: JigsawEngine.tabMargin,
                              theme: t,
                              simple: true,
                              lifted: true,
                            ),
                          ),
                          childWhenDragging: Opacity(
                              opacity: 0.3, child: w),
                          child: w,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pauseOverlay(LibraryThemeDef t) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [t.woodMid, t.woodDark],
                ),
                border: Border.all(color: t.accent, width: 2.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PAUSED',
                      style: Bibliophile.display(28, theme: t)),
                  const SizedBox(height: 6),
                  Text(
                      '${JigsawEngine.formatMs(_e.elapsedMs)} · ${(_e.completion * 100).round()}% · ${_e.moves} moves',
                      style: Bibliophile.body(13,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.75))),
                  const SizedBox(height: 16),
                  LeatherCardButton(
                      label: 'RESUME', theme: t, onTap: _resume),
                  const SizedBox(height: 10),
                  LeatherCardButton(
                      label: 'RESTART', theme: t, onTap: _restart),
                  const SizedBox(height: 10),
                  LeatherCardButton(
                      label: 'QUIT TO MENU',
                      theme: t,
                      onTap: _quitToMenu),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _celebrationOverlay(LibraryThemeDef t) => Positioned.fill(
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  t.lampGlow.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Text('Beautiful!',
                  style: Bibliophile.display(44, theme: t)),
            ),
          ),
        ),
      );
}

/// The linen puzzle mat: emerald baize with stitched border, perimeter
/// groove shadow, and brass corner brackets (Stitch design system).
class _MatPainter extends CustomPainter {
  final LibraryThemeDef theme;
  _MatPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final t = theme;
    // Baize field.
    canvas.drawRect(
        Offset.zero & size, Paint()..color = t.mat);
    // Subtle linen weave.
    final weave = Paint()
      ..color = t.matDark.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (double y = 8; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), weave);
    }
    // Perimeter groove (drop shadow onto the walnut).
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    // Stitched border.
    final stitch = Paint()
      ..color = t.ivory.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    const dash = 8.0, gap = 6.0;
    final r = Rect.fromLTWH(16, 16, size.width - 32, size.height - 32);
    for (double x = r.left; x < r.right; x += dash + gap) {
      canvas.drawLine(Offset(x, r.top),
          Offset((x + dash).clamp(r.left, r.right), r.top), stitch);
      canvas.drawLine(Offset(x, r.bottom),
          Offset((x + dash).clamp(r.left, r.right), r.bottom), stitch);
    }
    for (double y = r.top; y < r.bottom; y += dash + gap) {
      canvas.drawLine(Offset(r.left, y),
          Offset(r.left, (y + dash).clamp(r.top, r.bottom)), stitch);
      canvas.drawLine(Offset(r.right, y),
          Offset(r.right, (y + dash).clamp(r.top, r.bottom)), stitch);
    }
    // Brass corner brackets.
    final bracket = Paint()
      ..color = t.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const b = 30.0, o = 10.0;
    final corners = [
      (Offset(o, o + b), Offset(o, o), Offset(o + b, o)),
      (Offset(size.width - o - b, o), Offset(size.width - o, o),
          Offset(size.width - o, o + b)),
      (Offset(o, size.height - o - b), Offset(o, size.height - o),
          Offset(o + b, size.height - o)),
      (
        Offset(size.width - o - b, size.height - o),
        Offset(size.width - o, size.height - o),
        Offset(size.width - o, size.height - o - b)
      ),
    ];
    for (final c in corners) {
      canvas.drawLine(c.$1, c.$2, bracket);
      canvas.drawLine(c.$2, c.$3, bracket);
    }
  }

  @override
  bool shouldRepaint(covariant _MatPainter old) => old.theme != theme;
}

class _ThumbPainter extends CustomPainter {
  final int id;
  _ThumbPainter(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    PictureFolio.painter(id).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) => old.id != id;
}

/// A tray tile: shrunken piece with a lamplight hint ring when highlighted.
class _TrayPiece extends StatelessWidget {
  final JigsawEngine engine;
  final int pieceId;
  final LibraryThemeDef theme;
  final double size;
  final bool highlighted;
  final AnimationController pulse;
  final bool showMark;

  const _TrayPiece({
    required this.engine,
    required this.pieceId,
    required this.theme,
    required this.size,
    required this.highlighted,
    required this.pulse,
    required this.showMark,
  });

  @override
  Widget build(BuildContext context) {
    // Scale the piece down to fit the tile while keeping ≥48px touch target.
    const full = JigsawEngine.cell + JigsawEngine.tabMargin * 2;
    final s = size / full;
    Widget w = SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: s,
        alignment: Alignment.topLeft,
        child: PieceWidget(
          engine: engine,
          pieceId: pieceId,
          cellW: JigsawEngine.cell,
          cellH: JigsawEngine.cell,
          margin: JigsawEngine.tabMargin,
          theme: theme,
          simple: true,
          showMark: showMark,
        ),
      ),
    );
    if (highlighted) {
      w = AnimatedBuilder(
        animation: pulse,
        builder: (_, _) => CustomPaint(
          foregroundPainter:
              HintRingPainter(glow: theme.lampGlow),
          child: Transform.scale(
            scale: 1.0 + pulse.value * 0.06,
            child: w,
          ),
        ),
      );
    }
    return w;
  }
}

/// Expanding warm ring shown at a snap point.
class _SnapFlash extends StatefulWidget {
  final LibraryThemeDef theme;
  const _SnapFlash({required this.theme});

  @override
  State<_SnapFlash> createState() => _SnapFlashState();
}

class _SnapFlashState extends State<_SnapFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: 1 - _c.value,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.theme.lampGlow
                  .withValues(alpha: 0.9 * (1 - _c.value)),
              width: 4,
            ),
          ),
          transform: Matrix4.identity()
            ..scaleByDouble(0.4 + _c.value * 1.1, 0.4 + _c.value * 1.1, 1, 1),
          transformAlignment: Alignment.center,
        ),
      ),
    );
  }
}

class _Flash {
  final Offset pos;
  final LibraryThemeDef t;
  _Flash({required this.pos, required this.t});
}

class _TimeUpDialog extends StatelessWidget {
  final LibraryThemeDef theme;
  final VoidCallback onKeep;
  final VoidCallback onQuit;
  const _TimeUpDialog(
      {required this.theme, required this.onKeep, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return AlertDialog(
      backgroundColor: t.woodMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: t.accent, width: 2.5),
      ),
      title: Text("Time's up!", style: Bibliophile.display(24, theme: t)),
      content: Text(
        'The par time slipped away — but the puzzle is still here, and so is the lamp. Keep puzzling at your own pace?',
        style: Bibliophile.body(14, theme: t),
      ),
      actions: [
        TextButton(
          onPressed: onQuit,
          child: Text('Quit', style: Bibliophile.label(14, theme: t)),
        ),
        TextButton(
          onPressed: onKeep,
          child: Text('Keep puzzling',
              style: Bibliophile.label(14, theme: t)
                  .copyWith(color: t.accentLight)),
        ),
      ],
    );
  }
}
