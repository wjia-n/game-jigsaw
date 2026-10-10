import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

/// Phases owned by the engine (never by UI timers).
enum JigsawPhase { idle, playing, paused, victory, timeUp }

/// Game modes: 0 classic, 1 timed, 2 relaxed, 3 daily.
class JigsawMode {
  static const classic = 0;
  static const timed = 1;
  static const relaxed = 2;
  static const daily = 3;
}

/// A single puzzle piece. Positions are in mat-relative units
/// (cell = 100.0); the UI scales them to screen space.
class JigsawPiece {
  final int id;
  final int row;
  final int col;
  double x; // top-left of the piece bounds (incl. tab margin)
  double y;
  int clusterId;
  bool inTray;

  JigsawPiece({
    required this.id,
    required this.row,
    required this.col,
    required this.x,
    required this.y,
    required this.clusterId,
    this.inTray = true,
  });

  bool isEdgeOf(int rows, int cols) =>
      row == 0 || row == rows - 1 || col == 0 || col == cols - 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'c': clusterId,
        't': inTray ? 1 : 0,
      };
}

/// Result of a drop, driving UI feedback (sounds + animations).
class DropResult {
  final bool snapped;
  final List<int> mergedPieceIds;
  final bool noFit;
  final bool outOfBounds;
  final bool returnedToTray;
  final bool victory;
  final bool frameComplete;
  final Offset snapFlashAt;

  const DropResult({
    this.snapped = false,
    this.mergedPieceIds = const [],
    this.noFit = false,
    this.outOfBounds = false,
    this.returnedToTray = false,
    this.victory = false,
    this.frameComplete = false,
    this.snapFlashAt = Offset.zero,
  });
}

/// The Jigsaw engine. Owns ALL puzzle state: pieces, clusters, timer, hints,
/// moves, completion, save format. The UI renders and forwards gestures; the
/// engine decides what happens.
///
/// Watchdog: two engine-owned timers. [_ticker] accumulates the game clock
/// while playing; [_watchdog] runs every 3s and restarts the ticker if it
/// ever died without the phase changing, and cancels drags that went stale
/// (e.g. a gesture was interrupted by the OS). Stuck states are impossible
/// by construction: every phase has a live timer or a terminal screen.
class JigsawEngine extends ChangeNotifier {
  // ------------------------------------------------------------ config
  final int rows;
  final int cols;
  final int pictureId;
  final int seed;
  final int mode;
  final int pieceCount;
  final double snapRadiusFraction;

  static const double cell = 100.0;
  static const double tabMargin = 22.0; // 0.22 * cell

  double get puzzleW => cols * cell;
  double get puzzleH => rows * cell;

  /// Die-cut tabs. hTabs[r][c]: edge between (r,c)-(r,c+1), +1 bulges right.
  late final List<List<int>> hTabs;
  /// vTabs[r][c]: edge between (r,c)-(r+1,c), +1 bulges down.
  late final List<List<int>> vTabs;

  // -------------------------------------------------------------- state
  final List<JigsawPiece> pieces = [];
  final Map<int, JigsawPiece> _byId = {};
  final Map<int, Set<int>> clusters = {}; // clusterId -> piece ids
  JigsawPhase phase = JigsawPhase.idle;

  int elapsedMs = 0; // engine-owned clock, pauses with the game
  int moves = 0;
  int hintsUsed = 0;
  int hintPenaltyMs = 0;
  int hintBudget;
  int? selectedPieceId; // for the hint engine's "selected cluster" context
  bool frameAnnounced = false;
  bool victoryAnnounced = false;

  // drag state (engine-owned; UI mirrors)
  Set<int> _dragIds = {};
  final Map<int, Offset> _dragStart = {};
  DateTime _dragLastUpdate = DateTime.now();

  // timers
  Timer? _ticker;
  Timer? _watchdog;
  Timer? _autosaveTimer;
  bool _clockRunning = false;
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  // callbacks the UI wires up
  VoidCallback? onSnap;
  VoidCallback? onFrameComplete;
  VoidCallback? onVictory;
  VoidCallback? onTimeUp;
  VoidCallback? onAutosave;
  VoidCallback? onTick; // cheap per-tick UI refresh (timer label)

