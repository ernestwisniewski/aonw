import 'package:aonw_core/game/domain/movement.dart';
import 'package:test/test.dart';

void main() {
  group('UnitMovementPlan', () {
    test('estimates turns from movement remaining in the current turn', () {
      final plan = _plan(
        availableMovementPoints: 1,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 3),
        ],
      );

      expect(plan.estimatedTurns(3), 2);
    });

    test('does not spend current movement across an unaffordable step', () {
      final plan = _plan(
        availableMovementPoints: 2,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 3),
          UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 5),
        ],
      );

      expect(plan.estimatedTurns(3), 3);
    });

    test('counts a costly first step as the current turn when allowed', () {
      final plan = _plan(
        availableMovementPoints: 2,
        canSpendTurnEnteringFirstStep: true,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 4, cumulativeCost: 4),
        ],
      );

      expect(plan.canMoveNow, isTrue);
      expect(plan.estimatedTurns(3), 1);
    });

    test('rebases a persisted route at its current step', () {
      final plan = _plan(
        availableMovementPoints: 3,
        canSpendTurnEnteringFirstStep: true,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 3),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 4),
        ],
      );

      final remaining = plan.remainingFromStepIndex(1);

      expect(remaining.path, const [
        (col: 1, row: 0),
        (col: 2, row: 0),
        (col: 3, row: 0),
      ]);
      expect(remaining.steps.map((step) => step.cumulativeCost), const [
        0,
        2,
        3,
      ]);
      expect(remaining.totalCost, 3);
      expect(remaining.canMoveNow, isTrue);
      expect(remaining.estimatedTurns(3), 1);
    });
  });
}

UnitMovementPlan _plan({
  required int availableMovementPoints,
  required List<UnitMovementStep> steps,
  bool canSpendTurnEnteringFirstStep = false,
}) {
  final target = steps.last;
  return UnitMovementPlan(
    unitId: 'unit_1',
    targetCol: target.col,
    targetRow: target.row,
    totalCost: target.cumulativeCost,
    availableMovementPoints: availableMovementPoints,
    canSpendTurnEnteringFirstStep: canSpendTurnEnteringFirstStep,
    steps: steps,
  );
}
