import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('StrategicResourceDiscoveryRules', () {
    test('summarizes newly revealed strategic resources', () {
      const state = PersistentGameState(
        cities: [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Krakow',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Roma',
            center: CityHex(col: 6, row: 0),
          ),
        ],
      );

      final discoveries =
          StrategicResourceDiscoveryRules.discoveriesForTechnology(
            playerId: 'player_1',
            technologyId: TechnologyId.combustion,
            state: state,
            mapData: _map(),
          );

      expect(discoveries, hasLength(1));
      final discovery = discoveries.single;
      expect(discovery.resourceType, ResourceType.oil);
      expect(discovery.controlledCount, 1);
      expect(discovery.rivalControlledCount, 1);
      expect(discovery.unclaimedCount, 1);
      expect(
        discovery.toEvent().pressure,
        StrategicResourceDiscoveryPressure.expansionRace,
      );
      expect(discovery.nearestUnclaimedHex, const CityHex(col: 4, row: 0));
    });

    test('creates discovery events for map sources only', () {
      final events = StrategicResourceDiscoveryRules.eventsForTechnology(
        playerId: 'player_1',
        technologyId: TechnologyId.flight,
        state: const PersistentGameState(),
        mapData: _map(),
      );

      expect(events, isEmpty);
    });

    test('classifies discovery pressure from revealed source control', () {
      expect(
        StrategicResourceDiscoveryPressure.fromCounts(
          controlledCount: 1,
          rivalControlledCount: 0,
          unclaimedCount: 0,
        ),
        StrategicResourceDiscoveryPressure.securedSupply,
      );
      expect(
        StrategicResourceDiscoveryPressure.fromCounts(
          controlledCount: 1,
          rivalControlledCount: 1,
          unclaimedCount: 0,
        ),
        StrategicResourceDiscoveryPressure.contestedSupply,
      );
      expect(
        StrategicResourceDiscoveryPressure.fromCounts(
          controlledCount: 0,
          rivalControlledCount: 2,
          unclaimedCount: 0,
        ),
        StrategicResourceDiscoveryPressure.rivalMonopoly,
      );
    });
  });
}

MapData _map() {
  return MapData(
    cols: 7,
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
        resources: [ResourceType.oil],
        height: 0,
      ),
      TileData(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 3,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 4,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [ResourceType.oil],
        height: 0,
      ),
      TileData(
        col: 5,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 6,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [ResourceType.oil],
        height: 0,
      ),
    ],
  );
}
