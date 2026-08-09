import 'dart:async';

import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/game/load_game_screen.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows empty state when there are no saves', (tester) async {
    await _pumpLoadGameScreen(tester, const _FakeGameRepository());

    expect(find.text('Saved games'), findsOneWidget);
    expect(find.text('No game has been started yet.'), findsOneWidget);
    expect(find.text('Saves: 0'), findsOneWidget);
    expect(find.text('No saved games.'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
  });

  testWidgets('renders save cards from gameSavesIndexProvider', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          GameSaveIndex(
            id: 'save_1',
            name: 'Campaign',
            mapName: 'verdantia',
            mapSource: MapSource.asset,
            turn: 3,
            savedAt: DateTime(2026, 4, 25, 9),
            replayAvailable: true,
          ),
        ],
      ),
    );

    expect(
      find.text('Return to recent matches and continue from the saved turn.'),
      findsOneWidget,
    );
    expect(find.text('Saves: 1'), findsOneWidget);
    expect(find.text('Campaign'), findsOneWidget);
    expect(find.text('VERDANTIA · TURN 3'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(find.text('REPLAY'), findsOneWidget);
  });

  testWidgets(
    'explicit network save with AI is marked online and denied without session',
    (tester) async {
      final index = GameSaveIndex(
        id: 'online_save',
        name: 'Ranked match',
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        turn: 5,
        savedAt: DateTime(2026, 4, 25, 9),
        gameMode: GameMode.multiplayer,
        origin: GameSaveOrigin.network,
      );
      await _pumpLoadGameScreen(
        tester,
        _FakeGameRepository(
          saves: [index],
          fullSave: _fullSaveForIndex(
            index,
            players: _localSinglePlayerParticipants,
          ),
        ),
        updateNotice: Future.value(const MultiplayerUpdateNotice()),
      );

      expect(find.text('[online] Ranked match'), findsOneWidget);
      expect(find.text('Ranked match'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'RESUME'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'RETRY'), findsOneWidget);
      expect(
        find.text('Could not resume the last multiplayer session.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keeps multiplayer resume disabled while compatibility is pending',
    (tester) async {
      final pending = Completer<MultiplayerUpdateNotice?>();
      await _pumpLoadGameScreen(
        tester,
        _FakeGameRepository(saves: [_save(gameMode: GameMode.multiplayer)]),
        updateNotice: pending.future,
        networkSession: _networkSession('save_1'),
      );

      final resume = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'RESUME'),
      );
      expect(resume.onPressed, isNull);
      expect(find.text('Connecting to match...'), findsOneWidget);
      expect(find.byKey(const Key('game-screen')), findsNothing);
    },
  );

  testWidgets(
    'explains and blocks multiplayer resume when update is required',
    (tester) async {
      await _pumpLoadGameScreen(
        tester,
        _FakeGameRepository(saves: [_save(gameMode: GameMode.multiplayer)]),
        updateNotice: Future.value(const MultiplayerUpdateNotice()),
        networkSession: _networkSession('save_1'),
      );

      final resume = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'RESUME'),
      );
      expect(resume.onPressed, isNull);
      expect(find.textContaining('newer version is ready'), findsOneWidget);
      expect(find.byKey(const Key('game-screen')), findsNothing);
    },
  );

  testWidgets('retries an unavailable check before resuming online save', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(saves: [_save(gameMode: GameMode.multiplayer)]),
      updateNoticeLoader: () async {
        attempts++;
        if (attempts == 1) throw StateError('temporary outage');
        return null;
      },
      networkSession: _networkSession('save_1'),
    );

    expect(find.text('RETRY'), findsOneWidget);
    expect(
      find.text('Could not resume the last multiplayer session.'),
      findsOneWidget,
    );

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    final resume = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'RESUME'),
    );
    expect(attempts, 2);
    expect(resume.onPressed, isNotNull);

    await tester.tap(find.text('RESUME'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });

  testWidgets('resumes an allowed multiplayer save', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(saves: [_save(gameMode: GameMode.multiplayer)]),
      updateNotice: Future.value(),
      networkSession: _networkSession('save_1'),
    );

    await tester.tap(find.text('RESUME'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });

  testWidgets('compatibility denial does not block a single-player save', (
    tester,
  ) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          _save(
            gameMode: NewGameFlow.singlePlayer.gameMode,
            name: 'multi campaign',
          ),
        ],
        fullSave: _singlePlayerSave(name: 'multi campaign'),
      ),
      updateNotice: Future.value(const MultiplayerUpdateNotice()),
    );

    await tester.tap(find.text('RESUME'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-screen')), findsOneWidget);
    expect(NewGameFlow.singlePlayer.gameMode, GameMode.multiplayer);
    expect(find.text('[online] Campaign'), findsNothing);
  });

  testWidgets('opens replay route for playable saves', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          GameSaveIndex(
            id: 'save_1',
            name: 'Campaign',
            mapName: 'verdantia',
            mapSource: MapSource.asset,
            turn: 3,
            savedAt: DateTime(2026, 4, 25, 9),
            replayAvailable: true,
          ),
        ],
      ),
    );

    await tester.tap(find.text('REPLAY'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('replay-screen')), findsOneWidget);
  });

  testWidgets('marks corrupted saves as unavailable', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          GameSaveIndex(
            id: 'broken_save',
            name: 'Broken save',
            mapName: '',
            turn: 0,
            savedAt: DateTime(2026, 4, 25, 9),
            corrupted: true,
            corruptionMessage: 'Unsupported save schema version',
          ),
        ],
      ),
    );

    expect(find.text('Broken save'), findsOneWidget);
    expect(find.text('Corrupted save'), findsOneWidget);
    expect(find.textContaining('cannot be read'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);

    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-screen')), findsNothing);
  });
}

