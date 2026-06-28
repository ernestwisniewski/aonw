import 'package:aonw_core/game/domain/hex.dart';

class UnitMovementStep {
  final int col;
  final int row;
  final int enterCost;
  final int cumulativeCost;

  const UnitMovementStep({
    required this.col,
    required this.row,
    required this.enterCost,
    required this.cumulativeCost,
  });

  ({int col, int row}) get coord => (col: col, row: row);

  HexCoordinate get hex => HexCoordinate(col: col, row: row);

  @override
  bool operator ==(Object other) {
    return other is UnitMovementStep &&
        other.col == col &&
        other.row == row &&
        other.enterCost == enterCost &&
        other.cumulativeCost == cumulativeCost;
  }

  @override
  int get hashCode => Object.hash(col, row, enterCost, cumulativeCost);
}

class UnitMovementPlan {
  final String unitId;
  final int targetCol;
  final int targetRow;
  final int totalCost;
  final int availableMovementPoints;
  final int remainingAfterMove;
  final bool canMoveNow;
  final bool canSpendTurnEnteringFirstStep;
  final List<UnitMovementStep> steps;

  UnitMovementPlan({
    required this.unitId,
    required this.targetCol,
    required this.targetRow,
    required this.totalCost,
    required this.availableMovementPoints,
    this.canSpendTurnEnteringFirstStep = false,
    required List<UnitMovementStep> steps,
  }) : remainingAfterMove = _remainingAfterCost(
         availableMovementPoints,
         totalCost,
       ),
       canMoveNow = _canReachTarget(
         availableMovementPoints,
         steps,
         canSpendTurnEnteringFirstStep,
       ),
       steps = List.unmodifiable(steps);

  List<({int col, int row})> get path {
    return [for (final step in steps) step.coord];
  }

  List<UnitMovementStep> get reachableSteps {
    return [
      for (final step in steps)
        if (canReachStepThisTurn(step)) step,
    ];
  }

  Set<HexCoordinate> get reservedHexes {
    return {for (final step in reachableSteps.skip(1)) step.hex};
  }

  UnitMovementStep? get furthestReachableStep {
    final reachable = reachableSteps;
    if (reachable.isEmpty) return null;
    return reachable.last;
  }

  bool isStepUnreachableThisTurn(int col, int row) {
    return steps.any(
      (step) =>
          step.col == col && step.row == row && !canReachStepThisTurn(step),
    );
  }

  bool canReachStepThisTurn(UnitMovementStep step) {
    if (step.cumulativeCost <= availableMovementPoints) return true;
    return canSpendTurnEnteringFirstStep &&
        _isFirstTravelStep(step) &&
        availableMovementPoints > 0;
  }

  int remainingMovementPointsAfterStep(UnitMovementStep step) {
    return _remainingAfterCost(availableMovementPoints, step.cumulativeCost);
  }

  bool _isFirstTravelStep(UnitMovementStep step) {
    return steps.length > 1 && step == steps[1];
  }

  static bool _canReachTarget(
    int availableMovementPoints,
    List<UnitMovementStep> steps,
    bool canSpendTurnEnteringFirstStep,
  ) {
    if (steps.isEmpty) return false;
    final target = steps.last;
    if (target.cumulativeCost <= availableMovementPoints) return true;
    return canSpendTurnEnteringFirstStep &&
        steps.length == 2 &&
        availableMovementPoints > 0;
  }

  static int _remainingAfterCost(int availableMovementPoints, int cost) {
    final remaining = availableMovementPoints - cost;
    return remaining < 0 ? 0 : remaining;
  }
}
