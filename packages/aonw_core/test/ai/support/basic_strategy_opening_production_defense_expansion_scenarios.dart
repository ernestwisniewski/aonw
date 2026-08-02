part of '../basic_strategy_test.dart';

void _registerBasicStrategyOpeningProductionDefenseExpansionScenarios() {
  test('starts defender production when an empty city has no garrison', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartUnitProductionCommand>(),
      contains(
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      ),
    );
  });
  test(
    'starts second-city settler when an empty city already has a worker and guard',
    () {
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
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
        ],
        cities: [_TestCities.capital.copyWith(population: 4)],
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
        plan.commands.whereType<StartUnitProductionCommand>(),
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
    },
  );
  test('prioritizes a settler before granary when there is room to expand', () {
    final mapData = _roomyExpansionMap();
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
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        ),
      ],
      cities: [_TestCities.capital.copyWith(population: 4)],
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
      plan.commands.whereType<StartUnitProductionCommand>(),
      contains(
        const StartUnitProductionCommand('city_1', GameUnitType.settler),
      ),
    );
    expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
  });
  test('keeps expanding when a visible enemy army is distant', () {
    final mapData = _largeExpansionMap();
    const secondCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Second',
      population: 4,
      center: CityHex(col: 3, row: 5),
      buildings: {CityBuildingType.granary},
    );
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 1,
        ),
        GameUnit.produced(
          id: 'worker_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 3,
          row: 4,
        ),
        for (final entry in const [
          ('warrior_1', 1, 0),
          ('warrior_2', 1, 2),
          ('warrior_3', 3, 4),
          ('warrior_4', 4, 5),
        ])
          GameUnit.produced(
            id: entry.$1,
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: entry.$2,
            row: entry.$3,
          ),
        for (final entry in const [
          ('enemy_1', 9, 9),
          ('enemy_2', 8, 9),
          ('enemy_3', 9, 8),
          ('enemy_4', 8, 8),
          ('enemy_5', 9, 7),
        ])
          GameUnit.produced(
            id: entry.$1,
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: entry.$2,
            row: entry.$3,
          ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          population: 4,
          buildings: const {CityBuildingType.granary},
        ),
        secondCity,
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
      turn: 18,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 18,
      rng: AiRng.fromTurn(turn: 18, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);
    final unitTypes = plan.commands.whereType<StartUnitProductionCommand>().map(
      (command) => command.unitType,
    );

    expect(unitTypes, contains(GameUnitType.settler));
    expect(unitTypes, isNot(contains(GameUnitType.warrior)));
  });
  test('adds workers when cities outnumber existing workers', () {
    final mapData = _roomyExpansionMap();
    final secondCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Second',
      center: const CityHex(col: 5, row: 5),
      buildings: {CityBuildingType.granary},
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.research,
        investedProduction: 0,
      ),
    );
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
          col: 1,
          row: 0,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          buildings: const {CityBuildingType.granary},
        ),
        secondCity,
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
      plan.commands.whereType<StartUnitProductionCommand>().map(
        (command) => command.unitType,
      ),
      contains(GameUnitType.worker),
    );
  });
  test('aggressive persona trains military before a granary', () {
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
          col: 1,
          row: 0,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      persona: AiPersona.aggressive,
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
}
