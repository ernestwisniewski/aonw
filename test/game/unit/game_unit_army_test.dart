import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameUnit army', () {
    test('defaults to empty army', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
      expect(unit.army, isEmpty);
    });

    test('round-trips army through JSON', () {
      const army = [
        ArmyTroop(type: TroopType.warrior, count: 20),
        ArmyTroop(type: TroopType.archer, count: 5),
        ArmyTroop(type: TroopType.settler, count: 1),
      ];
      final unit = GameUnit(
        id: 'commander_p1',
        ownerPlayerId: 'p1',
        type: GameUnitType.commander,
        name: GameUnitType.commander.defaultNameToken,
        col: 0,
        row: 0,
        army: army,
      );
      final back = GameUnit.fromJson(unit.toJson());
      expect(back.army.length, 3);
      expect(back.army[0].type, TroopType.warrior);
      expect(back.army[0].count, 20);
      expect(back.army[1].type, TroopType.archer);
      expect(back.army[1].count, 5);
      expect(back.army[2].type, TroopType.settler);
      expect(back.army[2].count, 1);
    });

    test('copyWith preserves army when not overridden', () {
      const army = [ArmyTroop(type: TroopType.warrior, count: 10)];
      final unit = GameUnit(
        id: 'commander_p1',
        ownerPlayerId: 'p1',
        type: GameUnitType.commander,
        name: GameUnitType.commander.defaultNameToken,
        col: 0,
        row: 0,
        army: army,
      );
      final moved = unit.copyWith(col: 1);
      expect(moved.army, army);
    });

    test('round-trips fortified posture through JSON', () {
      final unit = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
      ).copyWith(posture: UnitPosture.fortified);

      final restored = GameUnit.fromJson(unit.toJson());

      expect(restored.posture, UnitPosture.fortified);
      expect(restored.isFortified, isTrue);
    });

    test('detachTroop removes one troop from the commander army', () {
      final unit = GameUnit.startingCommander(
        ownerPlayerId: 'p1',
        army: const [
          ArmyTroop(type: TroopType.warrior, count: 2),
          ArmyTroop(type: TroopType.settler, count: 1),
        ],
      );

      final updated = unit.detachTroop(TroopType.warrior);

      expect(updated.troopCount(TroopType.warrior), 1);
      expect(updated.troopCount(TroopType.settler), 1);
    });
  });
}
