import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notification_thumbnail.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders full activity timeline and filters by type', (
    tester,
  ) async {
    final entries = _entries();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityLogPanel(
              entries: entries,
              gameSave: _save,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('ACTIVITY LOG'), findsOneWidget);
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('activityLogPanel.surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    expect(decoration.color, isNull);
    expect(find.text('City founded'), findsOneWidget);
    expect(find.text('Technology discovered'), findsOneWidget);
    expect(
      find.textContaining('Warrior (Poland) attacked Warrior Enemy (Germany)'),
      findsOneWidget,
    );
    expect(find.textContaining('Warrior Enemy: -3 HP'), findsOneWidget);
    expect(
      find.text('Dispatches: A common enemy threatens us both.'),
      findsOneWidget,
    );
    expect(find.textContaining('Alice -> Bob'), findsOneWidget);

    await tester.tap(find.text('Cities'));
    await tester.pump();

    expect(find.text('City founded'), findsOneWidget);
    expect(find.text('Technology discovered'), findsNothing);
    expect(find.textContaining('Warrior Warrior'), findsNothing);

    await tester.tap(find.text('Science'));
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('City founded'), findsNothing);
    expect(find.textContaining('Alice -> Bob'), findsNothing);

    await tester.tap(find.text('Diplomacy').first);
    await tester.pump();

    expect(
      find.text('Dispatches: A common enemy threatens us both.'),
      findsOneWidget,
    );
    expect(find.textContaining('Alice -> Bob'), findsOneWidget);
    expect(find.text('Technology discovered'), findsNothing);
    expect(find.text('City founded'), findsNothing);
  });

  testWidgets('renders guided empty states for empty filters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityLogPanel(
              entries: const [],
              gameSave: _save,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('No recorded events'), findsOneWidget);
    expect(find.textContaining('First discoveries'), findsOneWidget);
    expect(find.text('Show all'), findsNothing);

    await tester.tap(find.text('Combat').first);
    await tester.pump();

    expect(find.text('No recorded battles'), findsOneWidget);
    expect(find.textContaining('Battles are recorded'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pump();

    expect(find.text('No recorded events'), findsOneWidget);
  });

  testWidgets('renders entity thumbnails in activity entries', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityLogPanel(
              entries: _thumbnailEntries(),
              gameSave: _save,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GameEventNotificationThumbnailView), findsNWidgets(4));
    expect(find.byType(BuildingSpriteIcon), findsOneWidget);
    expect(find.byType(TechnologySpriteIcon), findsOneWidget);
    expect(find.byType(UnitSpriteIcon), findsOneWidget);
  });

  testWidgets('renders turn timeline chart and filters by category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TurnTimelinePopup(
              entries: _timelineEntries(),
              gameSave: _saveWithTurn(6),
              currentTurn: 6,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('turnTimelinePopup.surface')), findsOneWidget);
    expect(find.text('TURN TIMELINE'), findsOneWidget);
    expect(find.text('Turn 6 • events: 4'), findsOneWidget);
    expect(find.text('Events across turns'), findsOneWidget);
    expect(find.byKey(const Key('turnTimelinePopup.turn.2')), findsOneWidget);
    expect(find.byKey(const Key('turnTimelinePopup.turn.4')), findsOneWidget);
    expect(find.byKey(const Key('turnTimelinePopup.turn.6')), findsOneWidget);
    expect(find.text('Technology discovered'), findsOneWidget);
    expect(
      find.textContaining('Warrior (Poland) attacked Warrior Enemy (Germany)'),
      findsOneWidget,
    );
    expect(
      find.text('Dispatches: A common enemy threatens us both.'),
      findsOneWidget,
    );
    expect(find.textContaining('Alice -> Bob'), findsOneWidget);

    await tester.tap(find.text('Combat').first);
    await tester.pump();

    expect(
      find.textContaining('Warrior (Poland) attacked Warrior Enemy (Germany)'),
      findsOneWidget,
    );
    expect(find.text('City founded'), findsNothing);
    expect(find.text('Technology discovered'), findsNothing);

    await tester.tap(find.text('Diplomacy').first);
    await tester.pump();

    expect(find.textContaining('Alice -> Bob'), findsOneWidget);
    expect(find.textContaining('Warrior Warrior'), findsNothing);
    expect(find.text('City founded'), findsNothing);
  });

  testWidgets('turn timeline combat empty state stays inside the popup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TurnTimelinePopup(
              entries: _nonCombatTimelineEntries(),
              gameSave: _saveWithTurn(8),
              currentTurn: 8,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Combat').first);
    await tester.pump();

    expect(find.text('No recorded battles'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    final surface = tester.getRect(
      find.byKey(const Key('turnTimelinePopup.surface')),
    );
    expect(surface.bottom, lessThanOrEqualTo(760));
  });

  testWidgets('uses compact mobile density for filters and entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityLogPanel(
              entries: _entries(),
              gameSave: _save,
              maxHeight: 500,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    final surface = tester.getRect(
      find.byKey(const Key('activityLogPanel.surface')),
    );
    final oldestEntryTitle = tester.getRect(find.text('City founded'));

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Diplo'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(
      find.textContaining('Warrior (Poland) attacked Warrior Enemy (Germany)'),
      findsOneWidget,
    );
    expect(
      oldestEntryTitle.bottom,
      lessThanOrEqualTo(surface.bottom),
      reason: 'compact activity log keeps the first event visible',
    );
  });
}

