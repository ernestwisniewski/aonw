import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('IntendedAttack', () {
    test('round-trips JSON', () {
      const attack = IntendedAttack(
        attackerUnitId: 'warrior_1',
        defenderCol: 4,
        defenderRow: 5,
        declaredAtTick: 7,
        declaringPlayerId: 'player_1',
      );

      final restored = IntendedAttack.fromJson(attack.toJson());

      expect(restored, attack);
      expect(restored.toJson(), {
        'attackerUnitId': 'warrior_1',
        'defenderCol': 4,
        'defenderRow': 5,
        'declaredAtTick': 7,
        'declaringPlayerId': 'player_1',
      });
    });

    test('round-trips non-default city conquest action', () {
      const attack = IntendedAttack(
        attackerUnitId: 'warrior_1',
        defenderCol: 4,
        defenderRow: 5,
        declaredAtTick: 7,
        declaringPlayerId: 'player_1',
        cityConquestAction: CityConquestAction.destroy,
      );

      final restored = IntendedAttack.fromJson(attack.toJson());

      expect(restored, attack);
      expect(restored.toJson(), {
        'attackerUnitId': 'warrior_1',
        'defenderCol': 4,
        'defenderRow': 5,
        'declaredAtTick': 7,
        'declaringPlayerId': 'player_1',
        'cityConquestAction': 'destroy',
      });
    });

    test('rejects malformed JSON', () {
      expect(
        () => IntendedAttack.fromJson({
          'attackerUnitId': '',
          'defenderCol': 4,
          'defenderRow': 5,
          'declaredAtTick': 7,
          'declaringPlayerId': 'player_1',
        }),
        throwsArgumentError,
      );
    });
  });
}
