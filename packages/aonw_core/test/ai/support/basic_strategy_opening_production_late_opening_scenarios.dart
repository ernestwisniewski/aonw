part of '../basic_strategy_test.dart';

void _registerBasicStrategyOpeningProductionLateOpeningScenarios() {
  test(
    'economic two-city opening starts a third-city settler before projects',
    () {
      final mapData = _roomyExpansionMap();
      final secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        population: 3,
        center: const CityHex(col: 5, row: 5),
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
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 5,
            row: 4,
          ),
        ],
        cities: [_TestCities.capital, secondCity],
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
        turn: 34,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.netherlands]!;
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 34,
        rng: AiRng.fromTurn(turn: 34, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
        strategicPlan: StrategicPlan(
          computedAtTurn: 34,
          mode: StrategicMode.expand,
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
      final unitTypes = plan.commands
          .whereType<StartUnitProductionCommand>()
          .map((command) => command.unitType);

      expect(unitTypes, contains(GameUnitType.settler));
      expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
    },
  );
}
