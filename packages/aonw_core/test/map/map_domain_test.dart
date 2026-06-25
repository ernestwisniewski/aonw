import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('shared map domain', () {
    test('exposes terrain and resource parsers', () {
      expect(TerrainType.fromString('forest'), TerrainType.forest);
      expect(TerrainType.fromString('wetlands'), TerrainType.wetlands);
      expect(TerrainType.fromString('lake'), TerrainType.lake);
      expect(ResourceType.fromString('iron'), ResourceType.iron);
    });

    test('looks up tiles and preserves primary terrain fallback', () {
      final map = MapData(
        cols: 2,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [ResourceType.wheat],
            height: 1,
          ),
          TileData(col: 1, row: 0, terrains: [], resources: [], height: 0),
        ],
      );

      expect(map.tileAt(0, 0)?.primaryTerrain, TerrainType.plains);
      expect(map.tileAt(1, 0)?.primaryTerrain, TerrainType.ocean);
      expect(map.tileAt(2, 0), isNull);
    });

    test('uses odd-q hex topology', () {
      expect(
        HexGridTopology.neighbors(col: 0, row: 0),
        contains((col: 1, row: -1)),
      );
      expect(
        HexGridTopology.neighbors(col: 1, row: 0),
        contains((col: 2, row: 1)),
      );
    });
  });
}
