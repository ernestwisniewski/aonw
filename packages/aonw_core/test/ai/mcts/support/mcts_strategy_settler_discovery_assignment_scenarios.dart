part of '../mcts_action_generator_test.dart';

void _registerMctsStrategySettlerDiscoveryAssignmentScenarios() {
  test('prioritizes settler movement toward assigned city sites', () {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
    );
    const move = MoveUnitCommand('settler_1', 1, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(
            StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
          CommandMctsAction(move),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [settler],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          settlerAssignments: const {'settler_1': CityHex(col: 2, row: 0)},
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(move));
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes settler moves that reveal assigned founding rings', () {
    final mapData = _squareMap(cols: 5, rows: 5);
    final visibleHexes = {
      const HexCoordinate(col: 0, row: 0),
      for (final tile in mapData.tiles)
        if (HexDistance.between(
                  HexCoordinate.fromTile(tile),
                  const HexCoordinate(col: 2, row: 2),
                ) <
                CityFoundingRules.minimumCenterDistance &&
            tile.col < 4)
          HexCoordinate.fromTile(tile),
    };
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 2,
      row: 2,
    );
    const revealMove = MoveUnitCommand('settler_1', 3, 2);
    const project = StartCityProjectCommand('capital', CityProjectType.wealth);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(project),
          CommandMctsAction(revealMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
          fogOfWar: _fogForHexes(_playerId, visibleHexes),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(revealMove));
    expect(actions.last, const EndPlanningAction());
  });
  test(
    'keeps assigned settler reveal moves ahead of routine defense builds',
    () {
      final mapData = _squareMap(cols: 5, rows: 5);
      final visibleHexes = {
        const HexCoordinate(col: 0, row: 0),
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 2, row: 2),
                  ) <
                  CityFoundingRules.minimumCenterDistance &&
              tile.col < 4)
            HexCoordinate.fromTile(tile),
      };
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 2,
        row: 2,
      );
      final garrison = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      ).copyWithHitPoints(7);
      final reserve = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      const revealMove = MoveUnitCommand('settler_1', 3, 2);
      const barracks = StartBuildingCommand(
        'capital',
        CityBuildingType.barracks,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(barracks),
            CommandMctsAction(FortifyUnitCommand('warrior_1')),
            CommandMctsAction(revealMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, garrison, reserve],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
            defenses: {
              'capital': StrategicDefenseAssignment(
                cityId: 'capital',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 1,
                assignedUnitIds: const ['warrior_1'],
              ),
            },
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(revealMove));
      expect(actions.last, const EndPlanningAction());
    },
  );
  test('keeps two-city reveal moves near distant visible military', () {
    final mapData = _squareMap(cols: 7, rows: 5);
    final visibleHexes = {
      const HexCoordinate(col: 0, row: 0),
      const HexCoordinate(col: 6, row: 2),
      for (final tile in mapData.tiles)
        if (HexDistance.between(
                  HexCoordinate.fromTile(tile),
                  const HexCoordinate(col: 2, row: 2),
                ) <
                CityFoundingRules.minimumCenterDistance &&
            tile.col < 4)
          HexCoordinate.fromTile(tile),
    };
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 2,
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
    const revealMove = MoveUnitCommand('settler_1', 3, 2);
    const project = StartCityProjectCommand('capital', CityProjectType.wealth);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(project),
          CommandMctsAction(revealMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, enemy],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 6, row: 4),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
          fogOfWar: _fogForHexes(_playerId, visibleHexes),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(revealMove));
    expect(actions.last, const EndPlanningAction());
  });
  test('keeps assigned settler moves near enemy civilian units', () {
    final mapData = _squareMap(cols: 7, rows: 5);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 4,
      row: 2,
    );
    final worker = GameUnit(
      id: 'enemy_worker',
      ownerPlayerId: _enemyId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 3,
      row: 1,
    );
    const move = MoveUnitCommand('settler_1', 3, 2);
    const building = StartBuildingCommand('capital', CityBuildingType.walls);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(building),
          CommandMctsAction(move),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, worker],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 6, row: 4),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.recover,
          settlerAssignments: const {'settler_1': CityHex(col: 3, row: 2)},
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(move));
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes endangered settler retreat moves', () {
    final mapData = _squareMap(cols: 8, rows: 5);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 4,
      row: 2,
    );
    final enemy = GameUnit(
      id: 'enemy_warrior',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 3,
      row: 2,
    );
    const retreat = MoveUnitCommand('settler_1', 7, 2);
    const unsafeMove = MoveUnitCommand('settler_1', 3, 1);
    const building = StartBuildingCommand('capital', CityBuildingType.walls);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(building),
          CommandMctsAction(unsafeMove),
          CommandMctsAction(retreat),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, enemy],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 7, row: 4),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
      ),
    );

    expect(actions.first, const CommandMctsAction(retreat));
    expect(_commands(actions), isNot(contains(unsafeMove)));
    expect(actions.last, const EndPlanningAction());
  });
}
