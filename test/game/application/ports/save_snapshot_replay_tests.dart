part of 'save_snapshot_test.dart';

void _registerSaveSnapshotReplayTests() {
  test('prepares replay player turns losslessly', () {
    final snapshot = SaveSnapshot.fromGameState(
      save: _save().copyWith(
        turn: 8,
        playerStates: const {
          'p1': PlayerTurnState.finished,
          'p2': PlayerTurnState.finished,
        },
        players: const [
          Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
          Player(id: 'p2', name: 'Bob', colorValue: 0xFFB83A3A),
        ],
      ),
      state: const GameState(playerGold: {'p1': 9}),
      eventLogOffset: 4,
    );

    final prepared = snapshot.withReplayPlayerTurnsReset();

    expect(prepared.session.turnStatesByPlayerId, const {
      'p1': PlayerTurnState.active,
      'p2': PlayerTurnState.active,
    });
    expect(prepared.domain.turn, snapshot.domain.turn);
    expect(prepared.metadata, snapshot.metadata);
    expect(prepared.eventLogOffset, 4);
    expect(prepared.playerGold, {'p1': 9});
  });

  test('keeps persisted turn start distinct from canonical fallback', () {
    final savedAt = DateTime.utc(2026, 1, 1);
    final snapshot = SaveSnapshot(
      save: _save().copyWith(gameMode: GameMode.multiplayer, savedAt: savedAt),
    );

    expect(snapshot.persistedTurnStartedAt, isNull);
    expect(snapshot.session.turnStartedAt, savedAt);
  });
}
