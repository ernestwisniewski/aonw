part of 'save_snapshot_test.dart';

void _registerSaveSnapshotReplayTests() {
  test('prepares and finalizes a replay turn losslessly', () {
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
    final savedAt = DateTime.utc(2026, 7, 28, 12, 30, 1);

    final prepared = snapshot.withReplayPlayerTurnsReset();
    final finalized = prepared.withReplayTurnFinalized(
      state: PersistentGameState.snapshot(
        playerGold: const {'p1': 10},
        runtimeState: GameRuntimeState(turnStartedAt: savedAt),
      ),
      savedAt: savedAt,
    );

    expect(prepared.session.turnStatesByPlayerId, const {
      'p1': PlayerTurnState.active,
      'p2': PlayerTurnState.active,
    });
    expect(finalized.domain.turn, 9);
    expect(finalized.session.turnStatesByPlayerId, const {
      'p1': PlayerTurnState.active,
      'p2': PlayerTurnState.active,
    });
    expect(finalized.metadata.savedAtUtc, savedAt);
    expect(finalized.persistedTurnStartedAt, savedAt);
    expect(finalized.eventLogOffset, 4);
    expect(finalized.playerGold, {'p1': 10});
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
