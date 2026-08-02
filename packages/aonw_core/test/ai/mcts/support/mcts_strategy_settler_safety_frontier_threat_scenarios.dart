part of '../mcts_action_generator_test.dart';

void _registerMctsStrategySettlerSafetyFrontierThreatScenarios() {
  test('keeps escorted unassigned settler frontier moves under pressure', () {
    final mapData = _squareMap(cols: 6, rows: 5);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 1,
      row: 0,
    );
    final escort = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 4,
    );
    final garrison = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 5,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 5,
      row: 4,
    );
    const frontierMove = MoveUnitCommand('settler_1', 3, 4);
    const barracks = StartBuildingCommand('capital', CityBuildingType.barracks);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(barracks),
          CommandMctsAction(frontierMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, escort, garrison, enemy],
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
              center: CityHex(col: 5, row: 0),
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
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
      ),
    );

    expect(actions.first, const CommandMctsAction(frontierMove));
    expect(actions.last, const EndPlanningAction());
  });
  test('drops unescorted settler frontier moves into enemy threat', () {
    final mapData = _squareMap(cols: 6, rows: 5);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 1,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 3,
      row: 1,
    );
    const frontierMove = MoveUnitCommand('settler_1', 2, 1);
    const barracks = StartBuildingCommand('capital', CityBuildingType.barracks);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(frontierMove),
          CommandMctsAction(barracks),
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
              center: CityHex(col: 4, row: 0),
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
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
      ),
    );

    expect(_commands(actions), isNot(contains(frontierMove)));
    expect(_commands(actions).single, isA<StartBuildingCommand>());
    expect(actions.last, const EndPlanningAction());
  });
  test(
    'drops third-city settler moves that outrun origin cover near threat',
    () {
      final mapData = _squareMap(cols: 6, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      final originEscort = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 1,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 5,
        row: 4,
      );
      const frontierMove = MoveUnitCommand('settler_1', 2, 4);
      const fallback = StartBuildingCommand(
        'capital',
        CityBuildingType.barracks,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(frontierMove),
            CommandMctsAction(fallback),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, originEscort, enemy],
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
                center: CityHex(col: 5, row: 0),
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
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        ),
      );

      expect(_commands(actions), isNot(contains(frontierMove)));
      expect(_commands(actions).single, fallback);
      expect(actions.last, const EndPlanningAction());
    },
  );
  test('drops one-city settler moves into remembered enemy city pressure', () {
    final mapData = _squareMap(cols: 8, rows: 7);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 4,
      row: 1,
    );
    const unsafeMove = MoveUnitCommand('settler_1', 6, 4);
    const fallback = StartBuildingCommand('capital', CityBuildingType.walls);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(unsafeMove),
          CommandMctsAction(fallback),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 2,
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
              center: CityHex(col: 4, row: 0),
            ),
            GameCity(
              id: 'enemy_city',
              ownerPlayerId: _enemyId,
              name: 'Enemy City',
              center: CityHex(col: 6, row: 5),
              controlledHexes: [CityHex(col: 6, row: 4)],
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
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      ),
    );

    expect(_commands(actions), isNot(contains(unsafeMove)));
    expect(actions.last, const EndPlanningAction());
  });
}
