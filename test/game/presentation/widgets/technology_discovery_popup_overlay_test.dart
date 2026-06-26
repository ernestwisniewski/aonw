import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/hud/technology_discovery_popup_settings_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_discovery_popup_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows a technology discovery popup', (tester) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);
    expect(find.textContaining('Farms'), findsOneWidget);
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('technologyDiscoveryDialog.surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    expect(decoration.color, isNull);
    expect(find.text('Do not show again'), findsOneWidget);
    expect(
      find.byKey(const Key('technologyDiscoveryDialog.minimize')),
      findsOneWidget,
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    container.read(gameEventNotificationsProvider.notifier).clear();
    _addTechnologyNotification(container, TechnologyId.mining);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
  });

  testWidgets('minimizes a technology discovery popup into HUD help entries', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('technologyDiscoveryDialog.minimize')),
    );
    await tester.pumpAndSettle();

    final state = container.read(hudMinimizedPopupsProvider);
    final entry = state.entries.single;
    expect(entry.id, _technologyDiscoveryPopupId(TechnologyId.agriculture));
    expect(entry.kind, HudMinimizedPopupKind.technologyDiscovery);
    expect(entry.title, 'Technology discovered');
    expect(entry.subtitle, contains('Agriculture'));
    expect(entry.subtitle, contains('Alice'));
    expect(entry.payload, {
      'playerId': 'player_1',
      'technologyId': TechnologyId.agriculture.name,
    });
    expect(
      container
          .read(technologyDiscoveryPopupSettingsProvider(_settingsKey()))
          .showPopup,
      isTrue,
    );

    container.read(gameEventNotificationsProvider.notifier).clear();
    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsNothing);

    container.read(gameEventNotificationsProvider.notifier).clear();
    _addTechnologyNotification(container, TechnologyId.mining);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('Mining'), findsOneWidget);
  });

  testWidgets('restores minimized technology discovery from HUD help request', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    final entry = HudMinimizedPopupEntry(
      id: _technologyDiscoveryPopupId(TechnologyId.agriculture),
      kind: HudMinimizedPopupKind.technologyDiscovery,
      title: 'Technology discovered',
      subtitle: 'Agriculture - Alice',
      payload: const {'playerId': 'player_1', 'technologyId': 'agriculture'},
    );

    container.read(hudMinimizedPopupsProvider.notifier)
      ..minimize(entry)
      ..requestRestore(entry.id);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(entry.id),
      false,
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('checkbox disables future technology discovery popups', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Do not show again'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(technologyDiscoveryPopupSettingsProvider(_settingsKey()))
          .showPopup,
      isFalse,
    );

    container.read(gameEventNotificationsProvider.notifier).clear();
    _addTechnologyNotification(container, TechnologyId.mining);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsNothing);
    expect(container.read(gameEventNotificationsProvider), isNotEmpty);
  });

  testWidgets('stored opt-out keeps discovery as toast only', (tester) async {
    SharedPreferences.setMockInitialValues({_settingsKey(): false});
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsNothing);
    expect(container.read(gameEventNotificationsProvider), isNotEmpty);
  });

  testWidgets('keeps queued technology popups scoped to their player', (
    tester,
  ) async {
    final save = _save.copyWith(
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
      ],
    );
    await _pumpOverlay(tester, save: save);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(save, 'player_2');
    await tester.pump();

    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsNothing);

    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(save, 'player_1');
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);
  });

  testWidgets('technology opt-out is remembered per player', (tester) async {
    final save = _save.copyWith(
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
        Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
      ],
    );
    await _pumpOverlay(tester, save: save);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addTechnologyNotification(container, TechnologyId.agriculture);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Do not show again'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(technologyDiscoveryPopupSettingsProvider(_settingsKey()))
          .showPopup,
      isFalse,
    );

    container.read(gameEventNotificationsProvider.notifier).clear();
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(save, 'player_2');
    await tester.pumpAndSettle();
    _addTechnologyNotification(
      container,
      TechnologyId.mining,
      playerId: 'player_2',
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('Mining'), findsOneWidget);
  });
}

Future<void> _pumpOverlay(WidgetTester tester, {GameSave? save}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderScope(
          overrides: [
            gamePlayerControlSaveProvider.overrideWithValue(save ?? _save),
          ],
          child: Scaffold(
            body: TechnologyDiscoveryPopupOverlay(gameSave: save ?? _save),
          ),
        ),
      ),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(TechnologyDiscoveryPopupOverlay)),
    listen: false,
  );
}

void _addTechnologyNotification(
  ProviderContainer container,
  TechnologyId technologyId, {
  String playerId = 'player_1',
}) {
  container.read(gameEventNotificationsProvider.notifier).addAll([
    TechnologyResearchedEvent(playerId: playerId, technologyId: technologyId),
  ], GameState(activePlayerId: playerId));
}

String _technologyDiscoveryPopupId(TechnologyId technologyId) {
  return HudMinimizedPopupIds.technologyDiscovery(
    _save.id,
    'player_1.${technologyId.name}',
  );
}

String _settingsKey({String playerId = 'player_1'}) {
  return TechnologyDiscoveryPopupSettingsKey.forSavePlayer(_save.id, playerId);
}

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 5, 3),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
  ],
);
