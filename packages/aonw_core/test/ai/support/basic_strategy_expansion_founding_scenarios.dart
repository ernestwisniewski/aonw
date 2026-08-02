part of '../basic_strategy_test.dart';

void _registerBasicStrategyExpansionFoundingScenarios() {
  test('targets distant assigned city sites so movement can be queued', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 1,
          row: 2,
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
      turn: 35,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 35,
      rng: AiRng.fromTurn(turn: 35, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 35,
        mode: StrategicMode.expand,
        expectations: EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 2,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        settlerAssignments: {'settler_player_1': CityHex(col: 6, row: 2)},
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands,
      contains(const MoveUnitCommand('settler_player_1', 6, 2)),
    );
  });

  test('founds a good current second-city site under expansion pressure', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 4,
          row: 3,
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
      turn: 24,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 24,
      rng: AiRng.fromTurn(turn: 24, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 24,
        mode: StrategicMode.expand,
        expectations: EconomyExpectations(
          expectedCityCount: 2,
          expectedWorkerCount: 1,
          expectedMilitaryCount: 1,
          goldReserveTarget: 8,
          minimumSciencePerTurn: 2,
        ),
        settlerAssignments: {'settler_player_1': CityHex(col: 4, row: 3)},
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    final foundings = plan.commands
        .whereType<FoundCityCommand>()
        .where((command) => command.founderId == 'settler_player_1')
        .toList();
    if (foundings.isEmpty) {
      final assessment = AiEmpireAssessment.fromView(view, context);
      final current = const AiCitySiteScorer().scoreCurrentSite(
        founder: state.units.first,
        view: view,
        context: context,
        assessment: assessment,
        knownCities: view.ownCities,
        reservedHexes: {
          for (final city in view.ownCities) city.center,
          for (final city in view.ownCities) ...city.controlledHexes,
        },
      );
      fail(
        'current=${current?.center.col},${current?.center.row} '
        'score=${current?.score}; '
        '${plan.commands.map(_debugCommand).join('; ')}',
      );
    }
    final founding = foundings.single;
    expect(founding.controlledHexes, hasLength(2));
    expect(
      plan.commands,
      isNot(contains(const MoveUnitCommand('settler_player_1', 4, 3))),
    );
  });

  test('founds a good current third-city site under expansion pressure', () {
    final mapData = _roomyExpansionMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'settler_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 4,
          row: 3,
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
        GameCity(
          id: 'second',
          ownerPlayerId: 'player_1',
          name: 'Second',
          center: CityHex(col: 7, row: 7),
          controlledHexes: [CityHex(col: 7, row: 6)],
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
      turn: 40,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 40,
      rng: AiRng.fromTurn(turn: 40, playerId: 'player_1', baseSeed: 1001),
      persona: profile.defaultPersona,
      civProfile: profile,
      strategicPlan: const StrategicPlan(
        computedAtTurn: 40,
        mode: StrategicMode.expand,
        expectations: EconomyExpectations(
          expectedCityCount: 3,
          expectedWorkerCount: 2,
          expectedMilitaryCount: 2,
          goldReserveTarget: 10,
          minimumSciencePerTurn: 3,
        ),
        settlerAssignments: {'settler_player_1': CityHex(col: 6, row: 3)},
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    final foundings = plan.commands
        .whereType<FoundCityCommand>()
        .where((command) => command.founderId == 'settler_player_1')
        .toList();
    if (foundings.isEmpty) {
      final assessment = AiEmpireAssessment.fromView(view, context);
      final current = const AiCitySiteScorer().scoreCurrentSite(
        founder: state.units.first,
        view: view,
        context: context,
        assessment: assessment,
        knownCities: view.ownCities,
        reservedHexes: {
          for (final city in view.ownCities) city.center,
          for (final city in view.ownCities) ...city.controlledHexes,
        },
      );
      fail(
        'current=${current?.center.col},${current?.center.row} '
        'score=${current?.score}; '
        '${plan.commands.map(_debugCommand).join('; ')}',
      );
    }
    final founding = foundings.single;
    expect(founding.controlledHexes, hasLength(2));
    expect(
      plan.commands,
      isNot(contains(const MoveUnitCommand('settler_player_1', 6, 3))),
    );
  });

  test('waits to found an assigned site until its exclusion zone is known', () {
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
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 0, row: 1),
              const HexCoordinate(col: 3, row: 3),
              const HexCoordinate(col: 3, row: 2),
              const HexCoordinate(col: 3, row: 4),
              const HexCoordinate(col: 2, row: 3),
              const HexCoordinate(col: 4, row: 3),
              const HexCoordinate(col: 2, row: 2),
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
        settlerAssignments: {'settler_player_1': CityHex(col: 3, row: 3)},
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'settler_player_1',
      ),
      isNotEmpty,
    );
  });

  test('reveals a partial third-city site near distant visible military', () {
    final mapData = _roomyExpansionMap();
    final visibleHexes = _allHexesIn(mapData)
      ..remove(const HexCoordinate(col: 2, row: 2));
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
        GameUnit.produced(
          id: 'enemy_worker',
          ownerPlayerId: 'player_2',
          type: GameUnitType.worker,
          col: 1,
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
          center: CityHex(col: 7, row: 7),
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: visibleHexes,
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 42,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 42,
      rng: AiRng.fromTurn(turn: 42, playerId: 'player_1', baseSeed: 1001),
      strategicPlan: const StrategicPlan(
        computedAtTurn: 42,
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
      plan.commands.whereType<FoundCityCommand>().where(
        (command) => command.founderId == 'settler_player_1',
      ),
      isEmpty,
    );
    expect(
      plan.commands.whereType<MoveUnitCommand>().where(
        (command) => command.unitId == 'settler_player_1',
      ),
      isNotEmpty,
    );
  });
}
