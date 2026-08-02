part of '../basic_strategy_test.dart';

void _registerBasicStrategyEconomyProductionDefenseProjectsScenarios() {
  test('threatened city without garrison trains a defender', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 1,
        ),
      ],
      cities: const [_TestCities.capital],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
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
          cityCenter: const CityHex(col: 1, row: 1),
          threatLevel: 12,
          assignedUnitIds: const [],
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
      plan.commands.whereType<StartUnitProductionCommand>(),
      contains(
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      ),
    );
    expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
  });
  test('threatened one-city core trains defense before worker recovery', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 1,
        ),
        GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
      ],
      cities: const [_TestCities.capital],
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
      turn: 68,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 68,
      rng: AiRng.fromTurn(turn: 68, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 68,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 1, row: 1),
            threatLevel: 8,
            assignedUnitIds: const ['warrior_1', 'warrior_2'],
            primaryThreatPlayerId: 'player_2',
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    final queuedUnits = plan.commands
        .whereType<StartUnitProductionCommand>()
        .map((command) => command.unitType)
        .toList();
    expect(queuedUnits, contains(GameUnitType.warrior));
    expect(queuedUnits, isNot(contains(GameUnitType.worker)));
  });
  test('uses city research project instead of spamming combat units', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      playerGold: const {'player_1': 16},
      units: [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
          row: 0,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          buildings: const {CityBuildingType.granary},
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
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
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<StartUnitProductionCommand>(), isEmpty);
    expect(
      plan.commands.whereType<StartCityProjectCommand>(),
      contains(
        const StartCityProjectCommand('city_1', CityProjectType.research),
      ),
    );
  });
  test('starts an unlocked city building when empire basics are covered', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      playerGold: const {'player_1': 20},
      units: [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
          row: 0,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          buildings: const {CityBuildingType.granary},
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.craftsmanship},
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 4,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 4,
      rng: AiRng.fromTurn(turn: 4, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartBuildingCommand>(),
      contains(const StartBuildingCommand('city_1', CityBuildingType.workshop)),
    );
  });
  test('economic persona prefers wealth over research at modest reserves', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      playerGold: const {'player_1': 16},
      units: [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
          row: 0,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          buildings: const {CityBuildingType.granary},
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
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
      persona: AiPersona.economic,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartCityProjectCommand>(),
      contains(const StartCityProjectCommand('city_1', CityProjectType.wealth)),
    );
  });
  test('uses city wealth project when treasury is low and gold is flat', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      playerGold: const {'player_1': 0},
      units: [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
          row: 0,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          buildings: const {CityBuildingType.granary},
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
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
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartCityProjectCommand>(),
      contains(const StartCityProjectCommand('city_1', CityProjectType.wealth)),
    );
  });
}
