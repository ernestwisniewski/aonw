import 'package:aonw_core/game/domain/combat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatStats', () {
    test('applies typed modifiers to matching stat targets', () {
      const base = CombatStats(
        attack: 4,
        defense: 2,
        hp: 10,
        range: 1,
        mobility: 1,
      );

      final effective = base.applyAll(const [
        TerrainModifier(
          label: 'terrain.forest',
          target: CombatStatTarget.defense,
          delta: 2,
        ),
        TechnologyModifier(
          label: 'tech.strategy',
          target: CombatStatTarget.attack,
          delta: 1,
        ),
        FortificationModifier(
          label: 'city.walls',
          target: CombatStatTarget.hp,
          delta: 3,
        ),
      ]);

      expect(
        effective,
        const CombatStats(attack: 5, defense: 4, hp: 13, range: 1, mobility: 1),
      );
    });

    test('multiplies additive troop stats while preserving range', () {
      const troopStats = CombatStats(
        attack: 2,
        defense: 1,
        hp: 3,
        range: 2,
        mobility: 1,
      );

      expect(
        troopStats.multiply(4),
        const CombatStats(attack: 8, defense: 4, hp: 12, range: 2, mobility: 4),
      );
    });
  });
}
