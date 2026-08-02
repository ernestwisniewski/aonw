part of '../basic_strategy_test.dart';

void _registerBasicStrategyMilitaryPressureMovementScenarios() {
  test('moves military toward a visible enemy beyond attack range', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
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
    expect(
      plan.commands.whereType<MoveUnitCommand>(),
      contains(const MoveUnitCommand('warrior_1', 3, 0)),
    );
  });
  test(
    'holds generic military pressure while a two-city core needs a third',
    () {
      final mapData = _roomyExpansionMap();
      const secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        center: CityHex(col: 5, row: 5),
      );
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
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 5,
            row: 4,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 7,
            row: 5,
          ),
        ],
        cities: const [_TestCities.capital, secondCity],
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
        turn: 34,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 34,
        rng: AiRng.fromTurn(turn: 34, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
        strategicPlan: const StrategicPlan(
          computedAtTurn: 34,
          mode: StrategicMode.consolidate,
          expectations: _testExpectations,
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.debug?.notes,
        isNot(
          contains(predicate<String>((note) => note.contains('pressure move'))),
        ),
      );
    },
  );
  test('uses clear force advantage to pressure during expansion', () {
    final mapData = _roomyExpansionMap();
    const secondCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Second',
      center: CityHex(col: 5, row: 5),
    );
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
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 5,
          row: 4,
        ),
        _unit(
          id: 'warrior_3',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 4,
          row: 5,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 7,
          row: 5,
        ),
      ],
      cities: const [_TestCities.capital, secondCity],
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
      turn: 34,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 34,
      rng: AiRng.fromTurn(turn: 34, playerId: 'player_1', baseSeed: 1001),
      persona: profile.defaultPersona,
      civProfile: profile,
      strategicPlan: const StrategicPlan(
        computedAtTurn: 34,
        mode: StrategicMode.consolidate,
        expectations: _testExpectations,
      ),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.debug?.notes,
      contains(predicate<String>((note) => note.contains('pressure move'))),
    );
  });
  test('moves assigned military toward its war goal city', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'near_enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Near',
          center: CityHex(col: 1, row: 0),
        ),
        GameCity(
          id: 'goal_city',
          ownerPlayerId: 'player_3',
          name: 'Goal',
          center: CityHex(col: 4, row: 0),
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
          kind: WarGoalKind.captureCity,
          targetCity: const CityHex(col: 4, row: 0),
          targetHex: const HexCoordinate(col: 4, row: 0),
          turnsBudget: 6,
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
      contains(const MoveUnitCommand('warrior_1', 3, 0)),
    );
  });
  test('does not move assault units onto enemy city centers', () {
    final mapData = _combatPressureMap();
    final state = DomainState.snapshot(
      units: [
        _unit(
          id: 'tank_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.tank,
          col: 1,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'goal_city',
          ownerPlayerId: 'player_2',
          name: 'Goal',
          center: CityHex(col: 4, row: 0),
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
          kind: WarGoalKind.captureCity,
          targetCity: const CityHex(col: 4, row: 0),
          targetHex: const HexCoordinate(col: 4, row: 0),
          turnsBudget: 6,
          assignedUnitIds: const ['tank_1'],
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
    final moves = plan.commands.whereType<MoveUnitCommand>();

    expect(moves, isNot(contains(const MoveUnitCommand('tank_1', 4, 0))));
    expect(moves, contains(const MoveUnitCommand('tank_1', 3, 0)));
  });
}