  JigsawEngine({
    required this.rows,
    required this.cols,
    required this.pictureId,
    required this.seed,
    required this.mode,
    required this.pieceCount,
    this.snapRadiusFraction = 0.28,
  }) : hintBudget = mode == JigsawMode.relaxed
            ? 9999
            : (pieceCount <= 48 ? 3 : 5) {
    final rng = Random(seed);
    hTabs = List.generate(
        rows, (_) => List.generate(cols - 1, (_) => rng.nextBool() ? 1 : -1));
    vTabs = List.generate(
        rows - 1, (_) => List.generate(cols, (_) => rng.nextBool() ? 1 : -1));
    final order = List<int>.generate(rows * cols, (i) => i)..shuffle(rng);
    for (final id in order) {
      final r = id ~/ cols;
      final c = id % cols;
      final piece = JigsawPiece(
        id: id,
        row: r,
        col: c,
        x: 0,
        y: 0,
        clusterId: id,
        inTray: true,
      );
      pieces.add(piece);
      _byId[id] = piece;
      clusters[id] = {id};
    }
  }

  // ---------------------------------------------------------- par / stars
  static int parMs(int pieceCount) => switch (pieceCount) {
        24 => 3 * 60 * 1000,
        48 => 8 * 60 * 1000,
        96 => 20 * 60 * 1000,
        192 => 45 * 60 * 1000,
        _ => 8 * 60 * 1000,
      };

  int get timeLimitMs => mode == JigsawMode.timed ? parMs(pieceCount) : 0;
  int get timeLeftMs =>
      timeLimitMs == 0 ? 0 : max(0, timeLimitMs - elapsedMs);

  int get finalTimeMs => elapsedMs + hintPenaltyMs;

  /// Star rating per RULES.md Section 8.
  int starRating() {
    final par = parMs(pieceCount);
    final t = finalTimeMs;
    if (t <= par && hintsUsed == 0) return 3;
    if (t <= par * 1.5) return 2;
    return 1;
  }

  double get completion {
    if (pieces.isEmpty) return 0;
    var snapped = 0;
    for (final p in pieces) {
      if (clusters[p.clusterId]!.length > 1) snapped++;
    }
    return snapped / pieces.length;
  }

  int get largestClusterSize {
    var m = 0;
    for (final s in clusters.values) {
      if (s.length > m) m = s.length;
    }
    return m;
  }

  // ------------------------------------------------------------- lifecycle
  /// Start the engine timers. Call once when the game screen opens.
  void start() {
    if (_disposed || phase != JigsawPhase.idle) return;
    phase = JigsawPhase.playing;
    _armTimers();
    notifyListeners();
  }

