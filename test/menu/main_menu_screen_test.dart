import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/main_menu_screen.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw/menu/manual_screen.dart';
import 'package:aonw_core/protocol.dart';
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

  testWidgets('main menu resumes a persisted running multiplayer match', (
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
    expect(container.read(networkSessionProvider)?.matchId, 'match_1');
    expect(container.read(networkSessionProvider)?.playerId, 'player_1');
    expect(find.byKey(const Key('game-screen')), findsOneWidget);
  });
}

class _ThrowingAudioController extends GameAudioController {
  @override
  Future<void> play(GameSoundCue cue, {double volume = 1}) {
    throw StateError('click audio failed');
  }
}

class _FakeNetworkSessionStore extends NetworkSessionStore {
  StoredNetworkSession? session;
  final savedMatchIds = <String?>[];

  _FakeNetworkSessionStore(this.session);

  @override
  Future<StoredNetworkSession?> load() async => session;

  @override
  Future<void> saveMatchId(String? matchId) async {
    savedMatchIds.add(matchId);
    session = session?.copyWith(matchId: matchId);
  }
}

class _FakeNetworkSessionClient extends NetworkSessionClient {
  final WireMatch match;
  final refreshTokens = <String>[];
  final loadedMatchIds = <String>[];

  _FakeNetworkSessionClient({required this.match})
    : super(serverpodHost: 'https://api.example.test');

  @override
  Future<AuthToken> refresh({required String refreshToken}) async {
    refreshTokens.add(refreshToken);
    return AuthToken('fresh-jwt-token');
  }

  @override
  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  }) async {
    loadedMatchIds.add(matchId);
    return match;
  }
}

WireMatch _runningMatch() {
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
    state: 'running',
    createdAt: DateTime.utc(2026, 4, 27, 12),
  );
}
