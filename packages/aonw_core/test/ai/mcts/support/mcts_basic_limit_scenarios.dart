part of '../mcts_action_generator_test.dart';

void _registerMctsBasicLimitScenarios() {
  test('keeps tactical alternatives under a tight candidate limit', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
      candidateLimit: 3,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 1),
      population: 3,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
      hitPoints: 7,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 1,
      row: 0,
      hitPoints: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );
    final commands = _commands(actions);

    expect(commands, hasLength(3));
    expect(commands, contains(const FortifyUnitCommand('warrior_1')));
  });

  test('respects candidate limit and de-duplicates commands', () {
    const fallbackPick = SelectTechnologyCommand(
      _playerId,
      TechnologyId.agriculture,
    );
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [fallbackPick, fallbackPick]),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(_view(), maxPlanningDepth: 3),
      _context(),
    );
    final commands = _commands(actions);

    expect(commands, hasLength(2));
    expect(commands, contains(fallbackPick));
    expect(
      commands,
      contains(const SelectTechnologyCommand(_playerId, TechnologyId.mining)),
    );
  });
}
