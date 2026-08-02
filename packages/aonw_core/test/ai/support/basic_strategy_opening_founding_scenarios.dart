part of '../basic_strategy_test.dart';

void _registerBasicStrategyOpeningFoundingScenarios() {
  test('plans a FoundCityCommand for a standalone settler', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 1,
          row: 1,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    final foundings = plan.commands.whereType<FoundCityCommand>().toList();
    expect(foundings, hasLength(1));
    expect(foundings.first.founderId, 'settler_player_1');
    expect(
      foundings.first.controlledHexes.length,
      CityFoundingDraft.requiredControlledHexes,
    );
  });

  test('founds an adequate opening site instead of chasing richer terrain', () {
    final mapData = _citySiteChoiceMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 0,
          row: 1,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands,
      contains(
        isA<FoundCityCommand>().having(
          (command) => command.founderId,
          'founderId',
          'settler_player_1',
        ),
      ),
    );
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'settler_player_1',
      ),
      isEmpty,
    );
  });

  test(
    'moves first settler instead of founding adjacent to enemy military',
    () {
      final mapData = _roomyExpansionMap();
      final state = DomainState.snapshot(
        units: [
          GameUnit.produced(
            id: 'settler_player_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 3,
          ),
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 2, row: 2),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 3,
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
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 1,
        rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
      final settlerMoves = plan.commands
          .whereType<MoveUnitCommand>()
          .where((command) => command.unitId == 'settler_player_1')
          .toList();
      expect(settlerMoves, isNotEmpty);
      final target = HexCoordinate(
        col: settlerMoves.first.targetCol,
        row: settlerMoves.first.targetRow,
      );
      expect(target, isNot(const HexCoordinate(col: 2, row: 3)));
      expect(
        HexDistance.between(target, const HexCoordinate(col: 1, row: 3)),
        greaterThan(1),
      );
    },
  );

  test('does not send the first settler to a hidden strategic site', () {
    final mapData = _hiddenRichSiteMap();
    const hiddenSite = CityHex(col: 5, row: 3);
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 3,
          row: 3,
        ),
        GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 3, row: 2),
        GameUnit.produced(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 3,
        ),
      ],
      cities: const [
        GameCity(
          id: 'hidden_enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Hidden',
          center: CityHex(col: 5, row: 3),
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 2, row: 2),
              const HexCoordinate(col: 2, row: 3),
              const HexCoordinate(col: 2, row: 4),
              const HexCoordinate(col: 3, row: 2),
              const HexCoordinate(col: 3, row: 3),
              const HexCoordinate(col: 3, row: 4),
              const HexCoordinate(col: 4, row: 2),
              const HexCoordinate(col: 4, row: 3),
              const HexCoordinate(col: 4, row: 4),
            },
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

    final settlerMove = plan.commands
        .whereType<MoveUnitCommand>()
        .where((command) => command.unitId == 'settler_player_1')
        .single;
    expect(
      CityHex(col: settlerMove.targetCol, row: settlerMove.targetRow),
      isNot(hiddenSite),
    );
    expect(
      view.visibility.canInspectTile(
        mapData.tileAt(settlerMove.targetCol, settlerMove.targetRow)!,
      ),
      isTrue,
    );
  });

  test('does not found multiple same-turn cities too close together', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_west',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
          row: 2,
        ),
        GameUnit.produced(
          id: 'settler_east',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 4,
          row: 2,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    final foundings = plan.commands.whereType<FoundCityCommand>().toList();
    expect(foundings, hasLength(1));
  });

  test('moves a settler toward a much stronger nearby city site', () {
    final mapData = _citySiteChoiceMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 0,
          row: 1,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 0, row: 1)],
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

    expect(plan.commands.whereType<MoveUnitCommand>(), isNotEmpty);
    final foundings = plan.commands.whereType<FoundCityCommand>().toList();
    expect(foundings, isEmpty);
  });

  test('uses strategic settler assignment before local founding', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 2,
          row: 2,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 0, row: 1)],
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 1,
        mode: StrategicMode.expand,
        expectations: EconomyExpectations(
          expectedCityCount: 2,
          expectedWorkerCount: 1,
          expectedMilitaryCount: 1,
          goldReserveTarget: 8,
          minimumSciencePerTurn: 2,
        ),
        settlerAssignments: {'settler_player_1': CityHex(col: 3, row: 2)},
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands,
      contains(const MoveUnitCommand('settler_player_1', 3, 2)),
    );
    final foundings = plan.commands.whereType<FoundCityCommand>().toList();
    expect(foundings, isEmpty);
  });
}
