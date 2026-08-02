part of '../basic_strategy_test.dart';

void _registerBasicStrategyArtifactScenarios() {
  test('matches RandomStrategy when no founder is available', () {
    final mapData = WorldMap(
      cols: 2,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
        WorldTile(
          col: 1,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
      ],
    );
    final state = DomainState.snapshot(
      units: [
        GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
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
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
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
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 77),
    );

    final randomPlan = const RandomStrategy().plan(view, context);
    final basicPlan = const BasicStrategy().plan(view, context);

    expect(basicPlan.commands, randomPlan.commands);
    expect(basicPlan.debug?.strategyId, 'basic');
  });

  test('starts excavation when a collector stands on a visible artifact', () {
    final mapData = _combatPressureMap();
    final scout = GameUnit.produced(
      id: 'scout_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.scout,
      col: 1,
      row: 0,
    );
    final artifact = WorldArtifact.placed(
      type: WorldArtifactType.astronomersTablets,
      col: 1,
      row: 0,
    );
    final state = DomainState.snapshot(
      units: [scout],
      artifacts: [artifact],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
      research: _researchWithActiveTarget(),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = _contextFor(mapData, turn: 3);

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands, contains(StartArtifactExcavationCommand(scout.id)));
  });

  test('stores a carried artifact in an empty own city slot', () {
    final mapData = _combatPressureMap();
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
    );
    final carrier = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    ).copyWithCarriedArtifact('artifact_1');
    const artifact = WorldArtifact(
      id: 'artifact_1',
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.carried(unitId: 'warrior_1'),
    );
    final state = DomainState.snapshot(
      units: [carrier],
      cities: const [city],
      artifacts: const [artifact],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
      research: _researchWithActiveTarget(),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = _contextFor(mapData, turn: 3);

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands,
      contains(const StoreArtifactInCityCommand('warrior_1', cityId: 'city_1')),
    );
  });

  test('moves carriers home and scouts toward visible artifacts', () {
    final mapData = _combatPressureMap();
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
    );
    const satellite = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      name: 'Harbor',
      center: CityHex(col: 2, row: 0),
    );
    final carrier = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 1,
      row: 0,
    ).copyWithCarriedArtifact('artifact_1');
    final scout = GameUnit.produced(
      id: 'scout_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.scout,
      col: 3,
      row: 0,
    );
    const carried = WorldArtifact(
      id: 'artifact_1',
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.carried(unitId: 'warrior_1'),
    );
    final mapArtifact = WorldArtifact.placed(
      type: WorldArtifactType.queensMirror,
      col: 4,
      row: 0,
    );
    final state = DomainState.snapshot(
      units: [carrier, scout],
      cities: const [city, satellite],
      artifacts: [carried, mapArtifact],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
      research: _researchWithActiveTarget(),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 3,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = _contextFor(mapData, turn: 3);

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands, contains(const MoveUnitCommand('warrior_1', 0, 0)));
    expect(plan.commands, contains(const MoveUnitCommand('scout_1', 4, 0)));
  });

  test('plans a FoundCityCommand when commander stands on a valid centerTile '
      'with a settler in its army', () {
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
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    final foundings = plan.commands.whereType<FoundCityCommand>().toList();
    expect(foundings, hasLength(1));
    expect(foundings.first.founderId, 'commander_player_1');
    expect(
      foundings.first.controlledHexes.length,
      CityFoundingDraft.requiredControlledHexes,
    );
    // Picker must produce neighbours of the center, not the center itself.
    for (final hex in foundings.first.controlledHexes) {
      expect(hex, isNot(const CityHex(col: 1, row: 1)));
    }
  });
}
