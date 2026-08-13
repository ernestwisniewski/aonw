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

  /// Total route cost in fixed-point movement units.
  final int totalCost;
  final int availableMovementUnits;
  final int remainingMovementUnitsAfterMove;
  final bool canMoveNow;
  final List<UnitMovementStep> steps;

  UnitMovementPlan({
    required this.unitId,
    required this.targetCol,
    required this.targetRow,
    required this.totalCost,
    int? availableMovementUnits,
    @Deprecated('Use availableMovementUnits') int? availableMovementPoints,
    required List<UnitMovementStep> steps,
  }) : assert(
         (availableMovementUnits == null) != (availableMovementPoints == null),
       ),
       availableMovementUnits =
           availableMovementUnits ?? availableMovementPoints!,
       remainingMovementUnitsAfterMove = _remainingAfterCost(
         availableMovementUnits ?? availableMovementPoints!,
         totalCost,
       ),
       canMoveNow = _canReachTarget(
         availableMovementUnits ?? availableMovementPoints!,
         steps,
       ),
       steps = List.unmodifiable(steps);

  @Deprecated('Use availableMovementUnits')
  int get availableMovementPoints => availableMovementUnits;

  @Deprecated('Use remainingMovementUnitsAfterMove')
  int get remainingAfterMove => remainingMovementUnitsAfterMove;

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
    if (step.cumulativeCost <= availableMovementUnits) return true;
    return step.cumulativeCost - step.enterCost < availableMovementUnits;
  }

  int remainingMovementUnitsAfterStep(UnitMovementStep step) {
    return _remainingAfterCost(availableMovementUnits, step.cumulativeCost);
  }

  @Deprecated('Use remainingMovementUnitsAfterStep')
  int remainingMovementPointsAfterStep(UnitMovementStep step) =>
      remainingMovementUnitsAfterStep(step);

  /// Returns the untravelled suffix with costs rebased to the current step.
  ///
  /// The current [availableMovementUnits] are preserved, so callers restoring
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
      availableMovementUnits: availableMovementUnits,
      steps: remainingSteps,
    );
  }

  /// Estimates calendar turns, including the partially spent current turn.
  int estimatedTurns(int maxMovementUnitsPerTurn) {
    if (totalCost <= 0) return 0;

    final fullTurnMovement = maxMovementUnitsPerTurn > 0
        ? maxMovementUnitsPerTurn
        : 1;
    var turns = 1;
    var remainingMovement = availableMovementUnits;
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
