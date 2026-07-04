import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class CombatDistance {
  static int betweenUnits(GameUnit attacker, GameUnit defender) {
    return fromUnitToCoordinate(
      attacker,
      HexCoordinate(col: defender.col, row: defender.row),
    );
  }

  static int fromUnitToHex(GameUnit unit, CityHex hex) {
    return fromUnitToCoordinate(unit, hex.toCoordinate());
  }

  static int fromUnitToCoordinate(GameUnit unit, HexCoordinate target) {
    return HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      target,
    );
  }
}
