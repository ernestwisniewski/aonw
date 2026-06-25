import 'package:aonw_core/game/domain/combat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatRng', () {
    test('produces the same sequence for the same turn and combatants', () {
      final a = CombatRng.fromTurn(
        turn: 7,
        attackerId: 'unit_a',
        defenderId: 'unit_b',
      );
      final b = CombatRng.fromTurn(
        turn: 7,
        attackerId: 'unit_a',
        defenderId: 'unit_b',
      );

      expect(
        [for (var i = 0; i < 8; i++) a.nextInt(1000)],
        [for (var i = 0; i < 8; i++) b.nextInt(1000)],
      );
    });

    test('changes the sequence when combatants change', () {
      final a = CombatRng.fromTurn(
        turn: 7,
        attackerId: 'unit_a',
        defenderId: 'unit_b',
      );
      final b = CombatRng.fromTurn(
        turn: 7,
        attackerId: 'unit_a',
        defenderId: 'unit_c',
      );

      expect([
        for (var i = 0; i < 8; i++) a.nextInt(1000),
      ], isNot([for (var i = 0; i < 8; i++) b.nextInt(1000)]));
    });

    test('signed roll stays within requested magnitude', () {
      final rng = CombatRng(123);

      for (var i = 0; i < 64; i++) {
        expect(rng.signed(2), inInclusiveRange(-2, 2));
      }
    });
  });
}
