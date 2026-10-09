import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw/engine/jigsaw_engine.dart';

/// Engine smoke tests against RULES.md.
void main() {
  JigsawEngine make({int cols = 6, int rows = 4}) => JigsawEngine(
        rows: rows,
        cols: cols,
        pictureId: 0,
        seed: 42,
        mode: JigsawMode.classic,
        pieceCount: cols * rows,
      );

  test('setup: 24 loose pieces in tray, empty mat, timer at 0', () {
    final e = make();
    expect(e.pieces.length, 24);
    expect(e.trayPieces.length, 24);
    expect(e.matPieces, isEmpty);
    expect(e.elapsedMs, 0);
    expect(e.completion, 0);
    expect(e.phase, JigsawPhase.idle);
    e.dispose();
  });

  test('first touch starts the clock; drag+drop counts a move', () async {
    final e = make();
    e.start();
    final p = e.pieces.first;
    e.beginDrag(p.id);
    e.updateDrag(const Offset(300, 200));
    final r = e.endDrag(
      matBounds: const Rect.fromLTWH(0, 0, 600, 400),
      droppedOnTray: false,
    );
    expect(e.moves, 1);
    expect(r.noFit, isTrue); // lone piece, nothing to snap to
    expect(e.matPieces.length, 1);
    e.dispose();
  });

  test('correct neighbors snap and merge into one cluster', () {
    final e = make();
    e.start();
    // Place piece (0,0) then its right neighbor (0,1) next to it.
    final a = e.piece(0);
    final b = e.piece(1);
    e.beginDrag(a.id);
    e.updateDrag(const Offset(300, 300) - Offset(a.x, a.y));
    e.endDrag(
        matBounds: const Rect.fromLTWH(0, 0, 600, 400),
        droppedOnTray: false);
    // Drop b so its left edge meets a's right edge (within 28% radius).
    e.beginDrag(b.id);
    final target =
        Offset(a.x + JigsawEngine.cell, a.y) - Offset(b.x, b.y);
    e.updateDrag(target + const Offset(5, 0)); // 5 units off: within radius
    final r = e.endDrag(
        matBounds: const Rect.fromLTWH(0, 0, 1200, 800),
        droppedOnTray: false);
    expect(r.snapped, isTrue, reason: 'true neighbors should snap');
    expect(e.piece(0).clusterId, e.piece(1).clusterId);
    expect(e.completion, closeTo(2 / 24, 0.001));
    e.dispose();
  });

  test('wrong neighbor never snaps', () {
    final e = make();
    e.start();
    final a = e.piece(0);
    final far = e.piece(23); // opposite corner, not a neighbor
    e.beginDrag(a.id);
    e.updateDrag(const Offset(300, 300) - Offset(a.x, a.y));
    e.endDrag(
        matBounds: const Rect.fromLTWH(0, 0, 600, 400),
        droppedOnTray: false);
    e.beginDrag(far.id);
    e.updateDrag(
        (Offset(a.x, a.y) - Offset(far.x, far.y)) + const Offset(5, 0));
    final r = e.endDrag(
        matBounds: const Rect.fromLTWH(0, 0, 1200, 800),
        droppedOnTray: false);
    expect(r.snapped, isFalse);
    expect(r.noFit, isTrue);
    expect(e.piece(0).clusterId == e.piece(23).clusterId, isFalse);
    e.dispose();
  });

  test('out-of-bounds drop springs back with no move counted', () {
    final e = make();
    e.start();
    final p = e.pieces.first;
    e.beginDrag(p.id);
    e.updateDrag(const Offset(5000, 5000));
    final r = e.endDrag(
      matBounds: const Rect.fromLTWH(0, 0, 600, 400),
      droppedOnTray: false,
    );
    expect(r.outOfBounds, isTrue);
    expect(e.moves, 0);
    expect(e.piece(p.id).x, 0);
    e.dispose();
  });

  test('hint returns a tray piece and banks +30s penalty', () {
    final e = make();
    e.start();
    final id = e.useHint();
    expect(id, isNotNull);
    expect(e.piece(id!).inTray, isTrue);
    expect(e.hintsUsed, 1);
    expect(e.hintPenaltyMs, 30000);
    e.dispose();
  });

  test('save/restore roundtrip preserves everything', () {
    final e = make();
    e.start();
    final a = e.piece(0);
    e.beginDrag(a.id);
    e.updateDrag(const Offset(300, 300) - Offset(a.x, a.y));
    e.endDrag(
        matBounds: const Rect.fromLTWH(0, 0, 600, 400),
        droppedOnTray: false);
    final raw = e.encode();
    final d = JigsawEngine.decode(raw);
    expect(d, isNotNull);
    expect(d!.pieces.length, 24);
    expect(d.matPieces.length, 1);
    expect(d.moves, e.moves);
    expect(d.piece(0).x, e.piece(0).x);
    e.dispose();
    d.dispose();
  });

  test('corrupt save returns null (never crashes)', () {
    expect(JigsawEngine.decode('not json'), isNull);
    expect(JigsawEngine.decode('{"v":999}'), isNull);
  });

  test('star rating: 3 stars under par with zero hints', () {
    final e = make();
    e.start();
    e.elapsedMs = 2 * 60 * 1000; // 2:00 < 3:00 par for 24 pieces
    expect(e.starRating(), 3);
    e.dispose();
  });
}
