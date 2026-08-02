part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyProductionExpansionDefenseScenarios() {
  test('keeps pinned garrison in a threatened city over settler escort', () {
    final mapData = _squareMap(cols: 5, rows: 5);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 1, row: 1),
      population: 4,
    );
    final garrison = GameUnit(
      id: 'garrison_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    ).copyWithHitPoints(7);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 3,
      row: 1,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 3,
      row: 2,
    );
    const escortMove = MoveUnitCommand('garrison_1', 2, 1);
    const fortify = FortifyUnitCommand('garrison_1');
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(escortMove),
          CommandMctsAction(fortify),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [garrison, settler, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          settlerAssignments: const {'settler_1': CityHex(col: 4, row: 1)},
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 1, row: 1),
              threatLevel: 4,
              assignedUnitIds: const ['garrison_1'],
              primaryThreatPlayerId: _enemyId,
            ),
          },
        ),
      ),
    );

    expect(_commands(actions), const [fortify]);
    expect(_commands(actions), isNot(contains(escortMove)));
    expect(actions.last, const EndPlanningAction());
  });
  test('prefers a second-city settler after local defense is covered', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    final warrior1 = GameUnit(
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
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 1,
      row: 1,
    );
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
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
          units: [warrior1, warrior2, worker, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        strategicPlan: _strategicPlan(
          mode: StrategicMode.military,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 4,
              assignedUnitIds: const ['warrior_1'],
              primaryThreatPlayerId: _enemyId,
            ),
          },
        ),
      ),
    );

    expect(_commands(actions), const [settler]);
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes third-city settlers once two cities are covered', () {
    const capital = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    const frontier = GameCity(
      id: 'city_2',
      ownerPlayerId: _playerId,
      name: 'Frontier',
      center: CityHex(col: 5, row: 5),
      population: 3,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 0,
      row: 1,
    );
    final capitalGuard = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final frontierGuard = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 5,
      row: 4,
    );
    const settler = StartUnitProductionCommand('city_1', GameUnitType.settler);
    const defender = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(defender),
          CommandMctsAction(
            StartCityProjectCommand('city_1', CityProjectType.research),
          ),
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
          units: [worker, capitalGuard, frontierGuard],
          cities: const [capital, frontier],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        civProfile: profile,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.military,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
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
      ),
    );

    expect(_commands(actions), const [settler]);
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes reserve defenders for a pressured two-city core', () {
    const capital = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 4,
    );
    const frontier = GameCity(
      id: 'city_2',
      ownerPlayerId: _playerId,
      name: 'Frontier',
      center: CityHex(col: 5, row: 5),
      population: 3,
    );
    final capitalGuard = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final frontierGuard = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 5,
      row: 5,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 1,
      row: 0,
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
    final mapData = _squareMap(cols: 8, rows: 8);
    final profile = CivilizationProfiles.all[PlayerCountry.netherlands]!;

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [capitalGuard, frontierGuard, enemy],
          cities: const [capital, frontier],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        civProfile: profile,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.consolidate,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 8,
              assignedUnitIds: const ['warrior_1'],
              primaryThreatPlayerId: _enemyId,
            ),
            'city_2': StrategicDefenseAssignment(
              cityId: 'city_2',
              cityCenter: const CityHex(col: 5, row: 5),
              threatLevel: 0,
              assignedUnitIds: const ['warrior_2'],
            ),
          },
        ),
      ),
    );

    expect(_commands(actions), const [defender]);
    expect(actions.last, const EndPlanningAction());
  });
}
