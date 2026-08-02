part of '../mcts_action_generator_test.dart';

void _registerMctsStrategySettlerDiscoveryDangerCrowdingScenarios() {
  test('prioritizes crowded settler reveal moves', () {
    final mapData = _squareMap(cols: 9, rows: 9);
    final visibleHexes = {
      const HexCoordinate(col: 6, row: 1),
      const HexCoordinate(col: 8, row: 1),
      const HexCoordinate(col: 8, row: 3),
      const HexCoordinate(col: 7, row: 1),
      const HexCoordinate(col: 8, row: 0),
      const HexCoordinate(col: 8, row: 2),
    };
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 8,
      row: 1,
    );
    const revealMove = MoveUnitCommand('settler_1', 4, 3);
    const building = StartBuildingCommand('capital', CityBuildingType.walls);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(building),
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
              center: CityHex(col: 6, row: 1),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: _playerId,
              name: 'Second',
              center: CityHex(col: 8, row: 3),
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
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
      ),
    );

    expect(actions.first, const CommandMctsAction(revealMove));
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes scout-led third-city site discovery', () {
    final mapData = _squareMap(cols: 8, rows: 8);
    final visibleHexes = {
      for (final tile in mapData.tiles)
        if (HexDistance.between(
                  HexCoordinate.fromTile(tile),
                  const HexCoordinate(col: 0, row: 0),
                ) <=
                2 ||
            HexDistance.between(
                  HexCoordinate.fromTile(tile),
                  const HexCoordinate(col: 7, row: 0),
                ) <=
                2 ||
            HexDistance.between(
                  HexCoordinate.fromTile(tile),
                  const HexCoordinate(col: 3, row: 2),
                ) <=
                2)
          HexCoordinate.fromTile(tile),
    };
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 1,
      row: 0,
    );
    final scout = GameUnit(
      id: 'scout_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.scout,
      name: 'Scout',
      col: 3,
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
    const scoutMove = MoveUnitCommand('scout_1', 4, 4);
    const fortify = FortifyUnitCommand('warrior_1');
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(fortify),
          CommandMctsAction(scoutMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, scout, warrior],
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
              center: CityHex(col: 7, row: 0),
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
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
      ),
    );

    expect(_commands(actions).first, scoutMove);
    expect(actions.last, const EndPlanningAction());
  });
  test(
    'uses surplus military for city-site discovery when no scout exists',
    () {
      final mapData = _squareMap(cols: 8, rows: 8);
      final visibleHexes = {
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 0, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 7, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 3, row: 2),
                  ) <=
                  2)
            HexCoordinate.fromTile(tile),
      };
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 2,
      );
      final reserve = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      ).copyWithHitPoints(7);
      const scoutMove = MoveUnitCommand('warrior_1', 4, 4);
      const fortify = FortifyUnitCommand('warrior_2');
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(fortify),
            CommandMctsAction(scoutMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, warrior, reserve],
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
                center: CityHex(col: 7, row: 0),
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
          strategicPlan: _strategicPlan(mode: StrategicMode.recover),
        ),
      );

      expect(_commands(actions).first, scoutMove);
      expect(actions.last, const EndPlanningAction());
    },
  );
}
