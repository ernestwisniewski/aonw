part of '../basic_strategy_test.dart';

void _registerBasicStrategyEconomyProductionExpansionRecoveryScenarios() {
  test('uses city wealth project when there is no research target', () {
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
            unlockedTechnologyIds: GameRuleset
                .defaults
                .technology
                .technologies
                .keys
                .toSet(),
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

    expect(plan.commands.whereType<SelectTechnologyCommand>(), isEmpty);
    expect(
      plan.commands.whereType<StartCityProjectCommand>(),
      contains(const StartCityProjectCommand('city_1', CityProjectType.wealth)),
    );
  });
  test('starts second settler before projects when expansion is thin', () {
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
      cities: [
        _TestCities.capital.copyWith(
          population: 4,
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
      plan.commands.whereType<StartUnitProductionCommand>().map(
        (command) => command.unitType,
      ),
      contains(GameUnitType.settler),
    );
    expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
  });
  test(
    'rebuilds a second-city settler once one-city defense is reinforced',
    () {
      final mapData = _roomyExpansionMap();
      final state = DomainState.snapshot(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 1,
            row: 2,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 2,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_3',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 3,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            population: 5,
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
        turn: 48,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 48,
        rng: AiRng.fromTurn(turn: 48, playerId: 'player_1', baseSeed: 1001),
        persona: AiPersona.economic,
        civProfile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>().map(
          (command) => command.unitType,
        ),
        contains(GameUnitType.settler),
      );
      expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
    },
  );
  test('trains an opening worker before chaining settlers', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
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
      cities: [
        _TestCities.capital.copyWith(
          population: 6,
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
      persona: AiPersona.aggressive,
    );

    final plan = const BasicStrategy().plan(view, context);
    final unitProduction = plan.commands
        .whereType<StartUnitProductionCommand>();

    expect(
      unitProduction.map((command) => command.unitType),
      contains(GameUnitType.worker),
    );
    expect(
      unitProduction.map((command) => command.unitType),
      isNot(contains(GameUnitType.settler)),
    );
  });
  test('expansive persona keeps producing settlers up to three cities', () {
    final mapData = _foundingScenarioMap();
    const secondCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Second',
      population: 4,
      center: CityHex(col: 0, row: 0),
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
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
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
      persona: AiPersona.expansive,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartUnitProductionCommand>().map(
        (command) => command.unitType,
      ),
      contains(GameUnitType.settler),
    );
  });
  test('skips production when a city already has a production queue', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      cities: [
        _TestCities.capital.copyWith(
          productionQueue: CityProductionQueue.unit(
            unitType: GameUnitType.worker,
            investedProduction: 0,
          ),
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
    expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
    expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
  });
}
