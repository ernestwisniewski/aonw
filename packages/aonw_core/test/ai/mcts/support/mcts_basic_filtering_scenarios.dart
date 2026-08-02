part of '../mcts_action_generator_test.dart';

void _registerMctsBasicFilteringScenarios() {
  test('filters terminal and already used commands', () {
    const move = MoveUnitCommand('unit_1', 1, 0);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(
        commands: [
          move,
          EndTurnCommand('player_1'),
          SubmitTurnCommand('player_1'),
        ],
      ),
      candidateLimit: 8,
    );
    final context = _context();
    final state = SimulatedState.fromView(
      _view(
        units: [
          GameUnit(
            id: 'unit_1',
            ownerPlayerId: _playerId,
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 0,
            row: 0,
          ),
        ],
        research: PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      ),
      maxPlanningDepth: 3,
    );

    final initial = generator.candidatesFor(state, context);
    final afterMove = generator.candidatesFor(
      state.apply(initial.first),
      context,
    );

    expect(initial, contains(const CommandMctsAction(move)));
    expect(
      initial,
      isNot(contains(const CommandMctsAction(EndTurnCommand('player_1')))),
    );
    expect(
      initial,
      isNot(contains(const CommandMctsAction(SubmitTurnCommand('player_1')))),
    );
    expect(afterMove, isNot(contains(const CommandMctsAction(move))));
    expect(afterMove.last, const EndPlanningAction());
  });

  test('can skip expensive source planning beyond configured depth', () {
    const move = MoveUnitCommand('unit_1', 1, 0);
    final source = _CountingStrategy(commands: const [move]);
    final stats = MctsActionGenerationStatsCollector();
    final generator = BasicPlanMctsActionGenerator(
      source: source,
      candidateLimit: 8,
      sourcePlanDepthLimit: 0,
      stats: stats,
    );
    final context = _context();
    final state = SimulatedState.fromView(
      _view(
        mapData: _lineMap(3),
        units: [
          GameUnit(
            id: 'unit_1',
            ownerPlayerId: _playerId,
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 0,
            row: 0,
          ),
        ],
        research: PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      ),
      maxPlanningDepth: 3,
    );

    final initial = generator.candidatesFor(state, context);
    final afterMove = generator.candidatesFor(
      state.apply(const CommandMctsAction(move)),
      context,
    );

    expect(initial, contains(const CommandMctsAction(move)));
    expect(afterMove, isNot(contains(const CommandMctsAction(move))));
    expect(source.calls, 1);
    final snapshot = stats.snapshot();
    expect(snapshot.sourcePlanCalls, 1);
    expect(snapshot.sourcePlanSkipped, 1);
  });

  test('drops fallback moves into occupied tiles', () {
    const occupiedMove = MoveUnitCommand('warrior_1', 1, 0);
    const legalMove = MoveUnitCommand('warrior_1', 0, 1);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [occupiedMove, legalMove]),
      candidateLimit: 8,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 1,
      row: 0,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, settler],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );

    expect(_commands(actions), contains(legalMove));
    expect(_commands(actions), isNot(contains(occupiedMove)));
  });

  test('drops moves whose path is blocked by hidden units', () {
    const blockedMove = MoveUnitCommand('warrior_1', 2, 0);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [blockedMove]),
      candidateLimit: 8,
    );
    final mapData = _lineMap(3);
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final hiddenBlocker = GameUnit(
      id: 'hidden_blocker',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Hidden Blocker',
      col: 1,
      row: 0,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, hiddenBlocker],
          fogOfWar: _fogForHexes(_playerId, {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 2, row: 0),
          }),
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), isNot(contains(blockedMove)));
  });

  test('keeps moves through full-turn passable terrain', () {
    const roughTerrainMove = MoveUnitCommand('warrior_1', 1, 0);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [roughTerrainMove]),
      candidateLimit: 8,
    );
    final mapData = _highCostLineMap();
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), contains(roughTerrainMove));
  });

  test('drops moves into remembered enemy city centers', () {
    const cityMove = MoveUnitCommand('warrior_1', 1, 0);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [cityMove]),
      candidateLimit: 8,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    const enemyCity = GameCity(
      id: 'enemy_city',
      ownerPlayerId: _enemyId,
      name: 'Enemy City',
      center: CityHex(col: 1, row: 0),
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior],
          cities: const [enemyCity],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );

    expect(_commands(actions), isNot(contains(cityMove)));
  });

  test('drops moves into discovered but non-visible hexes', () {
    const hiddenMove = MoveUnitCommand('warrior_1', 1, 0);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [hiddenMove]),
      candidateLimit: 8,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final mapData = _lineMap(3);

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior],
          fogOfWar: FogOfWarState(
            players: {
              _playerId: PlayerFogOfWar(
                playerId: _playerId,
                discoveredHexes: {const HexCoordinate(col: 1, row: 0)},
                visibleHexes: {const HexCoordinate(col: 0, row: 0)},
              ),
            },
          ),
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), isNot(contains(hiddenMove)));
  });
}
