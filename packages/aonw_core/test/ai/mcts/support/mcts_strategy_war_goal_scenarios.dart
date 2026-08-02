part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyWarGoalScenarios() {
  test('prioritizes attacks that match active war goals', () {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 1,
      row: 0,
      hitPoints: 1,
    );
    const attack = AttackHexCommand('warrior_1', 1, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(
            StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
          CommandMctsAction(attack),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, enemy],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        strategicPlan: _strategicPlan(
          mode: StrategicMode.military,
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 1, row: 0),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(attack));
    expect(actions.last, const EndPlanningAction());
  });

  test('keeps assigned offensive units from chasing unrelated attacks', () {
    final mapData = _squareMap(cols: 5, rows: 3);
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 1,
    );
    final unrelatedEnemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 0,
      row: 0,
      hitPoints: 1,
    );
    const unrelatedAttack = AttackHexCommand('warrior_1', 0, 0);
    const warMove = MoveUnitCommand('warrior_1', 1, 1);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(unrelatedAttack),
          CommandMctsAction(warMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, unrelatedEnemy],
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
          warGoals: [
            WarGoal(
              targetPlayerId: 'player_3',
              kind: WarGoalKind.captureCity,
              targetHex: const HexCoordinate(col: 4, row: 1),
              turnsBudget: 8,
              assignedUnitIds: const ['warrior_1'],
              priority: 6,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(warMove));
    expect(actions, isNot(contains(const CommandMctsAction(unrelatedAttack))));
  });

  test('keeps frontline blocker attacks for assigned offensive units', () {
    final mapData = _squareMap(cols: 5, rows: 3);
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 1,
    );
    final blocker = GameUnit(
      id: 'frontline_blocker',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Blocker',
      col: 1,
      row: 1,
      hitPoints: 1,
    );
    const blockerAttack = AttackHexCommand('warrior_1', 1, 1);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [CommandMctsAction(blockerAttack), EndPlanningAction()],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, blocker],
          cities: const [
            GameCity(
              id: 'goal_city',
              ownerPlayerId: 'player_3',
              name: 'Goal',
              center: CityHex(col: 4, row: 1),
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
          mode: StrategicMode.military,
          warGoals: [
            WarGoal(
              targetPlayerId: 'player_3',
              kind: WarGoalKind.captureCity,
              targetHex: const HexCoordinate(col: 4, row: 1),
              targetCity: const CityHex(col: 4, row: 1),
              turnsBudget: 8,
              assignedUnitIds: const ['warrior_1'],
              priority: 6,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(blockerAttack));
    expect(actions.last, const EndPlanningAction());
  });

  test('drops low-impact war-goal skirmishes', () {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 1,
      row: 0,
    );
    const attack = AttackHexCommand('warrior_1', 1, 0);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [CommandMctsAction(attack), EndPlanningAction()],
      ),
      candidateLimit: 2,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, enemy],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        strategicPlan: _strategicPlan(
          mode: StrategicMode.military,
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 1, row: 0),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(_commands(actions), isEmpty);
    expect(actions, const [EndPlanningAction()]);
  });

  test('does not promote far defensive war-goal attacks', () {
    final mapData = _lineMap(6);
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 4,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 5,
      row: 0,
      hitPoints: 1,
    );
    const attack = AttackHexCommand('warrior_1', 5, 0);
    const project = StartCityProjectCommand('city_1', CityProjectType.wealth);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(attack),
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
          units: [warrior, enemy],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
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
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.defend,
              targetHex: const HexCoordinate(col: 0, row: 0),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(project));
    expect(actions, isNot(contains(const CommandMctsAction(attack))));
    expect(actions.last, const EndPlanningAction());
  });

  test('promotes local defensive war-goal attacks', () {
    final mapData = _lineMap(6);
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 4,
      row: 0,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 5,
      row: 0,
      hitPoints: 1,
    );
    const attack = AttackHexCommand('warrior_1', 5, 0);
    const project = StartCityProjectCommand('city_1', CityProjectType.wealth);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(project),
          CommandMctsAction(attack),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          mapData: mapData,
          units: [warrior, enemy],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: _playerId,
              name: 'Capital',
              center: CityHex(col: 3, row: 0),
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
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.defend,
              targetHex: const HexCoordinate(col: 3, row: 0),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(attack));
    expect(actions.last, const EndPlanningAction());
  });
}
