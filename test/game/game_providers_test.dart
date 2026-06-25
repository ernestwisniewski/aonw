import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart' as api;
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGameRepository implements GameRepository {
  final Map<String, SaveSnapshot> snapshots;
  final Map<String, GameSave>? saves;
  final bool throwOnLoad;
  final Completer<void>? loadGate;
  int loadCount = 0;

  _FakeGameRepository({
    Map<String, SaveSnapshot>? snapshots,
    this.saves,
    this.throwOnLoad = false,
    this.loadGate,
  }) : snapshots = snapshots ?? {};

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    return '$mapDisplayName ${now.year}';
  }

  @override
  Future<String> create(NewGameRequest request) async {
    final id = 'save_${snapshots.length + 1}';
    final save = GameSave(
      id: id,
      name: request.name,
      mapName: request.mapName,
      mapSource: request.mapSource,
      turn: 1,
      playerStates: {
        for (final player in request.players) player.id: PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 4, 16),
      camera: CameraState.zero,
      players: request.players,
      gameMode: request.gameMode,
    );
    snapshots[id] = SaveSnapshot(save: save);
    return id;
  }

  @override
  Future<List<GameSaveIndex>> list() async {
    return [
      for (final snapshot in snapshots.values)
        GameSaveIndex(
          id: snapshot.save.id,
          name: snapshot.save.name,
          mapName: snapshot.save.mapName,
          mapSource: snapshot.save.mapSource,
          turn: snapshot.save.turn,
          savedAt: snapshot.save.savedAt,
        ),
    ];
  }

  @override
  Future<SaveSnapshot> load(String saveId) async {
    await loadGate?.future;
    loadCount++;
    if (throwOnLoad) throw StateError('load failed');
    final save = saves?[saveId];
    if (save != null) return SaveSnapshot(save: save);
    final snapshot = snapshots[saveId];
    if (snapshot == null) throw StateError('missing save');
    return snapshot;
  }

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    saves?[snapshot.save.id] = snapshot.save;
    snapshots[snapshot.save.id] = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {
    saves?.remove(saveId);
    snapshots.remove(saveId);
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final snapshot = await load(saveId);
    final updated = snapshot.copyWith(
      save: snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? DateTime.now().toUtc(),
      ),
    );
    await save(updated);
    return updated;
  }
}

class _FakeEventLog implements EventLog {
  final commands = <LoggedCommand>[];

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.fold<int>(0, (latest, command) {
      return command.offset > latest ? command.offset : latest;
    });
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}

class _TrackedEventLog extends _FakeEventLog {
  int _inFlightOperations = 0;
  int maxConcurrentOperations = 0;

  Future<T> _track<T>(Future<T> Function() operation) async {
    _inFlightOperations++;
    if (_inFlightOperations > maxConcurrentOperations) {
      maxConcurrentOperations = _inFlightOperations;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    try {
      return await operation();
    } finally {
      _inFlightOperations--;
    }
  }

  @override
  Future<void> append(String saveId, LoggedCommand command) {
    return _track(() => super.append(saveId, command));
  }

  @override
  Future<int> latestOffset(String saveId) {
    return _track(() => super.latestOffset(saveId));
  }
}

class _FakeSnapshotStore implements SnapshotStore {
  final snapshots = <Snapshot>[];

  @override
  Future<Snapshot?> latest(String saveId) async {
    return snapshots.isEmpty ? null : snapshots.last;
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    snapshots.add(snapshot);
  }
}

class _FakeGameLogger implements GameLogger {
  final warnings = <({String tag, String message, Object? error})>[];

  @override
  void info(String tag, String message) {}

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    warnings.add((tag: tag, message: message, error: error));
  }
}

class _FakeMultiplayerStream {
  final _listenCompleter = Completer<void>();
  final clientMessages = <sp.MultiplayerClientMessage>[];
  late final _messages = StreamController<sp.MultiplayerServerMessage>(
    onListen: () {
      if (!_listenCompleter.isCompleted) _listenCompleter.complete();
    },
  );

  Future<void> get listened => _listenCompleter.future;

  MultiplayerStreamConnector get connector {
    return ({
      required matchId,
      required token,
      required afterOffset,
      required input,
    }) {
      input.listen(clientMessages.add);
      return _messages.stream;
    };
  }

  void add(sp.MultiplayerServerMessage message) {
    _messages.add(message);
  }

  Future<void> close() => _messages.close();
}

class _FakeWireCommandDispatcher implements WireCommandDispatcher {
  final Future<WireCommandAck> Function({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  })
  handler;

  const _FakeWireCommandDispatcher(this.handler);

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  }) {
    return handler(
      saveId: saveId,
      token: token,
      afterOffset: afterOffset,
      wire: wire,
    );
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time.');
}

List<T> _transportOverrides<T>() {
  return [
    eventLogProvider.overrideWithValue(_FakeEventLog()) as T,
    networkEventLogProvider.overrideWith((ref) => ref.watch(eventLogProvider))
        as T,
    networkGameRepositoryProvider.overrideWith(
          (ref) => ref.watch(gameRepositoryProvider),
        )
        as T,
    snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()) as T,
  ];
}

