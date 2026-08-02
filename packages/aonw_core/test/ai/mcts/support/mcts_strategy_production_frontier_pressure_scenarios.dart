part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyProductionFrontierPressureScenarios() {
  test('allows third-city settlers with minimal calm city coverage', () {
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
          units: [capitalGuard, frontierGuard],
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
      ),
    );

    expect(_commands(actions), const [settler]);
    expect(actions.last, const EndPlanningAction());
  });
  test('moves active third-city settlers before low-priority war marches', () {
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
      center: CityHex(col: 7, row: 7),
      population: 3,
    );
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 2,
      row: 2,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    const settlerMove = MoveUnitCommand('settler_1', 3, 2);
    const warMove = MoveUnitCommand('warrior_1', 1, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(warMove),
          CommandMctsAction(settlerMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );
    final mapData = _squareMap(cols: 8, rows: 8);
    final profile = CivilizationProfiles.all[PlayerCountry.france]!;

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, warrior],
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
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 4, row: 0),
              turnsBudget: 4,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.2,
            ),
          ],
        ),
      ),
    );

    expect(_commands(actions), const [settlerMove]);
    expect(actions.last, const EndPlanningAction());
  });
  test('allows escorted third-city settlers during light city pressure', () {
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
    final guards = [
      for (var i = 1; i <= 3; i++)
        GameUnit(
          id: 'warrior_$i',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: i <= 2 ? 0 : 5,
          row: i,
        ),
    ];
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
          units: [...guards, enemy],
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
              threatLevel: 2,
              assignedUnitIds: const ['warrior_1'],
              primaryThreatPlayerId: _enemyId,
            ),
            'city_2': StrategicDefenseAssignment(
              cityId: 'city_2',
              cityCenter: const CityHex(col: 5, row: 5),
              threatLevel: 0,
              assignedUnitIds: const ['warrior_3'],
            ),
          },
        ),
      ),
    );

    expect(_commands(actions), const [settler]);
    expect(actions.last, const EndPlanningAction());
  });
}
