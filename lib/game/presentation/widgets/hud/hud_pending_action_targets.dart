import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/runtime.dart';

abstract final class HudPendingActionTargets {
  static String? attackUnitId(GameState? state) {
    return switch (state?.pendingAction) {
      PendingAttackTargeting(:final attackerUnitId) => attackerUnitId,
      _ => state?.selectedUnit?.id,
    };
  }

  static String? workerUnitId(GameState? state) {
    return switch (state?.pendingAction) {
      PendingWorkerActionSelection(:final unitId) => unitId,
      _ => state?.selectedUnit?.id,
    };
  }

  static String? merchantUnitId(GameState? state) {
    return switch (state?.pendingAction) {
      PendingMerchantTradeRouteSelection(:final unitId) => unitId,
      PendingMerchantMoveToCitySelection(:final unitId) => unitId,
      _ => state?.selectedUnit?.id,
    };
  }

  static String? cityWorkedHexCityId(GameState? state) {
    return switch (state?.pendingAction) {
      PendingCityWorkedHexSelection(:final cityId) => cityId,
      _ => state?.selection?.city?.id,
    };
  }

  static String? cityExpansionCityId(GameState? state) {
    return switch (state?.pendingAction) {
      PendingCityExpansionSelection(:final cityId) => cityId,
      _ => state?.selection?.city?.id,
    };
  }
}
