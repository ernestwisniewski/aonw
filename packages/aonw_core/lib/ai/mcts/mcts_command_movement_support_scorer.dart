part of 'mcts_command_movement_scorer.dart';

final class _MctsSupportMovementScorer {
  const _MctsSupportMovementScorer();

  double score(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext? context,
  }) {
    if (context == null) return 0;

    var score = 0.0;
    if (mctsCanServeAsMilitaryUnit(unit, context)) {
      score += _frontierClearingMoveScore(
        command,
        unit: unit,
        state: state,
        context: context,
      );
      score += _settlerEscortMoveScore(
        command,
        unit: unit,
        state: state,
        context: context,
      );
    }
    if (mctsCanDiscoverCitySites(unit, view: state.view, context: context)) {
      score += _citySiteDiscoveryMoveScore(
        command,
        unit: unit,
        state: state,
        context: context,
      );
    }
    return score;
  }

  double _frontierClearingMoveScore(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext context,
  }) {
    final assignment =
        context.strategicPlan?.frontierClearingAssignments[unit.id];
    if (assignment == null) return 0;

    final targetEnemy = mctsEnemyAt(
      state.visibleTargetableEnemyUnits,
      assignment.targetHex.col,
      assignment.targetHex.row,
    );
    if (targetEnemy == null ||
        targetEnemy.ownerPlayerId != assignment.targetPlayerId) {
      return 0;
    }

    final afterDistance = HexDistance.between(
      HexCoordinate(col: command.targetCol, row: command.targetRow),
      assignment.targetHex,
    );
    if (afterDistance > 2) return 0;

    return (0.095 +
            (2 - afterDistance) * 0.04 +
            assignment.priority * 0.012 -
            afterDistance * 0.015)
        .clamp(0.0, 0.25)
        .toDouble();
  }

  double _settlerEscortMoveScore(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext context,
  }) {
    final target = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    var best = 0.0;

    for (final founder in state.ownUnits) {
      final score = _escortScoreForFounder(
        target: target,
        founder: founder,
        state: state,
        context: context,
      );
      if (score > best) best = score;
    }

    return best.clamp(0.0, 0.20).toDouble();
  }

  double _escortScoreForFounder({
    required HexCoordinate target,
    required GameUnit founder,
    required SimulatedState state,
    required AiContext context,
  }) {
    if (!CityFoundingRules.canFoundCityWith(founder)) return 0;

    final assignment = context.strategicPlan?.settlerAssignments[founder.id];
    final focus =
        assignment?.toCoordinate() ??
        HexCoordinate(col: founder.col, row: founder.row);
    final founderHex = HexCoordinate(col: founder.col, row: founder.row);
    final enemyNearFounder =
        mctsVisibleMilitaryNear(
          state,
          founderHex.col,
          founderHex.row,
          3,
          context,
        ) ||
        mctsVisibleMilitaryNear(state, focus.col, focus.row, 3, context);
    if (!enemyNearFounder) return 0;

    final after = mctsMinDistance(target, founderHex, focus);
    if (after > 2) return 0;
    return after <= 1 ? 0.155 : 0.115;
  }

  double _citySiteDiscoveryMoveScore(
    MoveUnitCommand command, {
    required GameUnit unit,
    required SimulatedState state,
    required AiContext context,
  }) {
    final plan = context.strategicPlan;
    if (!AiFrontierExplorationScorer.needsCitySiteDiscovery(
      view: state.view,
      plan: plan,
    )) {
      return 0;
    }
    if (_hasHigherPriorityAssignment(unit.id, plan)) return 0;

    final targetScore = const AiFrontierExplorationScorer()
        .citySiteDiscoveryScore(
          view: state.view,
          origin: HexCoordinate(col: command.targetCol, row: command.targetRow),
        );
    if (targetScore <= 0) return 0;

    return (0.055 + targetScore * 0.011).clamp(0.0, 0.24).toDouble();
  }

  bool _hasHigherPriorityAssignment(String unitId, StrategicPlan? plan) {
    if (plan?.defenses.values.any(
          (defense) => defense.assignedUnitIds.contains(unitId),
        ) ??
        false) {
      return true;
    }
    if (plan?.frontierClearingAssignments.containsKey(unitId) ?? false) {
      return true;
    }
    return plan?.warGoals.any(
          (goal) => goal.assignedUnitIds.contains(unitId),
        ) ??
        false;
  }
}
