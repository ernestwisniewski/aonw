import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/runtime.dart';

abstract final class HudPendingActionTargets {
  static String? attackUnitId(GameClientState? state) {
    return switch (state?.pendingAction) {
      PendingAttackTargeting(:final attackerUnitId) => attackerUnitId,
      _ => state?.selectedUnit?.id,
    };
  }

  static String? workerUnitId(GameClientState? state) {
    return switch (state?.pendingAction) {
      PendingWorkerActionSelection(:final unitId) => unitId,
      _ => state?.selectedUnit?.id,
    };
  }

  static String? merchantUnitId(GameClientState? state) {
    return switch (state?.pendingAction) {
      PendingMerchantTradeRouteSelection(:final unitId) => unitId,
      PendingMerchantMoveToCitySelection(:final unitId) => unitId,
      _ => state?.selectedUnit?.id,
    };
  }

  static String? cityWorkedHexCityId(GameClientState? state) {
    return switch (state?.pendingAction) {
      PendingCityWorkedHexSelection(:final cityId) => cityId,
      _ => state?.selection?.city?.id,
    };
  }

  static String? cityExpansionCityId(GameClientState? state) {
    return switch (state?.pendingAction) {
      PendingCityExpansionSelection(:final cityId) => cityId,
      _ => state?.selection?.city?.id,
    };
  }
}
