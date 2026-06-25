import 'package:aonw_core/game/domain/unit.dart';

abstract final class AiUnitRoles {
  static bool isMilitaryUnit(GameUnit unit) => isMilitaryType(unit.type);

  static bool isMilitaryType(GameUnitType type) {
    return switch (type) {
      GameUnitType.commander ||
      GameUnitType.warrior ||
      GameUnitType.archer ||
      GameUnitType.scout ||
      GameUnitType.spearman ||
      GameUnitType.cavalry ||
      GameUnitType.catapult ||
      GameUnitType.heavyInfantry ||
      GameUnitType.fieldCannon ||
      GameUnitType.rifleman ||
      GameUnitType.tank ||
      GameUnitType.scoutShip ||
      GameUnitType.warship ||
      GameUnitType.reconPlane => true,
      GameUnitType.settler ||
      GameUnitType.worker ||
      GameUnitType.merchant => false,
    };
  }

  static bool isReconUnit(GameUnit unit) => isReconType(unit.type);

  static bool isReconType(GameUnitType type) {
    return switch (type) {
      GameUnitType.scout ||
      GameUnitType.scoutShip ||
      GameUnitType.reconPlane => true,
      _ => false,
    };
  }
}
