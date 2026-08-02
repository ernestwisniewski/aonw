part of '../mcts_action_generator_test.dart';

void _registerMctsStrategySettlerSafetyEscortAttacksScenarios() {
  test(
    'prioritizes unassigned settler frontier moves once core defense is covered',
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
      final garrison = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final reserve1 = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 5,
        row: 0,
      );
      final reserve2 = GameUnit(
        id: 'warrior_3',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 5,
        row: 1,
      );
      const frontierMove = MoveUnitCommand('settler_1', 3, 4);
      const fortify = FortifyUnitCommand('warrior_1');
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(fortify),
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
            units: [settler, garrison, reserve1, reserve2],
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
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            defenses: {
              'capital': StrategicDefenseAssignment(
                cityId: 'capital',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_1'],
              ),
            },
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(frontierMove));
      expect(actions.last, const EndPlanningAction());
    },
  );
  test(
    'prioritizes incremental settler spacing moves before routine city projects',
    () {
      final mapData = _squareMap(cols: 5, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 1,
      );
      const spacingMove = MoveUnitCommand('settler_1', 0, 2);
      const project = StartCityProjectCommand(
        'capital',
        CityProjectType.wealth,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(project),
            CommandMctsAction(spacingMove),
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
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        ),
      );

      expect(_commands(actions), const [spacingMove]);
      expect(actions.last, const EndPlanningAction());
    },
  );
  test(
    'does not prioritize crowded settler spacing once three cities exist',
    () {
      final mapData = _squareMap(cols: 6, rows: 6);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 1,
      );
      const crowdedMove = MoveUnitCommand('settler_1', 0, 2);
      const project = StartCityProjectCommand(
        'capital',
        CityProjectType.wealth,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(crowdedMove),
            CommandMctsAction(project),
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
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 4, row: 4),
              ),
              GameCity(
                id: 'third',
                ownerPlayerId: _playerId,
                name: 'Third',
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

      expect(_commands(actions), const [project]);
      expect(actions.last, const EndPlanningAction());
    },
  );
  test('prioritizes assigned frontier clearing attacks', () {
    final mapData = _squareMap(cols: 8, rows: 8);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 4,
      row: 5,
    );
    final clearer = GameUnit(
      id: 'warrior_clearer',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 3,
      row: 4,
    );
    final reserve = GameUnit(
      id: 'warrior_reserve',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final blocker = GameUnit(
      id: 'blocker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 4,
      row: 4,
    );
    const clearingAttack = AttackHexCommand('warrior_clearer', 4, 4);
    const fortify = FortifyUnitCommand('warrior_reserve');
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(fortify),
          CommandMctsAction(clearingAttack),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, clearer, reserve, blocker],
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
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          frontierClearingAssignments: const {
            'warrior_clearer': StrategicFrontierClearingAssignment(
              unitId: 'warrior_clearer',
              founderId: 'settler_1',
              targetPlayerId: 'player_2',
              targetHex: HexCoordinate(col: 4, row: 4),
              founderDistance: 1,
              priority: 4.5,
            ),
          },
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(clearingAttack));
    expect(actions.last, const EndPlanningAction());
  });
  test('prioritizes attacks that relieve unassigned settler pressure', () {
    final mapData = _squareMap(cols: 8, rows: 8);
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 4,
      row: 5,
    );
    final clearer = GameUnit(
      id: 'warrior_clearer',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 3,
      row: 5,
    );
    final reserve = GameUnit(
      id: 'warrior_reserve',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final blocker = GameUnit(
      id: 'blocker',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 4,
      row: 6,
    );
    const pressureAttack = AttackHexCommand('warrior_clearer', 4, 6);
    const fortify = FortifyUnitCommand('warrior_reserve');
    const building = StartBuildingCommand('capital', CityBuildingType.granary);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(building),
          CommandMctsAction(fortify),
          CommandMctsAction(pressureAttack),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [settler, clearer, reserve, blocker],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
          ],
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
      ),
    );

    expect(actions.first, const CommandMctsAction(pressureAttack));
    expect(actions.last, const EndPlanningAction());
  });
}
