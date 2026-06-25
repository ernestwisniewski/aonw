import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameView', () {
    test('filters enemy dynamic state through fog of war', () {
      final mapData = _mapData();
      const ownCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      const enemyCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 2, row: 0),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
          GameUnit.startingCommander(ownerPlayerId: 'player_2', col: 1, row: 0),
          GameUnit.produced(
            id: 'hidden_worker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.worker,
            col: 2,
            row: 1,
          ),
        ],
        cities: [ownCity, enemyCity],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 0, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
          FieldImprovement(
            hex: CityHex(col: 2, row: 0),
            type: FieldImprovementType.mine,
            builtByCityId: 'city_2',
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {const HexCoordinate(col: 2, row: 0)},
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
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        defaultNeutralPlayerIds: const ['default_neutral'],
      );

      expect(view.ownUnits.single.ownerPlayerId, 'player_1');
      expect(view.visibleEnemyUnits.map((unit) => unit.id), [
        'commander_player_2',
      ]);
      expect(
        view.movementBlockingUnits.map((unit) => unit.id),
        containsAll([
          'commander_player_1',
          'commander_player_2',
          'hidden_worker',
        ]),
      );
      expect(view.rememberedEnemyCities.single.id, 'city_2');
      expect(view.ownImprovements.single.type, FieldImprovementType.farm);
      expect(view.ownResearch, PlayerResearchState.empty);
    });

    test('filters visible artifacts through fog of war and ownership', () {
      final mapData = _mapData();
      const ownCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      const hiddenEnemyCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Hidden Rival',
        center: CityHex(col: 2, row: 1),
      );
      final ownCarrier = GameUnit.produced(
        id: 'carrier_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWithCarriedArtifact('own_carried');
      final hiddenCarrier = GameUnit.produced(
        id: 'hidden_carrier',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 2,
        row: 1,
      ).copyWithCarriedArtifact('hidden_carried');
      final state = PersistentGameState(
        units: [ownCarrier, hiddenCarrier],
        cities: const [ownCity, hiddenEnemyCity],
        artifacts: const [
          WorldArtifact(
            id: 'visible_map',
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.map(col: 1, row: 0),
          ),
          WorldArtifact(
            id: 'hidden_map',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.map(col: 2, row: 1),
          ),
          WorldArtifact(
            id: 'own_stored',
            type: WorldArtifactType.merchantsSeal,
            location: WorldArtifactLocation.stored(cityId: 'city_1'),
          ),
          WorldArtifact(
            id: 'hidden_stored',
            type: WorldArtifactType.queensMirror,
            location: WorldArtifactLocation.stored(cityId: 'city_2'),
          ),
          WorldArtifact(
            id: 'own_carried',
            type: WorldArtifactType.templeReliquary,
            location: WorldArtifactLocation.carried(unitId: 'carrier_1'),
          ),
          WorldArtifact(
            id: 'hidden_carried',
            type: WorldArtifactType.prophetMask,
            location: WorldArtifactLocation.carried(unitId: 'hidden_carrier'),
          ),
        ],
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
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );

      expect(view.artifacts.map((artifact) => artifact.id), [
        'visible_map',
        'own_stored',
        'own_carried',
      ]);
    });

    test('can expose static map state for AI planning', () {
      final mapData = _mapData();
      const enemyCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 2, row: 0),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
          GameUnit.produced(
            id: 'hidden_worker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.worker,
            col: 2,
            row: 1,
          ),
        ],
        cities: const [enemyCity],
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
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        ignoreFogOfWar: true,
      );

      expect(view.visibility.isEnabled, isFalse);
      expect(view.visibleEnemyUnits, isEmpty);
      expect(view.rememberedEnemyCities.single.id, 'city_2');
    });

    test('can also expose dynamic units for diagnostic simulations', () {
      final mapData = _mapData();
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'hidden_worker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.worker,
            col: 2,
            row: 1,
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
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        ignoreFogOfWar: true,
        ignoreDynamicFogOfWar: true,
      );

      expect(view.visibleEnemyUnits.single.id, 'hidden_worker');
    });

    test('filters targetable enemies through explicit diplomacy', () {
      final mapData = _mapData();
      final diplomacy = DiplomacyState.empty
          .setStatus('player_1', 'friendly', DiplomaticRelationStatus.friendly)
          .setStatus('player_1', 'neutral', DiplomaticRelationStatus.neutral)
          .setStatus('player_1', 'hostile', DiplomaticRelationStatus.hostile)
          .setStatus('player_1', 'war', DiplomaticRelationStatus.war);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'friendly_unit',
            ownerPlayerId: 'friendly',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'neutral_unit',
            ownerPlayerId: 'neutral',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'hostile_unit',
            ownerPlayerId: 'hostile',
            type: GameUnitType.warrior,
            col: 2,
            row: 0,
          ),
          GameUnit.produced(
            id: 'war_unit',
            ownerPlayerId: 'war',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
          GameUnit.produced(
            id: 'default_neutral_unit',
            ownerPlayerId: 'default_neutral',
            type: GameUnitType.warrior,
            col: 2,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'friendly_city',
            ownerPlayerId: 'friendly',
            name: 'Friendly',
            center: CityHex(col: 0, row: 1),
          ),
          GameCity(
            id: 'neutral_city',
            ownerPlayerId: 'neutral',
            name: 'Neutral',
            center: CityHex(col: 1, row: 0),
          ),
          GameCity(
            id: 'hostile_city',
            ownerPlayerId: 'hostile',
            name: 'Hostile',
            center: CityHex(col: 2, row: 0),
          ),
          GameCity(
            id: 'war_city',
            ownerPlayerId: 'war',
            name: 'War',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'default_neutral_city',
            ownerPlayerId: 'default_neutral',
            name: 'Default Neutral',
            center: CityHex(col: 2, row: 1),
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {
                const HexCoordinate(col: 0, row: 1),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 1, row: 1),
                const HexCoordinate(col: 2, row: 0),
                const HexCoordinate(col: 2, row: 1),
              },
              visibleHexes: {
                const HexCoordinate(col: 0, row: 1),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 1, row: 1),
                const HexCoordinate(col: 2, row: 0),
                const HexCoordinate(col: 2, row: 1),
              },
            ),
          },
        ),
        runtimeState: GameRuntimeState(diplomacy: diplomacy),
      );

      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        defaultNeutralPlayerIds: const ['default_neutral'],
      );

      expect(view.visibleTargetableEnemyUnits.map((unit) => unit.id), [
        'hostile_unit',
        'war_unit',
      ]);
      expect(view.rememberedTargetableEnemyCities.map((city) => city.id), [
        'hostile_city',
        'war_city',
      ]);
    });

    test('pressure targets override default neutral diplomacy', () {
      final mapData = _mapData();
      const targetCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Pressure Target',
        center: CityHex(col: 2, row: 0),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: const [targetCity],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {const HexCoordinate(col: 2, row: 0)},
              visibleHexes: {
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
            ),
          },
        ),
      );

      final neutralView = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        defaultNeutralPlayerIds: const ['player_2'],
      );
      final pressuredView = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        defaultNeutralPlayerIds: const ['player_2'],
        pressureTargetPlayerIds: const ['player_2'],
      );

      expect(neutralView.visibleTargetableEnemyUnits, isEmpty);
      expect(neutralView.rememberedTargetableEnemyCities, isEmpty);
      expect(pressuredView.visibleTargetableEnemyUnits.single.id, 'warrior_2');
      expect(pressuredView.rememberedTargetableEnemyCities.single.id, 'city_2');
    });

    test(
      'explicit neutral relation blocks stale pressure and hostility memory',
      () {
        final mapData = _mapData();
        final diplomacy = DiplomacyState.empty.setStatus(
          'player_1',
          'player_2',
          DiplomaticRelationStatus.neutral,
        );
        const targetCity = GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_2',
          name: 'Neutral Target',
          center: CityHex(col: 2, row: 0),
        );
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
          ],
          cities: const [targetCity],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                discoveredHexes: {const HexCoordinate(col: 2, row: 0)},
                visibleHexes: {
                  const HexCoordinate(col: 1, row: 0),
                  const HexCoordinate(col: 2, row: 0),
                },
              ),
            },
          ),
          runtimeState: GameRuntimeState(diplomacy: diplomacy),
        );

        final view = GameView.fromPersistentState(
          state,
          forPlayerId: 'player_1',
          turn: 4,
          mapData: mapData,
          ruleset: GameRuleset.defaults,
          recentHostilePlayerIds: const ['player_2'],
          pressureTargetPlayerIds: const ['player_2'],
        );

        expect(view.canTargetPlayer('player_2'), isFalse);
        expect(view.visibleTargetableEnemyUnits, isEmpty);
        expect(view.rememberedTargetableEnemyCities, isEmpty);
      },
    );

    test('current attack intent can override explicit neutral relation', () {
      final mapData = _mapData();
      final diplomacy = DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.neutral,
      );
      const targetCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Active Attacker',
        center: CityHex(col: 2, row: 0),
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: const [targetCity],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {const HexCoordinate(col: 2, row: 0)},
              visibleHexes: {
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
            ),
          },
        ),
        runtimeState: GameRuntimeState(diplomacy: diplomacy),
      );

      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        activeHostilePlayerIds: const ['player_2'],
      );

      expect(view.canTargetPlayer('player_2'), isTrue);
      expect(view.visibleTargetableEnemyUnits.single.id, 'warrior_2');
      expect(view.rememberedTargetableEnemyCities.single.id, 'city_2');
    });

    test('projects available technology ids from own research', () {
      final mapData = _mapData();
      final state = PersistentGameState(
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
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

      expect(view.availableTechnologyIds, contains(TechnologyId.mining));
      expect(view.availableTechnologyIds, contains(TechnologyId.hunting));
      expect(
        view.availableTechnologyIds,
        contains(TechnologyId.animalHusbandry),
      );
      expect(
        view.availableTechnologyIds,
        isNot(contains(TechnologyId.agriculture)),
      );
      expect(
        view.availableTechnologyIds,
        isNot(contains(TechnologyId.woodworking)),
      );
    });
  });
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 2,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 2; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
