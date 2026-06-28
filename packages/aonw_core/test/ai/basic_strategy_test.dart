import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategy', () {
    test('matches RandomStrategy when no founder is available', () {
      final mapData = MapData(
        cols: 2,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
          TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
        ],
      );
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
        contains(
          const StoreArtifactInCityCommand('warrior_1', cityId: 'city_1'),
        ),
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test('plans a FoundCityCommand for a standalone settler', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test(
      'founds an adequate opening site instead of chasing richer terrain',
      () {
        final mapData = _citySiteChoiceMap();
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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
      },
    );

    test(
      'moves first settler instead of founding adjacent to enemy military',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test('targets distant assigned city sites so movement can be queued', () {
      final mapData = _roomyExpansionMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test(
      'waits to found an assigned site until its exclusion zone is known',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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
      },
    );

    test('reveals a partial third-city site near distant visible military', () {
      final mapData = _roomyExpansionMap();
      final visibleHexes = _allHexesIn(mapData)
        ..remove(const HexCoordinate(col: 2, row: 2));
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test(
      'retreats an unassigned third-city settler from adjacent military',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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
      },
    );

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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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

    test(
      'lets a pressured third-city settler step away from visible danger',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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
      },
    );

    test('moves spare military to escort a pressured third-city settler', () {
      final mapData = _roomyExpansionMap();
      const assignment = CityHex(col: 5, row: 6);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_player_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 4,
            row: 5,
          ),
          GameUnit.produced(
            id: 'escort_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 7,
            row: 3,
          ),
          GameUnit.produced(
            id: 'capital_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'second_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 7,
            row: 1,
          ),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 5,
            row: 7,
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
            center: CityHex(col: 7, row: 0),
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
          settlerAssignments: const {
            'settler_player_1': CityHex(col: 0, row: 0),
          },
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
      final visible = {
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 0, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 7, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 3, row: 2),
                  ) <=
                  2)
            HexCoordinate.fromTile(tile),
      };
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_player_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'scout_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            col: 3,
            row: 2,
          ),
          GameUnit.produced(
            id: 'warrior_capital',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_second',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 7,
            row: 0,
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
            center: CityHex(col: 7, row: 0),
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
      final view = GameView.fromPersistentState(
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

    test('uses assigned military to clear a blocker near a spare settler', () {
      final mapData = _roomyExpansionMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 4,
            row: 5,
          ),
          GameUnit.produced(
            id: 'warrior_clearer',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 3,
            row: 4,
          ),
          GameUnit.produced(
            id: 'warrior_reserve',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'blocker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 4,
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
            center: CityHex(col: 7, row: 0),
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
      final view = GameView.fromPersistentState(
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
            expectedMilitaryCount: 3,
            goldReserveTarget: 10,
            minimumSciencePerTurn: 3,
          ),
          frontierClearingAssignments: {
            'warrior_clearer': StrategicFrontierClearingAssignment(
              unitId: 'warrior_clearer',
              founderId: 'settler_1',
              targetPlayerId: 'player_2',
              targetHex: HexCoordinate(col: 4, row: 4),
              founderDistance: 1,
              priority: 4.5,
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<AttackHexCommand>(),
        contains(const AttackHexCommand('warrior_clearer', 4, 4)),
      );
    });

    test('trains a scout when a third-city settler has no legal site', () {
      final mapData = _largeExpansionMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 6,
            row: 0,
          ),
          GameUnit.produced(
            id: 'capital_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 6,
            row: 1,
          ),
          GameUnit.produced(
            id: 'second_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 8,
            row: 3,
          ),
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 6,
            row: 1,
          ),
          GameUnit.produced(
            id: 'worker_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 8,
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
          GameCity(
            id: 'enemy_north',
            ownerPlayerId: 'player_2',
            name: 'Enemy North',
            center: CityHex(col: 3, row: 0),
          ),
          GameCity(
            id: 'enemy_west',
            ownerPlayerId: 'player_2',
            name: 'Enemy West',
            center: CityHex(col: 2, row: 3),
          ),
          GameCity(
            id: 'enemy_south',
            ownerPlayerId: 'player_3',
            name: 'Enemy South',
            center: CityHex(col: 6, row: 5),
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {
                const HexCoordinate(col: 6, row: 0),
                const HexCoordinate(col: 6, row: 1),
                const HexCoordinate(col: 8, row: 3),
              },
              discoveredHexes: {
                const HexCoordinate(col: 3, row: 0),
                const HexCoordinate(col: 2, row: 3),
                const HexCoordinate(col: 6, row: 5),
              },
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        strategicPlan: StrategicPlan(
          computedAtTurn: 42,
          mode: StrategicMode.recover,
          expectations: const EconomyExpectations(
            expectedCityCount: 3,
            expectedWorkerCount: 2,
            expectedMilitaryCount: 3,
            goldReserveTarget: 10,
            minimumSciencePerTurn: 3,
          ),
          defenses: {
            'capital': StrategicDefenseAssignment(
              cityId: 'capital',
              cityCenter: const CityHex(col: 6, row: 1),
              threatLevel: 0,
              assignedUnitIds: ['capital_guard'],
            ),
            'second': StrategicDefenseAssignment(
              cityId: 'second',
              cityCenter: const CityHex(col: 8, row: 3),
              threatLevel: 0,
              assignedUnitIds: ['second_guard'],
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);
      final unitTypes = plan.commands
          .whereType<StartUnitProductionCommand>()
          .map((command) => command.unitType);

      expect(unitTypes, contains(GameUnitType.scout));
    });

    test('does not found inside remembered enemy territory', () {
      final mapData = _foundingScenarioMap();
      const enemyCity = GameCity(
        id: 'enemy_city',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 2, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_player_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 1,
          ),
        ],
        cities: const [enemyCity],
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
      final view = GameView.fromPersistentState(
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

      final firstFounderCommand = plan.commands.firstWhere(
        (command) =>
            command is MoveUnitCommand &&
                command.unitId == 'settler_player_1' ||
            command is FoundCityCommand &&
                command.founderId == 'settler_player_1',
      );
      expect(firstFounderCommand, isA<MoveUnitCommand>());
    });

    test('skips founding when there is no valid neighbour', () {
      // 1x1 map: no neighbours, so no controlledHexes can be picked.
      final mapData = MapData(
        cols: 1,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
        ],
      );
      final state = PersistentGameState(
        units: [
          GameUnit.startingCommander(
            ownerPlayerId: 'player_1',
            col: 0,
            row: 0,
            army: const [ArmyTroop(type: TroopType.settler, count: 1)],
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(plan.commands.whereType<FoundCityCommand>(), isEmpty);
    });

    test('plans SelectTechnologyCommand when no research is active', () {
      final mapData = _foundingScenarioMap();
      final view = GameView.fromPersistentState(
        const PersistentGameState(),
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

      final research = plan.commands.whereType<SelectTechnologyCommand>();
      expect(
        research,
        contains(
          const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
        ),
      );
    });

    test('uses persona weights when selecting an early technology', () {
      final mapData = _foundingScenarioMap();
      final view = GameView.fromPersistentState(
        const PersistentGameState(),
        forPlayerId: 'player_1',
        turn: 1,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      AiContext contextFor(AiPersona persona) => AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 1,
        rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
        persona: persona,
      );

      final aggressivePlan = const BasicStrategy().plan(
        view,
        contextFor(AiPersona.aggressive),
      );
      final economicPlan = const BasicStrategy().plan(
        view,
        contextFor(AiPersona.economic),
      );

      expect(
        aggressivePlan.commands.whereType<SelectTechnologyCommand>(),
        contains(
          const SelectTechnologyCommand('player_1', TechnologyId.hunting),
        ),
      );
      expect(
        economicPlan.commands.whereType<SelectTechnologyCommand>(),
        contains(
          const SelectTechnologyCommand('player_1', TechnologyId.mining),
        ),
      );
    });

    test(
      'prioritizes technology that unlocks visible resource improvements',
      () {
        final mapData = _pastureResourceMap();
        final state = PersistentGameState(
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [CityHex(col: 1, row: 0)],
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.agriculture},
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
        final view = GameView.fromPersistentState(
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
          plan.commands.whereType<SelectTechnologyCommand>(),
          contains(
            const SelectTechnologyCommand(
              'player_1',
              TechnologyId.animalHusbandry,
            ),
          ),
        );
      },
    );

    test('uses persona to choose unlocked city specialization', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
            buildings: {CityBuildingType.archive},
          ),
        ],
        research: _researchWithUnlocked(TechnologyId.specialization),
      );
      final view = GameView.fromPersistentState(
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
        persona: AiPersona.scientific,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<SetCitySpecializationCommand>(),
        contains(
          const SetCitySpecializationCommand(
            'city_1',
            CitySpecializationType.science,
          ),
        ),
      );
    });

    test('skips research when a technology is already active', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.mining,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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

      expect(plan.commands.whereType<SelectTechnologyCommand>(), isEmpty);
    });

    test('starts defender production when an empty city has no garrison', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        cities: const [_TestCities.capital],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        plan.commands.whereType<StartUnitProductionCommand>(),
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );
    });

    test(
      'starts second-city settler when an empty city already has a worker and guard',
      () {
        final mapData = _foundingScenarioMap();
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
          cities: [_TestCities.capital.copyWith(population: 4)],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
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
          plan.commands.whereType<StartUnitProductionCommand>(),
          contains(
            const StartUnitProductionCommand('city_1', GameUnitType.settler),
          ),
        );
      },
    );

    test(
      'prioritizes a settler before granary when there is room to expand',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
          cities: [_TestCities.capital.copyWith(population: 4)],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
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
          plan.commands.whereType<StartUnitProductionCommand>(),
          contains(
            const StartUnitProductionCommand('city_1', GameUnitType.settler),
          ),
        );
        expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
      },
    );

    test('keeps expanding when a visible enemy army is distant', () {
      final mapData = _largeExpansionMap();
      const secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        population: 4,
        center: CityHex(col: 3, row: 5),
        buildings: {CityBuildingType.granary},
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'worker_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 3,
            row: 4,
          ),
          for (final entry in const [
            ('warrior_1', 1, 0),
            ('warrior_2', 1, 2),
            ('warrior_3', 3, 4),
            ('warrior_4', 4, 5),
          ])
            GameUnit.produced(
              id: entry.$1,
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: entry.$2,
              row: entry.$3,
            ),
          for (final entry in const [
            ('enemy_1', 9, 9),
            ('enemy_2', 8, 9),
            ('enemy_3', 9, 8),
            ('enemy_4', 8, 8),
            ('enemy_5', 9, 7),
          ])
            GameUnit.produced(
              id: entry.$1,
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: entry.$2,
              row: entry.$3,
            ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            population: 4,
            buildings: const {CityBuildingType.granary},
          ),
          secondCity,
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 18,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 18,
        rng: AiRng.fromTurn(turn: 18, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);
      final unitTypes = plan.commands
          .whereType<StartUnitProductionCommand>()
          .map((command) => command.unitType);

      expect(unitTypes, contains(GameUnitType.settler));
      expect(unitTypes, isNot(contains(GameUnitType.warrior)));
    });

    test('adds workers when cities outnumber existing workers', () {
      final mapData = _roomyExpansionMap();
      final secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        center: const CityHex(col: 5, row: 5),
        buildings: {CityBuildingType.granary},
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
          investedProduction: 0,
        ),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            buildings: const {CityBuildingType.granary},
          ),
          secondCity,
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 4,
        rng: AiRng.fromTurn(turn: 4, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>().map(
          (command) => command.unitType,
        ),
        contains(GameUnitType.worker),
      );
    });

    test('aggressive persona trains military before a granary', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: const [_TestCities.capital],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        persona: AiPersona.aggressive,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>(),
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );
      expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
    });

    test(
      'german roomy opening trains a reserve defender before first settler',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
          ],
          cities: const [_TestCities.capital],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 2,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 2,
          rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
          persona: profile.defaultPersona,
          civProfile: profile,
          strategicPlan: const StrategicPlan(
            computedAtTurn: 2,
            mode: StrategicMode.consolidate,
            expectations: _testExpectations,
          ),
        );

        final plan = const BasicStrategy().plan(view, context);
        final unitTypes = plan.commands
            .whereType<StartUnitProductionCommand>()
            .map((command) => command.unitType);

        expect(unitTypes, contains(GameUnitType.warrior));
        expect(unitTypes, isNot(contains(GameUnitType.settler)));
        expect(unitTypes, isNot(contains(GameUnitType.worker)));
      },
    );

    test(
      'german one-city recovery fills reserve before a second-city settler',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
          ],
          cities: const [_TestCities.capital],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 24,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 24,
          rng: AiRng.fromTurn(turn: 24, playerId: 'player_1', baseSeed: 1001),
          persona: profile.defaultPersona,
          civProfile: profile,
          strategicPlan: const StrategicPlan(
            computedAtTurn: 24,
            mode: StrategicMode.military,
            expectations: _testExpectations,
          ),
        );

        final plan = const BasicStrategy().plan(view, context);

        expect(
          plan.commands.whereType<StartUnitProductionCommand>(),
          contains(
            const StartUnitProductionCommand('city_1', GameUnitType.warrior),
          ),
        );
      },
    );

    test(
      'balanced one-city recovery starts a second-city settler with one guard',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
          ],
          cities: [_TestCities.capital.copyWith(population: 4)],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 20,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 20,
          rng: AiRng.fromTurn(turn: 20, playerId: 'player_1', baseSeed: 1001),
          strategicPlan: const StrategicPlan(
            computedAtTurn: 20,
            mode: StrategicMode.recover,
            expectations: _testExpectations,
          ),
        );

        final plan = const BasicStrategy().plan(view, context);

        expect(
          plan.commands,
          contains(
            const StartUnitProductionCommand('city_1', GameUnitType.settler),
          ),
        );
      },
    );

    test('german stable two-city opening starts a third-city settler', () {
      final mapData = _roomyExpansionMap();
      const secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        population: 3,
        center: CityHex(col: 5, row: 5),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 5,
            row: 4,
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
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 28,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 28,
        rng: AiRng.fromTurn(turn: 28, playerId: 'player_1', baseSeed: 1001),
        persona: profile.defaultPersona,
        civProfile: profile,
        strategicPlan: StrategicPlan(
          computedAtTurn: 28,
          mode: StrategicMode.military,
          expectations: _testExpectations,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 1, row: 1),
              threatLevel: 0,
              assignedUnitIds: const ['warrior_1'],
            ),
            'city_2': StrategicDefenseAssignment(
              cityId: 'city_2',
              cityCenter: const CityHex(col: 5, row: 5),
              threatLevel: 0,
              assignedUnitIds: const ['warrior_2'],
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>(),
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
    });

    test(
      'two-city opening can start a third settler with calm unassigned guards',
      () {
        final mapData = _roomyExpansionMap();
        const secondCity = GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_1',
          name: 'Second',
          population: 3,
          center: CityHex(col: 5, row: 5),
        );
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 5,
              row: 4,
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
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 32,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 32,
          rng: AiRng.fromTurn(turn: 32, playerId: 'player_1', baseSeed: 1001),
          persona: profile.defaultPersona,
          civProfile: profile,
          strategicPlan: StrategicPlan(
            computedAtTurn: 32,
            mode: StrategicMode.military,
            expectations: _testExpectations,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 1, row: 1),
                threatLevel: 0,
                assignedUnitIds: const [],
              ),
              'city_2': StrategicDefenseAssignment(
                cityId: 'city_2',
                cityCenter: const CityHex(col: 5, row: 5),
                threatLevel: 0,
                assignedUnitIds: const [],
              ),
            },
          ),
        );

        final plan = const BasicStrategy().plan(view, context);
        final unitTypes = plan.commands
            .whereType<StartUnitProductionCommand>()
            .map((command) => command.unitType)
            .toList();

        expect(
          unitTypes,
          contains(GameUnitType.settler),
          reason: 'unit production was $unitTypes',
        );
      },
    );

    test(
      'economic two-city opening starts a third-city settler before projects',
      () {
        final mapData = _roomyExpansionMap();
        final secondCity = GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_1',
          name: 'Second',
          population: 3,
          center: const CityHex(col: 5, row: 5),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.research,
            investedProduction: 0,
          ),
        );
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 5,
              row: 4,
            ),
          ],
          cities: [_TestCities.capital, secondCity],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 34,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final profile = CivilizationProfiles.all[PlayerCountry.netherlands]!;
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 34,
          rng: AiRng.fromTurn(turn: 34, playerId: 'player_1', baseSeed: 1001),
          persona: profile.defaultPersona,
          civProfile: profile,
          strategicPlan: StrategicPlan(
            computedAtTurn: 34,
            mode: StrategicMode.expand,
            expectations: _testExpectations,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 1, row: 1),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_1'],
              ),
              'city_2': StrategicDefenseAssignment(
                cityId: 'city_2',
                cityCenter: const CityHex(col: 5, row: 5),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_2'],
              ),
            },
          ),
        );

        final plan = const BasicStrategy().plan(view, context);
        final unitTypes = plan.commands
            .whereType<StartUnitProductionCommand>()
            .map((command) => command.unitType);

        expect(unitTypes, contains(GameUnitType.settler));
        expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
      },
    );

    test('threatened city without garrison trains a defender', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
        ],
        cities: const [_TestCities.capital],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 2,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 2,
        mode: StrategicMode.consolidate,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 1, row: 1),
            threatLevel: 12,
            assignedUnitIds: const [],
            primaryThreatPlayerId: 'player_2',
          ),
        },
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
        plan.commands.whereType<StartUnitProductionCommand>(),
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );
      expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
    });

    test('threatened one-city core trains defense before worker recovery', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 2,
            row: 1,
          ),
        ],
        cities: const [_TestCities.capital],
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 68,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 68,
        rng: AiRng.fromTurn(turn: 68, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: StrategicPlan(
          computedAtTurn: 68,
          mode: StrategicMode.military,
          expectations: _testExpectations,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 1, row: 1),
              threatLevel: 8,
              assignedUnitIds: const ['warrior_1', 'warrior_2'],
              primaryThreatPlayerId: 'player_2',
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      final queuedUnits = plan.commands
          .whereType<StartUnitProductionCommand>()
          .map((command) => command.unitType)
          .toList();
      expect(queuedUnits, contains(GameUnitType.warrior));
      expect(queuedUnits, isNot(contains(GameUnitType.worker)));
    });

    test('uses city research project instead of spamming combat units', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        playerGold: const {'player_1': 16},
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 0,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            buildings: const {CityBuildingType.granary},
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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

      expect(plan.commands.whereType<StartUnitProductionCommand>(), isEmpty);
      expect(
        plan.commands.whereType<StartCityProjectCommand>(),
        contains(
          const StartCityProjectCommand('city_1', CityProjectType.research),
        ),
      );
    });

    test('starts an unlocked city building when empire basics are covered', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        playerGold: const {'player_1': 20},
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 0,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            buildings: const {CityBuildingType.granary},
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.craftsmanship},
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 4,
        rng: AiRng.fromTurn(turn: 4, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartBuildingCommand>(),
        contains(
          const StartBuildingCommand('city_1', CityBuildingType.workshop),
        ),
      );
    });

    test(
      'economic persona prefers wealth over research at modest reserves',
      () {
        final mapData = _foundingScenarioMap();
        final state = PersistentGameState(
          playerGold: const {'player_1': 16},
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
            GameUnit.produced(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              col: 2,
              row: 0,
            ),
          ],
          cities: [
            _TestCities.capital.copyWith(
              buildings: const {CityBuildingType.granary},
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
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
          persona: AiPersona.economic,
        );

        final plan = const BasicStrategy().plan(view, context);

        expect(
          plan.commands.whereType<StartCityProjectCommand>(),
          contains(
            const StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
        );
      },
    );

    test('uses city wealth project when treasury is low and gold is flat', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        playerGold: const {'player_1': 0},
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 0,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            buildings: const {CityBuildingType.granary},
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        plan.commands.whereType<StartCityProjectCommand>(),
        contains(
          const StartCityProjectCommand('city_1', CityProjectType.wealth),
        ),
      );
    });

    test('uses city wealth project when there is no research target', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        playerGold: const {'player_1': 20},
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 0,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            buildings: const {CityBuildingType.granary},
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: GameRuleset
                  .defaults
                  .technology
                  .technologies
                  .keys
                  .toSet(),
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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

      expect(plan.commands.whereType<SelectTechnologyCommand>(), isEmpty);
      expect(
        plan.commands.whereType<StartCityProjectCommand>(),
        contains(
          const StartCityProjectCommand('city_1', CityProjectType.wealth),
        ),
      );
    });

    test('starts second settler before projects when expansion is thin', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            population: 4,
            buildings: const {CityBuildingType.granary},
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        plan.commands.whereType<StartUnitProductionCommand>().map(
          (command) => command.unitType,
        ),
        contains(GameUnitType.settler),
      );
      expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
    });

    test(
      'rebuilds a second-city settler once one-city defense is reinforced',
      () {
        final mapData = _roomyExpansionMap();
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 1,
              row: 2,
            ),
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 2,
              row: 1,
            ),
            GameUnit.produced(
              id: 'warrior_3',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
            GameUnit.produced(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 3,
              row: 1,
            ),
          ],
          cities: [
            _TestCities.capital.copyWith(
              population: 5,
              buildings: const {CityBuildingType.granary},
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 48,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 48,
          rng: AiRng.fromTurn(turn: 48, playerId: 'player_1', baseSeed: 1001),
          persona: AiPersona.economic,
          civProfile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
        );

        final plan = const BasicStrategy().plan(view, context);

        expect(
          plan.commands.whereType<StartUnitProductionCommand>().map(
            (command) => command.unitType,
          ),
          contains(GameUnitType.settler),
        );
        expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
      },
    );

    test('trains an opening worker before chaining settlers', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            population: 6,
            buildings: const {CityBuildingType.granary},
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        persona: AiPersona.aggressive,
      );

      final plan = const BasicStrategy().plan(view, context);
      final unitProduction = plan.commands
          .whereType<StartUnitProductionCommand>();

      expect(
        unitProduction.map((command) => command.unitType),
        contains(GameUnitType.worker),
      );
      expect(
        unitProduction.map((command) => command.unitType),
        isNot(contains(GameUnitType.settler)),
      );
    });

    test('expansive persona keeps producing settlers up to three cities', () {
      final mapData = _foundingScenarioMap();
      const secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        population: 4,
        center: CityHex(col: 0, row: 0),
        buildings: {CityBuildingType.granary},
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            population: 4,
            buildings: const {CityBuildingType.granary},
          ),
          secondCity,
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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
        persona: AiPersona.expansive,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>().map(
          (command) => command.unitType,
        ),
        contains(GameUnitType.settler),
      );
    });

    test('skips production when a city already has a production queue', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        cities: [
          _TestCities.capital.copyWith(
            productionQueue: CityProductionQueue.unit(
              unitType: GameUnitType.worker,
              investedProduction: 0,
            ),
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
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

      expect(plan.commands.whereType<StartUnitProductionCommand>(), isEmpty);
      expect(plan.commands.whereType<StartBuildingCommand>(), isEmpty);
      expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
    });

    test('replaces background city projects when core units are missing', () {
      final mapData = _roomyExpansionMap();
      final secondCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Second',
        center: const CityHex(col: 5, row: 5),
        population: 3,
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 4,
            row: 4,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            population: 3,
            productionQueue: CityProductionQueue.project(
              projectType: CityProjectType.wealth,
            ),
          ),
          secondCity,
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 8,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 8,
        rng: AiRng.fromTurn(turn: 8, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<StartUnitProductionCommand>().map(
          (command) => command.unitType,
        ),
        contains(GameUnitType.worker),
      );
      expect(plan.commands.whereType<StartCityProjectCommand>(), isEmpty);
    });

    test('assigns an idle worker standing on an improved city tile', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            controlledHexes: const [CityHex(col: 0, row: 1)],
          ),
        ],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 0, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        research: _researchWithUnlocked(TechnologyId.agriculture),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 3,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 3,
        rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<AssignWorkerToHexCommand>(),
        contains(const AssignWorkerToHexCommand('worker_1')),
      );
      expect(
        plan.commands.whereType<SelectWorkerImprovementCommand>(),
        isEmpty,
      );
    });

    test(
      'moves an idle worker off an improved tile to build a new improvement',
      () {
        final mapData = _pastureResourceMap();
        final state = PersistentGameState(
          units: [
            _unit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 1,
            ),
          ],
          cities: [
            _TestCities.capital.copyWith(
              center: const CityHex(col: 0, row: 0),
              controlledHexes: const [
                CityHex(col: 0, row: 1),
                CityHex(col: 1, row: 0),
              ],
            ),
          ],
          fieldImprovements: const [
            FieldImprovement(
              hex: CityHex(col: 0, row: 1),
              type: FieldImprovementType.farm,
              builtByCityId: 'city_1',
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {
                  TechnologyId.agriculture,
                  TechnologyId.animalHusbandry,
                },
                activeTechnologyId: TechnologyId.mining,
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
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 3,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 3,
          rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
        );

        final plan = const BasicStrategy().plan(view, context);

        expect(
          plan.commands.whereType<MoveUnitCommand>(),
          contains(const MoveUnitCommand('worker_1', 1, 0)),
        );
        expect(plan.commands.whereType<AssignWorkerToHexCommand>(), isEmpty);
      },
    );

    test(
      'starts a farm when an idle worker is on a controlled plains tile',
      () {
        final mapData = _foundingScenarioMap();
        final state = PersistentGameState(
          units: [
            _unit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              col: 0,
              row: 1,
            ),
          ],
          cities: [
            _TestCities.capital.copyWith(
              controlledHexes: const [CityHex(col: 0, row: 1)],
            ),
          ],
          research: _researchWithUnlocked(TechnologyId.agriculture),
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: _allHexesIn(mapData),
              ),
            },
          ),
        );
        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 3,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
        );
        final context = AiContext(
          ruleset: GameRuleset.defaults,
          mapData: mapData,
          turn: 3,
          rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
        );

        final plan = const BasicStrategy().plan(view, context);

        expect(
          plan.commands.whereType<SelectWorkerImprovementCommand>(),
          contains(
            const SelectWorkerImprovementCommand(
              'worker_1',
              FieldImprovementType.farm,
            ),
          ),
        );
        expect(
          plan.commands.whereType<MoveUnitCommand>().where(
            (command) => command.unitId == 'worker_1',
          ),
          isEmpty,
        );
      },
    );

    test('moves an idle worker from city center toward an improvable tile', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 1,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            controlledHexes: const [CityHex(col: 0, row: 1)],
          ),
        ],
        research: _researchWithUnlocked(TechnologyId.agriculture),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 3,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 3,
        rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<MoveUnitCommand>(),
        contains(const MoveUnitCommand('worker_1', 0, 1)),
      );
      expect(
        plan.commands.whereType<SelectWorkerImprovementCommand>(),
        isEmpty,
      );
    });

    test('fallback moves a worker toward a farther improvable tile', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 4, row: 0)],
          ),
        ],
        research: _researchWithUnlocked(TechnologyId.agriculture),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 3,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 3,
        rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: const StrategicPlan(
          computedAtTurn: 3,
          mode: StrategicMode.consolidate,
          expectations: _testExpectations,
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<MoveUnitCommand>(),
        contains(const MoveUnitCommand('worker_1', 3, 0)),
      );
    });

    test('uses strategic worker target before the local tile fallback', () {
      final mapData = _pastureResourceMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
        ],
        cities: [
          _TestCities.capital.copyWith(
            center: const CityHex(col: 0, row: 0),
            controlledHexes: const [
              CityHex(col: 0, row: 1),
              CityHex(col: 1, row: 0),
            ],
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {
                TechnologyId.agriculture,
                TechnologyId.animalHusbandry,
              },
              activeTechnologyId: TechnologyId.mining,
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 3,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 3,
        mode: StrategicMode.expand,
        expectations: const EconomyExpectations(
          expectedCityCount: 2,
          expectedWorkerCount: 1,
          expectedMilitaryCount: 1,
          goldReserveTarget: 8,
          minimumSciencePerTurn: 2,
        ),
        workerAssignments: {
          'worker_1': StrategicWorkerAssignment(
            workerId: 'worker_1',
            cityId: 'city_1',
            targets: const [
              StrategicWorkerTarget(
                cityId: 'city_1',
                targetHex: CityHex(col: 1, row: 0),
                improvementType: FieldImprovementType.pasture,
                score: 4000,
                buildTurns: 3,
                existingImprovement: false,
              ),
            ],
          ),
        },
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 3,
        rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: strategicPlan,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<MoveUnitCommand>(),
        contains(const MoveUnitCommand('worker_1', 1, 0)),
      );
      expect(
        plan.commands.whereType<SelectWorkerImprovementCommand>().where(
          (command) => command.unitId == 'worker_1',
        ),
        isEmpty,
      );
    });

    test('skips worker actions for a busy worker', () {
      final mapData = _foundingScenarioMap();
      final worker =
          _unit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ).copyWithWorkerJob(
            const WorkerJob(
              targetHex: CityHex(col: 0, row: 1),
              improvementType: FieldImprovementType.farm,
              remainingTurns: 1,
              totalTurns: 2,
            ),
          );
      final state = PersistentGameState(
        units: [worker],
        cities: [
          _TestCities.capital.copyWith(
            controlledHexes: const [CityHex(col: 0, row: 1)],
          ),
        ],
        research: _researchWithUnlocked(TechnologyId.agriculture),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 3,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 3,
        rng: AiRng.fromTurn(turn: 3, playerId: 'player_1', baseSeed: 1001),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(plan.commands.whereType<AssignWorkerToHexCommand>(), isEmpty);
      expect(
        plan.commands.whereType<SelectWorkerImprovementCommand>(),
        isEmpty,
      );
      expect(
        plan.commands.whereType<MoveUnitCommand>().where(
          (command) => command.unitId == 'worker_1',
        ),
        isEmpty,
      );
    });

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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test('prefers a pressure target when multiple enemies can be attacked', () {
      final mapData = _foundingScenarioMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test('moves military toward a visible enemy beyond attack range', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
        final state = PersistentGameState(
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
        final view = GameView.fromPersistentState(
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
            contains(
              predicate<String>((note) => note.contains('pressure move')),
            ),
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test('keeps assigned offensive military focused on its war target', () {
      final mapData = _roomyExpansionMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'unrelated_enemy',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
            hitPoints: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'goal_city',
            ownerPlayerId: 'player_3',
            name: 'Goal',
            center: CityHex(col: 7, row: 7),
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 90,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 90,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_3',
            kind: WarGoalKind.captureCity,
            targetCity: const CityHex(col: 7, row: 7),
            targetHex: const HexCoordinate(col: 7, row: 7),
            turnsBudget: 8,
            assignedUnitIds: const ['warrior_1'],
            priority: 6,
          ),
        ],
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 90,
        rng: AiRng.fromTurn(turn: 90, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: strategicPlan,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<AttackHexCommand>(),
        isNot(contains(const AttackHexCommand('warrior_1', 0, 0))),
      );
      expect(
        plan.commands.whereType<MoveUnitCommand>().where(
          (command) => command.unitId == 'warrior_1',
        ),
        isNotEmpty,
      );
    });

    test('clears frontline blockers near an assigned war goal', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          _unit(
            id: 'frontline_blocker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
            hitPoints: 1,
          ),
        ],
        cities: const [
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 90,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 90,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_3',
            kind: WarGoalKind.captureCity,
            targetCity: const CityHex(col: 4, row: 0),
            targetHex: const HexCoordinate(col: 4, row: 0),
            turnsBudget: 8,
            assignedUnitIds: const ['warrior_1'],
            priority: 6,
          ),
        ],
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 90,
        rng: AiRng.fromTurn(turn: 90, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: strategicPlan,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<AttackHexCommand>(),
        contains(const AttackHexCommand('warrior_1', 1, 0)),
      );
    });

    test('wakes fortified units assigned to an offensive war goal', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 0,
            row: 0,
            movementPoints: 0,
            posture: UnitPosture.fortified,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 1),
          ),
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 92,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 92,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_2',
            kind: WarGoalKind.captureCity,
            targetCity: const CityHex(col: 4, row: 0),
            targetHex: const HexCoordinate(col: 4, row: 0),
            turnsBudget: 6,
            assignedUnitIds: const ['warrior_1'],
            priority: 6,
          ),
        ],
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 92,
        rng: AiRng.fromTurn(turn: 92, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: strategicPlan,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands,
        contains(const CancelUnitActionCommand('warrior_1')),
      );
      expect(
        plan.commands.whereType<MoveUnitCommand>().map(
          (command) => command.unitId,
        ),
        isNot(contains('warrior_1')),
      );
    });

    test('attacks a war-goal city already in range', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'tank_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.tank,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'goal_city',
            ownerPlayerId: 'player_2',
            name: 'Goal',
            center: CityHex(col: 1, row: 0),
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 80,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 80,
        mode: StrategicMode.military,
        expectations: _testExpectations,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_2',
            kind: WarGoalKind.captureCity,
            targetCity: const CityHex(col: 1, row: 0),
            targetHex: const HexCoordinate(col: 1, row: 0),
            turnsBudget: 4,
            assignedUnitIds: const ['tank_1'],
            priority: 10,
          ),
        ],
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 80,
        rng: AiRng.fromTurn(turn: 80, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: strategicPlan,
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<AttackHexCommand>(),
        contains(const AttackHexCommand('tank_1', 1, 0)),
      );
      expect(
        plan.commands.whereType<MoveUnitCommand>().where(
          (command) => command.unitId == 'tank_1',
        ),
        isEmpty,
      );
    });

    test('prioritizes an exposed pressure city over a generic unit attack', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'tank_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.tank,
            col: 1,
            row: 0,
          ),
          _unit(
            id: 'raider_1',
            ownerPlayerId: 'player_3',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'pressure_city',
            ownerPlayerId: 'player_2',
            name: 'Pressure',
            center: CityHex(col: 2, row: 0),
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 80,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        pressureTargetPlayerIds: const ['player_2'],
      );
      const strategicPlan = StrategicPlan(
        computedAtTurn: 80,
        mode: StrategicMode.military,
        expectations: _testExpectations,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 80,
        rng: AiRng.fromTurn(turn: 80, playerId: 'player_1', baseSeed: 1001),
        strategicPlan: strategicPlan,
      );

      final plan = const BasicStrategy().plan(view, context);
      final attacks = plan.commands.whereType<AttackHexCommand>().toList();

      expect(attacks, contains(const AttackHexCommand('tank_1', 2, 0)));
      expect(attacks, isNot(contains(const AttackHexCommand('tank_1', 0, 0))));
    });

    test('keeps defensive war-goal pressure near its anchor', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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

    test('moves assigned garrison toward defended city', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 2,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 2,
        mode: StrategicMode.consolidate,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 10,
            assignedUnitIds: const ['warrior_1'],
            primaryThreatPlayerId: 'player_2',
          ),
        },
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
        plan.commands.whereType<MoveUnitCommand>(),
        contains(const MoveUnitCommand('warrior_1', 1, 0)),
      );
    });

    test('keeps assigned garrison in place when already defending city', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 2,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 2,
        mode: StrategicMode.consolidate,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 10,
            assignedUnitIds: const ['warrior_1'],
            primaryThreatPlayerId: 'player_2',
          ),
        },
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
        plan.commands.whereType<MoveUnitCommand>().where(
          (command) => command.unitId == 'warrior_1',
        ),
        isEmpty,
      );
    });

    test('keeps a calm assigned garrison reserved from pressure', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'tank_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.tank,
            col: 0,
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
          GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy',
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
      final view = GameView.fromPersistentState(
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
              threatLevel: 0,
              assignedUnitIds: const ['tank_1'],
              primaryThreatPlayerId: '',
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<MoveUnitCommand>().where(
          (command) => command.unitId == 'tank_1',
        ),
        isEmpty,
      );
      expect(plan.commands, contains(const FortifyUnitCommand('tank_1')));
    });

    test('fortifies assigned garrison in a threatened defense area', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
            hitPoints: 6,
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
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 2,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final strategicPlan = StrategicPlan(
        computedAtTurn: 2,
        mode: StrategicMode.consolidate,
        expectations: _testExpectations,
        defenses: {
          'city_1': StrategicDefenseAssignment(
            cityId: 'city_1',
            cityCenter: const CityHex(col: 0, row: 0),
            threatLevel: 10,
            assignedUnitIds: const ['warrior_1'],
            primaryThreatPlayerId: 'player_2',
          ),
        },
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
        plan.commands.whereType<FortifyUnitCommand>(),
        contains(const FortifyUnitCommand('warrior_1')),
      );
    });

    test('keeps assigned garrison from chasing adjacent enemies', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
        strategicPlan: StrategicPlan(
          computedAtTurn: 2,
          mode: StrategicMode.military,
          expectations: _testExpectations,
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 10,
              assignedUnitIds: const ['warrior_1'],
              primaryThreatPlayerId: 'player_2',
            ),
          },
        ),
      );

      final plan = const BasicStrategy().plan(view, context);

      expect(
        plan.commands.whereType<AttackHexCommand>().where(
          (command) => command.attackerUnitId == 'warrior_1',
        ),
        isEmpty,
      );
    });

    test('lets assigned garrison attack a pressure target in range', () {
      final mapData = _combatPressureMap();
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final reserveMove = plan.commands
          .whereType<MoveUnitCommand>()
          .singleWhere((command) => command.unitId == 'warrior_1');
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
      final state = PersistentGameState(
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
      final view = GameView.fromPersistentState(
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
  });
}

abstract final class _TestCities {
  static const capital = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Capital',
    center: CityHex(col: 1, row: 1),
  );
}

