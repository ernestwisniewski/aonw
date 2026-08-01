part of 'turn_reducer.dart';

bool _needsManualUnitAction(GameUnit unit, String playerId) =>
    UnitTurnActionRules.needsManualOrder(unit, playerId: playerId);

_UnitActionCategory _unitActionCategory(GameUnit unit) {
  if (UnitCombatStats.derive(unit).attack > 0) {
    return _UnitActionCategory.combat;
  }
  if (unit.type == GameUnitType.worker || unit.type == GameUnitType.settler) {
    return _UnitActionCategory.worker;
  }
  return _UnitActionCategory.other;
}
