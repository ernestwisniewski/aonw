part of '../basic_strategy_test.dart';

void _registerBasicStrategySettlerSafetyEscortDiscoveryScenarios() {
  test('moves spare military to escort a pressured third-city settler', () {
    final mapData = _roomyExpansionMap();
    const assignment = CityHex(col: 5, row: 6);
    final state = _pressuredThirdCityEscortState(mapData);
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 24,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 24,
      rng: AiRng.fromTurn(turn: 24, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 24,
        mode: StrategicMode.expand,
        expectations: const EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 3,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        settlerAssignments: const {'settler_player_1': assignment},
        defenses: {
          'capital': StrategicDefenseAssignment(
            cityId: 'capital',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 0,
            assignedUnitIds: ['capital_guard'],
          ),
          'second': StrategicDefenseAssignment(
            cityId: 'second',
            cityCenter: const CityHex(col: 7, row: 0),
            threatLevel: 0,
            assignedUnitIds: ['second_guard', 'escort_1'],
          ),
        },
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    final escortMove = plan.commands.whereType<MoveUnitCommand>().firstWhere(
      (command) => command.unitId == 'escort_1',
      orElse: () => fail(plan.commands.map(_debugCommand).join('; ')),
    );
    final before = HexDistance.between(
      const HexCoordinate(col: 7, row: 3),
      assignment.toCoordinate(),
    );
    final after = HexDistance.between(
      HexCoordinate(col: escortMove.targetCol, row: escortMove.targetRow),
      assignment.toCoordinate(),
    );
    expect(after, lessThan(before));
    expect(
      plan.commands,
      isNot(contains(const MoveUnitCommand('settler_player_1', 5, 6))),
    );
  });
  test('reserves queued settler path before moving military pressure', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 0,
          row: 3,
        ),
        GameUnit.produced(
          id: 'spearman_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.spearman,
          col: 3,
          row: 3,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 3),
        ),
        GameCity(
          id: 'second',
          ownerPlayerId: 'player_1',
          name: 'Second',
          center: CityHex(col: 3, row: 3),
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
      turn: 30,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 30,
      rng: AiRng.fromTurn(turn: 30, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: StrategicPlan(
        computedAtTurn: 30,
        mode: StrategicMode.military,
        expectations: const EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 2,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        settlerAssignments: const {'settler_player_1': CityHex(col: 0, row: 0)},
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_2',
            kind: WarGoalKind.eliminateUnits,
            targetHex: const HexCoordinate(col: 0, row: 1),
            turnsBudget: 6,
            assignedUnitIds: const ['spearman_1'],
            priority: 3,
          ),
        ],
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands,
      contains(const MoveUnitCommand('settler_player_1', 0, 0)),
    );
    final militaryTargets = {
      for (final command in plan.commands.whereType<MoveUnitCommand>())
        if (command.unitId == 'spearman_1')
          HexCoordinate(col: command.targetCol, row: command.targetRow),
    };
    expect(
      militaryTargets,
      isNot(contains(const HexCoordinate(col: 0, row: 2))),
    );
    expect(
      militaryTargets,
      isNot(contains(const HexCoordinate(col: 0, row: 1))),
    );
  });
  test('uses spare scouts to reveal legal third-city frontiers', () {
    final mapData = _roomyExpansionMap();
    final state = _thirdCityScoutDiscoveryState(mapData);
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 38,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 38,
      rng: AiRng.fromTurn(turn: 38, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 38,
        mode: StrategicMode.recover,
        expectations: EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 3,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    final scoutMoves = plan.commands
        .whereType<MoveUnitCommand>()
        .where((command) => command.unitId == 'scout_1')
        .toList();
    expect(scoutMoves, isNotEmpty);

    const scorer = AiFrontierExplorationScorer();
    final currentScore = scorer.citySiteDiscoveryScore(
      view: view,
      origin: const HexCoordinate(col: 3, row: 2),
    );
    final targetScore = scorer.citySiteDiscoveryScore(
      view: view,
      origin: HexCoordinate(
        col: scoutMoves.first.targetCol,
        row: scoutMoves.first.targetRow,
      ),
    );
    expect(targetScore, greaterThan(currentScore));
  });
}
