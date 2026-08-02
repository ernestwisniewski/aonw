part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyProductionOpeningReservesScenarios() {
  test('prioritizes rebuilding a reserve defender before projects', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(
            StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
          CommandMctsAction(defender),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
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
      _context(strategicPlan: _strategicPlan()),
    );

    expect(actions.first, const CommandMctsAction(defender));
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes settlers over spare defenders during safe expansion', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 0,
      row: 1,
    );
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(
            StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
          CommandMctsAction(defender),
          CommandMctsAction(settler),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, worker],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(strategicPlan: _strategicPlan(mode: StrategicMode.expand)),
    );

    expect(actions.first, const CommandMctsAction(settler));
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes safe second-city settlers over first workers', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final warrior2 = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 0,
    );
    const worker = StartUnitProductionCommand('city_1', GameUnitType.worker);
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(worker),
          CommandMctsAction(settler),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, warrior2],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(strategicPlan: _strategicPlan(mode: StrategicMode.expand)),
    );

    expect(_commands(actions), const [settler]);
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes escort production for an exposed active settler', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final garrison = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final activeSettler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 5,
      row: 2,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 6,
      row: 2,
    );
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(settler),
          CommandMctsAction(defender),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );
    final mapData = _squareMap(cols: 8, rows: 5);

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [garrison, activeSettler, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      ),
    );

    expect(_commands(actions), const [defender]);
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes worker recovery before chaining settlers', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final activeSettler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 1,
      row: 0,
    );
    const worker = StartUnitProductionCommand('city_1', GameUnitType.worker);
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(settler),
          CommandMctsAction(worker),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, activeSettler],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(strategicPlan: _strategicPlan(mode: StrategicMode.military)),
    );

    expect(_commands(actions), const [worker]);
    expect(actions.last, const EndPlanningAction());
  });
  test('defers german opening settler until reserve defense exists', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    const worker = StartUnitProductionCommand('city_1', GameUnitType.worker);
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(worker),
          CommandMctsAction(defender),
          CommandMctsAction(settler),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );
    final mapData = _squareMap(cols: 8, rows: 8);
    final profile = CivilizationProfiles.all[PlayerCountry.germany]!;

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        civProfile: profile,
      ),
    );

    expect(_commands(actions), const [defender]);
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes second-city settlers in unthreatened military plans', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final warrior2 = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 0,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 0,
      row: 1,
    );
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const project = StartCityProjectCommand('city_1', CityProjectType.wealth);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(project),
          CommandMctsAction(defender),
          CommandMctsAction(settler),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, warrior2, worker],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(strategicPlan: _strategicPlan(mode: StrategicMode.military)),
    );
    final commands = _commands(actions);

    expect(commands, const [settler]);
    expect(commands, isNot(contains(defender)));
    expect(commands, isNot(contains(project)));
    expect(actions.last, const EndPlanningAction());
  });
}
