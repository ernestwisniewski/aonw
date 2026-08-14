part of 'local_command_transport_test.dart';

void _registerNativeBackendTests() {
  test(
    'uses a supported preferred backend without loading Dart state',
    () async {
      final state = GameClientState(activePlayerId: 'player_1');
      final expected = CommandTransportResult(
        state: state,
        snapshot: null,
        offset: 7,
      );
      final repository = _MemoryGameRepository(
        GameSnapshotFactory.create(save: _save(players: const [_player1])),
      );
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
        eventLog: _MemoryEventLog(),
        snapshotStore: _MemorySnapshotStore(),
        preferredEngine: _FixedLocalEnginePort(expected),
      );

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const CancelUnitActionCommand('unit_1'),
      );

      expect(result, same(expected));
      expect(repository.loadCalls, 0);
    },
  );

  test('falls back to the Dart reducer when backend is unsupported', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final save = _save(players: const [_player1]);
    final repository = _MemoryGameRepository(
      GameSnapshotFactory.create(save: save, units: [commander]),
    );
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: _map()),
      gameRepository: repository,
      eventLog: _MemoryEventLog(),
      snapshotStore: _MemorySnapshotStore(),
      preferredEngine: const _FixedLocalEnginePort(null),
    );

    final result = await transport.dispatch(
      saveId: save.id,
      currentState: GameClientState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      ),
      command: MoveUnitCommand(commander.id, 1, 0),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    expect(result.accepted, isTrue);
    expect(repository.snapshot.units.single.col, 1);
  });

  test('does not mask an active engine failure with Dart fallback', () async {
    final repository = _MemoryGameRepository(
      GameSnapshotFactory.create(save: _save(players: const [_player1])),
    );
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: _map()),
      gameRepository: repository,
      eventLog: _MemoryEventLog(),
      snapshotStore: _MemorySnapshotStore(),
      preferredEngine: const _ThrowingLocalEnginePort(),
    );

    await expectLater(
      transport.dispatch(
        saveId: 'save_1',
        currentState: GameClientState(activePlayerId: 'player_1'),
        command: const CancelUnitActionCommand('unit_1'),
      ),
      throwsStateError,
    );
    expect(repository.loadCalls, 0);
  });
}

final class _FixedLocalEnginePort implements LocalEnginePort {
  const _FixedLocalEnginePort(this.result);

  final CommandTransportResult? result;

  @override
  Future<CommandTransportResult?> dispatchIfSupported({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    required GameCommandContext context,
    required bool fromMovePreviewConfirmation,
  }) async => result;
}

final class _ThrowingLocalEnginePort implements LocalEnginePort {
  const _ThrowingLocalEnginePort();

  @override
  Future<CommandTransportResult?> dispatchIfSupported({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    required GameCommandContext context,
    required bool fromMovePreviewConfirmation,
  }) async => throw StateError('Native engine failed.');
}
