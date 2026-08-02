part of '../basic_strategy_test.dart';

void _registerBasicStrategyEconomyProductionQueueReplacementScenarios() {
  test('replaces background city projects when core units are missing', () {
    final mapData = _roomyExpansionMap();
    final secondCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Second',
      center: const CityHex(col: 5, row: 5),
      population: 3,
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.research,
      ),
    );
    final state = DomainState.snapshot(
      units: [
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
          col: 4,
          row: 4,
        ),
      ],
      cities: [
        _TestCities.capital.copyWith(
          population: 3,
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
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
      turn: 8,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 8,
      rng: AiRng.fromTurn(turn: 8, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<StartUnitProductionCommand>().map(
        (command) => command.unitType,
      ),
      contains(GameUnitType.worker),
    );
    expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
  });
}
