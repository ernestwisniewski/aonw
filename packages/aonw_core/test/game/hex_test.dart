import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/hex/legacy_hex_coord_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('HexCoord', () {
    test('is a const value and stable map key', () {
      final coordinate = _coordinate(2, 3);
      final equalCoordinate = _coordinate(2, 3);
      final values = <HexCoord, String>{coordinate: 'first'};
      values[equalCoordinate] = 'second';

      expect(coordinate, equalCoordinate);
      expect(coordinate, isNot(_coordinate(3, 3)));
      expect(coordinate, isNot(_coordinate(2, 4)));
      expect(values, {coordinate: 'second'});
      expect(coordinate.toString(), 'HexCoord(col: 2, row: 3)');
    });

    test('allows negative values for callers to validate in context', () {
      expect(const HexCoord(col: -1, row: -2).col, -1);
      expect(const HexCoord(col: -1, row: -2).row, -2);
    });

    test('converts at the named legacy boundary', () {
      const coordinate = HexCoord(col: 2, row: 3);

      expect(
        LegacyHexCoordAdapter.fromHexCoordinate(
          LegacyHexCoordAdapter.toHexCoordinate(coordinate),
        ),
        coordinate,
      );
      expect(
        LegacyHexCoordAdapter.fromCityHex(
          LegacyHexCoordAdapter.toCityHex(coordinate),
        ),
        coordinate,
      );
      expect(LegacyHexCoordAdapter.toHexCoordinate(coordinate).toJson(), {
        'col': 2,
        'row': 3,
      });
      expect(LegacyHexCoordAdapter.toCityHex(coordinate).toJson(), {
        'col': 2,
        'row': 3,
      });
    });
  });

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

HexCoord _coordinate(int col, int row) => HexCoord(col: col, row: row);
