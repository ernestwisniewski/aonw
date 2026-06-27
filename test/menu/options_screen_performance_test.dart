import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/options_screen.dart';
import 'package:aonw/shared/performance/fps_counter_overlay.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('options screen toggles unit movement camera follow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Follow unit movement with camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow unit movement with camera'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(
      container.read(gameplaySettingsProvider).followUnitMovementCamera,
      isTrue,
    );
  });

  testWidgets('options screen toggles cinematic camera', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Cinematic camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinematic camera'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(
      container.read(gameplaySettingsProvider).cinematicCameraEnabled,
      isTrue,
    );
  });

  testWidgets('options screen toggles enemy unit camera follow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: OptionsScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Follow enemy units with camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow enemy units with camera'));
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(
      container.read(gameplaySettingsProvider).followEnemyUnitCamera,
      isTrue,
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
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
    final providerContainer = ProviderContainer(
      overrides: [
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
    await tester.pump();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
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
