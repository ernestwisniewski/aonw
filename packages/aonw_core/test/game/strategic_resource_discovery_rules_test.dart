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

    test(
      'matches a reordered WorldMap view and resolves nearest ties stably',
      () {
        const state = PersistentGameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Krakow',
              center: CityHex(col: 3, row: 2),
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Roma',
              center: CityHex(col: 6, row: 2),
            ),
          ],
        );
        final mapData = MapData(
          cols: 8,
          rows: 5,
          tiles: const [
            TileData(
              col: 3,
              row: 2,
              terrains: [TerrainType.plains],
              resources: [ResourceType.oil, ResourceType.wheat],
              height: 0,
            ),
            TileData(
              col: 2,
              row: 2,
              terrains: [TerrainType.plains],
              resources: [ResourceType.oil],
              height: 0,
            ),
            TileData(
              col: 4,
              row: 2,
              terrains: [TerrainType.plains],
              resources: [ResourceType.oil],
              height: 0,
            ),
            TileData(
              col: 6,
              row: 2,
              terrains: [TerrainType.plains],
              resources: [ResourceType.oil],
              height: 0,
            ),
            TileData(
              col: 0,
              row: 4,
              terrains: [TerrainType.hills],
              resources: [ResourceType.coal],
              height: 2,
            ),
          ],
        );
        final worldMap = _worldMapFromDataInReverse(mapData);

        final legacy = StrategicResourceDiscoveryRules.discoveriesForTechnology(
          playerId: 'player_1',
          technologyId: TechnologyId.combustion,
          state: state,
          mapData: mapData,
        );
        final canonical =
            StrategicResourceDiscoveryRules.discoveriesForTechnology(
              playerId: 'player_1',
              technologyId: TechnologyId.combustion,
              state: state,
              mapData: LegacyWorldMapAdapter.asReadView(worldMap),
            );

        expect(_discoveryShape(canonical), _discoveryShape(legacy));
        expect(canonical, hasLength(1));
        expect(canonical.single.controlledCount, 1);
        expect(canonical.single.rivalControlledCount, 1);
        expect(canonical.single.unclaimedCount, 2);
        expect(
          canonical.single.nearestUnclaimedHex,
          const CityHex(col: 2, row: 2),
        );
      },
    );

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

List<Map<String, Object?>> _discoveryShape(
  Iterable<StrategicResourceDiscovery> discoveries,
) {
  return [
    for (final discovery in discoveries)
      {
        'playerId': discovery.playerId,
        'resourceType': discovery.resourceType,
        'controlledCount': discovery.controlledCount,
        'rivalControlledCount': discovery.rivalControlledCount,
        'unclaimedCount': discovery.unclaimedCount,
        'nearestUnclaimedHex': discovery.nearestUnclaimedHex,
      },
  ];
}

WorldMap _worldMapFromDataInReverse(MapData mapData) {
  return WorldMap(
    cols: mapData.cols,
    rows: mapData.rows,
    tiles: [
      for (final tile in mapData.tiles.reversed)
        WorldTile(
          coordinate: HexCoord(col: tile.col, row: tile.row),
          terrains: tile.terrains,
          resources: tile.resources,
          height: tile.height,
        ),
    ],
  );
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
