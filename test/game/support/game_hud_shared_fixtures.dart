part of '../game_hud_test.dart';

class _FakeGameRepository implements GameRepository {
  _FakeGameRepository({CanonicalGameSnapshot? snapshot})
    : snapshot = _withHudTestVisibility(
        snapshot ?? GameSnapshotFactory.create(save: _save),
      );

  CanonicalGameSnapshot snapshot;
  CameraState? savedCamera;
  Completer<void>? loadGate;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async {
    return 'save';
  }

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    final gate = loadGate;
    if (gate != null) {
      loadGate = null;
      await gate.future;
    }
    return snapshot;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    savedCamera = camera;
    snapshot = snapshot.withGameSave(snapshot.save.copyWith(camera: camera));
    return snapshot;
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

class _RecordingGameLogger implements GameLogger {
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

class _SpyGameRenderer extends GameRenderer {
  _SpyGameRenderer({required super.mapData}) : super(onCommand: (_) async {});

  final handledEffects = <RendererEffect>[];
  final appliedStates = <GameClientState>[];

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    appliedStates.add(state);
    applyState(state, currentTurn: currentTurn);
    handledEffects.addAll(effects);
  }

  @override
  Future<void> handleEffects(Iterable<RendererEffect> effects) async {
    handledEffects.addAll(effects);
  }
}

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);
const _aiPlayer = Player(
  id: 'player_1',
  name: 'AI Random',
  colorValue: 0xFF4a7fc4,
  kind: PlayerKind.ai,
  ai: AiPlayer(
    strategyId: AiStrategyId.random,
    difficulty: AiDifficulty.normal,
    persona: AiPersona.balanced,
    seed: 99,
  ),
);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 2,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

WorldMap _makeMap() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (int row = 0; row < 3; row++)
      for (int col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameSession _makeSession(
  WorldMap mapData, {
  GameMode gameMode = GameMode.hotSeat,
}) => GameSession(
  mapData: mapData,
  viewMode: MapViewMode.tile,
  saveId: 'save',
  gameMode: gameMode,
);

WireMatch _terminalMatch({
  required String outcomeCondition,
  required String? winnerPlayerId,
}) {
  return WireMatch(
    id: 'save',
    ownerUserId: 'user_1',
    name: 'Game',
    mapName: 'verdantia',
    players: const [
      WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF4a7fc4,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
      WirePlayer(
        id: 'player_2',
        userId: 'user_2',
        name: 'Bob',
        colorValue: 0xFFc45050,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
    ],
    turn: 2,
    state: 'finished',
    createdAt: DateTime.utc(2026, 5, 11),
    endedAt: DateTime.utc(2026, 5, 12),
    outcomeCondition: outcomeCondition,
    winnerPlayerId: winnerPlayerId,
  );
}

Future<void> _pumpHud(
  WidgetTester tester, {
  required _FakeGameRepository repository,
  VoidCallback? onClose,
  GameSave? gameSave,
  GameSession? session,
  NetworkSession? networkSession,
  WireMatch? multiplayerMatch,
  bool showEntryHandoff = false,
  bool aiAutopilotEnabled = false,
  GameRenderer? renderer,
  EventLog? eventLog,
  GameLogger? logger,
  bool? autoActionFlowEnabled,
  bool? autoTurnFlowEnabled,
  ValueListenable<GamepadInputSnapshot>? gamepadInputListenable,
  ValueListenable<bool> initialCameraFocusReadyListenable =
      const AlwaysStoppedAnimation<bool>(true),
}) async {
  final mapData = _makeMap();
  final activeSession = session ?? _makeSession(mapData);
  final activeRenderer =
      renderer ?? _SpyGameRenderer(mapData: activeSession.mapData);
  final save = gameSave ?? _save;
  final activeEventLog = eventLog ?? _FakeEventLog();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeGameSessionProvider.overrideWithValue(activeSession),
        activeGameRendererProvider.overrideWithValue(activeRenderer),
        gamePlayerControlSaveProvider.overrideWithValue(save),
        gameRepositoryProvider.overrideWithValue(repository),
        networkGameRepositoryProvider.overrideWithValue(repository),
        eventLogProvider.overrideWithValue(activeEventLog),
        networkEventLogProvider.overrideWithValue(activeEventLog),
        snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
        if (logger != null) gameLoggerProvider.overrideWithValue(logger),
        if (autoActionFlowEnabled != null)
          hudAutoActionFlowProvider.overrideWith(
            () => _TestHudAutoActionFlowController(autoActionFlowEnabled),
          ),
        if (autoTurnFlowEnabled != null)
          hudAutoTurnFlowProvider.overrideWith(
            () => _TestHudAutoTurnFlowController(autoTurnFlowEnabled),
          ),
        if (networkSession != null)
          networkSessionProvider.overrideWithValue(networkSession),
        if (multiplayerMatch != null)
          multiplayerMatchProvider.overrideWithValue({
            multiplayerMatch.id: multiplayerMatch,
          }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameHud(
            session: activeSession,
            animatingUnitIdsListenable:
                activeRenderer.animatingUnitIdsListenable,
            gamepadInputListenable:
                gamepadInputListenable ??
                const AlwaysStoppedAnimation<GamepadInputSnapshot>(
                  GamepadInputSnapshot.empty,
                ),
            initialCameraFocusReadyListenable:
                initialCameraFocusReadyListenable,
            allowGraphicMode: false,
            onViewModeChanged: (_) {},
            onClose: onClose ?? () {},
            gameSave: save,
            displaySettings: const HexDisplaySettings(),
            onToggleTerrain: () {},
            onToggleResources: () {},
            onToggleHeightBadge: () {},
            onToggleCitySites: () {},
            onToggleCityGrowth: () {},
            onToggleHexBorders: () {},
            onToggleHeightWalls: () {},
            showEntryHandoff: showEntryHandoff,
            aiAutopilotEnabled: aiAutopilotEnabled,
          ),
        ),
      ),
    ),
  );
}

