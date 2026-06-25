import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/persistence/map_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapLoader.toJson round-trip', () {
    test('serializes and re-parses to identical MapData', () {
      final original = MapData(
        cols: 3,
        rows: 2,
        tiles: [
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
          const TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [ResourceType.iron],
            height: 2,
          ),
          const TileData(
            col: 2,
            row: 0,
            terrains: [TerrainType.mountain],
            resources: [],
            height: 5,
          ),
          const TileData(
            col: 0,
            row: 1,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 1,
          ),
          const TileData(
            col: 1,
            row: 1,
            terrains: [TerrainType.desert],
            resources: [],
            height: 3,
          ),
          const TileData(
            col: 2,
            row: 1,
            terrains: [TerrainType.snow],
            resources: [],
            height: 4,
          ),
        ],
      );

      final jsonString = MapLoader.toJson(original);
      final parsed = MapLoader.fromJson(jsonString);

      expect(parsed.cols, original.cols);
      expect(parsed.rows, original.rows);
      expect(parsed.tiles.length, original.tiles.length);

      for (int i = 0; i < original.tiles.length; i++) {
        expect(parsed.tiles[i].col, original.tiles[i].col);
        expect(parsed.tiles[i].row, original.tiles[i].row);
        expect(parsed.tiles[i].terrains, original.tiles[i].terrains);
        expect(parsed.tiles[i].resources, original.tiles[i].resources);
        expect(parsed.tiles[i].height, original.tiles[i].height);
      }
    });
  });
}
