part of 'mcts_command_movement_scorer.dart';

final class _MctsSettlerMovementScorer {
  const _MctsSettlerMovementScorer();

  double score(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext? context,
  }) {
    if (context == null) return 0;

    final retreatScore = _emergencyRetreatScore(
      command,
      unit: unit,
      state: state,
      context: context,
    );
    if (retreatScore > 0) return retreatScore;

    final assignment =
        context.strategicPlan?.settlerAssignments[command.unitId];
    if (assignment == null) {
      return _unassignedMoveScore(
        command,
        unit: unit,
        state: state,
        context: context,
      );
    }

    return _assignedMoveScore(
      command,
      unit: unit,
      state: state,
      context: context,
      assignment: assignment,
    );
  }

  double _assignedMoveScore(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext context,
    required CityHex assignment,
  }) {
    final target = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    final distanceToAssignment = HexDistance.between(
      target,
      assignment.toCoordinate(),
    );
    var score = _assignedProgressScore(
      distanceToAssignment: distanceToAssignment,
      state: state,
      context: context,
    );
    if (distanceToAssignment == 0) score += 0.08;

    final unknown = AiCityFoundingSafety.unknownCenterExclusionTiles(
      view: state.view,
      center: assignment,
    );
    if (unknown.isEmpty) return score;

    final revealGain =
        AiCityFoundingSafety.revealableUnknownCenterExclusionTileCount(
          view: state.view,
          center: assignment,
          observer: unit.copyWith(
            col: command.targetCol,
            row: command.targetRow,
          ),
        );
    if (revealGain <= 0) return score;

    return score + 0.22 + revealGain * 0.08 - distanceToAssignment * 0.015;
  }

  double _assignedProgressScore({
    required int distanceToAssignment,
    required SimulatedState state,
    required AiContext context,
  }) {
    if (state.ownCities.isEmpty) return 0;

    final assessment = AiEmpireAssessment.fromView(state.view, context);
    if (assessment.cityCount >= assessment.desiredCityCount) return 0;
    if (assessment.settlerCount <= 0) return 0;

    final thirdCityPressure = assessment.cityCount == 2 ? 0.055 : 0.025;
    final modePressure = switch (context.strategicPlan?.mode) {
      StrategicMode.expand => 0.03,
      StrategicMode.military || StrategicMode.recover => 0.045,
      _ => 0.0,
    };
    final distancePenalty =
        distanceToAssignment * 0.012 / context.civProfile.expansionDistance;
    return (0.18 + thirdCityPressure + modePressure - distancePenalty)
        .clamp(0.04, 0.30)
        .toDouble();
  }

  double _emergencyRetreatScore(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext context,
  }) {
    if (state.ownCities.isEmpty) return 0;

    final currentEnemyDistance = mctsNearestVisibleMilitaryDistance(
      state,
      unit.col,
      unit.row,
      context,
    );
    if (currentEnemyDistance == null || currentEnemyDistance > 2) return 0;

    final targetEnemyDistance = mctsNearestVisibleMilitaryDistance(
      state,
      command.targetCol,
      command.targetRow,
      context,
    );
    if (!_isSaferRetreatTarget(currentEnemyDistance, targetEnemyDistance)) {
      return 0;
    }

    final escorted = mctsOwnMilitaryNear(
      state,
      command.targetCol,
      command.targetRow,
      2,
      context,
    );
    final distanceGain =
        (targetEnemyDistance ?? currentEnemyDistance + 3) -
        currentEnemyDistance;
    return 0.22 + distanceGain * 0.08 + (escorted ? 0.06 : 0);
  }

  bool _isSaferRetreatTarget(
    int currentEnemyDistance,
    int? targetEnemyDistance,
  ) {
    if (targetEnemyDistance != null && targetEnemyDistance <= 1) return false;
    if (targetEnemyDistance != null &&
        targetEnemyDistance <= currentEnemyDistance) {
      return false;
    }

    final minimumRetreatDistance = currentEnemyDistance <= 1 ? 4 : 5;
    return targetEnemyDistance == null ||
        targetEnemyDistance >= minimumRetreatDistance;
  }

  double _unassignedMoveScore(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext context,
  }) {
    final targetEscorted = mctsOwnMilitaryNear(
      state,
      command.targetCol,
      command.targetRow,
      2,
      context,
    );
    final target = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    final cityPressurePenalty = _rememberedEnemyCityPenalty(
      target: target,
      targetEscorted: targetEscorted,
      state: state,
    );
    if (cityPressurePenalty != 0) return cityPressurePenalty;

    final targetSafety = _MctsSettlerTargetSafety.forMove(
      command: command,
      state: state,
      context: context,
      targetEscorted: targetEscorted,
    );
    if (targetSafety.blocksMove) return targetSafety.blockingPenalty;
    if (!_canRetreatFromCurrentDanger(command, unit, state, context)) return 0;

    final targetDistance = mctsNearestOwnCityDistance(
      state,
      command.targetCol,
      command.targetRow,
    );
    final currentDistance = mctsNearestOwnCityDistance(
      state,
      unit.col,
      unit.row,
    );
    if (targetDistance <= 1) return 0;
    if (_isSpacingMove(state, targetDistance)) {
      return _spacingMoveScore(
        command,
        state: state,
        spacingGain: targetDistance - currentDistance,
      );
    }

    return _openMoveScore(
      command,
      state: state,
      context: context,
      currentEscorted: mctsOwnMilitaryNear(
        state,
        unit.col,
        unit.row,
        2,
        context,
      ),
      targetEscorted: targetEscorted,
      enemyNearTarget: targetSafety.enemyNearTarget,
      targetDistance: targetDistance,
    );
  }

  double _rememberedEnemyCityPenalty({
    required HexCoordinate target,
    required bool targetEscorted,
    required SimulatedState state,
  }) {
    if (state.ownCities.isEmpty) return 0;
    if (AiCityFoundingSafety.isKnownEnemyCityHex(
      view: state.view,
      hex: target,
    )) {
      return -0.08;
    }

    final targetEnemyCityDistance =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: state.view,
          hex: target,
        );
    if (targetEnemyCityDistance == null) return 0;
    if (targetEnemyCityDistance <= 1) return -0.08;
    if (targetEnemyCityDistance <= 2 && !targetEscorted) return -0.03;
    return 0;
  }

  bool _canRetreatFromCurrentDanger(
    MoveUnitCommand command,
    GameUnit unit,
    SimulatedState state,
    AiContext context,
  ) {
    final currentEnemyDistance = mctsNearestVisibleMilitaryDistance(
      state,
      unit.col,
      unit.row,
      context,
    );
    final targetEnemyDistance = mctsNearestVisibleMilitaryDistance(
      state,
      command.targetCol,
      command.targetRow,
      context,
    );
    final minimumSafeDistance =
        currentEnemyDistance != null && currentEnemyDistance <= 1 ? 4 : 5;
    return currentEnemyDistance == null ||
        currentEnemyDistance > 2 ||
        targetEnemyDistance == null ||
        targetEnemyDistance >= minimumSafeDistance;
  }

  bool _isSpacingMove(SimulatedState state, int targetDistance) {
    return state.ownCities.length >= 2 &&
        targetDistance < CityFoundingRules.minimumCenterDistance;
  }

  double _spacingMoveScore(
    MoveUnitCommand command, {
    required SimulatedState state,
    required int spacingGain,
  }) {
    if (spacingGain <= 0) return 0;
    return 0.12 +
        spacingGain * 0.055 +
        mctsSettlerFrontierScore(state, command.targetCol, command.targetRow) *
            0.004;
  }

  double _openMoveScore(
    MoveUnitCommand command, {
    required SimulatedState state,
    required AiContext context,
    required bool currentEscorted,
    required bool targetEscorted,
    required bool enemyNearTarget,
    required int targetDistance,
  }) {
    var score =
        0.10 +
        (targetDistance - 1) * 0.04 +
        mctsSettlerFrontierScore(state, command.targetCol, command.targetRow) *
            0.006;
    if (targetDistance >= CityFoundingRules.minimumCenterDistance) {
      score += 0.11;
    }
    if (currentEscorted || targetEscorted) score += 0.06;
    if (enemyNearTarget) score -= 0.045;

    final coreDefenseDeficit = mctsCoreDefenseDeficit(
      assessment: AiEmpireAssessment.fromView(state.view, context),
      state: state,
      context: context,
    );
    if (coreDefenseDeficit > 0) score *= 0.5;
    return score;
  }
}

