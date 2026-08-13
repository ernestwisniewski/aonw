import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('road transport', () {
    test('worker builds a road without consuming its improvement charge', () {
      final worker = _unit(GameUnitType.worker, col: 1);
      final started = const DomainTransportCommandResolver().buildRoad(
        state: DomainState.snapshot(
          participants: const [
            Player(id: 'player_1', name: 'Player', colorValue: 1),
          ],
          units: [worker],
          cities: const [_city],
        ),
        command: const BuildRoadCommand('unit_1'),
        actorPlayerId: 'player_1',
        mapTiles: _map(),
        paceBalance: PaceBalance.standard60,
      );

      expect(started.accepted, isTrue);
      expect(started.state.units.single.workerJob?.buildsRoad, isTrue);
      expect(started.state.units.single.movementPoints, 0);

      final completed = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: started.state.units,
        cities: started.state.cities,
        fieldImprovements: const [],
        transportNetwork: started.state.transportNetwork,
        mapData: _map(),
      );

      expect(completed.transportNetwork.hasOperationalRoadAt(1, 0), isTrue);
      expect(completed.units.single.workerBuildCharges, 1);
      expect(completed.units.single.workerJob, isNull);
      expect(completed.fieldImprovements, isEmpty);
    });

    test('operational road reduces only passable land traversal to one', () {
      final network = TransportNetworkState(
        segments: const [
          TransportSegment(
            hex: HexCoord(col: 1, row: 0),
            builtByPlayerId: 'player_1',
          ),
          TransportSegment(
            hex: HexCoord(col: 2, row: 0),
            builtByPlayerId: 'player_1',
          ),
        ],
      );
      final resolver = InfrastructureAwareTraversalCostResolver(
        network,
        cityCenters: [_city.center.toCoordinate()],
      );
      final cityCenter = _map().tileAt(0, 0)!;
      final hill = _map().tileAt(1, 0)!;
      final mountain = _map().tileAt(2, 0)!;

      expect(
        resolver
            .costForStep(
              unit: _unit(GameUnitType.warrior),
              from: cityCenter,
              to: hill,
            )
            .value,
        1,
      );
      expect(
        resolver
            .costForStep(
              unit: _unit(GameUnitType.reconPlane),
              from: cityCenter,
              to: hill,
            )
            .value,
        4,
      );
      expect(
        resolver
            .costForStep(
              unit: _unit(GameUnitType.warrior),
              from: hill,
              to: mountain,
            )
            .blocked,
        isTrue,
      );
    });

    test('longer connected road is preferred between city centers', () {
      final map = _cityRouteMap();
      final cities = [
        _cityAt(id: 'city_a', col: 0, row: 1),
        _cityAt(id: 'city_b', col: 6, row: 1),
      ];
      final unit = _unit(GameUnitType.warrior).copyWith(col: 0, row: 1);
      final network = TransportNetworkState(
        segments: [
          for (final hex in const [
            HexCoord(col: 0, row: 2),
            HexCoord(col: 0, row: 3),
            HexCoord(col: 1, row: 3),
            HexCoord(col: 2, row: 3),
            HexCoord(col: 3, row: 3),
            HexCoord(col: 4, row: 3),
            HexCoord(col: 5, row: 3),
            HexCoord(col: 6, row: 3),
            HexCoord(col: 6, row: 2),
          ])
            TransportSegment(hex: hex, builtByPlayerId: 'player_1'),
        ],
      );

      final withoutRoad = UnitMovementPathfinder(
        mapData: map,
        units: [unit],
      ).plan(unit: unit, targetTile: map.tileAt(6, 1)!);
      final withRoad = UnitMovementPathfinder(
        mapData: map,
        units: [unit],
        costResolver: InfrastructureAwareTraversalCostResolver(
          network,
          cityCenters: [for (final city in cities) city.center.toCoordinate()],
        ),
      ).plan(unit: unit, targetTile: map.tileAt(6, 1)!);

      expect(withoutRoad?.totalCost, 12);
      expect(withoutRoad?.path.every((hex) => hex.row == 1), isTrue);
      expect(withRoad?.totalCost, 10);
      expect(withRoad?.path, const [
        (col: 0, row: 1),
        (col: 0, row: 2),
        (col: 0, row: 3),
        (col: 1, row: 3),
        (col: 2, row: 3),
        (col: 3, row: 3),
        (col: 4, row: 3),
        (col: 5, row: 3),
        (col: 6, row: 3),
        (col: 6, row: 2),
        (col: 6, row: 1),
      ]);
    });

    test('active merchant route replans onto a newly connected road', () {
      final map = _cityRouteMap();
      final cities = [
        _cityAt(id: 'city_a', col: 0, row: 1),
        _cityAt(id: 'city_b', col: 6, row: 1),
      ];
      final merchant = _unit(GameUnitType.merchant)
          .copyWith(col: 0, row: 1)
          .copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_a',
              destinationCityId: 'city_b',
              steps: [
                for (var col = 0; col <= 6; col++)
                  UnitMovementStep(
                    col: col,
                    row: 1,
                    enterCost: col == 0 ? 0 : 2,
                    cumulativeCost: col * 2,
                  ),
              ],
            ),
          );
      final network = TransportNetworkState(
        segments: [
          for (final hex in const [
            HexCoord(col: 0, row: 2),
            HexCoord(col: 0, row: 3),
            HexCoord(col: 1, row: 3),
            HexCoord(col: 2, row: 3),
            HexCoord(col: 3, row: 3),
            HexCoord(col: 4, row: 3),
            HexCoord(col: 5, row: 3),
            HexCoord(col: 6, row: 3),
            HexCoord(col: 6, row: 2),
          ])
            TransportSegment(hex: hex, builtByPlayerId: 'player_1'),
        ],
      );

      final advanced = MerchantTradeRouteRules.advanceUnit(
        unit: merchant,
        units: [merchant],
        cities: cities,
        mapData: map,
        transportNetwork: network,
      );

      expect(advanced.routeInvalidated, isFalse);
      expect(advanced.movedSteps.map((step) => step.coord), const [
        (col: 0, row: 2),
        (col: 0, row: 3),
        (col: 1, row: 3),
        (col: 2, row: 3),
        (col: 3, row: 3),
        (col: 4, row: 3),
      ]);
      expect((advanced.unit.col, advanced.unit.row), (4, 3));
      expect(
        advanced.unit.merchantTradeRoute!.steps.any((step) => step.row == 3),
        isTrue,
      );
    });

    test('network JSON is deterministic and round-trips', () {
      final state = TransportNetworkState(
        segments: const [
          TransportSegment(
            hex: HexCoord(col: 2, row: 1),
            builtByPlayerId: 'player_2',
            condition: TransportSegmentCondition.pillaged,
          ),
          TransportSegment(
            hex: HexCoord(col: 0, row: 1),
            builtByPlayerId: 'player_1',
            builtByCityId: 'city_1',
          ),
        ],
      );

      final json = state.toJson();

      expect(json.first['col'], 0);
      expect(TransportNetworkState.fromJson(json), state);
    });

    test('known network includes owned, city-owned, and discovered roads', () {
      const ownRoad = TransportSegment(
        hex: HexCoord(col: 0, row: 0),
        builtByPlayerId: 'player_1',
      );
      const ownCityRoad = TransportSegment(
        hex: HexCoord(col: 1, row: 0),
        builtByPlayerId: 'player_2',
        builtByCityId: 'city_1',
      );
      const discoveredRoad = TransportSegment(
        hex: HexCoord(col: 2, row: 0),
        builtByPlayerId: 'player_2',
      );
      const hiddenRoad = TransportSegment(
        hex: HexCoord(col: 3, row: 0),
        builtByPlayerId: 'player_2',
      );
      final network = TransportNetworkState(
        segments: const [ownRoad, ownCityRoad, discoveredRoad, hiddenRoad],
      );
      final visibility = FogVisibilityQuery(
        playerId: 'player_1',
        state: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {const HexCoordinate(col: 2, row: 0)},
            ),
          },
        ),
      );

      final known = TransportNetworkVisibilityRules.knownFor(
        network: network,
        playerId: 'player_1',
        ownCityIds: const ['city_1'],
        visibility: visibility,
      );

      expect(
        known.segments,
        containsAll(const [ownRoad, ownCityRoad, discoveredRoad]),
      );
      expect(known.segments, isNot(contains(hiddenRoad)));
      expect(
        TransportNetworkVisibilityRules.knownFor(
          network: TransportNetworkState.empty,
          playerId: 'player_1',
          ownCityIds: const [],
          visibility: visibility,
        ),
        same(TransportNetworkState.empty),
      );
    });

    test('engine classifies road construction as infrastructure', () {
      expect(
        GameEngine.commandFamily(const BuildRoadCommand('unit_1')),
        GameEngineCommandFamily.infrastructure,
      );
    });

    test('engine starts road construction through the canonical boundary', () {
      final snapshot = CanonicalGameSnapshot.snapshot(
        domain: DomainState.snapshot(
          participants: const [
            Player(id: 'player_1', name: 'Player', colorValue: 1),
          ],
          units: [_unit(GameUnitType.worker, col: 1)],
          cities: const [_city],
        ),
        metadata: GameSnapshotMetadata(
          id: 'road-test',
          schemaVersion: gameSaveCurrentSchemaVersion,
          name: 'Road test',
          world: const WorldReference(name: 'road', source: MapSource.asset),
          savedAtUtc: DateTime.utc(2026, 8, 11),
          camera: GameSnapshotCamera.zero,
        ),
      );

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const BuildRoadCommand('unit_1'),
        context: GameEngineContext(
          actorPlayerId: 'player_1',
          mapView: _map(),
          ruleset: GameRuleset.defaults,
          commandTick: 1,
        ),
      );

      expect(result, isA<GameEngineAccepted>());
      expect(result.snapshot.domain.units.single.workerJob?.buildsRoad, true);
      expect(result.snapshot.metadata, same(snapshot.metadata));
    });

    test(
      'construction legality rejects occupied infrastructure and cities',
      () {
        final worker = _unit(GameUnitType.worker, col: 1);
        final existing = RoadConstructionRules.evaluate(
          unit: worker,
          cities: const [_city],
          network: TransportNetworkState(
            segments: const [
              TransportSegment(
                hex: HexCoord(col: 1, row: 0),
                builtByPlayerId: 'player_1',
              ),
            ],
          ),
          mapTiles: _map(),
        );
        final cityCenter = RoadConstructionRules.evaluate(
          unit: _unit(GameUnitType.worker),
          cities: const [_city],
          network: TransportNetworkState.empty,
          mapTiles: _map(),
        );

        expect(existing.blocker, RoadConstructionBlocker.existingRoad);
        expect(cityCenter.blocker, RoadConstructionBlocker.cityCenter);
      },
    );
  });
}

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 1, row: 0)],
);

GameCity _cityAt({required String id, required int col, required int row}) =>
    GameCity(
      id: id,
      ownerPlayerId: 'player_1',
      name: id,
      center: CityHex(col: col, row: row),
    );

GameUnit _unit(GameUnitType type, {int col = 0}) => GameUnit(
  id: 'unit_1',
  ownerPlayerId: 'player_1',
  type: type,
  name: type.defaultNameToken,
  col: col,
  row: 0,
);

WorldMap _map() => WorldMap(
  cols: 3,
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
      terrains: [TerrainType.plains, TerrainType.hills],
      resources: [],
      height: 0,
    ),
    WorldTile(
      col: 2,
      row: 0,
      terrains: [TerrainType.mountain],
      resources: [],
      height: 0,
    ),
  ],
);

WorldMap _cityRouteMap() => WorldMap(
  cols: 7,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 7; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: [
            if (row == 1 || row == 3 || (row == 2 && (col == 0 || col == 6)))
              TerrainType.plains
            else
              TerrainType.mountain,
          ],
          resources: const [],
          height: 0,
        ),
  ],
);
