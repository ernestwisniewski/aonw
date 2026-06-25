import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArmyTroop', () {
    test('round-trips through JSON', () {
      const troop = ArmyTroop(type: TroopType.warrior, count: 20);
      final json = troop.toJson();
      final back = ArmyTroop.fromJson(json);
      expect(back.type, TroopType.warrior);
      expect(back.count, 20);
    });

    test('serializes all TroopType values', () {
      for (final type in TroopType.values) {
        final troop = ArmyTroop(type: type, count: 1);
        final back = ArmyTroop.fromJson(troop.toJson());
        expect(back.type, type);
      }
    });

    test('fromJson rejects unknown troop type', () {
      expect(
        () => ArmyTroop.fromJson({'type': 'scout', 'count': 1}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson requires count', () {
      expect(
        () => ArmyTroop.fromJson({'type': TroopType.warrior.name}),
        throwsA(isA<TypeError>()),
      );
    });

    test('two troops with same type and count are equal', () {
      const a = ArmyTroop(type: TroopType.warrior, count: 20);
      const b = ArmyTroop(type: TroopType.warrior, count: 20);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('troops with different count are not equal', () {
      const a = ArmyTroop(type: TroopType.warrior, count: 20);
      const b = ArmyTroop(type: TroopType.warrior, count: 10);
      expect(a, isNot(equals(b)));
    });
  });
}
