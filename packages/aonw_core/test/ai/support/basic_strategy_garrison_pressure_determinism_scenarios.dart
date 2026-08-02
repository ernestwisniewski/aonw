part of '../basic_strategy_test.dart';

void _registerBasicStrategyGarrisonPressureDeterminismScenarios() {
  test('lets assigned garrison attack a pressure target in range', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'tank_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.tank,
          col: 0,
          row: 0,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
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
      turn: 80,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
      pressureTargetPlayerIds: const ['player_2'],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 80,
      rng: AiRng.fromTurn(turn: 80, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 80,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 10,
            assignedUnitIds: const ['tank_1'],
            primaryThreatPlayerId: 'player_2',
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('tank_1', 1, 0)),
    );
  });
  test('pulls the last military unit back instead of raiding far away', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 3,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<AttackHexCommand>(), isEmpty);
    final reserveMove = plan.commands.whereType<MoveUnitCommand>().singleWhere(
      (command) => command.unitId == 'warrior_1',
    );
    expect(
      HexDistance.between(
        HexCoordinate(col: reserveMove.targetCol, row: reserveMove.targetRow),
        const HexCoordinate(col: 0, row: 0),
      ),
      lessThan(3),
    );
  });
  test('moves away from an adjacent visible enemy when low on hp', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
          hitPoints: 3,
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
    final retreat = plan.commands.whereType<MoveUnitCommand>().singleWhere(
      (command) => command.unitId == 'warrior_1',
    );
    expect(
      HexDistance.between(
        HexCoordinate(col: retreat.targetCol, row: retreat.targetRow),
        const HexCoordinate(col: 2, row: 1),
      ),
      greaterThan(1),
    );
  });
  test('produces the same plan for the same seed and view', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 1,
          row: 1,
          army: const [ArmyTroop(type: TroopType.settler, count: 1)],
        ),
      ],
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
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    AiContext makeContext() => AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final first = const BasicStrategy().plan(view, makeContext());
    final second = const BasicStrategy().plan(view, makeContext());

    expect(second.commands, first.commands);
  });
}
