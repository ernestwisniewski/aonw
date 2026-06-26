import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_screen.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGameRepository implements GameRepository {
  GameMode? createdMode;
  NewGameRequest? createdRequest;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async {
    createdRequest = request;
    createdMode = request.gameMode;
    return 'save_1';
  }

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => throw UnimplementedError();

  @override
  Future<void> save(SaveSnapshot snapshot) async {}

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

MapData _map({
  int cols = 8,
  int rows = 8,
  TerrainType terrain = TerrainType.grassland,
  List<ResourceType> resources = const [
    ResourceType.wheat,
    ResourceType.iron,
    ResourceType.gold,
  ],
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: [terrain],
            resources: resources,
            height: 0,
          ),
    ],
  );
}

Future<void> _pumpLobby(
  WidgetTester tester,
  _FakeGameRepository repository, {
  NewGameFlow flow = NewGameFlow.hotSeat,
  String mapName = 'verdantia',
  MapData? mapData,
  PlayerCountry? playerCountry = PlayerCountry.poland,
  List<dynamic> overrides = const [],
}) async {
  final selection = MapSelection(name: mapName, source: MapSource.asset);
  final resolvedMapData = (mapData ?? _map())..mapName ??= mapName;
  final router = GoRouter(
    initialLocation:
        '/lobby?name=$mapName&source=asset&mode=${flow.queryValue}',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox(key: Key('main-menu')),
      ),
      GoRoute(
        path: '/new-game',
        builder: (context, state) => const SizedBox(key: Key('new-game-menu')),
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) => LobbyScreen(
          mapName: mapName,
          mapSource: MapSource.asset,
          flow: flow,
          playerCountry: playerCountry,
        ),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const SizedBox(key: Key('game-screen')),
      ),
    ],
  );

  final providerOverrides = [
    gameRepositoryProvider.overrideWithValue(repository),
    activeMapProvider(selection).overrideWithValue(AsyncData(resolvedMapData)),
  ];
  // Riverpod's Override type is not exported from flutter_riverpod; keep the
  // extra test overrides dynamic and add them after inference picks the type.
  // ignore: cascade_invocations, prefer_spread_collections
  providerOverrides.addAll(overrides.cast());

  await tester.pumpWidget(
    ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _selectGameLength(WidgetTester tester, String label) async {
  final dropdown = find.byKey(const Key('game-length-dropdown'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('starts new games in hotseat mode from lobby', (tester) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(tester, repository);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(repository.createdMode, GameMode.hotSeat);
    expect(repository.createdRequest?.players[0].country, PlayerCountry.poland);
    expect(
      repository.createdRequest?.players[1].country,
      PlayerCountry.ukraine,
    );
    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });

  testWidgets('local lobby app bar back returns to new game setup', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(tester, repository);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-game-menu')), findsOneWidget);
  });

  testWidgets('offers only supported game length presets', (tester) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(tester, repository);
    final l10n = AppLocalizations.of(tester.element(find.byType(LobbyScreen)));

    final dropdown = find.byKey(const Key('game-length-dropdown'));
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.gameLengthPresetUnlimited.toUpperCase()),
      findsWidgets,
    );
    expect(
      find.text(l10n.gameLengthPresetStandard60.toUpperCase()),
      findsWidgets,
    );
    expect(find.text(l10n.gameLengthPresetLong120.toUpperCase()), findsWidgets);
    expect(find.text('TURNS'), findsNothing);
    expect(find.textContaining('30M'), findsNothing);
    expect(find.textContaining('45M'), findsNothing);
    await tester.tap(
      find.text(l10n.gameLengthPresetStandard60.toUpperCase()).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(
      repository.createdRequest?.matchRules,
      MatchRules.forGameLength(GameLengthConfig.standard60),
    );
  });

  testWidgets('shows non-blocking map validation warnings for short games', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(
      tester,
      repository,
      mapName: 'verdantia',
      mapData: _map(cols: 30, rows: 20),
    );

    expect(find.byKey(const Key('lobby.mapValidationNotice')), findsNothing);

    await _selectGameLength(tester, 'STANDARD 60 MIN');

    expect(find.byKey(const Key('lobby.mapValidationNotice')), findsOneWidget);
    expect(find.text('Map may be too slow for this preset'), findsOneWidget);
    expect(find.textContaining('first contact'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(repository.createdRequest?.mapName, 'verdantia');
    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });

  testWidgets('blocks local start when map validation reports errors', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(
      tester,
      repository,
      mapData: _map(terrain: TerrainType.ocean, resources: const []),
    );

    expect(find.byKey(const Key('lobby.mapValidationNotice')), findsOneWidget);
    expect(find.text('Map needs fixes'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNull);
    expect(find.byKey(const Key('game-screen')), findsNothing);
  });

  testWidgets('stores selected country for local players', (tester) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(tester, repository);

    final countryDropdown = find.byKey(
      const Key('lobby.primaryCountryDropdown'),
    );
    await tester.ensureVisible(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Russia').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(
      repository.createdRequest?.players.first.country,
      PlayerCountry.russia,
    );
  });

  testWidgets('shows selected multiplayer country in quickplay lobby', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    final client = _FakeNetworkSessionClient();
    final store = _FakeNetworkSessionStore(
      const StoredNetworkSession(
        userId: 'user_1',
        refreshToken: 'refresh-token',
        displayName: 'Alice',
      ),
    );
    await _pumpLobby(
      tester,
      repository,
      flow: NewGameFlow.multiplayer,
      overrides: [
        networkSessionClientProvider.overrideWithValue(client),
        networkSessionStoreProvider.overrideWithValue(store),
      ],
    );

    await tester.pumpAndSettle();
    final countryDropdown = find.byKey(
      const Key('multiplayer.countryDropdown'),
    );
    await tester.ensureVisible(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Russia').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('multiplayer.quickplayAction')));
    await tester.pumpAndSettle();

    expect(client.quickplayRequest?.country, PlayerCountry.russia);
    expect(find.byKey(const Key('multiplayer.queuePanel')), findsOneWidget);
    expect(find.textContaining('Russia'), findsOneWidget);
  });

  testWidgets(
    'starts single player as local multiplayer with three AI opponents',
    (tester) async {
      final repository = _FakeGameRepository();
      await _pumpLobby(
        tester,
        repository,
        flow: NewGameFlow.singlePlayer,
        mapData: _map(cols: 20, rows: 20),
      );

      expect(find.text('SINGLEPLAYER'), findsOneWidget);
      expect(find.text('+ ADD PLAYER'), findsNothing);

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      final request = repository.createdRequest;
      expect(repository.createdMode, GameMode.multiplayer);
      expect(request?.players, hasLength(4));
      expect(request?.players[0].name, 'Casimir III the Great');
      expect(request?.players[0].kind, PlayerKind.human);
      expect(request?.players.skip(1).map((player) => player.kind), [
        PlayerKind.ai,
        PlayerKind.ai,
        PlayerKind.ai,
      ]);
      expect(request?.players.skip(1).map((player) => player.ai?.strategyId), [
        AiStrategyId.mcts,
        AiStrategyId.mcts,
        AiStrategyId.mcts,
      ]);
      expect(find.byKey(const Key('game-screen')), findsOneWidget);
    },
  );

  testWidgets('can mark a hotseat player as AI before starting', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(tester, repository);

    final aiAction = find.text('AI');
    await tester.ensureVisible(aiAction);
    await tester.pumpAndSettle();
    await tester.tap(aiAction);
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    final player = repository.createdRequest?.players[1];
    expect(player?.kind, PlayerKind.ai);
    expect(player?.ai?.strategyId, AiStrategyId.mcts);
    expect(player?.ai?.difficulty, AiDifficulty.normal);
    expect(player?.ai?.persona, AiPersona.balanced);
  });
}