Future<void> _pumpLoadGameScreen(
  WidgetTester tester,
  _FakeGameRepository repository, {
  Future<MultiplayerUpdateNotice?>? updateNotice,
  Future<MultiplayerUpdateNotice?> Function()? updateNoticeLoader,
  NetworkSession? networkSession,
}) async {
  final router = GoRouter(
    initialLocation: '/load',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox(key: Key('home-screen')),
      ),
      GoRoute(
        path: '/load',
        builder: (context, state) => const LoadGameScreen(),
      ),
      GoRoute(
        path: '/new-game',
        builder: (context, state) => const SizedBox(key: Key('new-game')),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const SizedBox(key: Key('game-screen')),
      ),
      GoRoute(
        path: '/replay',
        builder: (context, state) => const SizedBox(key: Key('replay-screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repository),
        networkSessionProvider.overrideWithValue(networkSession),
        gameClockProvider.overrideWithValue(
          _FixedClock(DateTime(2026, 4, 25, 12)),
        ),
        if (updateNotice != null || updateNoticeLoader != null) ...[
          multiplayerUpdateCheckEnabledProvider.overrideWithValue(true),
          multiplayerUpdateNoticeProvider.overrideWith(
            (_) => updateNoticeLoader?.call() ?? updateNotice!,
          ),
        ],
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GameSaveIndex _save({required GameMode gameMode, String name = 'Campaign'}) {
  return GameSaveIndex(
    id: 'save_1',
    name: name,
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 3,
    savedAt: DateTime(2026, 4, 25, 9),
    gameMode: gameMode,
  );
}

class _FakeGameRepository implements GameRepository {
  final List<GameSaveIndex> saves;
  final GameSave? fullSave;

  const _FakeGameRepository({this.saves = const [], this.fullSave});

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => 'save_1';

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => saves;

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    final save = fullSave ?? _fullSaveForIndex(saves.single);
    return GameSnapshotFactory.create(save: save);
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

NetworkSession _networkSession(String saveId) {
  return NetworkSession(
    userId: 'user_1',
    playerId: 'player_1',
    token: AuthToken('token'),
    matchId: saveId,
    connectionState: const NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
    ),
  );
}

const _localSinglePlayerParticipants = [
  Player(id: 'human', name: 'Human', colorValue: 0xFF4A7FC4),
  Player(
    id: 'ai',
    name: 'AI',
    colorValue: 0xFFC45050,
    kind: PlayerKind.ai,
    ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1),
  ),
];

GameSave _singlePlayerSave({String name = 'Campaign'}) {
  return _fullSaveForIndex(
    _save(gameMode: NewGameFlow.singlePlayer.gameMode, name: name),
    players: _localSinglePlayerParticipants,
  );
}

GameSave _fullSaveForIndex(
  GameSaveIndex index, {
  List<Player> players = const [],
}) {
  return GameSave(
    id: index.id,
    name: index.name,
    mapName: index.mapName,
    mapSource: index.mapSource,
    turn: index.turn,
    playerStates: const {},
    savedAt: index.savedAt,
    camera: CameraState.zero,
    players: players,
    gameMode: index.gameMode,
    origin: index.origin,
  );
}

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}
