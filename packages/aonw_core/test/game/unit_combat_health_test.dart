import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('UnitCombatHealth.storedHp', () {
    const stats = CombatStats(
      attack: 4,
      defense: 3,
      hp: 10,
      range: 1,
      mobility: 1,
    );

    test('uses null as the canonical full-health representation', () {
      expect(UnitCombatHealth.storedHp(10, effectiveStats: stats), isNull);
      expect(UnitCombatHealth.storedHp(14, effectiveStats: stats), isNull);
    });

    test('persists clamped damage and zero health explicitly', () {
      expect(UnitCombatHealth.storedHp(7, effectiveStats: stats), 7);
      expect(UnitCombatHealth.storedHp(-2, effectiveStats: stats), 0);
    });

    test('normalizes against a known maximum without rebuilding stats', () {
      expect(UnitCombatHealth.storedHpForMax(10, maxHp: 10), isNull);
      expect(UnitCombatHealth.storedHpForMax(8, maxHp: 10), 8);
      expect(UnitCombatHealth.storedHpForMax(0, maxHp: 0), isNull);
    });
  });
}
