import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:aonw/game/presentation/widgets/hud/global_hud_actions.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_detail_sheet.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_dialog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGameRepository implements GameRepository {
  final Map<String, SaveSnapshot> snapshots;

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
  Future<SaveSnapshot> load(String saveId) async {
    final snapshot = snapshots[saveId];
    if (snapshot == null) throw StateError('missing save');
    return snapshot;
  }

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    snapshots[snapshot.save.id] = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {
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
        savedAt: savedAt ?? snapshot.save.savedAt,
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

MapData _makeMap() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (int r = 0; r < 3; r++)
      for (int c = 0; c < 3; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);

const _selection = MapSelection(name: 'test', source: MapSource.asset);
const _otherSelection = MapSelection(name: 'other', source: MapSource.asset);

MapData _makeOtherMap() => MapData(
  cols: 4,
  rows: 2,
  tiles: [
    for (int r = 0; r < 2; r++)
      for (int c = 0; c < 4; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

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

SaveSnapshot _makeSnapshot({
  required GameSave save,
  List<GameUnit> units = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
}) {
  return SaveSnapshot(save: save, units: units, fogOfWar: fogOfWar);
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
  AsyncValue<MapData>? mapAsync,
  AsyncValue<String?> imagePathAsync = const AsyncData(null),
  AsyncValue<CameraState?> cameraAsync = const AsyncData(null),
  AsyncValue<GameSave?> saveAsync = const AsyncData(null),
}) {
  return ProviderContainer(
    overrides: [
      activeMapProvider(
        _selection,
      ).overrideWithValue(mapAsync ?? AsyncData(_makeMap())),
      mapImagePathProvider(_selection).overrideWithValue(imagePathAsync),
      savedCameraProvider('').overrideWithValue(cameraAsync),
      gameSaveProvider('').overrideWithValue(saveAsync),
    ],
  );
}

ProviderContainer _makeMultiplayerGameContainer(GameSave save) {
  return ProviderContainer(
    overrides: [
      activeMapProvider(_selection).overrideWithValue(AsyncData(_makeMap())),
      mapImagePathProvider(_selection).overrideWithValue(const AsyncData(null)),
      gameRepositoryProvider.overrideWithValue(
        _FakeGameRepository(snapshots: {save.id: _makeSnapshot(save: save)}),
      ),
      eventLogProvider.overrideWithValue(_FakeEventLog()),
      snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
      networkSessionProvider.overrideWithValue(
        NetworkSession(
          userId: 'user_1',
          playerId: 'player_1',
          token: AuthToken('jwt-token'),
          refreshToken: 'refresh-token',
          matchId: save.id,
          connectionState: NetworkConnectionState.offline,
        ),
      ),
    ],
  );
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

void _expectWarmPanelSurface(
  WidgetTester tester,
  Key key, {
  required String reason,
}) {
  final surface = tester.widget<DecoratedBox>(find.byKey(key));
  final decoration = surface.decoration;
  expect(decoration, isA<BoxDecoration>(), reason: reason);
  final box = decoration as BoxDecoration;
  expect(box.gradient, isA<LinearGradient>(), reason: reason);
  expect(box.color, isNull, reason: reason);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows loading while session is loading', (tester) async {
    final container = _makeContainer(mapAsync: const AsyncLoading());
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container);

    expect(find.text('Loading world'), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.mapBackdrop')), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.frame')), findsOneWidget);
    expect(find.byKey(const Key('gameLoading.emblem')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders game HUD when session is ready', (tester) async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container);

    expect(find.byType(GameHud), findsOneWidget);
    final hudContext = tester.element(find.byType(GameHud));
    final scopedContainer = ProviderScope.containerOf(
      hudContext,
      listen: false,
    );
    expect(scopedContainer.read(activeGameSessionProvider)?.saveId, '');
    expect(container.read(activeGameSessionProvider), isNull);
    expect(
      tester.widget<GameHud>(find.byType(GameHud)).aiAutopilotEnabled,
      isTrue,
    );
  });

  testWidgets('returning to menu from multiplayer stores resume match', (
    tester,
  ) async {
    final save = _makeSave(id: 'match_1', gameMode: GameMode.multiplayer);
    final container = _makeMultiplayerGameContainer(save);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const SizedBox(key: Key('main-menu-screen')),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) =>
              const GameScreen(selection: _selection, saveId: 'match_1'),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await _pumpCappedGameFrame(tester);

    expect(find.byType(GameHud), findsOneWidget);

    final closeGame = tester.widget<GameHud>(find.byType(GameHud)).onClose;
    await closeGame();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('network.session.matchId'), 'match_1');
    expect(find.byKey(const Key('main-menu-screen')), findsOneWidget);
  });

  testWidgets('multiplayer game stores resume match before app shutdown', (
    tester,
  ) async {
    final save = _makeSave(
      id: 'match_shutdown',
      gameMode: GameMode.multiplayer,
    );
    final container = _makeMultiplayerGameContainer(save);
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container, saveId: save.id);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('network.session.matchId'), save.id);

    await prefs.remove('network.session.matchId');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(prefs.getString('network.session.matchId'), save.id);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('renders a non-interactive map vignette below the HUD', (
    tester,
  ) async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container);

    final vignetteFinder = find.byKey(const Key('gameScreen.mapVignette'));
    final ignorePointer = tester.widget<IgnorePointer>(vignetteFinder);
    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(of: vignetteFinder, matching: find.byType(DecoratedBox)),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    final gradient = decoration.gradient as RadialGradient;

    expect(ignorePointer.ignoring, isTrue);
    expect(gradient.radius, 0.92);
    expect(gradient.colors.first, Colors.transparent);
    expect(gradient.colors.last, GameUiTheme.bg.withAlpha(120));
    expect(gradient.stops, const [0.68, 1.0]);
    expect(find.byType(GameHud), findsOneWidget);
  });

  testWidgets('full map HUD capture keeps marker density and HUD aligned', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const scenarios = [
      (
        name: 'compact portrait',
        size: Size(678, 1442),
        compactDensity: true,
        showUnitDetails: false,
      ),
      (
        name: 'tablet portrait',
        size: Size(840, 1436),
        compactDensity: false,
        showUnitDetails: true,
      ),
      (
        name: 'desktop wide',
        size: Size(2592, 1438),
        compactDensity: false,
        showUnitDetails: true,
      ),
    ];

    for (final scenario in scenarios) {
      tester.view.physicalSize = scenario.size;
      final idSuffix = scenario.name.replaceAll(' ', '_');

      final save = _makeSave(id: 'save_$idSuffix');
      final unit = GameUnit(
        id: 'warrior_$idSuffix',
        ownerPlayerId: _player1.id,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 1,
      );
      final city = GameCity(
        id: 'city_$idSuffix',
        ownerPlayerId: _player1.id,
        name: 'City',
        center: const CityHex(col: 1, row: 1),
      );
      final visibleHexes = {
        for (var row = 0; row < 3; row++)
          for (var col = 0; col < 3; col++) HexCoordinate(col: col, row: row),
      };
      final snapshot = SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          activePlayerId: _player1.id,
          units: [unit],
          cities: [city],
          fogOfWar: FogOfWarState(
            players: {
              _player1.id: PlayerFogOfWar(
                playerId: _player1.id,
                visibleHexes: visibleHexes,
              ),
            },
          ),
        ),
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: snapshot},
      );
      final container = ProviderContainer(
        overrides: [
          activeMapProvider(
            _selection,
          ).overrideWithValue(AsyncData(_makeMap())),
          mapImagePathProvider(
            _selection,
          ).overrideWithValue(const AsyncData(null)),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          eventLogProvider.overrideWithValue(_FakeEventLog()),
          snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
        ],
      );

      try {
        await _pumpGameScreen(tester, container, saveId: save.id);
        final scopedContainer = ProviderScope.containerOf(
          tester.element(find.byType(GameRuntimeBinding)),
          listen: false,
        );
        await scopedContainer.read(gameStateProvider(save.id).future);
        await tester.pump();

        final renderer = scopedContainer.read(activeGameRendererProvider)!
          ..setZoom(0.75);
        await tester.pump();

        expect(
          find.byWidgetPredicate((widget) => widget is GameWidget),
          findsOneWidget,
        );
        expect(find.byType(GameHud), findsOneWidget);
        expect(renderer.unitsForTesting.map((unit) => unit.id), [unit.id]);
        expect(renderer.citiesForTesting.map((city) => city.id), [city.id]);
        expect(
          renderer.compactMarkerDensityForTesting,
          scenario.compactDensity,
          reason: '${scenario.name} marker density class',
        );
        expect(
          renderer.unitMarkerShowsPeripheralDetailsForTesting(unit.id),
          scenario.showUnitDetails,
          reason: '${scenario.name} unit details at zoom 0.75',
        );
        expect(
          renderer.cityMarkerPaintsLabelForTesting(city.id),
          isTrue,
          reason: '${scenario.name} city label at zoom 0.75',
        );

        final viewport = Offset.zero & scenario.size;
        final resourceStrip = tester.getRect(
          find.byKey(const Key('gameHud.resource.strip')),
        );
        final deck = tester.getRect(
          find.byKey(const Key('hudActionDeck.surface')),
        );
        final research = tester.getRect(
          find.byKey(const Key('globalHud.action.research')),
        );
        final objectives = tester.getRect(
          find.byKey(const Key('globalHud.action.objectives')),
        );
        final empire = tester.getRect(
          find.byKey(const Key('globalHud.action.empire')),
        );

        _expectRectInside(
          resourceStrip,
          viewport,
          reason: '${scenario.name} resource strip',
        );
        _expectRectInside(deck, viewport, reason: '${scenario.name} deck');
        _expectRectInside(
          research,
          viewport,
          reason: '${scenario.name} research action',
        );
        _expectRectInside(
          empire,
          viewport,
          reason: '${scenario.name} empire action',
        );
        expect(
          objectives.bottom,
          lessThan(deck.top),
          reason: '${scenario.name} objectives in left menu',
        );
        expect(
          resourceStrip.bottom,
          lessThan(deck.top),
          reason: '${scenario.name} top strip above deck',
        );
        if (scenario.size.width >= 900) {
          expect(
            deck.width,
            lessThanOrEqualTo(HudActionDeck.wideMaxWidth + 1),
            reason: '${scenario.name} desktop deck max width',
          );
        }
        expect(
          find.byKey(const Key('gameHud.resource.identityRow')),
          findsNothing,
          reason: '${scenario.name} identity row removed',
        );
        expect(
          find.byKey(const Key('gameHud.resource.singleRow')),
          findsOneWidget,
          reason: '${scenario.name} top resource layout',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        container.dispose();
      }
    }
  });

  testWidgets('full GameScreen mobile panel capture keeps sheets above map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final panelMap = MapData(
      cols: 5,
      rows: 5,
      tiles: [
        for (var row = 0; row < 5; row++)
          for (var col = 0; col < 5; col++)
            TileData(
              col: col,
              row: row,
              terrains: [
                [
                  const [
                    TerrainType.ocean,
                    TerrainType.coast,
                    TerrainType.plains,
                    TerrainType.grassland,
                    TerrainType.forest,
                  ],
                  const [
                    TerrainType.coast,
                    TerrainType.plains,
                    TerrainType.hills,
                    TerrainType.forest,
                    TerrainType.jungle,
                  ],
                  const [
                    TerrainType.plains,
                    TerrainType.grassland,
                    TerrainType.hills,
                    TerrainType.wetlands,
                    TerrainType.forest,
                  ],
                  const [
                    TerrainType.desert,
                    TerrainType.plains,
                    TerrainType.grassland,
                    TerrainType.hills,
                    TerrainType.tundra,
                  ],
                  const [
                    TerrainType.ocean,
                    TerrainType.coast,
                    TerrainType.desert,
                    TerrainType.tundra,
                    TerrainType.snow,
                  ],
                ][row][col],
              ],
              resources: const [],
              height: row == col ? 1 : 0,
            ),
      ],
    );
    const city = GameCity(
      id: 'city_panel',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 2, row: 2),
      controlledHexes: [
        CityHex(col: 2, row: 2),
        CityHex(col: 2, row: 3),
        CityHex(col: 3, row: 2),
      ],
    );
    final warrior = GameUnit(
      id: 'warrior_panel',
      ownerPlayerId: _player1.id,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 2,
    );
    final activeResearch = ResearchState(
      players: {
        _player1.id: PlayerResearchState(
          activeTechnologyId: TechnologyId.mining,
        ),
      },
    );
    final visibleHexes = {
      for (var row = 0; row < 5; row++)
        for (var col = 0; col < 5; col++) HexCoordinate(col: col, row: row),
    };
    final baseState = GameState(
      activePlayerId: _player1.id,
      playerColors: {_player1.id: _player1.colorValue},
      playerGold: {_player1.id: 128},
      units: [warrior],
      cities: const [city],
      research: activeResearch,
      fogOfWar: FogOfWarState(
        players: {
          _player1.id: PlayerFogOfWar(
            playerId: _player1.id,
            visibleHexes: visibleHexes,
          ),
        },
      ),
    );

    Future<void> activateGlobalAction(String actionId) async {
      final key = Key('globalHud.action.$actionId');
      final sideMenuFinder = find.byWidgetPredicate(
        (widget) => widget is GameUiSideMenuButton && widget.buttonKey == key,
      );
      if (sideMenuFinder.evaluate().isNotEmpty) {
        tester.widget<GameUiSideMenuButton>(sideMenuFinder).onPressed();
        return;
      }
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is GlobalHudActionButton && widget.actionId == actionId,
      );
      expect(finder, findsOneWidget, reason: 'global action $actionId exists');
      tester.widget<GlobalHudActionButton>(finder).onPressed();
    }

    Future<void> activateSelectionAction(String label) async {
      final finder = find.byWidgetPredicate(
        (widget) => widget is SelectionCommandChip && widget.label == label,
      );
      expect(finder, findsOneWidget, reason: 'selection action $label exists');
      tester.widget<SelectionCommandChip>(finder).onTap!();
    }

    Future<void> verifyPanel({
      required String name,
      required GameState state,
      required Future<void> Function(ProviderContainer scoped, GameState state)?
      prepare,
      required Future<void> Function() openPanel,
      required Type panelType,
      required Key surfaceKey,
      required String expectedTitle,
      Future<void> Function(Rect panel)? verifyContent,
    }) async {
      final save = _makeSave(id: 'save_panel_$name');
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: SaveSnapshot.fromGameState(save: save, state: state),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeMapProvider(_selection).overrideWithValue(AsyncData(panelMap)),
          mapImagePathProvider(
            _selection,
          ).overrideWithValue(const AsyncData(null)),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          eventLogProvider.overrideWithValue(_FakeEventLog()),
          snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
        ],
      );

      try {
        await _pumpGameScreen(tester, container, saveId: save.id);
        final scopedContainer = ProviderScope.containerOf(
          tester.element(find.byType(GameRuntimeBinding)),
          listen: false,
        );
        final loadedState = await scopedContainer.read(
          gameStateProvider(save.id).future,
        );
        await tester.pump();
        await prepare?.call(scopedContainer, loadedState);
        await tester.pump();

        final viewport = Offset.zero & const Size(390, 844);
        final gameWidget = tester.getRect(
          find.byWidgetPredicate((widget) => widget is GameWidget),
        );
        final resourceStrip = tester.getRect(
          find.byKey(const Key('gameHud.resource.strip')),
        );

        _expectRectInside(
          gameWidget,
          viewport,
          reason: '$name map widget in viewport',
        );
        _expectRectInside(
          resourceStrip,
          viewport,
          reason: '$name top resources in viewport',
        );

        await openPanel();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final deck = tester.getRect(
          find.byKey(const Key('hudActionDeck.surface')),
        );
        final panel = tester.getRect(find.byType(panelType));
        final surface = tester.getRect(find.byKey(surfaceKey));
        final mobileSheet = tester.getRect(
          find.byKey(const Key('hudOverlayPanelSlot.mobileSheet')),
        );

        expect(find.byType(GameHud), findsOneWidget, reason: name);
        expect(find.byKey(const Key('gameScreen.mapVignette')), findsOneWidget);
        expect(find.text(expectedTitle), findsOneWidget, reason: name);
        _expectRectInside(panel, viewport, reason: '$name panel in viewport');
        _expectRectInside(
          surface,
          viewport,
          reason: '$name surface in viewport',
        );
        _expectRectInside(deck, viewport, reason: '$name deck in viewport');
        _expectRectContains(
          panel.inflate(1),
          surface,
          reason: '$name surface follows panel',
        );
        expect(
          resourceStrip.bottom,
          lessThan(panel.top),
          reason: '$name panel starts below mobile top strip',
        );
        expect(
          panel.bottom,
          lessThanOrEqualTo(deck.top - 2),
          reason: '$name panel clears action deck',
        );
        expect(
          mobileSheet.width,
          greaterThanOrEqualTo(390 - 32),
          reason: '$name uses near-full-width mobile sheet',
        );
        _expectWarmPanelSurface(tester, surfaceKey, reason: name);
        await verifyContent?.call(panel);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        container.dispose();
      }
    }

    await verifyPanel(
      name: 'technology',
      state: baseState,
      prepare: null,
      openPanel: () => activateGlobalAction('research'),
      panelType: TechnologyTreePanel,
      surfaceKey: const Key('technologyTreePanel.surface'),
      expectedTitle: 'TECHNOLOGY TREE',
    );
    await verifyPanel(
      name: 'empire',
      state: baseState,
      prepare: null,
      openPanel: () => activateGlobalAction('empire'),
      panelType: EmpireOverviewPanel,
      surfaceKey: const Key('empireOverviewPanel.surface'),
      expectedTitle: 'EMPIRE',
    );
    await verifyPanel(
      name: 'production',
      state: baseState.copyWith(units: const []),
      prepare: (scoped, state) async {
        await scoped
            .read(gameCommandControllerProvider.notifier)
            .dispatch(SelectCityCommand(city.id));
        await tester.pump();
      },
      openPanel: () => activateSelectionAction('Production'),
      panelType: CityProductionPanel,
      surfaceKey: const Key('cityProductionPanel.surface'),
      expectedTitle: 'City',
      verifyContent: (panel) async {
        final firstUnit = tester.getRect(find.text('Warrior'));
        expect(
          firstUnit.bottom,
          lessThanOrEqualTo(panel.bottom),
          reason: 'production keeps the first unit decision visible',
        );
      },
    );
    await verifyPanel(
      name: 'activity_log',
      state: baseState,
      prepare: (scoped, state) async {
        scoped.read(gameEventNotificationsProvider.notifier).addAll([
          const CityFoundedEvent(
            cityId: 'city_panel',
            ownerPlayerId: 'player_1',
          ),
          const CityClaimedHexEvent(cityId: 'city_panel', col: 2, row: 3),
          const ResearchPointsGainedEvent(playerId: 'player_1', points: 7),
          const TechnologyResearchedEvent(
            playerId: 'player_1',
            technologyId: TechnologyId.agriculture,
          ),
        ], state);
        await tester.pump(const Duration(milliseconds: 2500));
        await tester.pump(const Duration(milliseconds: 400));
      },
      openPanel: () => activateGlobalAction('activityLog'),
      panelType: ActivityLogPanel,
      surfaceKey: const Key('activityLogPanel.surface'),
      expectedTitle: 'ACTIVITY LOG',
      verifyContent: (_) async {
        expect(find.text('All'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
      },
    );
  });

  testWidgets('renderer commands are dispatched in the scoped game session', (
    tester,
  ) async {
    final map = _makeMap();
    final unit = GameUnit.startingWarrior(
      ownerPlayerId: _player1.id,
      col: 1,
      row: 1,
    );
    final save = _makeSave();
    final gameRepository = _FakeGameRepository(
      snapshots: {
        save.id: _makeSnapshot(
          save: save,
          units: [unit],
          fogOfWar: _visibleFog(_player1.id, const [
            HexCoordinate(col: 1, row: 1),
          ]),
        ),
      },
    );
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(_selection).overrideWithValue(AsyncData(map)),
        mapImagePathProvider(
          _selection,
        ).overrideWithValue(const AsyncData(null)),
        gameRepositoryProvider.overrideWithValue(gameRepository),
        eventLogProvider.overrideWithValue(_FakeEventLog()),
        snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
      ],
    );
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container, saveId: save.id);
    final scopedContainer = ProviderScope.containerOf(
      tester.element(find.byType(ScopedRendererCommandDispatcher)),
      listen: false,
    );
    await scopedContainer.read(gameStateProvider(save.id).future);
    await tester.pump();

    final renderer = await _pumpUntilRendererReady(tester, scopedContainer);
    var state = scopedContainer.read(gameStateProvider(save.id)).value!;
    expect(state.selectedUnitId, unit.id);
    expect(state.moveCommandActive, isTrue);
    expect(renderer.isUnitMarkerSelectedForTesting(unit.id), isTrue);

    await renderer.handleTileTappedForTesting(map.tileAt(1, 1)!);
    await tester.pump();

    state = scopedContainer.read(gameStateProvider(save.id)).value!;
    expect(state.selectedUnitId, isNull);
    expect(renderer.isUnitMarkerSelectedForTesting(unit.id), isFalse);
    expect(renderer.selectedGridTileForTesting, (col: 1, row: 1));

    expect(gameRepository.snapshots[save.id]!.units, [unit]);
  });

  testWidgets('renderer inspection shows a tile without changing selection', (
    tester,
  ) async {
    final map = _makeMap();
    final commander = GameUnit.startingCommander(
      ownerPlayerId: _player1.id,
      col: 0,
      row: 0,
    );
    final save = _makeSave();
    final gameRepository = _FakeGameRepository(
      snapshots: {
        save.id: _makeSnapshot(
          save: save,
          units: [commander],
          fogOfWar: _visibleFog(_player1.id, const [
            HexCoordinate(col: 1, row: 1),
            HexCoordinate(col: 2, row: 2),
          ]),
        ),
      },
    );
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(_selection).overrideWithValue(AsyncData(map)),
        mapImagePathProvider(
          _selection,
        ).overrideWithValue(const AsyncData(null)),
        gameRepositoryProvider.overrideWithValue(gameRepository),
        eventLogProvider.overrideWithValue(_FakeEventLog()),
        snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
      ],
    );
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container, saveId: save.id);
    final scopedContainer = ProviderScope.containerOf(
      tester.element(find.byType(GameRuntimeBinding)),
      listen: false,
    );
    await scopedContainer.read(gameStateProvider(save.id).future);
    await tester.pump();

    final inspectedTile = map.tileAt(1, 1)!;
    final tappedTile = map.tileAt(2, 2)!;
    final selectionBeforeInspection = scopedContainer
        .read(gameStateProvider(save.id))
        .value!
        .selection;
    scopedContainer
        .read(activeGameRendererProvider)!
        .handleTileInspectedForTesting(inspectedTile);
    await tester.pump();

    var state = scopedContainer.read(gameStateProvider(save.id)).value!;
    expect(state.selection, selectionBeforeInspection);
    var inspection = scopedContainer.read(mapInspectionControllerProvider);
    expect(inspection.selection?.tile?.col, 1);
    expect(inspection.selection?.tile?.row, 1);

    await scopedContainer
        .read(activeGameRendererProvider)!
        .handleTileTappedForTesting(tappedTile);
    await tester.pump();

    state = scopedContainer.read(gameStateProvider(save.id)).value!;
    inspection = scopedContainer.read(mapInspectionControllerProvider);
    expect(inspection.active, isFalse);
    expect(state.selection, isNotNull);
  });

  testWidgets(
    'renderer inspection preview and long press selection both work',
    (tester) async {
      final map = _makeMap();
      final save = _makeSave();
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: _makeSnapshot(save: save)},
      );
      final container = ProviderContainer(
        overrides: [
          activeMapProvider(_selection).overrideWithValue(AsyncData(map)),
          mapImagePathProvider(
            _selection,
          ).overrideWithValue(const AsyncData(null)),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          eventLogProvider.overrideWithValue(_FakeEventLog()),
          snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
        ],
      );
      addTearDown(container.dispose);

      await _pumpGameScreen(tester, container, saveId: save.id);
      final scopedContainer = ProviderScope.containerOf(
        tester.element(find.byType(GameRuntimeBinding)),
        listen: false,
      );
      await scopedContainer.read(gameStateProvider(save.id).future);
      await tester.pump();

      final renderer = scopedContainer.read(activeGameRendererProvider)!;
      void previewTile(int col, int row) {
        renderer.handleTileInspectionPreviewedForTesting(map.tileAt(col, row)!);
      }

      previewTile(1, 1);
      await tester.pump();

      var inspection = scopedContainer.read(mapInspectionControllerProvider);
      expect(inspection.active, isTrue);
      expect(inspection.previewing, isTrue);
      expect(inspection.selection?.tile?.col, 1);
      expect(inspection.selection?.tile?.row, 1);
      expect(find.byType(SelectionDetailSheet), findsNothing);

      renderer.confirmTileInspectionForTesting();
      await tester.pump();

      inspection = scopedContainer.read(mapInspectionControllerProvider);
      expect(inspection.active, isTrue);
      expect(inspection.previewing, isFalse);
      expect(inspection.selection?.tile?.col, 1);
      expect(inspection.selection?.tile?.row, 1);

      previewTile(2, 1);
      await tester.pump();
      renderer.cancelTileInspectionForTesting();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        scopedContainer.read(mapInspectionControllerProvider).active,
        isFalse,
      );
      expect(find.byType(SelectionDetailSheet), findsNothing);

      renderer.handleTileLongPressedForTesting(map.tileAt(0, 2)!);
      await tester.pump();

      inspection = scopedContainer.read(mapInspectionControllerProvider);
      expect(inspection.active, isTrue);
      expect(inspection.previewing, isTrue);
      expect(inspection.selection?.tile?.col, 0);
      expect(inspection.selection?.tile?.row, 2);
      expect(inspection.anchor, isNotNull);
      final selectedState = scopedContainer
          .read(gameStateProvider(save.id))
          .value!;
      expect(selectedState.selection?.type, GameSelectionType.tile);
      expect(selectedState.selection?.tile?.col, 0);
      expect(selectedState.selection?.tile?.row, 2);
    },
  );

  testWidgets('shows error view when map loading fails', (tester) async {
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(
          _selection,
        ).overrideWith((ref) => throw Exception('map missing')),
        mapImagePathProvider(
          _selection,
        ).overrideWithValue(const AsyncData(null)),
        savedCameraProvider('').overrideWithValue(const AsyncData(null)),
        gameSaveProvider('').overrideWithValue(const AsyncData(null)),
      ],
    );
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container);

    expect(find.textContaining('Could not load map'), findsWidgets);
  });

  testWidgets('recreating the renderer disposes the previous renderer', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(_selection).overrideWithValue(AsyncData(_makeMap())),
        activeMapProvider(
          _otherSelection,
        ).overrideWithValue(AsyncData(_makeOtherMap())),
        mapImagePathProvider(
          _selection,
        ).overrideWithValue(const AsyncData(null)),
        mapImagePathProvider(
          _otherSelection,
        ).overrideWithValue(const AsyncData(null)),
        savedCameraProvider('').overrideWithValue(const AsyncData(null)),
        gameSaveProvider('').overrideWithValue(const AsyncData(null)),
      ],
    );
    addTearDown(container.dispose);

    await _pumpGameScreen(tester, container);
    final oldRenderer = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    ).read(activeGameRendererProvider);

    await _pumpGameScreen(tester, container, selection: _otherSelection);
    final newRenderer = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    ).read(activeGameRendererProvider);

    expect(oldRenderer, isA<GameRenderer>());
    expect(newRenderer, isA<GameRenderer>());
    expect(newRenderer, isNot(same(oldRenderer)));
    expect(oldRenderer?.isDisposedForTesting, isTrue);
    expect(newRenderer?.isDisposedForTesting, isFalse);
  });

  testWidgets(
    'closing the game route tears down without framework assertions',
    (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/game',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/game',
            builder: (context, state) =>
                const GameScreen(selection: _selection, saveId: ''),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final menuButton = find.descendant(
        of: find.byTooltip('Return to menu'),
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(menuButton).onTap?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('HOME'), findsOneWidget);
      expect(container.read(activeGameSessionProvider), isNull);
    },
  );

  testWidgets('map zoom debug sync waits until after GameScreen build', (
    tester,
  ) async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(mapZoomDebugProvider);
              return MediaQuery(
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(disableAnimations: true),
                child: const GameScreen(selection: _selection, saveId: ''),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(mapZoomDebugProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