const _testExpectations = EconomyExpectations(
  expectedCityCount: 2,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 1,
  goldReserveTarget: 8,
  minimumSciencePerTurn: 2,
);

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int col,
  required int row,
  int? hitPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    hitPoints: hitPoints,
  );
}

String _debugCommand(GameCommand command) {
  return switch (command) {
    MoveUnitCommand(:final unitId, :final targetCol, :final targetRow) =>
      'MoveUnit($unitId,$targetCol,$targetRow)',
    FoundCityCommand(:final founderId) => 'FoundCity($founderId)',
    StartUnitProductionCommand(:final cityId, :final unitType) =>
      'StartUnit($cityId,${unitType.name})',
    StartBuildingCommand(:final cityId, :final buildingType) =>
      'StartBuilding($cityId,${buildingType.name})',
    StartCityProjectCommand(:final cityId, :final projectType) =>
      'StartProject($cityId,${projectType.name})',
    SelectTechnologyCommand(:final technologyId) =>
      'SelectTechnology(${technologyId.name})',
    _ => command.runtimeType.toString(),
  };
}

ResearchState _researchWithUnlocked(TechnologyId technologyId) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        unlockedTechnologyIds: {technologyId},
        activeTechnologyId: TechnologyId.mining,
      ),
    },
  );
}

