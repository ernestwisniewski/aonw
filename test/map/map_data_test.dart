import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (int row = 0; row < 3; row++)
      for (int col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);

void main() {
  group('MapData.tileAt', () {
    test('returns the tile at the given coordinates', () {
      final map = _map();

      final tile = map.tileAt(1, 2);

      expect(tile?.col, 1);
      expect(tile?.row, 2);
    });

    test('returns null when coordinates are out of bounds', () {
      final map = _map();

      expect(map.tileAt(5, 0), isNull);
      expect(map.tileAt(0, 5), isNull);
      expect(map.tileAt(-1, 0), isNull);
    });
  });
}