class _TestHudAutoActionFlowController extends HudAutoActionFlowController {
  _TestHudAutoActionFlowController(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

class _TestHudAutoTurnFlowController extends HudAutoTurnFlowController {
  _TestHudAutoTurnFlowController(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int frames = 12,
  int ticksPerFrame = 40,
  Duration pollInterval = const Duration(milliseconds: 25),
}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump();
    if (done()) return;

    await tester.runAsync(() async {
      for (var tick = 0; tick < ticksPerFrame; tick++) {
        if (done()) return;
        await Future<void>.delayed(pollInterval);
      }
    });
    if (done()) return;
  }
}

Future<void> _cancelMoveTargetingBanner(WidgetTester tester) async {
  final moveAction = find.byKey(const Key('selectionInfo.action.move'));
  if (moveAction.evaluate().isEmpty) return;
  await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openHelpEntryById(WidgetTester tester, String popupId) async {
  await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
  await tester.pump();
  await tester.tap(find.byKey(Key('gameOptions.helpPopup.$popupId')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

GameClientState? _readGameState(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(GameHud)),
    listen: false,
  );
  return container.read(gameStateProvider('save')).value;
}

Future<void> _disableAutoTurnFlow(WidgetTester tester) async {
  await _setAutoTurnFlow(tester, false);
}

Future<void> _enableAutoTurnFlow(WidgetTester tester) async {
  await _setAutoTurnFlow(tester, true);
}

Future<void> _setAutoTurnFlow(WidgetTester tester, bool enabled) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(GameHud)),
    listen: false,
  );
  container.read(hudAutoActionFlowProvider.notifier).setEnabled(enabled);
  container.read(hudAutoTurnFlowProvider.notifier).setEnabled(enabled);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(container.read(hudAutoActionFlowProvider), enabled);
  expect(container.read(hudAutoTurnFlowProvider), enabled);
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

void _expectCoachmarkHaloTracks(
  WidgetTester tester,
  Finder target, {
  required String reason,
}) {
  final halo = tester.getRect(
    find.byKey(const Key('firstTurnCoachmarks.halo')),
  );
  final targetRect = tester.getRect(target);
  expect(halo.contains(targetRect.center), isTrue, reason: reason);
  expect(halo.overlaps(targetRect), isTrue, reason: reason);
}

Future<void> _pressGamepad(
  WidgetTester tester,
  ValueNotifier<GamepadInputSnapshot> input,
  GamepadInputSnapshot snapshot,
) async {
  input.value = snapshot;
  await tester.pump(const Duration(milliseconds: 16));
  input.value = GamepadInputSnapshot.empty;
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 120));
}
