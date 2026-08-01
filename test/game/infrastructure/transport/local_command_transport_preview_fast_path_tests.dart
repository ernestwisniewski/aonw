part of 'local_command_transport_test.dart';

void _registerPreviewFastPathTests() {
  test('applies client-only commands without replay log entries', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final save = _save(players: const [_player1]);
    final repository = _MemoryGameRepository(
      GameSnapshotFactory.create(save: save, units: [commander]),
    );
    final eventLog = _MemoryEventLog();
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: _map()),
      gameRepository: repository,
      eventLog: eventLog,
      snapshotStore: _MemorySnapshotStore(),
      clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
    );

    final result = await transport.dispatchAcrossBoundary(
      saveId: save.id,
      currentState: GameClientState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      ),
      command: SelectUnitCommand(commander.id),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    expect(result.offset, -1);
    expect(result.state.selectedUnitId, commander.id);
    expect(result.snapshot, isNull);
    expect(result.storedSnapshot, isFalse);
    expect(eventLog.commands, isEmpty);
    expect(repository.snapshot.eventLogOffset, 0);
  });

  test('previews movement without accessing persistence', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final save = _save(players: const [_player1]);
    final mapData = _map();
    final repository = _MemoryGameRepository(
      GameSnapshotFactory.create(save: save, units: [commander]),
    );
    final eventLog = _MemoryEventLog();
    final snapshotStore = _MemorySnapshotStore();
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: mapData),
      gameRepository: repository,
      eventLog: eventLog,
      snapshotStore: snapshotStore,
      clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
    );

    final result = await transport.dispatchAcrossBoundary(
      saveId: save.id,
      currentState: GameClientState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: mapData.tileAt(0, 0)),
          moveCommandActive: true,
        ),
      ),
      command: const TileTappedCommand(1, 0),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    expect(result.state.movePreview?.targetCol, 1);
    expect(result.snapshot, isNull);
    expect(result.offset, -1);
    expect(repository.loadCalls, 0);
    expect(repository.saveCalls, 0);
    expect(eventLog.accessCalls, 0);
    expect(snapshotStore.accessCalls, 0);
  });
}
