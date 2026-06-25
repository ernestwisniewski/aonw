import 'package:aonw/game/domain/city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityTerritoryBoundary', () {
    test('single city hex has all six outer edges', () {
      final edges = CityTerritoryBoundary.edgesFor(const [
        CityHex(col: 2, row: 2),
      ]);

      expect(edges, hasLength(6));
      expect(
        edges.map((edge) => edge.side).toSet(),
        CityHexEdge.values.toSet(),
      );
    });

    test('adjacent city hexes do not include their shared inner edge', () {
      const center = CityHex(col: 2, row: 2);
      const neighbor = CityHex(col: 3, row: 2);

      final edges = CityTerritoryBoundary.edgesFor(const [center, neighbor]);

      expect(edges, hasLength(10));
      expect(
        edges,
        isNot(
          contains(
            const CityTerritoryBoundaryEdge(
              hex: center,
              side: CityHexEdge.southEast,
            ),
          ),
        ),
      );
      expect(
        edges,
        isNot(
          contains(
            const CityTerritoryBoundaryEdge(
              hex: neighbor,
              side: CityHexEdge.northWest,
            ),
          ),
        ),
      );
    });
  });
}
