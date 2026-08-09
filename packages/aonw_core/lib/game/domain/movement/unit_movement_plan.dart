import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';

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
  final List<UnitMovementStep> steps;

  UnitMovementPlan({
    required this.unitId,
    required this.targetCol,
    required this.targetRow,
    required this.totalCost,
    required this.availableMovementPoints,
    required List<UnitMovementStep> steps,
  }) : remainingAfterMove = _remainingAfterCost(
         availableMovementPoints,
         totalCost,
       ),
       canMoveNow = _canReachTarget(availableMovementPoints, steps),
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
    return step.cumulativeCost - step.enterCost < availableMovementPoints;
  }

  int remainingMovementPointsAfterStep(UnitMovementStep step) {
    return _remainingAfterCost(availableMovementPoints, step.cumulativeCost);
  }

  /// Returns the untravelled suffix with costs rebased to the current step.
  ///
  /// The current [availableMovementPoints] are preserved, so callers restoring
  /// persisted routes must build this plan with the unit's current balance.
  UnitMovementPlan remainingFromStepIndex(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= steps.length) {
      throw RangeError.index(stepIndex, steps, 'stepIndex');
    }

    var cumulativeCost = 0;
    final remainingSteps = <UnitMovementStep>[];
    for (var index = stepIndex; index < steps.length; index++) {
      final step = steps[index];
      final enterCost = index == stepIndex ? 0 : step.enterCost;
      cumulativeCost += enterCost;
      remainingSteps.add(
        UnitMovementStep(
          col: step.col,
          row: step.row,
          enterCost: enterCost,
          cumulativeCost: cumulativeCost,
        ),
      );
    }

    return UnitMovementPlan(
      unitId: unitId,
      targetCol: targetCol,
      targetRow: targetRow,
      totalCost: cumulativeCost,
      availableMovementPoints: availableMovementPoints,
      steps: remainingSteps,
    );
  }

  /// Estimates calendar turns, including the partially spent current turn.
  int estimatedTurns(int maxMovementPointsPerTurn) {
    if (totalCost <= 0) return 0;

    final fullTurnMovement = maxMovementPointsPerTurn > 0
        ? maxMovementPointsPerTurn
        : 1;
    var turns = 1;
    var remainingMovement = availableMovementPoints;
    for (final step in steps.skip(1)) {
      if (step.enterCost <= remainingMovement) {
        remainingMovement -= step.enterCost;
      } else if (remainingMovement > 0) {
        remainingMovement = 0;
      } else {
        turns += 1;
        remainingMovement = step.enterCost >= fullTurnMovement
            ? 0
            : fullTurnMovement - step.enterCost;
      }
    }

    return turns;
  }

  static bool _canReachTarget(
    int availableMovementPoints,
    List<UnitMovementStep> steps,
  ) {
    if (steps.isEmpty) return false;
    final target = steps.last;
    if (target.cumulativeCost <= availableMovementPoints) return true;
    return target.cumulativeCost - target.enterCost < availableMovementPoints;
  }

  static int _remainingAfterCost(int availableMovementPoints, int cost) {
    final remaining = availableMovementPoints - cost;
    return remaining < 0 ? 0 : remaining;
  }
}