class _FakeNetworkSessionClient extends NetworkSessionClient {
  QuickplayMatchRequest? quickplayRequest;

  _FakeNetworkSessionClient()
    : super(serverpodHost: 'https://api.example.test');

  @override
  Future<AuthToken> refresh({required String refreshToken}) async {
    return AuthToken('fresh-jwt-token');
  }

  @override
  Future<WireMatch> quickplay({
    required AuthToken token,
    required QuickplayMatchRequest request,
  }) async {
    quickplayRequest = request;
    return WireMatch(
      id: 'match_1',
      ownerUserId: 'user_1',
      name: 'Quickplay',
      mapName: request.mapName,
      players: [
        WirePlayer(
          id: 'player_1',
          userId: 'user_1',
          name: 'Alice',
          colorValue: 0xFF2563EB,
          country: request.country ?? PlayerCountry.poland,
          kind: WirePlayerKind.human,
          connectionState: WirePlayerConnectionState.connected,
        ),
      ],
      maxPlayers: 4,
      minPlayers: 2,
      quickplay: true,
      turn: 0,
      state: 'open',
      createdAt: DateTime.utc(2026, 6, 12, 12),
    );
  }
}

class _FakeNetworkSessionStore extends NetworkSessionStore {
  StoredNetworkSession? session;
  String displayName;

  _FakeNetworkSessionStore(this.session)
    : displayName = session?.displayName ?? 'Player';

  @override
  Future<StoredNetworkSession?> load() async => session;

  @override
  Future<String> loadDisplayName() async => displayName;

  @override
  Future<void> save(StoredNetworkSession session) async {
    this.session = session;
    displayName = session.displayName;
  }

  @override
  Future<void> saveDisplayName(String displayName) async {
    this.displayName = displayName;
  }

  @override
  Future<void> saveMatchId(String? matchId) async {
    session = session?.copyWith(matchId: matchId);
  }

  @override
  Future<void> clear() async {
    session = null;
  }
}
