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

      final MapTileSource source = map;

      expect(source.tileAt(0, 0)?.primaryTerrain, TerrainType.plains);
      expect(source.tileAt(1, 0)?.primaryTerrain, TerrainType.ocean);
      expect(source.tileAt(2, 0), isNull);
    });

    test('exposes MapData metadata and terrain survey without copies', () {
      final terrains = <TerrainType>[TerrainType.plains, TerrainType.river];
      final map = MapData(
        cols: 3,
        rows: 2,
        mapName: 'survey',
        tiles: [
          TileData(
            col: 2,
            row: 1,
            terrains: terrains,
            resources: const [],
            height: 1,
          ),
        ],
      );
      final MapReadView view = map;
      final terrainSurvey = view.tileTerrains;
      final tileViews = view.tileViews;

      expect(view.mapName, 'survey');
      expect(view.cols, 3);
      expect(view.rows, 2);
      expect(view.tileCount, 1);
      expect(identical(view.mapTiles, map), isTrue);
      expect(identical(view.objectives, map.objectives), isTrue);
      expect(identical(tileViews.first, map.tiles.first), isTrue);
      expect(identical(terrainSurvey.single, terrains), isTrue);
      expect(terrainSurvey.map((entry) => entry.toList()).toList(), [
        [TerrainType.plains, TerrainType.river],
      ]);
      expect(terrainSurvey.map((entry) => entry.toList()).toList(), [
        [TerrainType.plains, TerrainType.river],
      ]);
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
