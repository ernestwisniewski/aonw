import 'package:aonw_core/game/domain/unit.dart';

abstract final class AiUnitRoles {
  static bool isMilitaryUnit(GameUnit unit) => isMilitaryType(unit.type);

  static bool isMilitaryType(GameUnitType type) {
    return UnitCatalog.isMilitaryType(type);
  }

  static bool isReconUnit(GameUnit unit) => isReconType(unit.type);

  static bool isReconType(GameUnitType type) {
    return UnitCatalog.isReconType(type);
  }
}
