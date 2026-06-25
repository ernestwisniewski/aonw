import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class QueuedMovementEffectBuilder {
  static List<AnimateUnitMoveEffect> fromUnitDelta({
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
  }) {
    final beforeById = {for (final unit in beforeUnits) unit.id: unit};
    final effects = <AnimateUnitMoveEffect>[];

    for (final after in afterUnits) {
      final before = beforeById[after.id];
      if (before == null) continue;
      if (before.col == after.col && before.row == after.row) continue;

      final steps = _stepsForMovedUnit(before: before, after: after);
      if (steps == null) continue;

      effects.add(
        AnimateUnitMoveEffect(
          unitId: before.id,
          fromCol: before.col,
          fromRow: before.row,
          steps: steps,
        ),
      );
    }

    return effects;
  }

  static List<UnitMovementStep>? _stepsForMovedUnit({
    required GameUnit before,
    required GameUnit after,
  }) {
    final pathSteps = _pathStepsFor(before);
    if (pathSteps == null) {
      return before.isAutoExploring || after.isAutoExploring
          ? [_destinationStep(after)]
          : null;
    }

    final startIndex = pathSteps.indexWhere(
      (step) => step.col == before.col && step.row == before.row,
    );
    final steps = <UnitMovementStep>[];
    if (startIndex < 0) {
      steps.add(_destinationStep(after));
    } else {
      final endIndex = pathSteps.indexWhere(
        (step) => step.col == after.col && step.row == after.row,
      );
      if (endIndex > startIndex) {
        steps.addAll(
          pathSteps.skip(startIndex + 1).take(endIndex - startIndex),
        );
      }
    }

    if (steps.isEmpty) {
      steps.add(_destinationStep(after));
    }
    return steps;
  }

  static List<UnitMovementStep>? _pathStepsFor(GameUnit unit) {
    final queuedPath = unit.queuedPath;
    if (queuedPath != null) return queuedPath.steps;
    if (unit.isMerchant) return unit.merchantTradeRoute?.steps;
    return null;
  }

  static UnitMovementStep _destinationStep(GameUnit unit) {
    return UnitMovementStep(
      col: unit.col,
      row: unit.row,
      enterCost: 0,
      cumulativeCost: 0,
    );
  }
}
