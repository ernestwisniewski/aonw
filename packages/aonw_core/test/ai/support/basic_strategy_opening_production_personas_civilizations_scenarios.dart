part of '../basic_strategy_test.dart';

void _registerBasicStrategyOpeningProductionPersonasCivilizationsScenarios() {
  test(
    'german roomy opening trains a reserve defender before first settler',
    () {
      final mapData = _roomyExpansionMap();
      final state = DomainState.snapshot(
        units: [
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
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 2,
        rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
        strategicPlan: const StrategicPlan(
          computedAtTurn: 2,
          mode: StrategicMode.consolidate,
          expectations: _testExpectations,
        ),
      );

      final plan = const BasicStrategy().plan(view, context);
      final unitTypes = plan.commands
          .whereType<StartUnitProductionCommand>()
          .map((command) => command.unitType);

      expect(unitTypes, contains(GameUnitType.warrior));
      expect(unitTypes, isNot(contains(GameUnitType.settler)));
      expect(unitTypes, isNot(contains(GameUnitType.worker)));
    },
  );
  test(
    'german one-city recovery fills reserve before a second-city settler',
    () {
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
        turn: 24,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 24,
        rng: AiRng.fromTurn(turn: 24, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
        strategicPlan: const StrategicPlan(
          computedAtTurn: 24,
          mode: StrategicMode.military,
          expectations: _testExpectations,
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>(),
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );
    },
  );
  test(
    'balanced one-city recovery starts a second-city settler with one guard',
    () {
      final mapData = _roomyExpansionMap();
      final state = DomainState.snapshot(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
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
        turn: 20,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 20,
        rng: AiRng.fromTurn(turn: 20, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: const StrategicPlan(
          computedAtTurn: 20,
          mode: StrategicMode.recover,
          expectations: _testExpectations,
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands,
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
    },
  );
  test('german stable two-city opening starts a third-city settler', () {
    final mapData = _roomyExpansionMap();
    const secondCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Second',
      population: 3,
      center: CityHex(col: 5, row: 5),
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
        GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 5,
          row: 4,
        ),
      ],
      cities: const [_TestCities.capital, secondCity],
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
      turn: 28,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 28,
      rng: AiRng.fromTurn(turn: 28, playerId: 'player_1', baseSeed: 1001),
      persona: profile.defaultPersona,
      civProfile: profile,
      strategicPlan: StrategicPlan(
        computedAtTurn: 28,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 1, row: 1),
            threatLevel: 0,
            assignedUnitIds: const ['warrior_1'],
          ),
          'city_2': StrategicDefenseAssignment(
            cityId: 'city_2',
            cityCenter: const CityHex(col: 5, row: 5),
            threatLevel: 0,
            assignedUnitIds: const ['warrior_2'],
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartUnitProductionCommand>(),
      contains(
        const StartUnitProductionCommand('city_1', GameUnitType.settler),
      ),
    );
  });
  test(
    'two-city opening can start a third settler with calm unassigned guards',
    () {
      final mapData = _roomyExpansionMap();
      const secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        population: 3,
        center: CityHex(col: 5, row: 5),
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
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 5,
            row: 4,
          ),
        ],
        cities: const [_TestCities.capital, secondCity],
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
        turn: 32,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 32,
        rng: AiRng.fromTurn(turn: 32, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
        strategicPlan: StrategicPlan(
          computedAtTurn: 32,
          mode: StrategicMode.military,
          expectations: _testExpectations,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 1, row: 1),
              threatLevel: 0,
              assignedUnitIds: const [],
            ),
            'city_2': StrategicDefenseAssignment(
              cityId: 'city_2',
              cityCenter: const CityHex(col: 5, row: 5),
              threatLevel: 0,
              assignedUnitIds: const [],
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);
      final unitTypes = plan.commands
          .whereType<StartUnitProductionCommand>()
          .map((command) => command.unitType)
          .toList();

      expect(
        unitTypes,
        contains(GameUnitType.settler),
        reason: 'unit production was $unitTypes',
      );
    },
  );
}
