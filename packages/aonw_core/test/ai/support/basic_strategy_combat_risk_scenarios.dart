part of '../basic_strategy_test.dart';

void _registerBasicStrategyCombatRiskScenarios() {
  test('aggressive persona accepts a riskier attack', () {
    final mapData = _foundingScenarioMap();
    const ruleset = GameRuleset(
      city: CityRulesets.standard,
      combat: CombatRuleset(
        unitBaseStats: {
          GameUnitType.warrior: CombatStats(
            attack: 6,
            defense: 1,
            hp: 10,
            range: 1,
            mobility: 1,
          ),
        },
      ),
      technology: TechnologyRulesets.standard,
    );
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
          hitPoints: 6,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: ruleset,
    );

    AiContext contextFor(AiPersona persona) => AiContext(
      ruleset: ruleset,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      persona: persona,
    );
    final balancedPlan = const BasicStrategy().plan(
      view,
      contextFor(AiPersona.balanced),
    );
    final aggressivePlan = const BasicStrategy().plan(
      view,
      contextFor(AiPersona.aggressive),
    );

    expect(balancedPlan.commands.whereType<AttackHexCommand>(), isEmpty);
    expect(
      aggressivePlan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_1', 2, 1)),
    );
  });
  test('civilization belligerence changes risk tolerance in combat', () {
    final mapData = _foundingScenarioMap();
    const ruleset = GameRuleset(
      city: CityRulesets.standard,
      combat: CombatRuleset(
        unitBaseStats: {
          GameUnitType.warrior: CombatStats(
            attack: 6,
            defense: 1,
            hp: 10,
            range: 1,
            mobility: 1,
          ),
        },
      ),
      technology: TechnologyRulesets.standard,
    );
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
          hitPoints: 6,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: ruleset,
    );
    const registry = CivilizationProfileRegistry();

    AiContext contextFor(PlayerCountry country) {
      final profile = registry.profileFor(country);
      return AiContext(
        ruleset: ruleset,
        mapData: mapData,
        turn: 2,
        rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
      );
    }

    final dutchPlan = const BasicStrategy().plan(
      view,
      contextFor(PlayerCountry.netherlands),
    );
    final germanPlan = const BasicStrategy().plan(
      view,
      contextFor(PlayerCountry.germany),
    );

    expect(dutchPlan.commands.whereType<AttackHexCommand>(), isEmpty);
    expect(
      germanPlan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_1', 2, 1)),
    );
  });
  test('skips a low-impact adjacent skirmish without a strategic reason', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<AttackHexCommand>(), isEmpty);
  });
  test('attacks a low-impact target when it has clear force advantage', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.cavalry,
          col: 1,
          row: 1,
        ),
        _unit(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 1,
        ),
        _unit(
          id: 'warrior_3',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_1', 2, 1)),
    );
  });
  test('prefers a war goal target when multiple enemies can be attacked', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
        _unit(
          id: 'goal_enemy',
          ownerPlayerId: 'player_3',
          type: GameUnitType.warrior,
          col: 1,
          row: 2,
          hitPoints: 1,
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final strategicPlan = StrategicPlan(
      computedAtTurn: 2,
      mode: StrategicMode.military,
      expectations: _testExpectations,
      warGoals: [
        WarGoal(
          targetPlayerId: 'player_3',
          kind: WarGoalKind.eliminateUnits,
          targetHex: const HexCoordinate(col: 1, row: 2),
          turnsBudget: 4,
          assignedUnitIds: const ['warrior_1'],
          priority: 5,
        ),
      ],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: strategicPlan,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_1', 1, 2)),
    );
    expect(
      plan.commands.whereType<AttackHexCommand>(),
      isNot(contains(const AttackHexCommand('warrior_1', 2, 1))),
    );
  });
}
