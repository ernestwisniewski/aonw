part of '../mcts_action_generator_test.dart';

void _registerMctsStrategyOpeningScenarios() {
  test('prioritizes first city founding over active war goals', () {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
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
    final found = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(0, 1, 1, 0),
    );
    const attack = AttackHexCommand('warrior_1', 1, 1);
    final generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          const CommandMctsAction(attack),
          CommandMctsAction(found),
          const EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [settler, warrior, enemy],
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
              targetHex: const HexCoordinate(col: 1, row: 1),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, CommandMctsAction(found));
    expect(actions.last, const EndPlanningAction());
  });

  test('moves the first settler when the opening plan has a better site', () {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
    );
    final found = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(0, 1, 1, 0),
    );
    const move = MoveUnitCommand('settler_1', 1, 0);
    final generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(found),
          const CommandMctsAction(move),
          const EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
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
          settlerAssignments: const {'settler_1': CityHex(col: 1, row: 0)},
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(move));
    expect(actions.last, const EndPlanningAction());
  });

  test('keeps first settler movement ahead of distant attacks', () {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
    );
    final warrior = GameUnit(
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
      col: 2,
      row: 1,
    );
    const move = MoveUnitCommand('settler_1', 1, 0);
    const attack = AttackHexCommand('warrior_1', 2, 1);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(attack),
          CommandMctsAction(move),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [settler, warrior, enemy],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(
        strategicPlan: _strategicPlan(
          mode: StrategicMode.military,
          settlerAssignments: const {'settler_1': CityHex(col: 2, row: 0)},
          warGoals: [
            WarGoal(
              targetPlayerId: _enemyId,
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 2, row: 1),
              turnsBudget: 3,
              assignedUnitIds: const ['warrior_1'],
              priority: 0.9,
            ),
          ],
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(move));
    expect(actions.last, const EndPlanningAction());
  });

  test('does not move a post-step founding command ahead of its movement', () {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.settler,
      name: 'Settler',
      col: 0,
      row: 0,
    );
    const move = MoveUnitCommand('settler_1', 1, 0);
    final foundAfterMove = FoundCityCommand(
      'settler_1',
      controlledHexes: foundingHexes(2, 0, 2, 1),
    );
    final generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(foundAfterMove),
          const CommandMctsAction(move),
          const EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
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
          settlerAssignments: const {'settler_1': CityHex(col: 1, row: 0)},
        ),
      ),
    );

    expect(actions.first, const CommandMctsAction(move));
    expect(actions.last, const EndPlanningAction());
  });

  test('drops stale no-op and occupied move candidates', () {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 0,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.worker,
      name: 'Worker',
      col: 1,
      row: 0,
    );
    const currentTile = MoveUnitCommand('warrior_1', 0, 0);
    const occupiedTile = MoveUnitCommand('warrior_1', 1, 0);
    const legalMove = MoveUnitCommand('warrior_1', 0, 1);
    const generator = StrategyAwareMctsActionGenerator(
      inner: _StaticActionGenerator(
        actions: [
          CommandMctsAction(currentTile),
          CommandMctsAction(occupiedTile),
          CommandMctsAction(legalMove),
          EndPlanningAction(),
        ],
      ),
      candidateLimit: 1,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(units: [warrior, worker]),
        maxPlanningDepth: 3,
      ),
      _context(strategicPlan: _strategicPlan()),
    );

    expect(_commands(actions), const [legalMove]);
    expect(actions.last, const EndPlanningAction());
  });

  test(
    'keeps protective attacks near the first settler in the opening pool',
    () {
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
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
      final found = FoundCityCommand(
        'settler_1',
        controlledHexes: foundingHexes(0, 1, 1, 0),
      );
      const attack = AttackHexCommand('warrior_1', 1, 0);
      final generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            const CommandMctsAction(attack),
            CommandMctsAction(found),
            const EndPlanningAction(),
          ],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [settler, warrior, enemy],
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

      expect(_commands(actions), [attack, found]);
      expect(actions.last, const EndPlanningAction());
    },
  );
}
