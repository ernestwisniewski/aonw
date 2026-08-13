part of 'local_command_transport_test.dart';

void _registerMovementPresentationTransportTests() {
  test(
    'logs authoritative movement instead of tile tap confirmation',
    () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _save(players: const [_player1]);
      final mapData = _map();
      final repository = _MemoryGameRepository(
        GameSnapshotFactory.create(save: save, units: [commander]),
      );
      final eventLog = _MemoryEventLog();
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: mapData),
        gameRepository: repository,
        eventLog: eventLog,
        snapshotStore: _MemorySnapshotStore(),
        clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
      );
      final selectedState = GameClientState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: mapData.tileAt(0, 0)),
          moveCommandActive: true,
        ),
      );

      final preview = await transport.dispatchAcrossBoundary(
        saveId: save.id,
        currentState: selectedState,
        command: const TileTappedCommand(1, 0),
        context: const GameCommandContext(actorPlayerId: 'player_1'),
      );
      final moved = await transport.dispatchAcrossBoundary(
        saveId: save.id,
        currentState: preview.state,
        command: const TileTappedCommand(1, 0),
        context: const GameCommandContext(actorPlayerId: 'player_1'),
      );

      expect(preview.offset, -1);
      expect(preview.state.movePreview?.targetCol, 1);
      expect(eventLog.commands, hasLength(1));
      expect(
        eventLog.commands.single.command,
        isA<MoveUnitCommand>()
            .having((command) => command.unitId, 'unitId', commander.id)
            .having((command) => command.targetCol, 'targetCol', 1)
            .having((command) => command.targetRow, 'targetRow', 0),
      );
      expect(moved.offset, 1);
      expect(moved.state.units.single.col, 1);
      expect(moved.state.movePreview, isNull);
      expect(moved.state.moveCommandActive, isTrue);
      expect(repository.snapshot.eventLogOffset, 1);
    },
  );

  test('rejected move preview confirmation clears stale targeting', () async {
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 0);
    final save = _save(players: const [_player1]);
    final mapData = _map();
    final repository = _MemoryGameRepository(
      GameSnapshotFactory.create(save: save, units: [commander]),
    );
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: mapData),
      gameRepository: repository,
      eventLog: _MemoryEventLog(),
      snapshotStore: _MemorySnapshotStore(),
      clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
    );
    final preview = UnitMovementPlan(
      unitId: commander.id,
      targetCol: 0,
      targetRow: 0,
      totalCost: 0,
      availableMovementUnits: 0,
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      ],
    );
    final state = GameClientState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: InteractionState(
        selection: GameSelection.unit(commander, tile: mapData.tileAt(0, 0)),
        moveCommandActive: true,
        movePreview: preview,
      ),
    );

    final result = await transport.dispatchAcrossBoundary(
      saveId: save.id,
      currentState: state,
      command: const TileTappedCommand(0, 0),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    expect(result.state.units, state.units);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('queued move preview confirmation exits targeting mode', () async {
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 1);
    final save = _save(players: const [_player1]);
    final mapData = _map();
    final repository = _MemoryGameRepository(
      GameSnapshotFactory.create(save: save, units: [commander]),
    );
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: mapData),
      gameRepository: repository,
      eventLog: _MemoryEventLog(),
      snapshotStore: _MemorySnapshotStore(),
      clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
    );
    final selected = GameClientState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: InteractionState(
        selection: GameSelection.unit(commander, tile: mapData.tileAt(0, 0)),
        moveCommandActive: true,
      ),
    );

    final preview = await transport.dispatchAcrossBoundary(
      saveId: save.id,
      currentState: selected,
      command: const TileTappedCommand(2, 0),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );
    final result = await transport.dispatchAcrossBoundary(
      saveId: save.id,
      currentState: preview.state,
      command: const TileTappedCommand(2, 0),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    expect(result.state.units.single.col, 1);
    expect(result.state.units.single.queuedPath?.targetCol, 2);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });
}
