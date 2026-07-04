import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:test/test.dart';

void main() {
  group('CombatDistance', () {
    test('measures distance from a unit to another unit', () {
      final attacker = _unit(id: 'attacker', col: 1, row: 1);
      final defender = _unit(id: 'defender', col: 3, row: 2);

      expect(
        CombatDistance.betweenUnits(attacker, defender),
        HexDistance.between(
          const HexCoordinate(col: 1, row: 1),
          const HexCoordinate(col: 3, row: 2),
        ),
      );
    });

    test('measures distance from a unit to city hexes and coordinates', () {
      final unit = _unit(id: 'unit', col: 2, row: 3);
      const target = HexCoordinate(col: 4, row: 4);
      final cityHex = CityHex.fromCoordinate(target);

      expect(
        CombatDistance.fromUnitToHex(unit, cityHex),
        CombatDistance.fromUnitToCoordinate(unit, target),
      );
    });
  });
}

GameUnit _unit({required String id, required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: id,
    col: col,
    row: row,
  );
}