final class _MctsSettlerTargetSafety {
  const _MctsSettlerTargetSafety({
    required this.enemyNearTarget,
    required this.targetEnemyDistance,
    required this.targetEscorted,
  });

  factory _MctsSettlerTargetSafety.forMove({
    required MoveUnitCommand command,
    required SimulatedState state,
    required AiContext context,
    required bool targetEscorted,
  }) {
    final targetEnemyDistance = mctsNearestVisibleMilitaryDistance(
      state,
      command.targetCol,
      command.targetRow,
      context,
    );
    return _MctsSettlerTargetSafety(
      enemyNearTarget: targetEnemyDistance != null && targetEnemyDistance <= 2,
      targetEnemyDistance: targetEnemyDistance,
      targetEscorted: targetEscorted,
    );
  }

  final bool enemyNearTarget;
  final int? targetEnemyDistance;
  final bool targetEscorted;

  bool get blocksMove => hasAdjacentEnemy || hasImmediateEnemyWithoutEscort;

  double get blockingPenalty => hasAdjacentEnemy ? -0.08 : -0.03;

  bool get hasAdjacentEnemy =>
      targetEnemyDistance != null && targetEnemyDistance! <= 1;

  bool get hasImmediateEnemyWithoutEscort => enemyNearTarget && !targetEscorted;
}
