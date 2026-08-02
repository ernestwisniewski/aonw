part of '../mcts_action_generator_test.dart';

void _registerMctsBasicCombatScenarios() {
  test('adds combat alternatives for visible enemies', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
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
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 1,
      row: 0,
      hitPoints: 1,
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
      _context(),
    );

    expect(
      _commands(actions),
      contains(const AttackHexCommand('warrior_1', 1, 0)),
    );
  });

  test('drops combat alternatives against friendly players', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [AttackHexCommand('warrior_1', 1, 0)]),
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
    final friendly = GameUnit(
      id: 'friendly_1',
      ownerPlayerId: _enemyId,
      type: GameUnitType.warrior,
      name: 'Friendly',
      col: 1,
      row: 0,
      hitPoints: 1,
    );
    final diplomacy = DiplomacyState.empty.setStatus(
      _playerId,
      _enemyId,
      DiplomaticRelationStatus.friendly,
    );

    final actions = generator.candidatesFor(
      SimulatedState.fromView(
        _view(
          units: [warrior, friendly],
          diplomacy: diplomacy,
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );

    expect(
      _commands(actions),
      isNot(contains(const AttackHexCommand('warrior_1', 1, 0))),
    );
  });

  test('adds capture alternatives for remembered enemy cities', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
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
      population: 2,
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

    expect(
      _commands(actions),
      contains(
        const AttackHexCommand(
          'warrior_1',
          1,
          0,
          cityConquestAction: CityConquestAction.capture,
        ),
      ),
    );
  });

  test('adds city attack when own unit is already on the city center', () {
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: []),
      candidateLimit: 8,
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 0,
    );
    const enemyCity = GameCity(
      id: 'enemy_city',
      ownerPlayerId: _enemyId,
      name: 'Enemy City',
      center: CityHex(col: 1, row: 0),
      population: 2,
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

    expect(
      _commands(actions),
      contains(
        const AttackHexCommand(
          'warrior_1',
          1,
          0,
          cityConquestAction: CityConquestAction.capture,
        ),
      ),
    );
  });

  test('drops city attacks blocked by an own unit on the target hex', () {
    const blockedAttack = AttackHexCommand('warrior_1', 1, 0);
    const generator = BasicPlanMctsActionGenerator(
      source: _StaticStrategy(commands: [blockedAttack]),
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
    final blocker = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: _playerId,
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
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
          units: [warrior, blocker],
          cities: const [enemyCity],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      ),
      _context(),
    );

    expect(_commands(actions), isNot(contains(blockedAttack)));
  });
}
