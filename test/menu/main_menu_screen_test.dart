import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/main_menu_screen.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw/menu/manual_screen.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Age of New Worlds',
      packageName: 'net.aonw',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('main menu routes new game directly to singleplayer setup', (
    tester,
  ) async {
    final visitedNewGameUris = <Uri>[];
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
        GoRoute(
          path: '/new-game',
          builder: (context, state) {
            visitedNewGameUris.add(state.uri);
            return const SizedBox(key: Key('new-game-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('SINGLEPLAYER'), findsNothing);
    expect(find.text('MULTIPLAYER'), findsNothing);
    expect(find.text('HOT SEAT'), findsNothing);

    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-game-screen')), findsOneWidget);
    expect(visitedNewGameUris.last.queryParameters['mode'], 'single-player');
    expect(visitedNewGameUris.last.queryParameters['direct'], isNull);
  });

  testWidgets('main menu opens new game with gamepad focus and confirm', (
    tester,
  ) async {
    final gamepadInput = ValueNotifier<GamepadInputSnapshot>(
      GamepadInputSnapshot.empty,
    );
    addTearDown(gamepadInput.dispose);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              MainMenuScreen(gamepadInputListenable: gamepadInput),
        ),
        GoRoute(
          path: '/new-game',
          builder: (context, state) =>
              const SizedBox(key: Key('new-game-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(dpadDown: true),
    );
    await _pressGamepad(
      tester,
      gamepadInput,
      const GamepadInputSnapshot(confirm: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-game-screen')), findsOneWidget);
  });

  testWidgets('main menu manual link opens controls manual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
        GoRoute(
          path: '/manual',
          builder: (context, state) => const ManualScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MANUAL').first);
    await tester.pumpAndSettle();

    expect(find.byType(ManualScreen), findsOneWidget);
    expect(find.byKey(const Key('manual.desktopSection')), findsOneWidget);
    expect(find.byKey(const Key('manual.mobileSection')), findsOneWidget);
  });

  testWidgets('main menu manual link still routes when click audio fails', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
        GoRoute(
          path: '/manual',
          builder: (context, state) => const ManualScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameAudioControllerProvider.overrideWithValue(
            _ThrowingAudioController(),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MANUAL').first);
    await tester.pumpAndSettle();

    expect(find.byType(ManualScreen), findsOneWidget);
  });

  testWidgets('main menu exit invokes the app exit handler', (tester) async {
    var exited = false;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MainMenuScreen(
            onExit: () async {
              exited = true;
            },
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('EXIT'));
    await tester.pump();

    expect(exited, isTrue);
  });

  testWidgets('main menu shows update notice in whats new', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainMenuUpdateNoticeProvider.overrideWith(
            (_) async => const MainMenuUpdateNotice(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainMenuScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('UPDATE INCOMING'), findsOneWidget);
    expect(
      find.textContaining('will appear on this platform soon'),
      findsOneWidget,
    );
    expect(find.text('WHAT\'S NEW'), findsOneWidget);
  });

  testWidgets('main menu keeps whats new when update check fails', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainMenuUpdateNoticeProvider.overrideWith((_) async {
            throw StateError('offline');
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainMenuScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('UPDATE INCOMING'), findsNothing);
    expect(find.text('WHAT\'S NEW'), findsOneWidget);
    expect(
      find.textContaining('Welcome to the Age of New Worlds'),
      findsOneWidget,
    );
  });

  testWidgets('main menu resumes twice with each rotated refresh token', (
    tester,
  ) async {
    final store = _FakeNetworkSessionStore(
      const StoredNetworkSession(
        userId: 'user_1',
        refreshToken: 'refresh-token',
        displayName: 'Alice',
        matchId: 'match_1',
      ),
    );
    final client = _FakeNetworkSessionClient(match: _runningMatch());
    final container = ProviderContainer(
      overrides: [
        networkSessionStoreProvider.overrideWithValue(store),
        networkSessionClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
        GoRoute(
          path: '/game',
          builder: (context, state) => const SizedBox(key: Key('game-screen')),
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
    await tester.pumpAndSettle();

    expect(find.text('RESUME GAME'), findsOneWidget);

    await tester.tap(find.text('RESUME GAME'));
    await tester.pumpAndSettle();

    expect(client.refreshTokens, ['refresh-token']);
    expect(client.loadedMatchIds, ['match_1']);
    expect(client.loadedTokens, [AuthToken('fresh-jwt-token-1')]);
    expect(store.session?.refreshToken, 'rotated-refresh-token-1');
    expect(container.read(networkSessionProvider)?.matchId, 'match_1');
    expect(container.read(networkSessionProvider)?.playerId, 'player_1');
    expect(
      container.read(networkSessionProvider)?.refreshToken,
      'rotated-refresh-token-1',
    );
    expect(find.byKey(const Key('game-screen')), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESUME GAME'));
    await tester.pumpAndSettle();

    expect(client.refreshTokens, ['refresh-token', 'rotated-refresh-token-1']);
    expect(client.loadedMatchIds, ['match_1', 'match_1']);
    expect(client.loadedTokens, [
      AuthToken('fresh-jwt-token-1'),
      AuthToken('fresh-jwt-token-2'),
    ]);
    expect(store.session?.refreshToken, 'rotated-refresh-token-2');
    expect(store.savedSessions.map((session) => session.refreshToken), [
      'rotated-refresh-token-1',
      'rotated-refresh-token-2',
    ]);
    expect(
      container.read(networkSessionProvider)?.refreshToken,
      'rotated-refresh-token-2',
    );
    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });

  testWidgets(
    'main menu keeps the persisted match after a transient resume failure',
    (tester) async {
      final store = _FakeNetworkSessionStore(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-token',
          displayName: 'Alice',
          matchId: 'match_1',
        ),
      );
      final client = _FakeNetworkSessionClient(
        match: _runningMatch(),
        loadMatchError: const sp.ServerpodClientException(
          'Service temporarily unavailable',
          503,
        ),
      );
      await _pumpResumeMenu(tester, store: store, client: client);

      await tester.tap(find.text('RESUME GAME'));
      await tester.pumpAndSettle();

      expect(client.refreshTokens, ['refresh-token']);
      expect(store.savedMatchIds, isEmpty);
      expect(store.session?.matchId, 'match_1');
      expect(store.session?.refreshToken, 'rotated-refresh-token-1');
      expect(find.text('RESUME GAME'), findsOneWidget);
      expect(find.byKey(const Key('game-screen')), findsNothing);
      expect(
        find.text('Could not resume the last multiplayer session.'),
        findsOneWidget,
      );

      await tester.tap(find.text('RESUME GAME'));
      await tester.pumpAndSettle();

      expect(client.refreshTokens, [
        'refresh-token',
        'rotated-refresh-token-1',
      ]);
      expect(store.savedMatchIds, isEmpty);
      expect(store.session?.matchId, 'match_1');
      expect(find.byKey(const Key('game-screen')), findsOneWidget);
    },
  );

  for (final code in const ['match_not_found', 'not_match_player']) {
    testWidgets('main menu forgets a match after authoritative $code', (
      tester,
    ) async {
      final store = _FakeNetworkSessionStore(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-token',
          displayName: 'Alice',
          matchId: 'match_1',
        ),
      );
      final client = _FakeNetworkSessionClient(
        match: _runningMatch(),
        loadMatchError: sp.MultiplayerException(
          code: code,
          message: 'No resumable match.',
        ),
      );
      await _pumpResumeMenu(tester, store: store, client: client);

      await tester.tap(find.text('RESUME GAME'));
      await tester.pumpAndSettle();

      expect(store.savedMatchIds, [null]);
      expect(store.session?.matchId, isNull);
      expect(find.text('RESUME GAME'), findsNothing);
      expect(find.byKey(const Key('game-screen')), findsNothing);
    });
  }

  testWidgets('main menu forgets a match that is no longer running', (
    tester,
  ) async {
    final store = _FakeNetworkSessionStore(
      const StoredNetworkSession(
        userId: 'user_1',
        refreshToken: 'refresh-token',
        displayName: 'Alice',
        matchId: 'match_1',
      ),
    );
    final client = _FakeNetworkSessionClient(
      match: _runningMatch(state: 'finished'),
    );
    await _pumpResumeMenu(tester, store: store, client: client);

    await tester.tap(find.text('RESUME GAME'));
    await tester.pumpAndSettle();

    expect(store.savedMatchIds, [null]);
    expect(store.session?.matchId, isNull);
    expect(find.text('RESUME GAME'), findsNothing);
    expect(find.byKey(const Key('game-screen')), findsNothing);
  });
}

Future<void> _pumpResumeMenu(
  WidgetTester tester, {
  required _FakeNetworkSessionStore store,
  required _FakeNetworkSessionClient client,
}) async {
  final container = ProviderContainer(
    overrides: [
      networkSessionStoreProvider.overrideWithValue(store),
      networkSessionClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
      GoRoute(
        path: '/game',
        builder: (context, state) => const SizedBox(key: Key('game-screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

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
  await tester.pumpAndSettle();

  expect(find.text('RESUME GAME'), findsOneWidget);
}

class _ThrowingAudioController extends GameAudioController {
  @override
  Future<void> play(GameSoundCue cue, {double volume = 1}) {
    throw StateError('click audio failed');
  }
}

class _FakeNetworkSessionStore extends NetworkSessionStore {
  StoredNetworkSession? session;
  final savedSessions = <StoredNetworkSession>[];
  final savedMatchIds = <String?>[];

  _FakeNetworkSessionStore(this.session);

  @override
  Future<StoredNetworkSession?> load() async => session;

  @override
  Future<void> save(StoredNetworkSession session) async {
    this.session = session;
    savedSessions.add(session);
  }

  @override
  Future<void> saveMatchId(String? matchId) async {
    savedMatchIds.add(matchId);
    session = session?.copyWith(matchId: matchId);
  }
}

class _FakeNetworkSessionClient extends NetworkSessionClient {
  final WireMatch match;
  Object? loadMatchError;
  final refreshTokens = <String>[];
  final loadedMatchIds = <String>[];
  final loadedTokens = <AuthToken>[];

  _FakeNetworkSessionClient({required this.match, this.loadMatchError})
    : super(serverpodHost: 'https://api.example.test');

  @override
  Future<NetworkSessionRefreshResult> refresh({
    required String refreshToken,
  }) async {
    refreshTokens.add(refreshToken);
    final refreshNumber = refreshTokens.length;
    return NetworkSessionRefreshResult(
      token: AuthToken('fresh-jwt-token-$refreshNumber'),
      refreshToken: 'rotated-refresh-token-$refreshNumber',
    );
  }

  @override
  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  }) async {
    loadedMatchIds.add(matchId);
    loadedTokens.add(token);
    final error = loadMatchError;
    loadMatchError = null;
    if (error != null) throw error;
    return match;
  }
}

WireMatch _runningMatch({String state = 'running'}) {
  return WireMatch(
    id: 'match_1',
    ownerUserId: 'user_1',
    name: 'Duel',
    mapName: 'verdantia',
    players: const [
      WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF2563EB,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
        ready: true,
      ),
      WirePlayer(
        id: 'player_2',
        userId: 'user_2',
        name: 'Bob',
        colorValue: 0xFFDC2626,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
        ready: true,
      ),
    ],
    maxPlayers: 4,
    minPlayers: 2,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 4, 27, 12),
  );
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
  await tester.pump(const Duration(milliseconds: 180));
}
