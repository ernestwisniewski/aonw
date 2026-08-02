part of '../game_hud_test.dart';

GameClientState _notificationMatrixState() {
  final worker = GameUnit(
    id: 'worker_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: 'Worker One',
    col: 2,
    row: 1,
  );
  final enemy = GameUnit(
    id: 'enemy_1',
    ownerPlayerId: 'player_2',
    type: GameUnitType.warrior,
    name: 'Enemy One',
    col: 2,
    row: 2,
  );
  return GameClientState(
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 1, row: 1),
      ),
    ],
    units: [worker, enemy],
    activePlayerId: 'player_1',
  );
}

void _addPrimaryNotificationBatch(
  ProviderContainer container,
  GameClientState state,
) {
  container.read(gameEventNotificationsProvider.notifier).addAll(const [
    CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
    CityBuiltBuildingEvent(
      cityId: 'city_1',
      buildingType: CityBuildingType.granary,
    ),
    CityProducedUnitEvent(
      cityId: 'city_1',
      unitType: GameUnitType.worker,
      producedUnitId: 'worker_2',
    ),
    CityClaimedHexEvent(cityId: 'city_1', col: 2, row: 2),
    UnitMovedEvent(
      unitId: 'worker_1',
      fromCol: 1,
      fromRow: 1,
      toCol: 2,
      toRow: 1,
    ),
    TurnEndedEvent(playerId: 'player_1'),
    WorkerCompletedJobEvent(unitId: 'worker_1'),
    ResearchPointsGainedEvent(playerId: 'player_1', points: 7),
    TechnologyResearchedEvent(
      playerId: 'player_1',
      technologyId: TechnologyId.agriculture,
    ),
  ], state);
}

void _expectPrimaryNotificationBatch() {
  expect(find.text('City founded'), findsOneWidget);
  expect(find.text('Construction complete'), findsOneWidget);
  expect(find.text('Unit trained'), findsNothing);
  expect(find.text('+4 more ↓'), findsOneWidget);
  expect(find.byType(GameEventNotificationCard), findsNWidgets(2));
  for (final hidden in const [
    'City borders',
    'Unit movement',
    'Turn ended',
    'Work complete',
    'Science',
    'Technology discovered',
  ]) {
    expect(find.text(hidden), findsNothing);
  }
}

void _addCombatNotificationBatch(
  ProviderContainer container,
  GameClientState state,
) {
  container.read(gameEventNotificationsProvider.notifier).addAll([
    const UnitAttackedEvent(
      attackerUnitId: 'worker_1',
      attackerOwnerPlayerId: 'player_1',
      defenderUnitId: 'enemy_1',
      defenderOwnerPlayerId: 'player_2',
    ),
    CombatResolvedEvent(
      attackerUnitId: 'worker_1',
      defenderUnitId: 'enemy_1',
      outcome: CombatOutcome(
        attackerUnitId: 'worker_1',
        defenderUnitId: 'enemy_1',
        attackerHpAfter: 1,
        defenderHpAfter: 0,
        attackerKilled: false,
        defenderKilled: true,
        steps: [
          const ModifierAppliedStep(
            TerrainModifier(
              label: 'terrain.forest.defense',
              target: CombatStatTarget.defense,
              delta: 1,
            ),
          ),
          const RollStep(seed: 42, value: -1),
          AttackStep(
            damage: 3,
            active: const [
              TerrainModifier(
                label: 'terrain.forest.defense',
                target: CombatStatTarget.defense,
                delta: 1,
              ),
            ],
          ),
          RetaliationStep(damage: 1),
        ],
      ),
    ),
    const UnitKilledEvent(unitId: 'worker_1', ownerPlayerId: 'player_1'),
    const UnitRetreatedEvent(
      unitId: 'worker_1',
      ownerPlayerId: 'player_1',
      fromCol: 2,
      fromRow: 1,
      toCol: 1,
      toRow: 1,
    ),
    const CityCapturedEvent(
      cityId: 'city_1',
      previousOwnerPlayerId: 'player_2',
      newOwnerPlayerId: 'player_1',
    ),
  ], state);
}

void _expectCombatNotificationBatch() {
  expect(find.text('Attack'), findsNothing);
  expect(find.text('Combat'), findsOneWidget);
  expect(find.textContaining('Enemy One: -3 HP -> defeated'), findsOneWidget);
  expect(find.textContaining('Worker One: -1 HP -> 1 HP'), findsOneWidget);
  for (final hidden in const [
    'Defender defeated',
    'Terrain forest defense +1',
    'Roll -1',
    'Attack: -3 HP',
    'Retaliation: -1 HP',
    'Retreat',
    'City captured',
  ]) {
    expect(find.text(hidden), findsNothing);
  }
  expect(find.text('Unit defeated'), findsOneWidget);
  expect(find.text('+2 more ↓'), findsOneWidget);
  expect(find.byType(GameEventNotificationCard), findsNWidgets(2));
}
