import 'package:aonw/game/domain/city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityTerritoryRules', () {
    test('accepts territory connected through the city center', () {
      expect(
        CityTerritoryRules.isConnected(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 4, row: 2),
          ],
        ),
        isTrue,
      );
    });

    test('rejects controlled hex islands inside the city radius', () {
      expect(
        CityTerritoryRules.isConnected(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 4, row: 2),
            CityHex(col: 0, row: 2),
          ],
        ),
        isFalse,
      );
    });

    test('distance returns maxDistance plus one when target is too far', () {
      expect(
        CityTerritoryRules.distance(
          from: const CityHex(col: 2, row: 2),
          to: const CityHex(col: 4, row: 4),
          maxDistance: 2,
        ),
        3,
      );
    });
  });
}
