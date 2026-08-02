part of '../basic_strategy_test.dart';

void _registerBasicStrategyMilitaryPressureWarGoalScenarios() {
  test('keeps assigned offensive military focused on its war target', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 1,
        ),
        _unit(
          id: 'unrelated_enemy',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
          hitPoints: 1,
        ),
      ],
      cities: const [
        GameCity(
          id: 'goal_city',
          ownerPlayerId: 'player_3',
          name: 'Goal',
          center: CityHex(col: 7, row: 7),
        ),
      ],
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
      turn: 90,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 90,
      mode: StrategicMode.military,
      expectations: _testExpectations,
      warGoals: [
        WarGoal(
          targetPlayerId: 'player_3',
          kind: WarGoalKind.captureCity,
          targetCity: const CityHex(col: 7, row: 7),
          targetHex: const HexCoordinate(col: 7, row: 7),
          turnsBudget: 8,
          assignedUnitIds: const ['warrior_1'],
          priority: 6,
        ),
      ],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 90,
      rng: AiRng.fromTurn(turn: 90, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      isNot(contains(const AttackHexCommand('warrior_1', 0, 0))),
    );
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'warrior_1',
      ),
      isNotEmpty,
    );
  });
  test('clears frontline blockers near an assigned war goal', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
        _unit(
          id: 'frontline_blocker',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
          hitPoints: 1,
        ),
      ],
      cities: const [
        GameCity(
          id: 'goal_city',
          ownerPlayerId: 'player_3',
          name: 'Goal',
          center: CityHex(col: 4, row: 0),
        ),
      ],
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
      turn: 90,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 90,
      mode: StrategicMode.military,
      expectations: _testExpectations,
      warGoals: [
        WarGoal(
          targetPlayerId: 'player_3',
          kind: WarGoalKind.captureCity,
          targetCity: const CityHex(col: 4, row: 0),
          targetHex: const HexCoordinate(col: 4, row: 0),
          turnsBudget: 8,
          assignedUnitIds: const ['warrior_1'],
          priority: 6,
        ),
      ],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 90,
      rng: AiRng.fromTurn(turn: 90, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_1', 1, 0)),
    );
  });
  test('wakes fortified units assigned to an offensive war goal', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
          movementPoints: 0,
          posture: UnitPosture.fortified,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 1),
        ),
        GameCity(
          id: 'goal_city',
          ownerPlayerId: 'player_2',
          name: 'Goal',
          center: CityHex(col: 4, row: 0),
        ),
      ],
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
      turn: 92,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 92,
      mode: StrategicMode.military,
      expectations: _testExpectations,
      warGoals: [
        WarGoal(
          targetPlayerId: 'player_2',
          kind: WarGoalKind.captureCity,
          targetCity: const CityHex(col: 4, row: 0),
          targetHex: const HexCoordinate(col: 4, row: 0),
          turnsBudget: 6,
          assignedUnitIds: const ['warrior_1'],
          priority: 6,
        ),
      ],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 92,
      rng: AiRng.fromTurn(turn: 92, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands, contains(const CancelUnitActionCommand('warrior_1')));
    expect(
      plan.commands.whereType<MoveUnitCommand>().map(
        (command) => command.unitId,
      ),
      isNot(contains('warrior_1')),
    );
  });
  test('attacks a war-goal city already in range', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'tank_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.tank,
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'goal_city',
          ownerPlayerId: 'player_2',
          name: 'Goal',
          center: CityHex(col: 1, row: 0),
        ),
      ],
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
      turn: 80,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 80,
      mode: StrategicMode.military,
      expectations: _testExpectations,
      warGoals: [
        WarGoal(
          targetPlayerId: 'player_2',
          kind: WarGoalKind.captureCity,
          targetCity: const CityHex(col: 1, row: 0),
          targetHex: const HexCoordinate(col: 1, row: 0),
          turnsBudget: 4,
          assignedUnitIds: const ['tank_1'],
          priority: 10,
        ),
      ],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 80,
      rng: AiRng.fromTurn(turn: 80, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('tank_1', 1, 0)),
    );
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'tank_1',
      ),
      isEmpty,
    );
  });
  test('prioritizes an exposed pressure city over a generic unit attack', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'tank_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.tank,
          col: 1,
          row: 0,
        ),
        _unit(
          id: 'raider_1',
          ownerPlayerId: 'player_3',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'pressure_city',
          ownerPlayerId: 'player_2',
          name: 'Pressure',
          center: CityHex(col: 2, row: 0),
        ),
      ],
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
      turn: 80,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
      pressureTargetPlayerIds: const ['player_2'],
    );
    const strategicPlan = StrategicPlan(
      computedAtTurn: 80,
      mode: StrategicMode.military,
      expectations: _testExpectations,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 80,
      rng: AiRng.fromTurn(turn: 80, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);
    final attacks = plan.commands.whereType<AttackHexCommand>().toList();

    expect(attacks, contains(const AttackHexCommand('tank_1', 2, 0)));
    expect(attacks, isNot(contains(const AttackHexCommand('tank_1', 0, 0))));
  });
}
