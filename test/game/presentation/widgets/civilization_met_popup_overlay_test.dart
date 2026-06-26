import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud/civilization_met_popup_settings_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows civilization met popup with per-player opt-out', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    final container = _container(tester);

    _addCivilizationMetNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('Civilization encountered'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Otto von Bismarck - Bruno'), findsOneWidget);
    expect(find.textContaining('new neighbor'), findsOneWidget);
    expect(find.text('Do not show again'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Civilization encountered'), findsNothing);
  });

  testWidgets('does not show another hotseat player civilization popup', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addCivilizationMetNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('Civilization encountered'), findsNothing);

    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_1');
    await tester.pump();
    await tester.pump();

    expect(find.text('Civilization encountered'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
  });

  testWidgets('civilization met opt-out is remembered per player', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    final container = _container(tester);

    _addCivilizationMetNotification(container);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Do not show again'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(civilizationMetPopupSettingsProvider(_settingsKey()))
          .showPopup,
      isFalse,
    );

    container.read(gameEventNotificationsProvider.notifier).clear();
    _addCivilizationMetNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('Civilization encountered'), findsNothing);

    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pumpAndSettle();
    container.read(gameEventNotificationsProvider.notifier).clear();
    _addCivilizationMetNotification(
      container,
      playerId: 'player_2',
      metPlayerId: 'player_1',
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Civilization encountered'), findsOneWidget);
    expect(find.text('Poland'), findsOneWidget);
  });

  testWidgets('stored civilization opt-out keeps popup hidden', (tester) async {
    SharedPreferences.setMockInitialValues({_settingsKey(): false});
    await _pumpOverlay(tester);
    final container = _container(tester);

    _addCivilizationMetNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('Civilization encountered'), findsNothing);
    expect(container.read(gameEventNotificationsProvider), isNotEmpty);
  });
}

Future<void> _pumpOverlay(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderScope(
          overrides: [gamePlayerControlSaveProvider.overrideWithValue(_save)],
          child: Scaffold(body: CivilizationMetPopupOverlay(gameSave: _save)),
        ),
      ),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(CivilizationMetPopupOverlay)),
    listen: false,
  );
}

void _addCivilizationMetNotification(
  ProviderContainer container, {
  String playerId = 'player_1',
  String metPlayerId = 'player_2',
}) {
  container.read(gameEventNotificationsProvider.notifier).addAll(
    [CivilizationMetEvent(playerId: playerId, metPlayerId: metPlayerId)],
    GameState(
      activePlayerId: playerId,
      playerColors: const {'player_1': 0xFF4A7FC4, 'player_2': 0xFFB83A3A},
      playerCountries: const {
        'player_1': PlayerCountry.poland,
        'player_2': PlayerCountry.germany,
      },
    ),
  );
}

String _settingsKey({String playerId = 'player_1'}) {
  return CivilizationMetPopupSettingsKey.forSavePlayer(_save.id, playerId);
}

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 5, 26),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
    Player(
      id: 'player_2',
      name: 'Bruno',
      colorValue: 0xFFB83A3A,
      country: PlayerCountry.germany,
      kind: PlayerKind.ai,
    ),
  ],
);
