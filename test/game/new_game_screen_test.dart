import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game_screen.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeGameRepository implements GameRepository {
  NewGameRequest? createdRequest;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async {
    createdRequest = request;
    return 'save_1';
  }

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => throw UnimplementedError();

  @override
  Future<void> save(SaveSnapshot snapshot) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('singleplayer starts directly with three AI opponents', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) =>
              const NewGameScreen(initialPlayerCountry: PlayerCountry.poland),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) => const SizedBox(key: Key('game-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    final modeTop = tester
        .getRect(find.byKey(const Key('newGame.mode.multiplayer')))
        .top;
    expect(
      tester.getRect(find.byKey(const Key('newGame.mode.single-player'))).top,
      moreOrLessEquals(modeTop, epsilon: 1),
    );
    expect(
      tester.getRect(find.byKey(const Key('newGame.mode.hot-seat'))).top,
      moreOrLessEquals(modeTop, epsilon: 1),
    );
    expect(
      modeTop,
      lessThan(
        tester.getRect(find.byKey(const Key('newGame.countryPanel'))).top,
      ),
    );
    expect(
      tester.getRect(find.byKey(const Key('newGame.countryPanel'))).bottom,
      lessThan(
        tester
            .getRect(find.byKey(const Key('newGame.singlePlayerSettingsPanel')))
            .top,
      ),
    );
    expect(
      tester
          .getRect(find.byKey(const Key('newGame.singlePlayerSettingsPanel')))
          .bottom,
      lessThan(
        tester.getRect(find.byKey(const Key('newGame.victoryPanel'))).top,
      ),
    );
    expect(
      tester.getRect(find.byKey(const Key('newGame.victoryPanel'))).bottom,
      lessThan(
        tester.getRect(find.byKey(const Key('newGame.premisePanel'))).top,
      ),
    );

    expect(find.text('Victory paths'), findsOneWidget);
    expect(find.text('Domination'), findsOneWidget);
    expect(find.text('Artifacts'), findsOneWidget);
    expect(find.textContaining('6 unique world artifacts'), findsOneWidget);
    expect(find.textContaining('5 turns'), findsOneWidget);

    expect(find.text('Casimir III the Great'), findsOneWidget);
    final countryDropdown = tester.widget<DropdownButton<PlayerCountry>>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<PlayerCountry>),
        matching: find.byType(DropdownButton<PlayerCountry>),
      ),
    );
    expect(
      countryDropdown.items?.map((item) => item.value),
      _englishAlphabeticalCountries,
    );
    expect(find.text('Normal'), findsNWidgets(2));
    await tester.tap(find.byType(DropdownButtonFormField<PlayerCountry>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('France').last);
    await tester.pumpAndSettle();
    expect(find.text('Napoleon Bonaparte'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newGame.gameLengthSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newGame.aiDifficultySelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hard').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Expedition ready'), findsOneWidget);
    expect(find.text('Random default'), findsOneWidget);
    expect(find.text('Long'), findsWidgets);
    expect(find.text('Hard'), findsWidgets);
    expect(find.text('You + 3 AI'), findsOneWidget);
    expect(repository.createdRequest, isNull);

    await tester.tap(find.text('CHANGE MAP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE').last);
    await tester.pumpAndSettle();

    expect(find.text('Chosen manually'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    final players = repository.createdRequest?.players;
    expect(repository.createdRequest?.gameMode, GameMode.multiplayer);
    expect(
      repository.createdRequest?.matchRules.gameLength,
      GameLengthConfig.long120,
    );
    expect(repository.createdRequest?.mapName, selection.name);
    expect(players, isNotNull);
    final createdPlayers = players!;
    expect(createdPlayers, hasLength(NewGameFlowX.singlePlayerPlayerCount));
    expect(createdPlayers[0].name, 'Napoleon Bonaparte');
    expect(createdPlayers[0].country, PlayerCountry.france);
    expect(createdPlayers[0].kind, PlayerKind.human);
    final aiPlayers = createdPlayers.skip(1).toList();
    expect(aiPlayers.map((player) => player.country).toSet(), hasLength(3));
    expect(
      aiPlayers.map((player) => player.country),
      isNot(contains(PlayerCountry.france)),
    );
    expect(aiPlayers.map((player) => player.kind), [
      PlayerKind.ai,
      PlayerKind.ai,
      PlayerKind.ai,
    ]);
    expect(aiPlayers.map((player) => player.ai?.strategyId), [
      AiStrategyId.mcts,
      AiStrategyId.mcts,
      AiStrategyId.mcts,
    ]);
    expect(aiPlayers.map((player) => player.ai?.difficulty), [
      AiDifficulty.hard,
      AiDifficulty.hard,
      AiDifficulty.hard,
    ]);
    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });

  testWidgets('singleplayer defaults to normal length and normal AI', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) => const NewGameScreen(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) => const SizedBox(key: Key('game-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(
      repository.createdRequest?.matchRules.gameLength,
      GameLengthConfig.normal90,
    );
    expect(
      repository.createdRequest?.players
          .skip(1)
          .map((player) => player.ai?.difficulty),
      [AiDifficulty.normal, AiDifficulty.normal, AiDifficulty.normal],
    );
  });

  testWidgets('new game app bar back follows the wizard before leaving menu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox(key: Key('main-menu')),
        ),
        GoRoute(
          path: '/new-game',
          builder: (context, state) => const NewGameScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('Expedition ready'), findsOneWidget);

    await tester.tap(find.text('CHANGE MAP'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the world'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Expedition ready'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('What story do you want to begin?'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('main-menu')), findsOneWidget);
  });

  testWidgets('multiplayer direct route opens lobby with a random map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    final visitedLobbyUris = <Uri>[];
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) => const NewGameScreen(
            flow: NewGameFlow.multiplayer,
            startAtMap: true,
          ),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) {
            visitedLobbyUris.add(state.uri);
            return const SizedBox(key: Key('lobby-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNull);
    expect(find.byKey(const Key('lobby-screen')), findsOneWidget);
    expect(visitedLobbyUris.single.queryParameters['mode'], 'multiplayer');
    expect(visitedLobbyUris.single.queryParameters['name'], 'verdantia');
    expect(visitedLobbyUris.single.queryParameters['source'], 'asset');
    expect(
      PlayerCountry.values.map((country) => country.name),
      contains(visitedLobbyUris.single.queryParameters['country']),
    );
  });

  testWidgets('multiplayer continue skips map choice and opens lobby', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    final visitedLobbyUris = <Uri>[];
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) =>
              const NewGameScreen(flow: NewGameFlow.multiplayer),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) {
            visitedLobbyUris.add(state.uri);
            return const SizedBox(key: Key('lobby-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GO TO LOBBY'), findsOneWidget);
    expect(find.text('Choose the world'), findsNothing);

    await tester.tap(find.byKey(const Key('newGame.multiplayerLobbyAction')));
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNull);
    expect(find.byKey(const Key('lobby-screen')), findsOneWidget);
    expect(visitedLobbyUris.single.queryParameters['mode'], 'multiplayer');
    expect(visitedLobbyUris.single.queryParameters['name'], 'verdantia');
    expect(
      PlayerCountry.values.map((country) => country.name),
      contains(visitedLobbyUris.single.queryParameters['country']),
    );
  });

  testWidgets('singleplayer length and difficulty labels are localized', (
    tester,
  ) async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final pl = await AppLocalizations.delegate.load(const Locale('en'));

    expect(en.gameLengthPresetShort60, 'Short');
    expect(en.gameLengthPresetNormal90, 'Normal');
    expect(en.gameLengthPresetVeryLong, 'Very long');
    expect(en.aiDifficultyVeryHard, 'Very hard');
    expect(pl.gameLengthPresetShort60, 'Short');
    expect(pl.gameLengthPresetNormal90, 'Normal');
    expect(pl.gameLengthPresetVeryLong, 'Very long');
    expect(pl.aiDifficultyVeryHard, 'Very hard');
  });
}

MapData _map() => MapData(
  cols: 20,
  rows: 20,
  mapName: 'verdantia',
  tiles: [
    for (var row = 0; row < 20; row++)
      for (var col = 0; col < 20; col++)
        TileData(
          col: col,
          row: row,
          terrains: [TerrainType.grassland],
          resources: const [
            ResourceType.wheat,
            ResourceType.iron,
            ResourceType.gold,
          ],
          height: 0,
        ),
  ],
);

const _englishAlphabeticalCountries = [
  PlayerCountry.canada,
  PlayerCountry.china,
  PlayerCountry.france,
  PlayerCountry.germany,
  PlayerCountry.italy,
  PlayerCountry.japan,
  PlayerCountry.korea,
  PlayerCountry.netherlands,
  PlayerCountry.poland,
  PlayerCountry.portugal,
  PlayerCountry.russia,
  PlayerCountry.spain,
  PlayerCountry.sweden,
  PlayerCountry.ukraine,
  PlayerCountry.unitedKingdom,
  PlayerCountry.unitedStates,
];
