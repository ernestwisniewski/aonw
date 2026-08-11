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
      final resolver = InfrastructureAwareTraversalCostResolver(network);
      final hill = _map().tileAt(1, 0)!;
      final mountain = _map().tileAt(2, 0)!;

      expect(
        resolver
            .costToEnter(unit: _unit(GameUnitType.warrior), tile: hill)
            .value,
        1,
      );
      expect(
        resolver
            .costToEnter(unit: _unit(GameUnitType.reconPlane), tile: hill)
            .value,
        2,
      );
      expect(
        resolver
            .costToEnter(unit: _unit(GameUnitType.warrior), tile: mountain)
            .blocked,
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
