part of '../basic_strategy_test.dart';

void _registerBasicStrategyGarrisonAssignmentScenarios() {
  test('moves assigned garrison toward defended city', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 4,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
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
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 2,
      mode: StrategicMode.consolidate,
      expectations: _testExpectations,
      defenses: {
        'city_1': StrategicDefenseAssignment(
          cityId: 'city_1',
          cityCenter: const CityHex(col: 0, row: 0),
          threatLevel: 10,
          assignedUnitIds: const ['warrior_1'],
          primaryThreatPlayerId: 'player_2',
        ),
      },
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      contains(const MoveUnitCommand('warrior_1', 1, 0)),
    );
  });
  test('keeps assigned garrison in place when already defending city', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 4,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
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
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 2,
      mode: StrategicMode.consolidate,
      expectations: _testExpectations,
      defenses: {
        'city_1': StrategicDefenseAssignment(
          cityId: 'city_1',
          cityCenter: const CityHex(col: 0, row: 0),
          threatLevel: 10,
          assignedUnitIds: const ['warrior_1'],
          primaryThreatPlayerId: 'player_2',
        ),
      },
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'warrior_1',
      ),
      isEmpty,
    );
  });
  test('keeps a calm assigned garrison reserved from pressure', () {
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
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
        ),
        GameCity(
          id: 'enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Enemy',
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
      turn: 80,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
      pressureTargetPlayerIds: const ['player_2'],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 80,
      rng: AiRng.fromTurn(turn: 80, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 80,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 0,
            assignedUnitIds: const ['tank_1'],
            primaryThreatPlayerId: '',
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'tank_1',
      ),
      isEmpty,
    );
    expect(plan.commands, contains(const FortifyUnitCommand('tank_1')));
  });
  test('fortifies assigned garrison in a threatened defense area', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
          hitPoints: 6,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
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
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 2,
      mode: StrategicMode.consolidate,
      expectations: _testExpectations,
      defenses: {
        'city_1': StrategicDefenseAssignment(
          cityId: 'city_1',
          cityCenter: const CityHex(col: 0, row: 0),
          threatLevel: 10,
          assignedUnitIds: const ['warrior_1'],
          primaryThreatPlayerId: 'player_2',
        ),
      },
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<FortifyUnitCommand>(),
      contains(const FortifyUnitCommand('warrior_1')),
    );
  });
  test('keeps assigned garrison from chasing adjacent enemies', () {
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
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
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
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 2,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 10,
            assignedUnitIds: const ['warrior_1'],
            primaryThreatPlayerId: 'player_2',
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>().where(
        (command) => command.attackerUnitId == 'warrior_1',
      ),
      isEmpty,
    );
  });
}
