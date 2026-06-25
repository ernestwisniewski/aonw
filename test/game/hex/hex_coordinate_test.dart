import 'package:aonw_core/game/domain/hex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexCoordinate', () {
    test('round-trips through JSON', () {
      const hex = HexCoordinate(col: 2, row: 3);

      expect(HexCoordinate.fromJson(hex.toJson()), hex);
    });

    test('fromJson requires coordinates', () {
      expect(
        () => HexCoordinate.fromJson({'col': 2}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
