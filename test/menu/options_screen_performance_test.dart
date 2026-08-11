import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/options_screen.dart';
import 'package:aonw/shared/performance/fps_counter_overlay.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw/shared/providers/display_settings_provider.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/window/game_window.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'options_screen_camera_map_scenarios.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  registerOptionsScreenCameraMapTests();

  testWidgets('options screen toggles the FPS counter setting', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Show FPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show FPS'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(container.read(performanceSettingsProvider).showFps, isTrue);
  });

  testWidgets('graphics section precedes audio and toggles windowed mode', (
    tester,
  ) async {
    final window = _RecordingGameWindow();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameWindowProvider.overrideWithValue(window)],
        child: const _LocalizedHarness(child: OptionsScreen()),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Windowed mode'));
    await tester.pumpAndSettle();

    final graphicsSection = find.text('GRAPHICS');
    final audioSection = find.text('AUDIO');
    expect(graphicsSection, findsOneWidget);
    expect(audioSection, findsOneWidget);
    expect(
      tester.getTopLeft(graphicsSection).dy,
      lessThan(tester.getTopLeft(audioSection).dy),
    );

    await tester.tap(find.text('Windowed mode'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    expect(container.read(displaySettingsProvider).windowed, isTrue);
    expect(window.appliedWindowModes, [true]);
  });

  testWidgets('graphics section is hidden on unsupported platforms', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameWindowProvider.overrideWithValue(
            _RecordingGameWindow(supportsWindowModes: false),
          ),
        ],
        child: const _LocalizedHarness(child: OptionsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('GRAPHICS'), findsNothing);
    expect(find.text('Windowed mode'), findsNothing);
  });

  testWidgets('options screen toggles the map zoom debug setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Show map zoom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show map zoom'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(container.read(performanceSettingsProvider).showMapZoom, isTrue);
  });

  testWidgets('options screen toggles the AI battery saver setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('AI battery saver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI battery saver'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(container.read(aiSettingsProvider).batterySaver, isTrue);
  });

  testWidgets('options screen toggles gamepad input', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Gamepad input'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gamepad input'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(container.read(gameplaySettingsProvider).gamepad.enabled, isFalse);
  });

  testWidgets('options screen renders gamepad controls at the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    final mapSection = find.text('MAP DISPLAY');
    final cameraSection = find.text('CAMERA');
    final automationSection = find.text('AUTOMATION');
    final performanceSection = find.text('PERFORMANCE');
    final gamepadSection = find.text('GAMEPAD CONTROLS');

    expect(mapSection, findsOneWidget);
    expect(cameraSection, findsOneWidget);
    expect(automationSection, findsOneWidget);
    expect(performanceSection, findsOneWidget);
    expect(gamepadSection, findsOneWidget);
    expect(
      tester.getTopLeft(gamepadSection).dy,
      greaterThan(tester.getTopLeft(performanceSection).dy),
    );
  });

  testWidgets('options screen signs out of stored multiplayer account', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'network.session.userId': 'user_1',
      'network.session.displayName': 'Alice',
      'network.session.matchId': 'match_1',
    });
    final secureTokens = _MemorySecureSessionTokenStore({
      'network.session.refreshToken': 'refresh_1',
    });
    final client = _FakeLogoutNetworkSessionClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkSessionClientProvider.overrideWithValue(client),
          networkSessionStoreProvider.overrideWithValue(
            NetworkSessionStore(secureTokens: secureTokens),
          ),
        ],
        child: const _LocalizedHarness(child: OptionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('options.multiplayer.signOut')),
    );
    final signOutButton = tester.widget<EpicButton>(
      find.byKey(const Key('options.multiplayer.signOut')),
    );
    expect(signOutButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('options.multiplayer.signOut')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(client.signedOutToken, isNull);
    expect(client.signedOutRefreshToken, 'refresh_1');
    expect(prefs.getString('network.session.userId'), isNull);
    expect(prefs.getString('network.session.matchId'), isNull);
    expect(prefs.getString('network.session.displayName'), 'Alice');
    expect(await secureTokens.read('network.session.refreshToken'), isNull);
  });

  testWidgets('options screen signs out of active multiplayer session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'network.session.userId': 'user_1',
      'network.session.displayName': 'Alice',
      'network.session.matchId': 'match_1',
    });
    final secureTokens = _MemorySecureSessionTokenStore();
    final client = _FakeLogoutNetworkSessionClient();
    final providerContainer = ProviderContainer(
      overrides: [
        networkSessionClientProvider.overrideWithValue(client),
        networkSessionStoreProvider.overrideWithValue(
          NetworkSessionStore(secureTokens: secureTokens),
        ),
      ],
    );
    addTearDown(providerContainer.dispose);
    providerContainer
        .read(networkSessionStateProvider.notifier)
        .set(
          NetworkSession(
            userId: 'user_1',
            token: AuthToken('jwt-token'),
            refreshToken: 'refresh_1',
            matchId: 'match_1',
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: const _LocalizedHarness(child: OptionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('options.multiplayer.signOut')),
    );
    final signOutButton = tester.widget<EpicButton>(
      find.byKey(const Key('options.multiplayer.signOut')),
    );
    expect(signOutButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('options.multiplayer.signOut')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    expect(client.signedOutToken?.value, 'jwt-token');
    expect(client.signedOutRefreshToken, 'refresh_1');
    expect(container.read(networkSessionProvider), isNull);
    expect(prefs.getString('network.session.userId'), isNull);
    expect(prefs.getString('network.session.matchId'), isNull);
    expect(prefs.getString('network.session.displayName'), 'Alice');
  });

  testWidgets('options screen orders languages alphabetically', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    final languageDropdown = tester.widget<DropdownButton<GameLanguage>>(
      find.descendant(
        of: find.byKey(const ValueKey('options.language.en')),
        matching: find.byType(DropdownButton<GameLanguage>),
      ),
    );

    expect(
      languageDropdown.items
          ?.map((item) => item.value)
          .whereType<GameLanguage>(),
      [
        GameLanguage.dutch,
        GameLanguage.english,
        GameLanguage.french,
        GameLanguage.german,
        GameLanguage.polish,
        GameLanguage.spanish,
      ],
    );
  });

  testWidgets('FPS counter renders a bottom-corner sized label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Align(child: FpsCounterOverlay())),
      ),
    );

    expect(find.byKey(const Key('performance.fpsCounter')), findsOneWidget);
    expect(find.text('0 FPS'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('FPS'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FPS counter can render the current map zoom beside FPS', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            child: FpsCounterOverlay(showMapZoom: true, mapZoom: 1.25),
          ),
        ),
      ),
    );

    expect(find.text('0 FPS · 1.25Z'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            child: FpsCounterOverlay(
              showFps: false,
              showMapZoom: true,
              mapZoom: 0.75,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0.75Z'), findsOneWidget);
    expect(find.textContaining('FPS'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeLogoutNetworkSessionClient extends NetworkSessionClient {
  _FakeLogoutNetworkSessionClient()
    : super(serverpodHost: 'http://localhost:8080');

  AuthToken? signedOutToken;
  String? signedOutRefreshToken;

  @override
  Future<void> signOutCurrentSession({
    AuthToken? token,
    String? refreshToken,
  }) async {
    signedOutToken = token;
    signedOutRefreshToken = refreshToken;
  }
}

final class _RecordingGameWindow implements GameWindow {
  _RecordingGameWindow({this.supportsWindowModes = true});

  @override
  final bool supportsWindowModes;

  final List<bool> appliedWindowModes = [];

  @override
  Future<void> initialize({required bool windowed}) async {}

  @override
  Future<void> setWindowed(bool windowed) async {
    appliedWindowModes.add(windowed);
  }
}

class _MemorySecureSessionTokenStore implements SecureSessionTokenStore {
  final Map<String, String> values;

  _MemorySecureSessionTokenStore([Map<String, String>? values])
    : values = Map.of(values ?? const {});

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _LocalizedHarness extends StatelessWidget {
  const _LocalizedHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
