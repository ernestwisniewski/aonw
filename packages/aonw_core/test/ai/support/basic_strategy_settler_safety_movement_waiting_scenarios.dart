part of '../basic_strategy_test.dart';

void _registerBasicStrategySettlerSafetyMovementWaitingScenarios() {
  test('retreats an unassigned third-city settler from adjacent military', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 6,
          row: 3,
        ),
        GameUnit.produced(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 5,
          row: 3,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 6, row: 1),
        ),
        GameCity(
          id: 'second',
          ownerPlayerId: 'player_1',
          name: 'Second',
          center: CityHex(col: 8, row: 3),
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
      turn: 44,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 44,
      rng: AiRng.fromTurn(turn: 44, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 44,
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

    final move = plan.commands.whereType<MoveUnitCommand>().singleWhere(
      (command) => command.unitId == 'settler_player_1',
    );
    final before = HexDistance.between(
      const HexCoordinate(col: 6, row: 3),
      const HexCoordinate(col: 5, row: 3),
    );
    final after = HexDistance.between(
      HexCoordinate(col: move.targetCol, row: move.targetRow),
      const HexCoordinate(col: 5, row: 3),
    );
    expect(after, greaterThan(before));
    expect(after, greaterThan(1));
  });
  test('moves blocked settlers outward to reveal legal founding rings', () {
    final mapData = _roomyExpansionMap();
    final visible = {
      for (final tile in mapData.tiles)
        if (HexDistance.between(
              HexCoordinate.fromTile(tile),
              const HexCoordinate(col: 3, row: 3),
            ) <=
            2)
          HexCoordinate.fromTile(tile),
    };
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 3,
          row: 3,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 3, row: 3),
          controlledHexes: [CityHex(col: 3, row: 4)],
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: visible,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    final move = plan.commands.whereType<MoveUnitCommand>().singleWhere(
      (command) => command.unitId == 'settler_player_1',
    );
    expect(
      HexDistance.between(
        HexCoordinate(col: move.targetCol, row: move.targetRow),
        const HexCoordinate(col: 3, row: 3),
      ),
      greaterThanOrEqualTo(2),
    );
    expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
  });
  test('waits for escort before pushing an unescorted settler frontier', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 3,
          row: 3,
        ),
        GameUnit.produced(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 6,
          row: 3,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 3, row: 3),
          controlledHexes: [CityHex(col: 3, row: 4)],
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
      turn: 32,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 32,
      rng: AiRng.fromTurn(turn: 32, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'settler_player_1',
      ),
      isEmpty,
    );
    expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
  });
  test(
    'does not let a third-city settler outrun origin cover under pressure',
    () {
      final mapData = _roomyExpansionMap();
      final state = DomainState.snapshot(
        units: [
          GameUnit.produced(
            id: 'settler_player_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 0,
          ),
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 1, row: 1),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 6,
            row: 3,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'second',
            ownerPlayerId: 'player_1',
            name: 'Second',
            center: CityHex(col: 5, row: 0),
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
        turn: 36,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 36,
        rng: AiRng.fromTurn(turn: 36, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: const StrategicPlan(
          computedAtTurn: 36,
          mode: StrategicMode.expand,
          expectations: EconomyExpectations(
            expectedCityCount: 3,
            expectedWorkerCount: 2,
            expectedMilitaryCount: 2,
            goldReserveTarget: 10,
            minimumSciencePerTurn: 3,
          ),
          settlerAssignments: {'settler_player_1': CityHex(col: 3, row: 3)},
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands,
        isNot(contains(const MoveUnitCommand('settler_player_1', 3, 3))),
      );
      expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
    },
  );
  test('lets a pressured third-city settler step away from visible danger', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 4,
          row: 4,
        ),
        GameUnit.produced(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 4,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
        ),
        GameCity(
          id: 'second',
          ownerPlayerId: 'player_1',
          name: 'Second',
          center: CityHex(col: 0, row: 5),
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
      turn: 36,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 36,
      rng: AiRng.fromTurn(turn: 36, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 36,
        mode: StrategicMode.expand,
        expectations: EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 2,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        settlerAssignments: {'settler_player_1': CityHex(col: 5, row: 4)},
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands,
      contains(const MoveUnitCommand('settler_player_1', 5, 4)),
    );
    expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
  });
}
