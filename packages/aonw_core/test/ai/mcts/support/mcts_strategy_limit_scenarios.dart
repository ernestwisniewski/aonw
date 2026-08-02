part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyLimitScenarios() {
  test('keeps end planning last and respects candidate limit', () {
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(
            StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
          CommandMctsAction(
            StartCityProjectCommand('city_2', CityProjectType.wealth),
          ),
          CommandMctsAction(
            StartCityProjectCommand('city_3', CityProjectType.wealth),
          ),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(strategicPlan: _strategicPlan()),
    );

    expect(_commands(actions), hasLength(2));
    expect(actions, hasLength(3));
    expect(actions.last, const EndPlanningAction());
  });
}
