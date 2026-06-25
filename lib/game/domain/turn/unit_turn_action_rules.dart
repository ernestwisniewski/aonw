import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitTurnActionRules {
  static bool hasStandingOrders(GameUnit unit) {
    return unit.queuedPath != null || unit.merchantTradeRoute != null;
  }

  static bool needsManualOrder(GameUnit unit, {required String playerId}) {
    if (unit.ownerPlayerId != playerId) return false;
    if (unit.isWorking) return false;
    if (unit.isAutoExploring) return false;
    if (unit.movementPoints <= 0) return false;
    if (hasStandingOrders(unit)) return false;
    return true;
  }
}
