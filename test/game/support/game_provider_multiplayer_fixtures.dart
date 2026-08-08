part of '../game_providers_test.dart';

final class _MutableInt {
  int value = 0;
}

final class _LiveCommandFixture {
  const _LiveCommandFixture({
    required this.commander,
    required this.save,
    required this.container,
    required this.stream,
    required this.renderer,
    required this.snapshotStore,
    required this.fallbackCommands,
  });

  final GameUnit commander;
  final GameSave save;
  final ProviderContainer container;
  final _FakeMultiplayerStream stream;
  final _SpyGameRenderer renderer;
  final _FakeSnapshotStore snapshotStore;
  final _MutableInt fallbackCommands;

  Future<void> bootstrap() async {
    await container.read(gameStateProvider(save.id).future);
    await stream.listened;
  }
}

_LiveCommandFixture _createLiveCommandFixture() {
  final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
  final save = _makeSave(
    players: const [_player1],
    gameMode: GameMode.multiplayer,
  );
  final gameRepository = _FakeGameRepository(
    snapshots: {
      save.id: _makeSnapshot(save: save, units: [commander]),
    },
  );
  final renderer = _SpyGameRenderer(mapData: _makeLandMap());
  final snapshotStore = _FakeSnapshotStore();
  final stream = _FakeMultiplayerStream();
  final fallbackCommands = _MutableInt();
  final commandDispatcher = _FakeWireCommandDispatcher(({
    required saveId,
    required token,
    required afterOffset,
    required wire,
    required clientMessageId,
  }) async {
    fallbackCommands.value += 1;
    throw StateError('Expected command to use the live match channel.');
  });
  final container = ProviderContainer(
    overrides: [
      activeGameSessionProvider.overrideWithValue(
        _makeSession(mapData: _makeLandMap(), gameMode: GameMode.multiplayer),
      ),
      activeGameRendererProvider.overrideWithValue(renderer),
      activeRendererViewModelProvider.overrideWithValue(
        TestRendererViewModel(renderer),
      ),
      gameRepositoryProvider.overrideWithValue(gameRepository),
      eventLogProvider.overrideWithValue(_FakeEventLog()),
      networkEventLogProvider.overrideWith(
        (ref) => ref.watch(eventLogProvider),
      ),
      networkGameRepositoryProvider.overrideWith(
        (ref) => ref.watch(gameRepositoryProvider),
      ),
      snapshotStoreProvider.overrideWithValue(snapshotStore),
      wireCommandDispatcherProvider.overrideWithValue(commandDispatcher),
      multiplayerStreamConnectorProvider.overrideWithValue(stream.connector),
      networkSessionProvider.overrideWithValue(
        api.NetworkSession(
          userId: 'user_1',
          playerId: 'player_1',
          token: AuthToken('jwt-token'),
          matchId: save.id,
          connectionState: const NetworkConnectionState(
            status: NetworkConnectionStatus.connected,
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(stream.close);
  final subscription = container.listen(gameStateProvider(save.id), (_, _) {});
  addTearDown(subscription.close);
  return _LiveCommandFixture(
    commander: commander,
    save: save,
    container: container,
    stream: stream,
    renderer: renderer,
    snapshotStore: snapshotStore,
    fallbackCommands: fallbackCommands,
  );
}
