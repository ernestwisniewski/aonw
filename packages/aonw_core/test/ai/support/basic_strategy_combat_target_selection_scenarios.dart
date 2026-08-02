part of '../basic_strategy_test.dart';

void _registerBasicStrategyCombatTargetSelectionScenarios() {
  test('prefers a pressure target when multiple enemies can be attacked', () {
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
          id: 'pressure_enemy',
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
      pressureTargetPlayerIds: const {'player_3'},
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
      contains(const AttackHexCommand('warrior_1', 1, 2)),
    );
    expect(
      plan.commands.whereType<AttackHexCommand>(),
      isNot(contains(const AttackHexCommand('warrior_1', 2, 1))),
    );
  });
  test('prioritizes a unit currently attacking one of its cities', () {
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
          id: 'city_attacker',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
        _unit(
          id: 'weakened_enemy',
          ownerPlayerId: 'player_3',
          type: GameUnitType.warrior,
          col: 1,
          row: 2,
          hitPoints: 1,
        ),
      ],
      cities: const [
        GameCity(
          id: 'capital',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 1),
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
      pendingCityAttackThreats: const [
        PendingCityAttackThreat(
          attackerPlayerId: 'player_2',
          attackerUnitId: 'city_attacker',
          attackerHex: HexCoordinate(col: 2, row: 1),
          cityId: 'capital',
          cityCenter: CityHex(col: 0, row: 1),
        ),
      ],
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
    expect(
      plan.commands.whereType<AttackHexCommand>(),
      isNot(contains(const AttackHexCommand('warrior_1', 1, 2))),
    );
  });
  test('does not stack multiple attacks into the same enemy hex', () {
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
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 2,
        ),
        _unit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<AttackHexCommand>(), hasLength(1));
    expect(
      plan.commands.whereType<AttackHexCommand>(),
      contains(const AttackHexCommand('warrior_1', 2, 1)),
    );
  });
}