ResearchState _researchWithActiveTarget() {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        activeTechnologyId: TechnologyId.agriculture,
      ),
    },
  );
}

AiContext _contextFor(MapData mapData, {int turn = 1}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: turn,
    rng: AiRng.fromTurn(turn: turn, playerId: 'player_1', baseSeed: 1001),
  );
}

MapData _foundingScenarioMap() {
  final tiles = <TileData>[];
  for (var col = 0; col < 3; col++) {
    for (var row = 0; row < 3; row++) {
      tiles.add(
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return MapData(cols: 3, rows: 3, tiles: tiles);
}

MapData _roomyExpansionMap() {
  final tiles = <TileData>[];
  for (var col = 0; col < 8; col++) {
    for (var row = 0; row < 8; row++) {
      tiles.add(
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return MapData(cols: 8, rows: 8, tiles: tiles);
}

MapData _hiddenRichSiteMap() {
  final richHexes = {
    const HexCoordinate(col: 5, row: 3): ResourceType.wheat,
    const HexCoordinate(col: 5, row: 2): ResourceType.deer,
    const HexCoordinate(col: 5, row: 4): ResourceType.iron,
    const HexCoordinate(col: 6, row: 3): ResourceType.gold,
  };
  final tiles = <TileData>[];
  for (var col = 0; col < 8; col++) {
    for (var row = 0; row < 8; row++) {
      final hex = HexCoordinate(col: col, row: row);
      final resource = richHexes[hex];
      tiles.add(
        TileData(
          col: col,
          row: row,
          terrains: [
            resource == ResourceType.iron
                ? TerrainType.hills
                : TerrainType.plains,
          ],
          resources: resource == null ? const [] : [resource],
          height: 0,
        ),
      );
    }
  }
  return MapData(cols: 8, rows: 8, tiles: tiles);
}

MapData _largeExpansionMap() {
  final tiles = <TileData>[];
  for (var col = 0; col < 10; col++) {
    for (var row = 0; row < 10; row++) {
      tiles.add(
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return MapData(cols: 10, rows: 10, tiles: tiles);
}

MapData _citySiteChoiceMap() {
  final tiles = <TileData>[];
  for (var col = 0; col < 5; col++) {
    for (var row = 0; row < 3; row++) {
      final resources = <ResourceType>[];
      var terrain = TerrainType.desert;
      if (col == 0 && row == 1) terrain = TerrainType.plains;
      if (col == 2 && row == 1) {
        terrain = TerrainType.plains;
        resources.add(ResourceType.wheat);
      }
      if (col == 2 && row == 0) {
        terrain = TerrainType.grassland;
        resources.add(ResourceType.wheat);
      }
      if (col == 2 && row == 2) {
        terrain = TerrainType.plains;
        resources.add(ResourceType.deer);
      }
      if (col == 3 && row == 1) {
        terrain = TerrainType.hills;
        resources.add(ResourceType.iron);
      }
      tiles.add(
        TileData(
          col: col,
          row: row,
          terrains: [terrain],
          resources: resources,
          height: 0,
        ),
      );
    }
  }
  return MapData(cols: 5, rows: 3, tiles: tiles);
}

MapData _combatPressureMap() {
  return MapData(
    cols: 5,
    rows: 1,
    tiles: [
      for (var col = 0; col < 5; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

MapData _pastureResourceMap() {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [ResourceType.sheep],
        height: 0,
      ),
      TileData(
        col: 0,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

Set<HexCoordinate> _allHexesIn(MapData mapData) {
  return {
    for (var col = 0; col < mapData.cols; col++)
      for (var row = 0; row < mapData.rows; row++)
        HexCoordinate(col: col, row: row),
  };
}
