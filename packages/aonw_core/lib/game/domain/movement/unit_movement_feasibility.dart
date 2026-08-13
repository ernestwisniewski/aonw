import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

typedef UnitMovementCapacityException = bool Function(UnitMovementStep step);

abstract final class UnitMovementFeasibility {
  static bool canTraverseStep({
    required GameUnit unit,
    required UnitMovementStep step,
    UnitMovementCapacityException? canEnterStepBeyondCapacity,
  }) {
    final maxMovement = UnitMovementBalance.maxMovementUnitsFor(
      type: unit.type,
      carriedArtifactId: unit.carriedArtifactId,
    );
    if (step.enterCost <= maxMovement) return true;
    // Carrying an artifact lowers movement speed, but it must not turn
    // otherwise passable rough terrain into a permanent wall. The movement
    // plan spends the carrier's whole turn on such a step.
    if (unit.isCarryingArtifact) return true;
    return canEnterStepBeyondCapacity?.call(step) ?? false;
  }

  static UnitMovementStep? firstStepBeyondPerTurnCapacity({
    required GameUnit unit,
    required UnitMovementPlan plan,
    UnitMovementCapacityException? canEnterStepBeyondCapacity,
  }) {
    for (final step in plan.steps.skip(1)) {
      if (canTraverseStep(
        unit: unit,
        step: step,
        canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
      )) {
        continue;
      }
      return step;
    }
    return null;
  }

  static bool canEventuallyTraverse({
    required GameUnit unit,
    required UnitMovementPlan plan,
    UnitMovementCapacityException? canEnterStepBeyondCapacity,
  }) {
    return firstStepBeyondPerTurnCapacity(
          unit: unit,
          plan: plan,
          canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
        ) ==
        null;
  }
}
