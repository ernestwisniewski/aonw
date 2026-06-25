import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HexCoordinate', () {
    test('round-trips through JSON', () {
      const hex = HexCoordinate(col: 2, row: 3);

      expect(HexCoordinate.fromJson(hex.toJson()), hex);
    });
  });

  group('HexDistance', () {
    test('returns one for odd-q neighboring coordinates', () {
      const center = HexCoordinate(col: 1, row: 1);

      expect(
        HexDistance.between(center, const HexCoordinate(col: 2, row: 1)),
        1,
      );
      expect(
        HexDistance.between(center, const HexCoordinate(col: 2, row: 2)),
        1,
      );
    });
  });

  group('HexNeighbors', () {
    test('filters neighbors to existing map tiles', () {
      final map = MapData(
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
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
        ],
      );

      expect(
        HexNeighbors.existingAround(const HexCoordinate(col: 0, row: 0), map),
        [const HexCoordinate(col: 1, row: 0)],
      );
    });
  });
}
