part of 'game_screen_test.dart';

class _FakeGameRepository implements GameRepository {
  final Map<String, CanonicalGameSnapshot> snapshots;

  _FakeGameRepository({required this.snapshots});

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    return '$mapDisplayName ${now.year}';
  }

  @override
  Future<String> create(NewGameRequest request) async {
    throw UnimplementedError();
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
    final snapshot = snapshots[saveId];
    if (snapshot == null) throw StateError('missing save');
    return snapshot;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    snapshots[snapshot.save.id] = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {
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
        savedAt: savedAt ?? snapshot.save.savedAt,
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

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _localAiPlayer = Player(
  id: 'ai_1',
  name: 'AI',
  colorValue: 0xFFc45050,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1),
);

WorldMap _makeMap({TerrainType terrain = TerrainType.ocean}) => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (int r = 0; r < 3; r++)
      for (int c = 0; c < 3; c++)
        WorldTile(
          col: c,
          row: r,
          terrains: [terrain],
          resources: const [],
          height: 0,
        ),
  ],
);

const _selection = MapSelection(name: 'test', source: MapSource.asset);
const _otherSelection = MapSelection(name: 'other', source: MapSource.asset);

GameSave _makeSave({
  String id = 'save_1',
  List<Player> players = const [_player1],
  CameraState camera = CameraState.zero,
  GameMode gameMode = GameMode.multiplayer,
}) {
  return GameSave(
    id: id,
    name: 'Game',
    mapName: 'test',
    mapSource: MapSource.asset,
    turn: 2,
    playerStates: {
      for (final player in players) player.id: PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 4, 25),
    camera: camera,
    players: players,
    gameMode: gameMode,
  );
}

CanonicalGameSnapshot _makeSnapshot({
  required GameSave save,
  List<GameUnit> units = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
}) {
  return GameSnapshotFactory.create(
    save: save,
    units: units,
    fogOfWar: fogOfWar,
  );
}

FogOfWarState _visibleFog(
  String playerId,
  Iterable<HexCoordinate> visibleHexes,
) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(
        playerId: playerId,
        visibleHexes: Set<HexCoordinate>.of(visibleHexes),
      ),
    },
  );
}

ProviderContainer _makeContainer({
  AsyncValue<WorldMap>? mapAsync,
  AsyncValue<MapImageSource?> imageSourceAsync = const AsyncData(null),
  AsyncValue<CameraState?> cameraAsync = const AsyncData(null),
  AsyncValue<GameSave?> saveAsync = const AsyncData(null),
}) {
  return ProviderContainer(
    overrides: [
      activeMapProvider(
        _selection,
      ).overrideWithValue(mapAsync ?? AsyncData(_makeMap())),
      mapImageSourceProvider(_selection).overrideWithValue(imageSourceAsync),
      savedCameraProvider('').overrideWithValue(cameraAsync),
      gameSaveProvider('').overrideWithValue(saveAsync),
    ],
  );
}

ProviderContainer _makeMultiplayerGameContainer(
  GameSave save, {
  bool connected = false,
  NetworkSessionClient? sessionClient,
}) {
  final gameRepository = _FakeGameRepository(
    snapshots: {save.id: _makeSnapshot(save: save)},
  );
  final eventLog = _FakeEventLog();
  return ProviderContainer(
      overrides: [
        activeMapProvider(_selection).overrideWithValue(AsyncData(_makeMap())),
        mapImageSourceProvider(
          _selection,
        ).overrideWithValue(const AsyncData(null)),
        gameRepositoryProvider.overrideWithValue(gameRepository),
        networkGameRepositoryProvider.overrideWithValue(gameRepository),
        eventLogProvider.overrideWithValue(eventLog),
        networkEventLogProvider.overrideWithValue(eventLog),
        snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
        if (sessionClient != null)
          networkSessionClientProvider.overrideWithValue(sessionClient),
      ],
    )
    ..read(networkSessionStateProvider.notifier).set(
      NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('jwt-token'),
        refreshToken: 'refresh-token',
        matchId: save.id,
        connectionState: connected
            ? const NetworkConnectionState(
                status: NetworkConnectionStatus.connected,
              )
            : NetworkConnectionState.offline,
      ),
    );
}

final class _RecordingMapLoadedClient extends NetworkSessionClient {
  _RecordingMapLoadedClient()
    : super(serverpodHost: 'https://api.example.test');

  final Completer<WireMatch> _pendingResponse = Completer<WireMatch>();
  var markMapLoadedCalls = 0;
  String? markedMatchId;

  void complete(WireMatch match) {
    _pendingResponse.complete(match);
  }

  @override
  Future<WireMatch> markMapLoaded({
    required AuthToken token,
    required String matchId,
  }) {
    markMapLoadedCalls++;
    markedMatchId = matchId;
    return _pendingResponse.future;
  }
}

Future<void> _pumpGameScreen(
  WidgetTester tester,
  ProviderContainer container, {
  MapSelection selection = _selection,
  String saveId = '',
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(disableAnimations: true),
          child: GameScreen(selection: selection, saveId: saveId),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await _pumpCappedGameFrame(tester);
}

Future<void> _pumpCappedGameFrame(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 34));
  await tester.pump();
}

Future<void> _pumpUntilLocalStartupReady(WidgetTester tester) async {
  const overlayKey = Key('gameScreen.startupLoadingOverlay');
  for (var attempt = 0; attempt < 80; attempt++) {
    if (find.byKey(overlayKey).evaluate().isEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Game startup overlay did not finish local asset loading.');
}

Future<GameRenderer> _pumpUntilRendererReady(
  WidgetTester tester,
  ProviderContainer scopedContainer,
) async {
  final renderer = scopedContainer.read(activeGameRendererProvider)!;
  for (var i = 0; i < 80; i++) {
    if (renderer.readyListenable.value) return renderer;
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Game renderer did not become ready.');
}

void _expectRectInside(Rect rect, Rect viewport, {required String reason}) {
  expect(rect.left, greaterThanOrEqualTo(viewport.left), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(viewport.top), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.right), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.bottom), reason: reason);
}

void _expectRectContains(Rect outer, Rect inner, {required String reason}) {
  expect(inner.left, greaterThanOrEqualTo(outer.left), reason: reason);
  expect(inner.top, greaterThanOrEqualTo(outer.top), reason: reason);
  expect(inner.right, lessThanOrEqualTo(outer.right), reason: reason);
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom), reason: reason);
}
