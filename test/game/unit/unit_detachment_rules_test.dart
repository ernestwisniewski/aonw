import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitDetachmentRules', () {
    test('detaches one troop from a commander into a standalone unit', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 2,
        row: 3,
        army: const [
          ArmyTroop(type: TroopType.warrior, count: 2),
          ArmyTroop(type: TroopType.archer, count: 1),
        ],
      );

      final result = UnitDetachmentRules.detachTroop(
        source: commander,
        troopType: TroopType.warrior,
        detachedUnitId: 'commander_player_1_warrior_1',
        destinationCol: 3,
        destinationRow: 3,
      );

      expect(result, isNotNull);
      expect(result!.updatedSource.troopCount(TroopType.warrior), 1);
      expect(result.updatedSource.troopCount(TroopType.archer), 1);
      expect(result.detachedUnit.id, 'commander_player_1_warrior_1');
      expect(result.detachedUnit.type, GameUnitType.warrior);
      expect(result.detachedUnit.name, GameUnitType.warrior.defaultNameToken);
      expect(result.detachedUnit.col, 3);
      expect(result.detachedUnit.row, 3);
      expect(
        result.detachedUnit.movementPoints,
        UnitMovementBalance.maxMovementPointsForType(GameUnitType.warrior),
      );
    });

    test('gives a detached troop its own movement pool', () {
      final exhaustedCommander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        army: const [ArmyTroop(type: TroopType.archer, count: 1)],
      ).copyWith(movementPoints: 0);

      final result = UnitDetachmentRules.detachTroop(
        source: exhaustedCommander,
        troopType: TroopType.archer,
        detachedUnitId: 'commander_player_1_archer_1',
        destinationCol: 1,
        destinationRow: 0,
      );

      expect(result, isNotNull);
      expect(
        result!.detachedUnit.movementPoints,
        UnitMovementBalance.maxMovementPointsForType(GameUnitType.archer),
      );
    });

    test('rejects detaching from a unit that has no matching troop', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        army: const [ArmyTroop(type: TroopType.archer, count: 1)],
      );

      final result = UnitDetachmentRules.detachTroop(
        source: commander,
        troopType: TroopType.warrior,
        detachedUnitId: 'ignored',
        destinationCol: 1,
        destinationRow: 0,
      );

      expect(result, isNull);
    });
  });
}