MapData _makeMap() => MapData(
  cols: 5,
  rows: 5,
  tiles: [
    for (int r = 0; r < 5; r++)
      for (int c = 0; c < 5; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);

MapData _makeLandMap() => MapData(
  cols: 5,
  rows: 5,
  tiles: [
    for (int r = 0; r < 5; r++)
      for (int c = 0; c < 5; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);

GameSave _makeSave({
  int turn = 1,
  List<Player> players = const [_player1],
  Map<String, PlayerTurnState>? playerStates,
  GameMode gameMode = GameMode.hotSeat,
}) => GameSave(
  id: 'save_1',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: turn,
  playerStates:
      playerStates ??
      {for (final player in players) player.id: PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: const CameraState(x: 4, y: 5, zoom: 1.25),
  players: players,
  gameMode: gameMode,
);

SaveSnapshot _makeSnapshot({
  GameSave? save,
  Map<String, int> playerColors = const {},
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  List<FieldImprovement> fieldImprovements = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  ResearchState research = ResearchState.empty,
  GameRuntimeState runtimeState = GameRuntimeState.empty,
  int eventLogOffset = 0,
}) {
  return SaveSnapshot(
    save: save ?? _makeSave(),
    playerColors: playerColors,
    units: units,
    cities: cities,
    fieldImprovements: fieldImprovements,
    fogOfWar: fogOfWar,
    research: research,
    runtimeState: runtimeState,
    eventLogOffset: eventLogOffset,
  );
}

GameSession _makeSession({
  String saveId = 'save_1',
  MapData? mapData,
  GameMode gameMode = GameMode.hotSeat,
}) {
  final map = mapData ?? _makeMap();
  return GameSession(
    mapData: map,
    viewMode: MapViewMode.tile,
    saveId: saveId,
    gameMode: gameMode,
  );
}

GameRenderer _makeRenderer() {
  return GameRenderer(
    mapData: _makeMap(),
    initialViewMode: MapViewMode.tile,
    onCommand: (_) async {},
  );
}

class _SpyGameRenderer extends GameRenderer {
  _SpyGameRenderer({MapData? mapData})
    : super(
        mapData: mapData ?? _makeMap(),
        initialViewMode: MapViewMode.tile,
        onCommand: (_) async {},
      );

  final handledEffects = <RendererEffect>[];

  @override
  Future<void> applyTransition(
    GameState state,
    Iterable<RendererEffect> effects,
  ) async {
    handledEffects.addAll(effects);
  }

  @override
  Future<void> handleEffects(Iterable<RendererEffect> effects) async {
    handledEffects.addAll(effects);
  }
}

void main() {
  group('GameSessionNotifier', () {
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);

    ProviderContainer makeContainer({
      required AsyncValue<MapData> mapAsync,
      AsyncValue<String?> imagePathAsync = const AsyncData(null),
      AsyncValue<CameraState?> cameraAsync = const AsyncData(null),
      AsyncValue<GameSave?> saveAsync = const AsyncData(null),
    }) {
      return ProviderContainer(
        overrides: [
          activeMapProvider(selection).overrideWithValue(mapAsync),
          mapImagePathProvider(selection).overrideWithValue(imagePathAsync),
          savedCameraProvider('save_1').overrideWithValue(cameraAsync),
          gameSaveProvider('save_1').overrideWithValue(saveAsync),
        ],
      );
    }

    test('resolves to GameSession when all providers are ready', () async {
      final container = makeContainer(mapAsync: AsyncData(_makeMap()));
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session, isNotNull);
      expect(session.viewMode, MapViewMode.graphic);
      expect(session.imagePath, isNull);
    });

    test('resolves with imagePath when image provider has data', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        imagePathAsync: const AsyncData('/tmp/map.png'),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.imagePath, '/tmp/map.png');
    });

    test('resolves with null imagePath when image provider errors', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        imagePathAsync: AsyncError(Exception('no image'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.imagePath, isNull);
    });

    test('propagates map load error as AsyncError', () async {
      final container = makeContainer(
        mapAsync: AsyncError(Exception('map missing'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSessionProvider(selection, 'save_1').future),
        throwsA(anything),
      );
    });

    test('setViewMode updates viewMode in AsyncData state', () async {
      final container = makeContainer(mapAsync: AsyncData(_makeMap()));
      addTearDown(container.dispose);

      await container.read(gameSessionProvider(selection, 'save_1').future);
      container
          .read(gameSessionProvider(selection, 'save_1').notifier)
          .setViewMode(MapViewMode.graphic);

      final session = container
          .read(gameSessionProvider(selection, 'save_1'))
          .value;
      expect(session?.viewMode, MapViewMode.graphic);
    });

    test('setViewMode is no-op when state is not AsyncData', () async {
      final container = makeContainer(mapAsync: const AsyncLoading<MapData>());
      addTearDown(container.dispose);

      // should not throw
      container
          .read(gameSessionProvider(selection, 'save_1').notifier)
          .setViewMode(MapViewMode.graphic);

      final state = container.read(gameSessionProvider(selection, 'save_1'));
      expect(state, isA<AsyncLoading<GameSession>>());
    });

    test('includes saved camera metadata in the session', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        cameraAsync: const AsyncData(CameraState(x: 1, y: 2, zoom: 3)),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.initialCamera?.x, 1);
      expect(session.initialCamera?.y, 2);
      expect(session.initialCamera?.zoom, 3);
    });

    test('includes saved game mode in the session', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        saveAsync: AsyncData(_makeSave(gameMode: GameMode.multiplayer)),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.gameMode, GameMode.multiplayer);
    });

    test(
      'session does not depend on world-slice repository providers',
      () async {
        final container = ProviderContainer(
          overrides: [
            activeMapProvider(
              selection,
            ).overrideWithValue(AsyncData(_makeMap())),
            mapImagePathProvider(
              selection,
            ).overrideWithValue(const AsyncData(null)),
            savedCameraProvider(
              'save_1',
            ).overrideWithValue(const AsyncData(null)),
            gameSaveProvider('save_1').overrideWithValue(const AsyncData(null)),
          ],
        );
        addTearDown(container.dispose);

        final session = await container.read(
          gameSessionProvider(selection, 'save_1').future,
        );

        expect(session.mapData.cols, 5);
      },
    );
  });

  group('GameStateNotifier', () {
    setUp(LiveEventSubscription.resetLocalCommandEchoGuardForTesting);

    test('loads state from repository for the active session', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _makeSave(players: const [_player1]);
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(
            save: save,
            playerColors: const {'player_1': 0xFF123456},
            units: [commander],
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(gameStateProvider('save_1').future);

      expect(state.playerColors, const {'player_1': 0xFF123456});
      expect(state.units, [commander]);
      expect(state.activePlayerId, 'player_1');
      expect(
        state.activePlayerVisibility.canSeeDynamicAt(
          commander.col,
          commander.row,
        ),
        isTrue,
      );
      expect(
        gameRepository.snapshots[save.id]!.fogOfWar.playerIds,
        contains('player_1'),
      );
    });

    test('uses network session player for multiplayer control', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
      final save = _makeSave(
        players: const [_player1, _player2],
        gameMode: GameMode.multiplayer,
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          networkSessionProvider.overrideWithValue(
            api.NetworkSession(
              userId: 'user_2',
              playerId: 'player_2',
              token: AuthToken('jwt-token'),
              matchId: save.id,
              connectionState: const NetworkConnectionState(
                status: NetworkConnectionStatus.connected,
              ),
            ),
          ),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(gameStateProvider(save.id).future);

      expect(state.activePlayerId, 'player_2');
      expect(state.selectedUnitId, commander.id);
      expect(state.canControlUnit(commander), isTrue);
    });

    test(
      'animates opponent movement from live multiplayer event snapshots',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
        final moved = commander.copyWith(col: 1, row: 0);
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final fakeStream = _FakeMultiplayerStream();
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
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
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened.timeout(const Duration(seconds: 1));
        final snapshot = _makeSnapshot(
          save: save,
          units: [moved],
          eventLogOffset: 1,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'server_1',
            matchId: save.id,
            offset: 1,
            snapshot: const SnapshotCodec().toWire(
              matchId: save.id,
              snapshot: snapshot,
            ),
            event: const EventCodec().toWire(
              matchId: save.id,
              offset: 1,
              timestamp: DateTime.utc(2026, 4, 27, 12),
              actorPlayerId: 'player_2',
              command: const MoveUnitCommand('commander_player_2', 1, 0),
              events: const [
                UnitMovedEvent(
                  unitId: 'commander_player_2',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ],
            ),
          ),
        );

        await _waitFor(() {
          final state = container.read(gameStateProvider(save.id)).value;
          return state?.units.single.col == 1;
        });

        final state = container.read(gameStateProvider(save.id)).value!;
        final effect = renderer.handledEffects
            .whereType<AnimateUnitMoveEffect>()
            .single;
        expect(effect.unitId, 'commander_player_2');
        expect(effect.fromCol, 0);
        expect(effect.fromRow, 0);
        expect(effect.steps.single.col, 1);
        expect(effect.steps.single.row, 0);
        expect(state.activePlayerId, 'player_1');
        expect(state.canControlUnit(state.units.single), isFalse);
      },
    );

    test(
      'animates queued opponent movement from live multiplayer snapshot resync',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2')
            .copyWithQueuedPath(
              QueuedMovePath(
                targetCol: 2,
                targetRow: 0,
                steps: const [
                  UnitMovementStep(
                    col: 0,
                    row: 0,
                    enterCost: 0,
                    cumulativeCost: 0,
                  ),
                  UnitMovementStep(
                    col: 1,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                  UnitMovementStep(
                    col: 2,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 2,
                  ),
                ],
              ),
            );
        final moved = commander.copyWith(col: 1, row: 0);
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final fakeStream = _FakeMultiplayerStream();
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
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
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened.timeout(const Duration(seconds: 1));

        final snapshot = _makeSnapshot(
          save: save,
          units: [moved],
          eventLogOffset: 1,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'server_1',
            matchId: save.id,
            offset: 1,
            snapshot: const SnapshotCodec().toWire(
              matchId: save.id,
              snapshot: snapshot,
            ),
          ),
        );

        await _waitFor(() {
          final state = container.read(gameStateProvider(save.id)).value;
          return state?.units.single.col == 1;
        });

        final state = container.read(gameStateProvider(save.id)).value!;
        final effect = renderer.handledEffects
            .whereType<AnimateUnitMoveEffect>()
            .single;
        expect(effect.unitId, 'commander_player_2');
        expect(effect.fromCol, 0);
        expect(effect.fromRow, 0);
        expect(effect.steps.single.col, 1);
        expect(effect.steps.single.row, 0);
        expect(state.activePlayerId, 'player_1');
        expect(state.activePlayerCanAct, isTrue);
        expect(state.canControlUnit(state.units.single), isFalse);
      },
    );

    test(
      'does not synthesize movement animation from snapshot-only direct deltas',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
        final moved = commander.copyWith(col: 1, row: 0);
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final fakeStream = _FakeMultiplayerStream();
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
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
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened.timeout(const Duration(seconds: 1));

        final snapshot = _makeSnapshot(
          save: save,
          units: [moved],
          eventLogOffset: 1,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'server_1',
            matchId: save.id,
            offset: 1,
            snapshot: const SnapshotCodec().toWire(
              matchId: save.id,
              snapshot: snapshot,
            ),
          ),
        );

        await _waitFor(() {
          final state = container.read(gameStateProvider(save.id)).value;
          return state?.units.single.col == 1;
        });

        expect(
          renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
          isEmpty,
        );
      },
    );

    test('refreshes save metadata after live multiplayer snapshots', () async {
      final save = _makeSave(
        players: const [_player1, _player2],
        gameMode: GameMode.multiplayer,
      );
      final advancedSave = save.copyWith(
        turn: 2,
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: _makeSnapshot(save: save)},
      );
      final fakeStream = _FakeMultiplayerStream();
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          multiplayerStreamConnectorProvider.overrideWithValue(
            fakeStream.connector,
          ),
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
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final saveSubscription = container.listen(
        gameSaveProvider(save.id),
        (_, _) {},
      );
      addTearDown(saveSubscription.close);
      final stateSubscription = container.listen(
        gameStateProvider(save.id),
        (_, _) {},
      );
      addTearDown(stateSubscription.close);

      await container.read(gameSaveProvider(save.id).future);
      await container.read(gameStateProvider(save.id).future);
      await fakeStream.listened.timeout(const Duration(seconds: 1));
      gameRepository.snapshots[save.id] = _makeSnapshot(
        save: advancedSave,
        eventLogOffset: 1,
      );
      fakeStream.add(
        sp.MultiplayerServerMessage(
          serverMessageId: 'server_1',
          matchId: save.id,
          offset: 1,
          event: const EventCodec().toWire(
            matchId: save.id,
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 27, 12),
            actorPlayerId: 'player_2',
            command: const SubmitTurnCommand('player_2'),
            events: [
              AllPlayersSubmittedEvent(
                turn: 1,
                playerIds: ['player_1', 'player_2'],
              ),
            ],
          ),
        ),
      );

      await _waitFor(() {
        return container.read(gameSaveProvider(save.id)).value?.turn == 2;
      });
    });

    test(
      'marks multiplayer session reconnecting when live stream closes',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = _FakeGameRepository(
          snapshots: {save.id: _makeSnapshot(save: save)},
        );
        final fakeStream = _FakeMultiplayerStream();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(networkSessionStateProvider.notifier)
            .set(
              api.NetworkSession(
                userId: 'user_1',
                playerId: 'player_1',
                token: AuthToken('jwt-token'),
                matchId: save.id,
                connectionState: const NetworkConnectionState(
                  status: NetworkConnectionStatus.connected,
                ),
              ),
            );

        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened.timeout(const Duration(seconds: 1));

        await fakeStream.close();

        await _waitFor(() {
          return container.read(multiplayerConnectionStatusProvider)?.status ==
              NetworkConnectionStatus.reconnecting;
        });
        expect(
          container.read(multiplayerConnectionStatusProvider)?.message,
          'Live event stream reconnecting',
        );
      },
    );

    test('dispatch updates provider state and persists the snapshot', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _makeSave(players: const [_player1]);
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gameStateProvider('save_1').future);
      final notifier = container.read(gameStateProvider('save_1').notifier);

      await notifier.dispatch(
        const SetActivePlayerCommand('player_1', canAct: true),
      );

      final uiEffects = await notifier.dispatch(
        MoveUnitCommand(commander.id, 1, 0),
      );

      final state = container.read(gameStateProvider('save_1')).value!;
      expect(state.units.single.col, 1);
      expect(gameRepository.snapshots[save.id]!.units.single.col, 1);
      expect(uiEffects.single, isA<AnimateUnitMoveEffect>());
    });

    test(
      'serializes concurrent local dispatches before event log writes',
      () async {
        final save = _makeSave(players: const [_player1]);
        final gameRepository = _FakeGameRepository(
          snapshots: {save.id: _makeSnapshot(save: save)},
        );
        final eventLog = _TrackedEventLog();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            eventLogProvider.overrideWithValue(eventLog),
            snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);

        await container.read(gameStateProvider(save.id).future);
        final notifier = container.read(gameStateProvider(save.id).notifier);

        await Future.wait([
          notifier.dispatch(
            const ResetUnitMovementCommand(playerId: 'player_1'),
          ),
          notifier.dispatch(
            const ResetUnitMovementCommand(playerId: 'player_1'),
          ),
          notifier.dispatch(
            const ResetUnitMovementCommand(playerId: 'player_1'),
          ),
        ]);

        expect(eventLog.maxConcurrentOperations, 1);
        expect(eventLog.commands.map((command) => command.offset), [1, 2, 3]);
        expect(
          eventLog.commands.map((command) => command.command),
          everyElement(isA<ResetUnitMovementCommand>()),
        );
      },
    );

    test(
      'uses network transport for a connected multiplayer session',
      () async {
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
        const eventCodec = EventCodec();
        const snapshotCodec = SnapshotCodec();
        var fallbackCommandCount = 0;
        final commandDispatcher = _FakeWireCommandDispatcher(({
          required saveId,
          required token,
          required afterOffset,
          required wire,
        }) async {
          fallbackCommandCount += 1;
          throw StateError('Expected command to use the live match channel.');
        });
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final snapshotStore = _FakeSnapshotStore();
        final fakeStream = _FakeMultiplayerStream();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
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
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
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
        addTearDown(fakeStream.close);
        final stateSubscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(stateSubscription.close);

        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened;
        await Future<void>.delayed(Duration.zero);
        expect(fallbackCommandCount, 0);

        final pendingResult = container
            .read(gameCommandControllerProvider.notifier)
            .dispatchTransition(MoveUnitCommand(commander.id, 1, 0));
        await _waitFor(
          () =>
              fakeStream.clientMessages.isNotEmpty || fallbackCommandCount > 0,
        );
        expect(fallbackCommandCount, 0);

        final sent = fakeStream.clientMessages.single;
        expect(sent.lastSeenOffset, 0);
        final wire = sent.command!;
        expect(wire.actorPlayerId, 'player_1');
        expect(wire.command['type'], 'MoveUnit');
        final moved = commander.copyWith(col: 1, row: 0, movementPoints: 2);
        final serverState = GameState(
          units: [moved],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final snapshot = SaveSnapshot.fromGameState(
          save: save,
          state: serverState,
          eventLogOffset: 4,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'ack-4',
            matchId: save.id,
            offset: 4,
            ack: WireCommandAck(
              matchId: wire.matchId,
              accepted: true,
              offset: 4,
              snapshot: snapshotCodec.toWire(
                matchId: wire.matchId,
                snapshot: snapshot,
              ),
              events: eventCodec.eventsToJsonList(const [
                UnitMovedEvent(
                  unitId: 'commander_player_1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ]),
            ),
          ),
        );

        final result = await pendingResult;

        expect(result.state.units.single.col, 1);
        expect(result.events.single, isA<UnitMovedEvent>());
        expect(snapshotStore.snapshots.single.offset, 4);
        expect(snapshotStore.snapshots.single.state.units.single.col, 1);
      },
    );

    test(
      'ignores local live command echoes while waiting for the ACK',
      () async {
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
        const eventCodec = EventCodec();
        const snapshotCodec = SnapshotCodec();
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final snapshotStore = _FakeSnapshotStore();
        final fakeStream = _FakeMultiplayerStream();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            eventLogProvider.overrideWithValue(_FakeEventLog()),
            networkEventLogProvider.overrideWith(
              (ref) => ref.watch(eventLogProvider),
            ),
            networkGameRepositoryProvider.overrideWith(
              (ref) => ref.watch(gameRepositoryProvider),
            ),
            snapshotStoreProvider.overrideWithValue(snapshotStore),
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
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
        addTearDown(fakeStream.close);
        final stateSubscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(stateSubscription.close);

        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened;

        final pendingResult = container
            .read(gameCommandControllerProvider.notifier)
            .dispatchTransition(MoveUnitCommand(commander.id, 1, 0));
        await _waitFor(() => fakeStream.clientMessages.isNotEmpty);

        final wire = fakeStream.clientMessages.single.command!;
        final moved = commander.copyWith(col: 1, row: 0, movementPoints: 2);
        final serverState = GameState(
          units: [moved],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final snapshot = SaveSnapshot.fromGameState(
          save: save,
          state: serverState,
          eventLogOffset: 4,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'echo-4',
            matchId: save.id,
            offset: 4,
            snapshot: snapshotCodec.toWire(
              matchId: save.id,
              snapshot: snapshot,
            ),
            event: eventCodec.toWire(
              matchId: save.id,
              offset: 4,
              timestamp: DateTime.utc(2026, 4, 27, 12),
              actorPlayerId: wire.actorPlayerId,
              tick: wire.tick,
              command: const MoveUnitCommand('commander_player_1', 1, 0),
              events: const [
                UnitMovedEvent(
                  unitId: 'commander_player_1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ],
            ),
          ),
        );
        await pumpEventQueue(times: 5);

        expect(
          renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
          isEmpty,
          reason: 'The local command must animate once from the ACK path only.',
        );

        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'ack-4',
            matchId: save.id,
            offset: 4,
            ack: WireCommandAck(
              matchId: wire.matchId,
              accepted: true,
              offset: 4,
              snapshot: snapshotCodec.toWire(
                matchId: wire.matchId,
                snapshot: snapshot,
              ),
              events: eventCodec.eventsToJsonList(const [
                UnitMovedEvent(
                  unitId: 'commander_player_1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ]),
            ),
          ),
        );

        final result = await pendingResult;

        expect(result.state.units.single.col, 1);
        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>(),
          hasLength(1),
        );
        expect(snapshotStore.snapshots.single.offset, 4);
      },
    );

    test('surfaces bootstrap load errors as AsyncError', () async {
      final gameRepository = _FakeGameRepository(throwOnLoad: true);
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameStateProvider('broken').future),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(gameStateProvider('broken')),
        isA<AsyncError<GameState>>(),
      );
    });
  });

  group('GameCommandController', () {
    test(
      'dispatch forwards commands to active game state and returns effects',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = _makeSave(players: const [_player1]);
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);

        final effects = await container
            .read(gameCommandControllerProvider.notifier)
            .dispatch(MoveUnitCommand(commander.id, 1, 0));

        final state = container.read(gameStateProvider(save.id)).value!;
        expect(state.units.single.col, 1);
        expect(gameRepository.snapshots[save.id]!.units.single.col, 1);
        expect(effects.single, isA<AnimateUnitMoveEffect>());
      },
    );

    test('presentation shows HUD feedback effects', () async {
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(gameCommandControllerProvider.notifier)
          .presentHandoffPresentation(
            const HandoffPresentation(
              command: TileTappedCommand(1, 0),
              state: GameState(),
              previousState: GameState(),
              events: [],
              uiEffects: [
                ShowHudFeedbackEffect(
                  title: 'City occupied',
                  body: 'Only one unit can stand in a city.',
                ),
              ],
            ),
          );

      final feedback = container.read(hudFeedbackProvider).single;
      expect(feedback.kind, HudFeedbackKind.actionBlocked);
      expect(feedback.title, 'City occupied');
    });

    test('turn-start focus renders a slower camera transition', () async {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 2,
        row: 3,
      );
      final save = _makeSave(players: const [_player1]);
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
      final renderer = _SpyGameRenderer(mapData: _makeLandMap());
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          activeGameRendererProvider.overrideWithValue(renderer),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gameStateProvider(save.id).future);

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const FocusTurnStartActionCommand('player_1'));

      final effect = renderer.handledEffects
          .whereType<SmoothCameraEffect>()
          .single;
      expect(effect.col, 2);
      expect(effect.row, 3);
      expect(effect.duration, 0.85);
    });

    test(
      'next-action focus keeps the default camera transition speed',
      () async {
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 2,
          row: 3,
        );
        final save = _makeSave(players: const [_player1]);
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);

        await container
            .read(gameCommandControllerProvider.notifier)
            .dispatch(const FocusNextPendingActionCommand('player_1'));

        final effect = renderer.handledEffects
            .whereType<SmoothCameraEffect>()
            .single;
        expect(effect.col, 2);
        expect(effect.row, 3);
        expect(effect.duration, 0.48);
      },
    );

    test(
      'dispatch logs and preserves current state when save snapshot is missing',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = _makeSave(players: const [_player1]);
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final logger = _FakeGameLogger();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            gameLoggerProvider.overrideWithValue(logger),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);
        gameRepository.snapshots.clear();

        final effects = await container
            .read(gameCommandControllerProvider.notifier)
            .dispatch(MoveUnitCommand(commander.id, 1, 0));

        final state = container.read(gameStateProvider(save.id)).value!;
        expect(effects, isEmpty);
        expect(state.units.single.col, 0);
        expect(logger.warnings, hasLength(1));
        expect(logger.warnings.single.tag, 'GameCommandController');
        expect(logger.warnings.single.message, 'command dispatch failed');
      },
    );

    test(
      'saveCamera stores the current session camera through repository',
      () async {
        final save = _makeSave();
        final session = _makeSession();
        final renderer = _makeRenderer();
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(session),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(gameCommandControllerProvider.notifier)
            .saveCamera();

        final updated = saves[save.id]!;
        expect(updated.camera.zoom, 1);
        expect(updated.savedAt.isAfter(save.savedAt), isTrue);
      },
    );

    test('saveCamera skips active network matches', () async {
      final save = _makeSave(gameMode: GameMode.multiplayer);
      final session = _makeSession(
        saveId: save.id,
        gameMode: GameMode.multiplayer,
      );
      final renderer = _makeRenderer();
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: _makeSnapshot(save: save)},
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(session),
          activeGameRendererProvider.overrideWithValue(renderer),
          gameRepositoryProvider.overrideWithValue(gameRepository),
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

      await container.read(gameCommandControllerProvider.notifier).saveCamera();

      expect(gameRepository.loadCount, 0);
    });

    test(
      'focusTurnStartMapTarget shows production bubbles once per player turn',
      () async {
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 1, row: 1),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
        );
        final save = _makeSave(turn: 4, players: const [_player1]);
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(
              save: save,
              cities: [city],
              research: ResearchState(
                players: {
                  'player_1': PlayerResearchState(
                    activeTechnologyId: TechnologyId.agriculture,
                  ),
                },
              ),
            ),
          },
        );
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);
        final controller = container.read(
          gameCommandControllerProvider.notifier,
        );

        await controller.focusTurnStartMapTarget('player_1');
        await controller.focusTurnStartMapTarget('player_1');

        expect(
          renderer.handledEffects.whereType<ShowCityProductionBubbleEffect>(),
          hasLength(1),
        );
        final smoothDurations = renderer.handledEffects
            .whereType<SmoothCameraEffect>()
            .map((effect) => effect.duration)
            .toList(growable: false);
        expect(smoothDurations, isNotEmpty);
        expect(smoothDurations, everyElement(0.85));
      },
    );

    test(
      'saveCamera is a no-op when activeGameSessionProvider is null',
      () async {
        final saves = <String, GameSave>{};
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(null),
            gameRepositoryProvider.overrideWithValue(
              _FakeGameRepository(saves: saves),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(gameCommandControllerProvider.notifier)
            .saveCamera();

        expect(saves, isEmpty);
      },
    );
  });

  group('GamePlayerControlController', () {
    test('syncWithSave selects the first save player', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final save = _makeSave(players: const [_player1, _player2]);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);

      final state = container.read(gamePlayerControlControllerProvider);
      expect(state.activePlayerId, 'player_1');
      expect(state.canAct, isTrue);
    });

    test('syncWithSave mirrors active player into GameStateNotifier', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _makeSave(players: const [_player1, _player2]);
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        gameStateProvider('save_1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(gameStateProvider('save_1').future);

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(gameStateProvider('save_1')).value!;
      expect(state.activePlayerId, 'player_1');
      expect(state.activePlayerCanAct, isTrue);
    });

    test('selectPlayer updates control state for finished players', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final save = _makeSave(
        players: const [_player1, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .selectPlayer(save, 'player_2');

      final state = container.read(gamePlayerControlControllerProvider);
      expect(state.activePlayerId, 'player_2');
      expect(state.canAct, isFalse);
    });

    test('selectPlayer mirrors canAct into GameStateNotifier', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
      final save = _makeSave(
        players: const [_player1, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        gameStateProvider('save_1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(gameStateProvider('save_1').future);

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .selectPlayer(save, 'player_2');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(gameStateProvider('save_1')).value!;
      expect(state.activePlayerId, 'player_2');
      expect(state.activePlayerCanAct, isFalse);
    });

    test(
      'endTurn keeps control on finished player while turn continues',
      () async {
        final save = _makeSave(players: const [_player1, _player2]);
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(gamePlayerControlControllerProvider.notifier)
            .syncWithSave(save);
        final updated = await container
            .read(gamePlayerControlControllerProvider.notifier)
            .endTurn(save);

        expect(updated, isNotNull);
        expect(updated!.turn, 1);
        expect(updated.playerStates['player_1'], PlayerTurnState.finished);

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_1');
        expect(state.canAct, isFalse);
      },
    );

    test(
      'endTurn keeps current control until new-turn handoff is confirmed',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(gamePlayerControlControllerProvider.notifier)
            .syncWithSave(save);
        container
            .read(gamePlayerControlControllerProvider.notifier)
            .selectPlayer(save, 'player_2');
        final updated = await container
            .read(gamePlayerControlControllerProvider.notifier)
            .endTurn(save);

        expect(updated, isNotNull);
        expect(updated!.turn, 2);

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_2');
        expect(state.canAct, isTrue);
        expect(container.read(gameHandoffProvider)?.playerId, 'player_1');
      },
    );

    test(
      'endTurn starts handoff when a hotseat session waits for another player',
      () async {
        final save = _makeSave(players: const [_player1, _player2]);
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(gamePlayerControlControllerProvider.notifier)
            .syncWithSave(save);
        final updated = await container
            .read(gamePlayerControlControllerProvider.notifier)
            .endTurn(save);

        expect(updated, isNotNull);
        final handoff = container.read(gameHandoffProvider);
        expect(handoff?.playerId, 'player_2');
        expect(handoff?.playerName, 'Bob');
      },
    );

    test(
      'confirmHandoff reloads the latest save before selecting player',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);
        final saveSubscription = container.listen(
          gameSaveProvider(save.id),
          (_, _) {},
        );
        addTearDown(saveSubscription.close);

        await container.read(gameSaveProvider(save.id).future);
        await container.read(gameStateProvider(save.id).future);
        final controller = container.read(
          gamePlayerControlControllerProvider.notifier,
        )..selectPlayer(save, 'player_2');

        final updated = await controller.endTurn(save);
        expect(updated?.turn, 2);
        expect(container.read(gameHandoffProvider)?.playerId, 'player_1');

        await controller.confirmHandoff('player_1');

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_1');
        expect(state.canAct, isTrue);
      },
    );

    test(
      'confirmHandoff logs repository failures instead of throwing',
      () async {
        final save = _makeSave(players: const [_player1, _player2]);
        final gameRepository = _FakeGameRepository(throwOnLoad: true);
        final logger = _FakeGameLogger();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            gameLoggerProvider.overrideWithValue(logger),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          gamePlayerControlControllerProvider.notifier,
        )..syncWithSave(save);

        await controller.confirmHandoff('player_2');

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_1');
        expect(logger.warnings, hasLength(1));
        expect(logger.warnings.single.tag, 'GamePlayerControlController');
        expect(logger.warnings.single.message, 'confirm handoff failed');
      },
    );

    test('endTurn does not start handoff in multiplayer sessions', () async {
      final save = _makeSave(players: const [_player1, _player2]);
      final saves = {save.id: save};
      final gameRepository = _FakeGameRepository(saves: saves);
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      final updated = await container
          .read(gamePlayerControlControllerProvider.notifier)
          .endTurn(save);

      expect(updated, isNotNull);
      expect(container.read(gameHandoffProvider), isNull);
    });

    test('endTurn does not use Ref after control provider disposal', () async {
      final save = _makeSave();
      final gate = Completer<void>();
      final saves = {save.id: save};
      final gameRepository = _FakeGameRepository(saves: saves, loadGate: gate);
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        gamePlayerControlControllerProvider.notifier,
      )..syncWithSave(save);
      final future = notifier.endTurn(save);

      container.invalidate(gamePlayerControlControllerProvider);
      gate.complete();

      final updated = await future;
      expect(updated, isNotNull);
      expect(updated!.turn, 2);
    });
  });

  group('gameRepositoryProvider', () {
    test('uses JSON repository by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(gameRepositoryProvider), isA<JsonGameRepository>());
    });

    test(
      'keeps default repository local while multiplayer match can resume',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(networkSessionStateProvider.notifier)
            .set(
              api.NetworkSession(
                userId: 'user_1',
                playerId: 'player_1',
                token: AuthToken('token'),
                matchId: 'match_1',
                connectionState: const NetworkConnectionState(
                  status: NetworkConnectionStatus.connected,
                ),
              ),
            );

        expect(
          container.read(gameRepositoryProvider),
          isA<JsonGameRepository>(),
        );
      },
    );
  });

  group('gameSavesIndexProvider', () {
    test('lists saves through repository', () async {
      final save = _makeSave();
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: SaveSnapshot(save: save)},
      );
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSavesIndexProvider.future),
        completion(
          contains(
            isA<GameSaveIndex>()
                .having((index) => index.id, 'id', save.id)
                .having((index) => index.name, 'name', save.name),
          ),
        ),
      );
    });
  });

  group('savedCameraProvider', () {
    test('returns null for an empty save id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(savedCameraProvider('').future),
        completion(isNull),
      );
    });

    test('loads camera through repository', () async {
      final gameRepository = _FakeGameRepository(
        saves: {'save_1': _makeSave()},
      );
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(savedCameraProvider('save_1').future),
        completion(
          isA<CameraState>()
              .having((camera) => camera.x, 'x', 4)
              .having((camera) => camera.y, 'y', 5)
              .having((camera) => camera.zoom, 'zoom', 1.25),
        ),
      );
      expect(gameRepository.loadCount, 1);
    });

    test('surfaces repository errors', () async {
      final gameRepository = _FakeGameRepository(throwOnLoad: true);
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(savedCameraProvider('broken').future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('gameSaveProvider', () {
    test('returns null for an empty save id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSaveProvider('').future),
        completion(isNull),
      );
    });

    test('loads save through repository', () async {
      final save = _makeSave();
      final gameRepository = _FakeGameRepository(saves: {'save_1': save});
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSaveProvider('save_1').future),
        completion(same(save)),
      );
      expect(gameRepository.loadCount, 1);
    });

    test('surfaces repository errors', () async {
      final gameRepository = _FakeGameRepository(throwOnLoad: true);
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSaveProvider('broken').future),
        throwsA(isA<StateError>()),
      );
    });
  });
}
