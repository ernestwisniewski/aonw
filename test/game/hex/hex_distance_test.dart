import 'package:aonw_core/game/domain/hex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexDistance', () {
    test('returns zero for the same coordinate', () {
      const hex = HexCoordinate(col: 2, row: 3);

      expect(HexDistance.between(hex, hex), 0);
    });

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
      expect(
        HexDistance.between(center, const HexCoordinate(col: 0, row: 1)),
        1,
      );
    });
  });
}
