part of '../game_providers_test.dart';

class _FakeGameRepository implements GameRepository {
  final Map<String, CanonicalGameSnapshot> snapshots;
  final Map<String, GameSave>? saves;
  final bool throwOnLoad;
  final Completer<void>? loadGate;
  int loadCount = 0;

  _FakeGameRepository({
    Map<String, CanonicalGameSnapshot>? snapshots,
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
    snapshots[id] = GameSnapshotFactory.create(save: save);
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
  Future<CanonicalGameSnapshot> load(String saveId) async {
    await loadGate?.future;
    loadCount++;
    if (throwOnLoad) throw StateError('load failed');
    final save = saves?[saveId];
    if (save != null) return GameSnapshotFactory.create(save: save);
    final snapshot = snapshots[saveId];
    if (snapshot == null) throw StateError('missing save');
    return snapshot;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    saves?[snapshot.save.id] = snapshot.save;
    snapshots[snapshot.save.id] = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {
    saves?.remove(saveId);
    snapshots.remove(saveId);
  }

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final snapshot = await load(saveId);
    final updated = snapshot.withGameSave(
      snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? DateTime.now().toUtc(),
      ),
    );
    await save(updated);
    return updated;
  }
}

class _FakeEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.fold<int>(0, (latest, command) {
      return command.offset > latest ? command.offset : latest;
    });
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<RecordedDomainCommand> readSince(
    String saveId, {
    int offset = 0,
  }) async* {
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
  Future<void> append(String saveId, RecordedDomainCommand command) {
    return _track(() => super.append(saveId, command));
  }

  @override
  Future<int> latestOffset(String saveId) {
    return _track(() => super.latestOffset(saveId));
  }
}

class _FakeSnapshotStore implements SnapshotStore {
  final snapshots = <Snapshot>[];
  final saveIds = <String>[];

  @override
  Future<Snapshot?> latest(String saveId) async {
    return snapshots.isEmpty ? null : snapshots.last;
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    saveIds.add(saveId);
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
    required String clientMessageId,
  })
  handler;

  const _FakeWireCommandDispatcher(this.handler);

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) {
    return handler(
      saveId: saveId,
      token: token,
      afterOffset: afterOffset,
      wire: wire,
      clientMessageId: clientMessageId,
    );
  }
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

ProviderContainer _liveMovementContainer({
  required GameSave save,
  required _FakeGameRepository gameRepository,
  required _FakeMultiplayerStream fakeStream,
  required _SpyGameRenderer renderer,
  GameAudioController? audioController,
}) {
  return ProviderContainer(
    overrides: [
      activeGameSessionProvider.overrideWithValue(
        _makeSession(mapData: _makeLandMap(), gameMode: GameMode.multiplayer),
      ),
      activeGameRendererProvider.overrideWithValue(renderer),
      if (audioController != null)
        gameAudioControllerProvider.overrideWithValue(audioController),
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
}

WorldMap _makeMap() => WorldMap(
  cols: 5,
  rows: 5,
  tiles: [
    for (int r = 0; r < 5; r++)
      for (int c = 0; c < 5; c++)
        WorldTile(
          col: c,
          row: r,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldMap _makeLandMap() => WorldMap(
  cols: 5,
  rows: 5,
  tiles: [
    for (int r = 0; r < 5; r++)
      for (int c = 0; c < 5; c++)
        WorldTile(
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

CanonicalGameSnapshot _makeSnapshot({
  GameSave? save,
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  List<FieldImprovement> fieldImprovements = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  ResearchState research = ResearchState.empty,
  Set<String> submittedPlayerIds = const {},
  int eventLogOffset = 0,
}) {
  return GameSnapshotFactory.create(
    save: save ?? _makeSave(),
    units: units,
    cities: cities,
    fieldImprovements: fieldImprovements,
    fogOfWar: fogOfWar,
    research: research,
    submittedPlayerIds: submittedPlayerIds,
    eventLogOffset: eventLogOffset,
  );
}

GameSession _makeSession({
  String saveId = 'save_1',
  WorldMap? mapData,
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

class _SpyGameRenderer extends GameRenderer {
  _SpyGameRenderer({WorldMap? mapData})
    : super(
        mapData: mapData ?? _makeMap(),
        initialViewMode: MapViewMode.tile,
        onCommand: (_) async {},
      );

  final handledEffects = <RendererEffect>[];

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    handledEffects.addAll(effects);
  }

  @override
  Future<void> handleEffects(Iterable<RendererEffect> effects) async {
    handledEffects.addAll(effects);
  }
}
