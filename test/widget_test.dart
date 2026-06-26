import 'package:aonw/app/app.dart' show HexApp;
import 'package:aonw/developer/assets_editor_screen.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_screen.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/menu/main_menu_screen.dart';
import 'package:aonw/menu/options_screen.dart';
import 'package:aonw/shared/providers/accessibility_settings_provider.dart';
import 'package:aonw/shared/providers/audio_settings_provider.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Age of New Worlds',
      packageName: 'net.aonw',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
  });

  testWidgets('App configures mobile-friendly tooltip behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    final theme = Theme.of(
      tester.element(find.byType(MainMenuScreen)),
    ).tooltipTheme;

    expect(theme.triggerMode, TooltipTriggerMode.longPress);
    expect(theme.showDuration, const Duration(seconds: 5));
  });

  testWidgets('main menu settings can scale text globally', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.byType(OptionsScreen), findsOneWidget);
    expect(find.text('TEXT SIZE'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<GameLanguage>), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(DropdownButtonFormField<GameLanguage>),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Extra large'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra large'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(
      container.read(accessibilitySettingsProvider).textScale,
      GameTextScale.extraLarge,
    );
    expect(MediaQuery.textScalerOf(context).scale(10), 13);
  });

  testWidgets('main menu settings can switch to Polish', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<GameLanguage>));
    await tester.pumpAndSettle();
    for (final label in const [
      'Polish',
      'English',
      'German',
      'Spanish',
      'Dutch',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    for (final code in const ['PL', 'EN', 'DE', 'ES', 'NL']) {
      expect(find.text(code), findsWidgets);
    }
    await tester.tap(find.text('Polish').last);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(
      container.read(languageSettingsProvider).language,
      GameLanguage.polish,
    );
    expect(find.byType(OptionsScreen), findsOneWidget);
  });

  testWidgets('options screen toggles audio volume controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OptionsScreen));
    final container = ProviderScope.containerOf(context, listen: false);
    final audioSettings = container.read(gameAudioSettingsProvider);

    expect(audioSettings.soundsEnabled, isTrue);
    expect(audioSettings.soundVolume, 0.25);
    expect(audioSettings.musicEnabled, isTrue);
    expect(audioSettings.musicVolume, 0.2);
    expect(audioSettings.natureEnabled, isTrue);
    expect(audioSettings.natureVolume, 0.4);

    expect(find.text('Game sounds'), findsOneWidget);
    expect(find.text('Sound volume'), findsOneWidget);
    expect(find.text('Game music'), findsOneWidget);
    expect(find.text('Music volume'), findsOneWidget);
    expect(find.text('Nature sounds'), findsOneWidget);
    expect(find.text('Nature volume'), findsOneWidget);

    await tester.ensureVisible(find.text('Game music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game music'));
    await tester.pumpAndSettle();

    expect(container.read(gameAudioSettingsProvider).musicEnabled, isFalse);
    expect(find.text('Music volume'), findsNothing);

    await tester.ensureVisible(find.text('Game sounds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game sounds'));
    await tester.pumpAndSettle();

    expect(container.read(gameAudioSettingsProvider).soundsEnabled, isFalse);
    expect(find.text('Sound volume'), findsNothing);

    await tester.ensureVisible(find.text('Nature sounds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nature sounds'));
    await tester.pumpAndSettle();

    expect(container.read(gameAudioSettingsProvider).natureEnabled, isFalse);
    expect(find.text('Nature volume'), findsNothing);
  });

  testWidgets('main menu keeps the primary actions in order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    const primaryLabels = [
      'NEW GAME',
      'LOAD GAME',
      'SETTINGS',
      'TOOLS',
      'EXIT',
    ];
    for (final label in primaryLabels) {
      expect(find.text(label), findsOneWidget);
    }

    final positions = [
      for (final label in primaryLabels) tester.getTopLeft(find.text(label)).dy,
    ];
    for (var index = 0; index < positions.length - 1; index++) {
      expect(positions[index], lessThan(positions[index + 1]));
    }
  });

  testWidgets('new game begins with enabled mode selection', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availableMapsProvider.overrideWithValue(const AsyncData([])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NewGameScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MULTIPLAYER'), findsWidgets);
    expect(find.text('SINGLEPLAYER'), findsWidgets);
    expect(find.text('HOT SEAT'), findsWidgets);
    expect(find.text('Unavailable in the alpha release.'), findsNothing);
  });

  testWidgets('main menu shows TestFlight alpha version metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    expect(find.text('ALPHA v0.1.0+1'), findsOneWidget);
  });

  testWidgets('main menu groups developer tools under Developer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HexApp()));
    await tester.pump();

    expect(find.text('TOOLS'), findsOneWidget);
    expect(find.text('MAP EDITOR'), findsNothing);
    expect(find.text('ASSET EDITOR'), findsNothing);

    await tester.tap(find.text('TOOLS'));
    await tester.pump();

    expect(find.text('MAP EDITOR'), findsOneWidget);
    expect(find.text('ASSET EDITOR'), findsOneWidget);
  });

  testWidgets('assets editor previews catalog assets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssetsEditorScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ASSETS EDITOR'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('IDLE'), findsOneWidget);
    expect(find.text('WALK'), findsOneWidget);
    expect(find.text('ATTACK'), findsOneWidget);
    expect(find.text('WORK'), findsOneWidget);
    expect(find.text('CITY'), findsNothing);
    expect(find.text('IMPROVEMENT'), findsOneWidget);
    expect(find.text('BUILDING'), findsNothing);
    expect(find.text('DICE'), findsOneWidget);
    expect(find.text('TECHNOLOGY'), findsNothing);

    await tester.tap(find.text('WORK'));
    await tester.pump();

    expect(find.text('Worker'), findsOneWidget);

    await tester.tap(find.text('IMPROVEMENT'));
    await tester.pump();

    expect(find.text('Farm - Early'), findsOneWidget);

    await tester.tap(find.text('DICE'));
    await tester.pump();

    expect(find.text('Dice 1'), findsOneWidget);

    await tester.tap(find.text('EDIT'));
    await tester.pump();

    expect(find.text('SAVE'), findsOneWidget);
    expect(find.text('ALIGN'), findsWidgets);
    expect(find.text('SCALE'), findsWidgets);
    expect(find.text('CROP'), findsWidgets);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_right).first);
    await tester.pump();

    expect(find.text('2, 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.zoom_in).first);
    await tester.pump();

    expect(find.text('1.05x, 1.05x'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    final preview = find.byKey(
      const Key('assetsEditor.preview.assets/sprites/dice.png:frame-0'),
    );
    expect(preview, findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
