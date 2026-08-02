part of '../mcts_action_generator_test.dart';

void _registerMctsBasicEconomyScenarios() {
  test('adds research alternatives beyond fallback plan', () {
    const fallbackPick = SelectTechnologyCommand(
      _playerId,
      TechnologyId.agriculture,
    );
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [fallbackPick]),
      candidateLimit: 8,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(_view(), maxPlanningDepth: 3),
      _context(),
    );
    final commands = _commands(actions);

    expect(commands, contains(fallbackPick));
    expect(
      commands,
      contains(const SelectTechnologyCommand(_playerId, TechnologyId.mining)),
    );
    expect(commands.where((command) => command == fallbackPick), hasLength(1));
  });

  test('adds multiple city production alternatives', () {
    const fallbackPick = StartBuildingCommand(
      'city_1',
      CityBuildingType.granary,
    );
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [fallbackPick]),
      candidateLimit: 12,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
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

    expect(commands, contains(fallbackPick));
    expect(
      commands,
      contains(const StartUnitProductionCommand('city_1', GameUnitType.worker)),
    );
    expect(
      commands,
      contains(
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      ),
    );
    expect(
      commands,
      contains(const StartCityProjectCommand('city_1', CityProjectType.wealth)),
    );
  });

  test('adds replacement production alternatives for project queues', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
      candidateLimit: 12,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: const CityHex(col: 0, row: 0),
      population: 3,
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.wealth,
      ),
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          cities: [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );
    final commands = _commands(actions);

    expect(
      commands,
      contains(const StartUnitProductionCommand('city_1', GameUnitType.worker)),
    );
    expect(
      commands,
      isNot(
        contains(
          const StartCityProjectCommand('city_1', CityProjectType.wealth),
        ),
      ),
    );
  });

  test(
    'keeps production alternatives from being starved by combat options',
    () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final units = [
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        ),
        GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          col: 1,
          row: 2,
        ),
        for (final entry in const [
          ('enemy_1', 2, 1),
          ('enemy_2', 1, 0),
          ('enemy_3', 0, 1),
          ('enemy_4', 2, 2),
          ('enemy_5', 1, 3),
          ('enemy_6', 0, 2),
        ])
          GameUnit.produced(
            id: entry.$1,
            ownerPlayerId: _enemyId,
            type: GameUnitType.warrior,
            col: entry.$2,
            row: entry.$3,
          ),
      ];

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: _squareMap(cols: 4, rows: 4),
            cities: const [city],
            units: units,
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: _squareMap(cols: 4, rows: 4)),
      );
      final commands = _commands(actions);

      expect(
        commands,
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
    },
  );

  test('adds worker improvement alternatives', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
      candidateLimit: 8,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: const CityHex(col: 0, row: 0),
      controlledHexes: const [CityHex(col: 1, row: 0)],
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.wealth,
      ),
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 1,
      row: 0,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [worker],
          cities: [city],
          research: PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
            activeTechnologyId: TechnologyId.mining,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );

    expect(
      _commands(actions),
      contains(
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.farm,
        ),
      ),
    );
  });
}
