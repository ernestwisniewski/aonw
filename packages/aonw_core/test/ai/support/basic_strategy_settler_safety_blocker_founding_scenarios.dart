part of '../basic_strategy_test.dart';

void _registerBasicStrategySettlerSafetyBlockerFoundingScenarios() {
  test('uses assigned military to clear a blocker near a spare settler', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 4,
          row: 5,
        ),
        GameUnit.produced(
          id: 'warrior_clearer',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 3,
          row: 4,
        ),
        GameUnit.produced(
          id: 'warrior_reserve',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'blocker',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 4,
          row: 4,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
        ),
        GameCity(
          id: 'second',
          ownerPlayerId: 'player_1',
          name: 'Second',
          center: CityHex(col: 7, row: 0),
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 42,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 42,
      rng: AiRng.fromTurn(turn: 42, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 42,
        mode: StrategicMode.expand,
        expectations: EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 3,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        frontierClearingAssignments: {
          'warrior_clearer': StrategicFrontierClearingAssignment(
            unitId: 'warrior_clearer',
            founderId: 'settler_1',
            targetPlayerId: 'player_2',
            targetHex: HexCoordinate(col: 4, row: 4),
            founderDistance: 1,
            priority: 4.5,
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_clearer', 4, 4)),
    );
  });
  test('trains a scout when a third-city settler has no legal site', () {
    final mapData = _largeExpansionMap();
    final state = _blockedThirdCityScoutProductionState();
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 42,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 42,
      rng: AiRng.fromTurn(turn: 42, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 42,
        mode: StrategicMode.recover,
        expectations: const EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 3,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        defenses: {
          'capital': StrategicDefenseAssignment(
            cityId: 'capital',
            cityCenter: const CityHex(col: 6, row: 1),
            threatLevel: 0,
            assignedUnitIds: ['capital_guard'],
          ),
          'second': StrategicDefenseAssignment(
            cityId: 'second',
            cityCenter: const CityHex(col: 8, row: 3),
            threatLevel: 0,
            assignedUnitIds: ['second_guard'],
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);
    final unitTypes = plan.commands.whereType<StartUnitProductionCommand>().map(
      (command) => command.unitType,
    );

    expect(unitTypes, contains(GameUnitType.scout));
  });
  test('does not found inside remembered enemy territory', () {
    final mapData = _foundingScenarioMap();
    const enemyCity = GameCity(
      id: 'enemy_city',
      ownerPlayerId: 'player_2',
      name: 'Rival',
      center: CityHex(col: 2, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 1,
          row: 1,
        ),
      ],
      cities: const [enemyCity],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    final firstFounderCommand = plan.commands.firstWhere(
      (command) =>
          command is MoveUnitCommand && command.unitId == 'settler_player_1' ||
          command is FoundCityCommand &&
              command.founderId == 'settler_player_1',
    );
    expect(firstFounderCommand, isA<MoveUnitCommand>());
  });
  test('skips founding when there is no valid neighbour', () {
    // 1x1 map: no neighbours, so no controlledHexes can be picked.
    final mapData = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
      ],
    );
    final state = DomainState.snapshot(
      units: [
        GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 0,
          row: 0,
          army: const [ArmyTroop(type: TroopType.settler, count: 1)],
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
  });
}
