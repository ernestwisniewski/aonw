part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyGarrisonScenarios() {
  test(
    'prioritizes defender production for threatened ungarrisoned cities',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(
              StartBuildingCommand('city_1', CityBuildingType.granary),
            ),
            CommandMctsAction(defender),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 2,
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
        _context(
          strategicPlan: _strategicPlan(
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 2,
                assignedUnitIds: const [],
                primaryThreatPlayerId: _enemyId,
              ),
            },
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(defender));
      expect(actions.last, const EndPlanningAction());
    },
  );

  test('prioritizes only-city protection over distant war attacks', () {
    final mapData = WorldMap(
      cols: 5,
      rows: 3,
      tiles: [
        for (var col = 0; col < 5; col++)
          for (var row = 0; row < 3; row++)
            WorldTile(
              col: col,
              row: row,
              terrains: const [TerrainType.plains],
              resources: const [],
              height: 0,
            ),
      ],
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final cityThreat = GameUnit(
      id: 'enemy_near',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Near',
      col: 1,
      row: 0,
      hitPoints: 1,
    );
    final distantEnemy = GameUnit(
      id: 'enemy_far',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Far',
      col: 4,
      row: 2,
    );
    const protectCity = AttackHexCommand('warrior_1', 1, 0);
    const raid = AttackHexCommand('warrior_1', 4, 2);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(raid),
          CommandMctsAction(protectCity),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, cityThreat, distantEnemy],
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
          mode: StrategicMode.military,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 8,
              assignedUnitIds: const ['warrior_1'],
              primaryThreatPlayerId: _enemyId,
            ),
          },
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 4, row: 2),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(protectCity));
    expect(actions.last, const EndPlanningAction());
  });

  test('drops raids by the last military unit away from owned cities', () {
    final mapData = WorldMap(
      cols: 5,
      rows: 1,
      tiles: [
        for (var col = 0; col < 5; col++)
          WorldTile(
            col: col,
            row: 0,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
      ],
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 3,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_far',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Far',
      col: 4,
      row: 0,
    );
    const raid = AttackHexCommand('warrior_1', 4, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [CommandMctsAction(raid), EndPlanningAction()],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.military),
      ),
    );

    expect(_commands(actions), isEmpty);
    expect(actions, const [EndPlanningAction()]);
  });

  test('drops low-impact attacks by the last military unit', () {
    final mapData = _lineMap(3);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_near',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Near',
      col: 2,
      row: 0,
    );
    const attack = AttackHexCommand('warrior_1', 2, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [CommandMctsAction(attack), EndPlanningAction()],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.military),
      ),
    );

    expect(_commands(actions), isEmpty);
    expect(actions, const [EndPlanningAction()]);
  });

  test('keeps finishing attacks by the last military unit', () {
    final mapData = _lineMap(3);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_near',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Near',
      col: 2,
      row: 0,
      hitPoints: 1,
    );
    const attack = AttackHexCommand('warrior_1', 2, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [CommandMctsAction(attack), EndPlanningAction()],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, enemy],
          cities: const [city],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.military),
      ),
    );

    expect(_commands(actions), const [attack]);
    expect(actions.last, const EndPlanningAction());
  });

  test('drops distant raids by a reserved city garrison', () {
    final mapData = _squareMap(cols: 6, rows: 2);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    final homeGuard = GameUnit(
      id: 'home_guard',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Home Guard',
      col: 0,
      row: 0,
    );
    final raider = GameUnit(
      id: 'raider',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Raider',
      col: 2,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_far',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Far',
      col: 3,
      row: 0,
      hitPoints: 1,
    );
    const homeRaid = AttackHexCommand('home_guard', 3, 0);
    const raiderAttack = AttackHexCommand('raider', 3, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(homeRaid),
          CommandMctsAction(raiderAttack),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 3,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [homeGuard, raider, enemy],
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
          mode: StrategicMode.military,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 0,
              assignedUnitIds: const ['home_guard'],
              primaryThreatPlayerId: '',
            ),
          },
        ),
      ),
    );

    expect(_commands(actions), contains(raiderAttack));
    expect(_commands(actions), isNot(contains(homeRaid)));
  });

  test('keeps calm baseline garrisons from chasing perimeter attacks', () {
    final mapData = _squareMap(cols: 4, rows: 2);
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: _playerId,
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
      population: 3,
    );
    final homeGuard = GameUnit(
      id: 'home_guard',
      ownerPlayerId: _playerId,
      type: GameUnitType.archer,
      name: 'Home Guard',
      col: 0,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_perimeter',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy Perimeter',
      col: 2,
      row: 0,
    );
    const perimeterShot = AttackHexCommand('home_guard', 2, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [CommandMctsAction(perimeterShot), EndPlanningAction()],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [homeGuard, enemy],
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
          mode: StrategicMode.consolidate,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 0,
              assignedUnitIds: const ['home_guard'],
              primaryThreatPlayerId: '',
            ),
          },
        ),
      ),
    );

    expect(_commands(actions), isNot(contains(perimeterShot)));
  });
}
