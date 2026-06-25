import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

abstract final class UnitMovementFeasibility {
  static UnitMovementStep? firstStepBeyondPerTurnCapacity({
    required GameUnit unit,
    required UnitMovementPlan plan,
    bool Function(UnitMovementStep step)? canEnterStepBeyondCapacity,
  }) {
    final maxMovement = UnitMovementBalance.maxMovementPointsFor(
      type: unit.type,
      carriedArtifactId: unit.carriedArtifactId,
    );
    for (final step in plan.steps.skip(1)) {
      if (step.enterCost <= maxMovement) continue;
      if (canEnterStepBeyondCapacity?.call(step) ?? false) continue;
      return step;
    }
    return null;
  }

  static bool canEventuallyTraverse({
    required GameUnit unit,
    required UnitMovementPlan plan,
    bool Function(UnitMovementStep step)? canEnterStepBeyondCapacity,
  }) {
    return firstStepBeyondPerTurnCapacity(
          unit: unit,
          plan: plan,
          canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
        ) ==
        null;
  }
}
