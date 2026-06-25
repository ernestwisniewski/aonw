import 'package:aonw_core/game/domain/combat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatOutcomeSerializer', () {
    test('round-trips outcome with steps and modifiers', () {
      final outcome = CombatOutcome(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        attackerHpAfter: 7,
        defenderHpAfter: 0,
        attackerKilled: false,
        defenderKilled: true,
        steps: [
          const ModifierAppliedStep(
            TerrainModifier(
              label: 'terrain.forest',
              target: CombatStatTarget.defense,
              delta: 2,
            ),
          ),
          AttackStep(
            damage: 6,
            active: const [
              TechnologyModifier(
                label: 'tech.strategy',
                target: CombatStatTarget.attack,
                delta: 1,
              ),
            ],
          ),
          const RollStep(seed: 42, value: -1),
        ],
      );

      final json = CombatOutcomeSerializer.toJson(outcome);
      final restored = CombatOutcomeSerializer.fromJson(json);

      expect(restored, outcome);
      expect(
        restored.steps.whereType<ModifierAppliedStep>().single.modifier,
        isA<TerrainModifier>(),
      );
      expect(
        restored.steps.whereType<AttackStep>().single.active.single,
        isA<TechnologyModifier>(),
      );
    });

    test('reports missing outcome fields with useful names', () {
      expect(
        () => CombatOutcomeSerializer.fromJson({'attackerUnitId': 'attacker'}),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'CombatOutcome.defenderUnitId',
          ),
        ),
      );
    });
  });
}
