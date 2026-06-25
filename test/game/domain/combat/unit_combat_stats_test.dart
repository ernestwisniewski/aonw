import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitCombatStats', () {
    test('uses base ruleset stats for standalone combat units', () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 1,
      );

      expect(
        UnitCombatStats.derive(warrior),
        CombatRuleset.standard.baseStatsFor(GameUnitType.warrior),
      );
    });

    test('keeps worker and settler non-damaging by default', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 1,
      );
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 1,
      );

      expect(UnitCombatStats.derive(worker).attack, 0);
      expect(UnitCombatStats.derive(settler).attack, 0);
      expect(UnitCombatStats.derive(worker).hp, 1);
      expect(UnitCombatStats.derive(settler).hp, 1);
    });

    test(
      'derives commander stats from base commander plus army composition',
      () {
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          army: const [
            ArmyTroop(type: TroopType.warrior, count: 2),
            ArmyTroop(type: TroopType.archer, count: 1),
          ],
        );

        expect(
          UnitCombatStats.derive(commander),
          const CombatStats(
            attack: 7,
            defense: 6,
            hp: 16,
            range: 1,
            mobility: 2,
          ),
        );
      },
    );
  });
}
