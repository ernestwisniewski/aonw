import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

DominationProgressEntry _entry(
  String playerId, {
  int controlled = 0,
  double controlPercent = 0,
  int holdTurns = 0,
  int validTiles = 100,
  double requiredPercent = 60,
  int requiredHold = 3,
}) {
  return DominationProgressEntry(
    playerId: playerId,
    controlledTileCount: controlled,
    validTileCount: validTiles,
    controlPercent: controlPercent,
    requiredControlPercent: requiredPercent,
    holdTurns: holdTurns,
    requiredHoldTurns: requiredHold,
  );
}

DominationProgressEntry _ready(
  String playerId, {
  int controlled = 70,
  int holdTurns = 3,
}) {
  return _entry(
    playerId,
    controlled: controlled,
    controlPercent: 70,
    holdTurns: holdTurns,
  );
}

void main() {
  group('DominationProgressSnapshot', () {
    test('entryFor returns the matching entry or null', () {
      final snapshot = DominationProgressSnapshot(
        entries: [_entry('p1', controlled: 10), _entry('p2', controlled: 20)],
        validTileCount: 100,
      );

      expect(snapshot.entryFor('p2')?.controlledTileCount, 20);
      expect(snapshot.entryFor('unknown'), isNull);
    });

    test('leader is null without entries', () {
      const snapshot = DominationProgressSnapshot(
        entries: [],
        validTileCount: 100,
      );

      expect(snapshot.leader, isNull);
    });

    test('leader prefers control, then hold turns, then player id', () {
      final byControl = DominationProgressSnapshot(
        entries: [_entry('p1', controlled: 10), _entry('p2', controlled: 30)],
        validTileCount: 100,
      );
      final byHold = DominationProgressSnapshot(
        entries: [
          _entry('p1', controlled: 30, holdTurns: 1),
          _entry('p2', controlled: 30, holdTurns: 2),
        ],
        validTileCount: 100,
      );
      final byId = DominationProgressSnapshot(
        entries: [
          _entry('p2', controlled: 30, holdTurns: 2),
          _entry('p1', controlled: 30, holdTurns: 2),
        ],
        validTileCount: 100,
      );

      expect(byControl.leader?.playerId, 'p2');
      expect(byHold.leader?.playerId, 'p2');
      expect(byId.leader?.playerId, 'p1');
    });

    test('topOpponentFor skips the requesting player', () {
      final snapshot = DominationProgressSnapshot(
        entries: [_entry('p1', controlled: 40), _entry('p2', controlled: 10)],
        validTileCount: 100,
      );

      expect(snapshot.topOpponentFor('p1')?.playerId, 'p2');
      expect(snapshot.topOpponentFor('p2')?.playerId, 'p1');
    });

    test('topOpponentFor is null without opponents', () {
      final snapshot = DominationProgressSnapshot(
        entries: [_entry('p1', controlled: 40)],
        validTileCount: 100,
      );

      expect(snapshot.topOpponentFor('p1'), isNull);
    });

    test('winnerCandidate is null when nobody can win yet', () {
      final snapshot = DominationProgressSnapshot(
        entries: [
          _entry('p1', controlled: 70, controlPercent: 70, holdTurns: 2),
          _entry('p2', controlled: 10, controlPercent: 10, holdTurns: 9),
        ],
        validTileCount: 100,
      );

      expect(snapshot.winnerCandidate(), isNull);
    });

    test('winnerCandidate returns the only ready player', () {
      final snapshot = DominationProgressSnapshot(
        entries: [_ready('p1'), _entry('p2', controlled: 10)],
        validTileCount: 100,
      );

      expect(snapshot.winnerCandidate()?.playerId, 'p1');
    });

    test('winnerCandidate is null on an exact ready tie', () {
      final snapshot = DominationProgressSnapshot(
        entries: [_ready('p1'), _ready('p2')],
        validTileCount: 100,
      );

      expect(snapshot.winnerCandidate(), isNull);
    });

    test('winnerCandidate resolves a ready tie by control and hold', () {
      final byControl = DominationProgressSnapshot(
        entries: [_ready('p1', controlled: 80), _ready('p2')],
        validTileCount: 100,
      );
      final byHold = DominationProgressSnapshot(
        entries: [_ready('p1'), _ready('p2', holdTurns: 5)],
        validTileCount: 100,
      );

      expect(byControl.winnerCandidate()?.playerId, 'p1');
      expect(byHold.winnerCandidate()?.playerId, 'p2');
    });
  });
}
