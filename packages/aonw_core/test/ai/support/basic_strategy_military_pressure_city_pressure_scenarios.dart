part of '../basic_strategy_test.dart';

void _registerBasicStrategyMilitaryPressureCityPressureScenarios() {
  test('keeps defensive war-goal pressure near its anchor', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 0,
        ),
        _unit(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 4,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
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
          targetPlayerId: 'player_2',
          kind: WarGoalKind.defend,
          targetHex: const HexCoordinate(col: 0, row: 0),
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

    expect(plan.commands.whereType<AttackHexCommand>(), isEmpty);
    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      contains(const MoveUnitCommand('warrior_1', 1, 0)),
    );
    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      isNot(contains(const MoveUnitCommand('warrior_1', 3, 0))),
    );
  });
}
