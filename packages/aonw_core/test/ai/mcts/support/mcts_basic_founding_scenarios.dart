part of '../mcts_action_generator_test.dart';

void _registerMctsBasicFoundingScenarios() {
  test('drops founding commands that are illegal in the current state', () {
    final invalidFounding = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(2, 0, 2, 1),
    );
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [invalidFounding]),
      candidateLimit: 8,
    );
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
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
      _context(),
    );

    expect(_commands(actions), isNot(contains(invalidFounding)));
  });

  test('drops founding commands when nearby fog could hide a city', () {
    final riskyFounding = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(1, 0, 0, 1),
    );
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [riskyFounding]),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 4, rows: 4);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
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
              center: CityHex(col: 3, row: 3),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
          fogOfWar: _fogForHexes(_playerId, {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 1, row: 0),
            const HexCoordinate(col: 0, row: 1),
          }),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), isNot(contains(riskyFounding)));
  });

  test('keeps founding commands under AI full-map planning', () {
    final founding = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(1, 0, 0, 1),
    );
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [founding]),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 4, rows: 4);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
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
              center: CityHex(col: 3, row: 3),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
          fogOfWar: _fogForHexes(_playerId, {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 1, row: 0),
            const HexCoordinate(col: 0, row: 1),
          }),
          ignoreFogOfWar: true,
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), contains(founding));
  });

  test('keeps founding commands when the exclusion zone is known', () {
    final founding = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(1, 0, 0, 1),
    );
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [founding]),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 4, rows: 4);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
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
              center: CityHex(col: 3, row: 3),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), contains(founding));
  });

  test('adds current founding alternatives for active settlers', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 8, rows: 8);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 3,
      row: 4,
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
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 7, row: 7),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );
    final foundings = _commands(actions).whereType<FoundCityCommand>().where(
      (command) => command.founderId == 'settler_1',
    );

    expect(foundings, isNotEmpty);
    expect(foundings.single.controlledHexes, hasLength(2));
  });

  test('adds spacing moves for settlers stuck near owned cities', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 5, rows: 5);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 1,
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
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 4, row: 4),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(
      _commands(actions),
      contains(const MoveUnitCommand('settler_1', 0, 2)),
    );
  });

  test('reserves room for spacing moves when fallback plan is full', () {
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(
        commands: [
          for (var index = 0; index < 12; index++)
            StartCityProjectCommand('city_$index', CityProjectType.wealth),
        ],
      ),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 5, rows: 5);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 1,
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
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 4, row: 4),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );
    final commands = _commands(actions);

    expect(commands, hasLength(8));
    expect(commands, contains(const MoveUnitCommand('settler_1', 0, 2)));
  });

  test('drops partial second-city founding until the ring is known', () {
    final founding = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(3, 2, 4, 3),
    );
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [founding]),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 8, rows: 8);
    final visibleHexes = {
      for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
    }..remove(const HexCoordinate(col: 2, row: 2));
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 3,
      row: 3,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 6,
      row: 3,
    );
    final worker = GameUnit(
      id: 'enemy_worker',
      ownerPlayerId: _enemyId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 1,
      row: 3,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, enemy, worker],
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
      _context(mapData: mapData),
    );

    expect(_commands(actions), isNot(contains(founding)));
  });

  test('drops partial third-city founding until the ring is known', () {
    final founding = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(3, 2, 4, 3),
    );
    final generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [founding]),
      candidateLimit: 8,
    );
    final mapData = _squareMap(cols: 8, rows: 8);
    final visibleHexes = {
      for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
    }..remove(const HexCoordinate(col: 2, row: 2));
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 3,
      row: 3,
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
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 7, row: 7),
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
          fogOfWar: _fogForHexes(_playerId, visibleHexes),
        ),
        maxPlanningDepth: 3,
      ),
      _context(mapData: mapData),
    );

    expect(_commands(actions), isNot(contains(founding)));
  });
}