  /// Arm (or re-arm) the engine-owned timers. Idempotent.
  void _armTimers() {
    if (_disposed) return;
    _ticker?.cancel();
    _watchdog?.cancel();
    _autosaveTimer?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_disposed) return;
      if (phase == JigsawPhase.playing && _clockRunning && !_pausedByLifecycle) {
        elapsedMs += 250;
        onTick?.call();
        if (mode == JigsawMode.timed && timeLimitMs > 0 &&
            elapsedMs >= timeLimitMs) {
          phase = JigsawPhase.timeUp;
          _clockRunning = false;
          onTimeUp?.call();
          notifyListeners();
        }
      }
    });
    _autosaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_disposed) return;
      if (phase == JigsawPhase.playing) onAutosave?.call();
    });
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _guard());
  }

  /// The watchdog: restarts a dead clock ticker, cancels stale drags,
  /// and validates cluster invariants. Runs on the engine's own timer —
  /// never on UI state.
  void _guard() {
    if (_disposed) return;
    // 1. Clock ticker must be alive while playing — re-arm if it died.
    if (phase == JigsawPhase.playing &&
        (_ticker == null || !_ticker!.isActive)) {
      _armTimers();
    }
    // 2. Stale drag: no gesture update for 15s -> cancel and restore
    // pre-drag positions (covers app-backgrounded-mid-drag).
    if (_dragIds.isNotEmpty &&
        DateTime.now().difference(_dragLastUpdate) >
            const Duration(seconds: 15)) {
      _restorePositions(_dragIds, _dragStart);
      _dragIds = {};
      _dragStart.clear();
      notifyListeners();
    }
    // 3. Cluster invariant: every piece belongs to exactly one cluster.
    assert(() {
      final seen = <int>{};
      for (final e in clusters.entries) {
        for (final id in e.value) {
          assert(!seen.contains(id), 'piece $id in two clusters');
          seen.add(id);
        }
      }
      assert(seen.length == pieces.length, 'cluster coverage broken');
      return true;
    }());
  }

  /// First piece touch starts the clock (RULES.md test 2).
  void noteFirstTouch() {
    if (!_clockRunning && phase == JigsawPhase.playing) {
      _clockRunning = true;
    }
  }

  void pauseGame() {
    if (phase != JigsawPhase.playing) return;
    phase = JigsawPhase.paused;
    _pausedByLifecycle = false;
    notifyListeners();
  }

  void resumeGame() {
    if (phase != JigsawPhase.paused) return;
    phase = JigsawPhase.playing;
    notifyListeners();
  }

  /// Keep puzzling after time-up: switch to classic scoring.
  void continueAfterTimeUp() {
    if (phase != JigsawPhase.timeUp) return;
    phase = JigsawPhase.playing;
    notifyListeners();
  }

  void onAppPaused() {
    _pausedByLifecycle = true;
  }

  void onAppResumed() {
    _pausedByLifecycle = false;
  }

  // ----------------------------------------------------------------- drag
  JigsawPiece piece(int id) => _byId[id]!;

  /// Ids of the currently dragged cluster (empty when not dragging).
  Set<int> get dragIds => Set.of(_dragIds);

  /// Ghost preview target for the dragged anchor: the exact position it
  /// would snap to if its nearest correct neighbor is within 2x the snap
  /// radius. Null when no neighbor is near.
  Offset? ghostPreview() {
    if (_dragIds.isEmpty || phase != JigsawPhase.playing) return null;
    final p = piece(_dragIds.first);
    final radius = snapRadiusFraction * cell * 2;
    Offset? best;
    var bestDist = double.infinity;
    for (final n in _gridNeighbors(p)) {
      final q = piece(n);
      if (q.inTray || q.clusterId == p.clusterId) continue;
      final ex = q.x + (p.col - q.col) * cell;
      final ey = q.y + (p.row - q.row) * cell;
      final d = (Offset(p.x, p.y) - Offset(ex, ey)).distance;
      if (d <= radius && d < bestDist) {
        bestDist = d;
        best = Offset(ex, ey);
      }
    }
    return best;
  }

  /// Begin dragging the cluster containing [pieceId]. Returns the ids of
  /// the whole cluster (they move as one rigid unit — RULES.md Section 4).
  Set<int> beginDrag(int pieceId) {
    if (phase != JigsawPhase.playing) return {};
    // Never orphan an in-flight drag: restore it first.
    if (_dragIds.isNotEmpty) cancelDrag();
    noteFirstTouch();
    final p = piece(pieceId);
    final cid = p.clusterId;
    _dragIds = Set.of(clusters[cid]!);
    _dragStart.clear();
    for (final id in _dragIds) {
      final q = piece(id);
      _dragStart[id] = Offset(q.x, q.y);
    }
    _dragLastUpdate = DateTime.now();
    selectedPieceId = pieceId;
    notifyListeners();
    return _dragIds;
  }

  void updateDrag(Offset delta) {
    if (_dragIds.isEmpty || phase != JigsawPhase.playing) return;
    for (final id in _dragIds) {
      final p = piece(id);
      p.x += delta.dx;
      p.y += delta.dy;
    }
    _dragLastUpdate = DateTime.now();
    notifyListeners();
  }

  /// Cancel the in-flight drag and restore pre-drag positions.
  /// Used when a pinch gesture interrupts a piece drag.
  void cancelDrag() {
    if (_dragIds.isEmpty) return;
    _restorePositions(_dragIds, _dragStart);
    _dragIds = {};
    _dragStart.clear();
    notifyListeners();
  }

  /// End a drag at the given mat-space drop point.
  ///
  /// [dropPoint] is the mat-relative point of the drop (for tray detection
  /// the UI passes [droppedOnTray]). [matBounds] is the playable mat rect in
  /// mat units; a drop whose piece-center leaves it springs back (RULES 5).
  DropResult endDrag({
    required Rect matBounds,
    required bool droppedOnTray,
  }) {
    if (_dragIds.isEmpty || phase != JigsawPhase.playing) {
      return const DropResult();
    }
    final dragged = Set.of(_dragIds);
    final dragStart = Map.of(_dragStart);
    _dragIds = {};
    _dragStart.clear();

    // Anchor = first dragged piece (the one actually touched).
    final anchor = piece(dragged.first);

    if (droppedOnTray) {
      // Return to tray (RULES.md Section 4).
      for (final id in dragged) {
        piece(id).inTray = true;
      }
      _restorePositions(dragged, dragStart);
      moves++;
      notifyListeners();
      return const DropResult(returnedToTray: true);
    }

    // Out-of-bounds: piece center must be on the mat (RULES.md 12).
    final center = Offset(anchor.x + cell / 2, anchor.y + cell / 2);
    if (!matBounds.contains(center)) {
      _restorePositions(dragged, dragStart);
      notifyListeners();
      return const DropResult(outOfBounds: true);
    }

    // Snap attempt: find the closest correct mating pair within the
    // snap radius (28% of edge, 40% generous — RULES.md Section 7).
    // Pieces dropped straight from the tray can snap into place too
    // (RULES.md Section 12: final-piece-from-tray victory).
    final radius = snapRadiusFraction * cell;
    int? bestPiece;
    int? bestTargetCid; // cluster of the exact piece we snapped onto
    Offset? bestDelta;
    var bestDist = double.infinity;
    for (final id in dragged) {
      final p = piece(id);
      for (final n in _gridNeighbors(p)) {
        final q = piece(n);
        if (q.inTray) continue;
        if (q.clusterId == p.clusterId) continue; // same cluster: nothing to do
        // Expected position of p given q's actual position.
        final ex = q.x + (p.col - q.col) * cell;
        final ey = q.y + (p.row - q.row) * cell;
        final d = (Offset(p.x, p.y) - Offset(ex, ey)).distance;
        if (d <= radius && d < bestDist) {
          bestDist = d;
          bestPiece = id;
          bestTargetCid = q.clusterId;
          bestDelta = Offset(ex - p.x, ey - p.y);
        }
      }
    }

    moves++;
    if (bestPiece != null && bestDelta != null) {
      // Snap: shift the whole dragged group into alignment, then merge.
      for (final id in dragged) {
        final p = piece(id);
        p.x += bestDelta.dx;
        p.y += bestDelta.dy;
        p.inTray = false;
      }
      final anchorPiece = piece(bestPiece);
      // Merge with the cluster of the exact piece we snapped onto
      // (not just any neighbor — that stuck pieces to the wrong cluster).
      final otherCid = bestTargetCid;
      final myCid = anchorPiece.clusterId;
      final merged = <int>[];
      if (otherCid != null && otherCid != myCid) {
        merged.addAll(clusters[otherCid]!);
        for (final id in clusters[otherCid]!) {
          piece(id).clusterId = myCid;
        }
        clusters[myCid]!.addAll(clusters[otherCid]!);
        clusters.remove(otherCid);
      }
      merged.addAll(dragged);
      notifyListeners();
      onSnap?.call();
      onAutosave?.call();

      final frameDone = _checkFrameComplete();
      final won = largestClusterSize == pieces.length;
      if (won && !victoryAnnounced) {
        victoryAnnounced = true;
        phase = JigsawPhase.victory;
        _clockRunning = false;
        onVictory?.call();
      }
      return DropResult(
        snapped: true,
        mergedPieceIds: merged,
        victory: won,
        frameComplete: frameDone,
        snapFlashAt: Offset(anchorPiece.x + cell / 2, anchorPiece.y + cell / 2),
      );
    }

    // No snap: the piece simply rests where dropped (RULES.md Section 5).
    for (final id in dragged) {
      piece(id).inTray = false;
    }
    anchor.inTray = false;
    notifyListeners();
    return const DropResult(noFit: true);
  }

  void _restorePositions(Set<int> dragged, Map<int, Offset> start) {
    for (final id in dragged) {
      final s = start[id];
      if (s != null) {
        piece(id).x = s.dx;
        piece(id).y = s.dy;
      }
    }
  }

  /// Grid neighbors of [p] (up/down/left/right), as piece ids.
  List<int> _gridNeighbors(JigsawPiece p) {
    final out = <int>[];
    if (p.row > 0) out.add(p.id - cols);
    if (p.row < rows - 1) out.add(p.id + cols);
    if (p.col > 0) out.add(p.id - 1);
    if (p.col < cols - 1) out.add(p.id + 1);
    return out;
  }

  /// The cluster id of a correct neighbor of [anchor] that is NOT in
  
  bool _checkFrameComplete() {
    if (frameAnnounced) return false;
    int? cid;
    for (final p in pieces) {
      if (!p.isEdgeOf(rows, cols)) continue;
      if (p.inTray) return false;
      cid ??= p.clusterId;
      if (p.clusterId != cid) return false;
    }
    frameAnnounced = true;
    onFrameComplete?.call();
    return true;
  }

  // ----------------------------------------------------------------- hint
  /// The librarian's suggestion (RULES.md Section 11):
  /// 1. a tray piece that mates with the selected cluster;
  /// 2. else a random unplaced edge piece;
  /// 3. else a random loose piece.
  /// Returns the piece id to highlight, or null when the budget is spent.
  int? useHint() {
    if (phase != JigsawPhase.playing) return null;
    if (mode != JigsawMode.relaxed && hintsUsed >= hintBudget) return null;
    int? pick;
    // 1. neighbor of the selected cluster, sitting in the tray.
    if (selectedPieceId != null) {
      final sel = piece(selectedPieceId!);
      final selCid = sel.clusterId;
      for (final p in pieces) {
        if (!p.inTray) continue;
        for (final n in _gridNeighbors(p)) {
          if (piece(n).clusterId == selCid) {
            pick = p.id;
            break;
          }
        }
        if (pick != null) break;
      }
    }
    // 2. random unplaced edge piece.
    pick ??= _randomLoose(preferEdge: true);
    // 3. any random loose piece.
    pick ??= _randomLoose(preferEdge: false);
    if (pick == null) return null;
    if (mode != JigsawMode.relaxed) {
      hintsUsed++;
      hintPenaltyMs += 30000; // +30s per hint (RULES.md Section 7)
    }
    notifyListeners();
    return pick;
  }

  int? _randomLoose({required bool preferEdge}) {
    final rng = Random();
    final loose = pieces.where((p) => p.inTray).toList();
    if (loose.isEmpty) return null;
    final edge = loose.where((p) => p.isEdgeOf(rows, cols)).toList();
    final pool = (preferEdge && edge.isNotEmpty) ? edge : loose;
    return pool[rng.nextInt(pool.length)].id;
  }

  int get hintsLeft =>
      mode == JigsawMode.relaxed ? 9999 : max(0, hintBudget - hintsUsed);

  // ----------------------------------------------------------------- save
  Map<String, dynamic> toJson() {
    // In-flight drags are discarded on restore (RULES.md 12): the save
    // uses pre-drag positions for dragged pieces.
    final savedPieces = <Map<String, dynamic>>[];
    for (final p in pieces) {
      final s = _dragStart[p.id];
      savedPieces.add({
        'id': p.id,
        'x': s?.dx ?? p.x,
        'y': s?.dy ?? p.y,
        'c': p.clusterId,
        't': p.inTray ? 1 : 0,
      });
    }
    return {
      'v': 1,
      'rows': rows,
      'cols': cols,
      'pictureId': pictureId,
      'seed': seed,
      'mode': mode,
      'pieceCount': pieceCount,
      'snap': snapRadiusFraction,
      'elapsedMs': elapsedMs,
      'moves': moves,
      'hintsUsed': hintsUsed,
      'hintPenaltyMs': hintPenaltyMs,
      'frameAnnounced': frameAnnounced,
      'pieces': savedPieces,
    };
  }

  String encode() => jsonEncode(toJson());

  /// Restore a saved engine. Returns null when the save fails validation
  /// (corrupt save -> fresh start, never a crash — RULES.md 12).
  static JigsawEngine? decode(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['v'] != 1) return null;
      final rows = m['rows'] as int;
      final cols = m['cols'] as int;
      final e = JigsawEngine(
        rows: rows,
        cols: cols,
        pictureId: m['pictureId'] as int,
        seed: m['seed'] as int,
        mode: m['mode'] as int,
        pieceCount: m['pieceCount'] as int,
        snapRadiusFraction: (m['snap'] as num).toDouble(),
      );
      final plist = m['pieces'] as List;
      if (plist.length != rows * cols) return null;
      final seenCid = <int>{};
      for (final pm in plist) {
        final p = pm as Map<String, dynamic>;
        final id = p['id'] as int;
        if (id < 0 || id >= rows * cols) return null;
        final piece = e._byId[id];
        if (piece == null) return null;
        piece.x = (p['x'] as num).toDouble();
        piece.y = (p['y'] as num).toDouble();
        piece.clusterId = p['c'] as int;
        piece.inTray = (p['t'] as int) == 1;
        seenCid.add(piece.clusterId);
      }
      // Rebuild clusters from piece assignments.
      e.clusters.clear();
      for (final p in e.pieces) {
        e.clusters.putIfAbsent(p.clusterId, () => <int>{}).add(p.id);
      }
      e.elapsedMs = m['elapsedMs'] as int;
      e.moves = m['moves'] as int;
      e.hintsUsed = m['hintsUsed'] as int;
      e.hintPenaltyMs = m['hintPenaltyMs'] as int;
      e.frameAnnounced = m['frameAnnounced'] as bool;
      return e;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- tray
  /// Loose pieces in shuffled tray order.
  List<JigsawPiece> get trayPieces =>
      pieces.where((p) => p.inTray).toList();

  /// Mat pieces in drop order (later-moved on top — RULES.md 12).
  List<JigsawPiece> get matPieces =>
      pieces.where((p) => !p.inTray).toList();

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _watchdog?.cancel();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  static String formatMs(int ms) {
    final s = (ms / 1000).floor();
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