List<GameEventNotification> _thumbnailEntries() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Roma',
    center: CityHex(col: 1, row: 1),
  );
  const state = GameState(activePlayerId: 'player_1', cities: [city]);

  return [
    const GameEventNotification(
      id: 1,
      event: CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
      state: state,
      playerId: 'player_1',
    ),
    const GameEventNotification(
      id: 2,
      event: CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      state: state,
      playerId: 'player_1',
    ),
    const GameEventNotification(
      id: 3,
      event: CityProducedUnitEvent(
        cityId: 'city_1',
        unitType: GameUnitType.worker,
        producedUnitId: 'worker_1',
      ),
      state: state,
      playerId: 'player_1',
    ),
    const GameEventNotification(
      id: 4,
      event: TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
      state: state,
      playerId: 'player_1',
    ),
  ];
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
    Player(
      id: 'player_1',
      name: 'Alice',
      colorValue: 0xFF4A7FC4,
      country: PlayerCountry.poland,
    ),
    Player(
      id: 'player_2',
      name: 'Bob',
      colorValue: 0xFFC45050,
      country: PlayerCountry.germany,
    ),
  ],
);

GameSave _saveWithTurn(int turn) {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 5, 3),
    camera: CameraState.zero,
    players: const [
      Player(
        id: 'player_1',
        name: 'Alice',
        colorValue: 0xFF4A7FC4,
        country: PlayerCountry.poland,
      ),
      Player(
        id: 'player_2',
        name: 'Bob',
        colorValue: 0xFFC45050,
        country: PlayerCountry.germany,
      ),
    ],
  );
}

List<GameEventNotification> _entries() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Roma',
    center: CityHex(col: 1, row: 1),
  );
  final warrior = GameUnit(
    id: 'warrior_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: 'Warrior',
    col: 1,
    row: 1,
  );
  final enemy = GameUnit(
    id: 'enemy_1',
    ownerPlayerId: 'player_2',
    type: GameUnitType.warrior,
    name: 'Enemy',
    col: 2,
    row: 1,
  );
  final state = GameState(
    activePlayerId: 'player_1',
    cities: const [city],
    units: [warrior, enemy],
  );

  return [
    GameEventNotification(
      id: 1,
      event: const CityFoundedEvent(
        cityId: 'city_1',
        ownerPlayerId: 'player_1',
      ),
      state: state,
      playerId: 'player_1',
    ),
    GameEventNotification(
      id: 2,
      event: CombatResolvedEvent(
        attackerUnitId: 'warrior_1',
        defenderUnitId: 'enemy_1',
        outcome: CombatOutcome(
          attackerUnitId: 'warrior_1',
          defenderUnitId: 'enemy_1',
          attackerHpAfter: 3,
          defenderHpAfter: 0,
          attackerKilled: false,
          defenderKilled: true,
          steps: [AttackStep(damage: 3)],
        ),
      ),
      state: state,
      playerId: 'player_1',
    ),
    GameEventNotification(
      id: 3,
      event: const DiplomaticMessageSentEvent(
        messageId: 'message_1',
        fromPlayerId: 'player_1',
        toPlayerId: 'player_2',
        topic: DiplomaticMessageTopic.commonEnemy,
        category: DiplomaticMessageCategory.cooperation,
        expiresOnTurn: 8,
      ),
      state: state,
      playerId: 'player_1',
    ),
    GameEventNotification(
      id: 4,
      event: const TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
      state: state,
      playerId: 'player_1',
    ),
  ];
}

List<GameEventNotification> _timelineEntries() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Roma',
    center: CityHex(col: 1, row: 1),
  );
  final warrior = GameUnit(
    id: 'warrior_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: 'Warrior',
    col: 1,
    row: 1,
  );
  final enemy = GameUnit(
    id: 'enemy_1',
    ownerPlayerId: 'player_2',
    type: GameUnitType.warrior,
    name: 'Enemy',
    col: 2,
    row: 1,
  );
  final state = GameState(
    activePlayerId: 'player_1',
    cities: const [city],
    units: [warrior, enemy],
  );

  return [
    GameEventNotification(
      id: 1,
      event: const CityFoundedEvent(
        cityId: 'city_1',
        ownerPlayerId: 'player_1',
      ),
      state: state,
      playerId: 'player_1',
      turn: 2,
    ),
    GameEventNotification(
      id: 2,
      event: CombatResolvedEvent(
        attackerUnitId: 'warrior_1',
        defenderUnitId: 'enemy_1',
        outcome: CombatOutcome(
          attackerUnitId: 'warrior_1',
          defenderUnitId: 'enemy_1',
          attackerHpAfter: 3,
          defenderHpAfter: 0,
          attackerKilled: false,
          defenderKilled: true,
          steps: [AttackStep(damage: 3)],
        ),
      ),
      state: state,
      playerId: 'player_1',
      turn: 3,
    ),
    GameEventNotification(
      id: 3,
      event: const DiplomaticMessageSentEvent(
        messageId: 'message_1',
        fromPlayerId: 'player_1',
        toPlayerId: 'player_2',
        topic: DiplomaticMessageTopic.commonEnemy,
        category: DiplomaticMessageCategory.cooperation,
        expiresOnTurn: 8,
      ),
      state: state,
      playerId: 'player_1',
      turn: 4,
    ),
    GameEventNotification(
      id: 4,
      event: const TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
      state: state,
      playerId: 'player_1',
      turn: 5,
    ),
  ];
}

List<GameEventNotification> _nonCombatTimelineEntries() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Roma',
    center: CityHex(col: 1, row: 1),
  );
  const state = GameState(activePlayerId: 'player_1', cities: [city]);

  return [
    const GameEventNotification(
      id: 1,
      event: CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
      state: state,
      playerId: 'player_1',
      turn: 2,
    ),
    const GameEventNotification(
      id: 2,
      event: TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
      state: state,
      playerId: 'player_1',
      turn: 5,
    ),
  ];
}
