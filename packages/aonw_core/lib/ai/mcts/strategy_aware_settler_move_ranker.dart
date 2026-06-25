part of 'strategy_aware_settler_ranker.dart';

final class _StrategicSettlerRanker {
  const _StrategicSettlerRanker()
    : _moveSafety = const _SettlerMoveSafetyPolicy(),
      _retreatRanker = const _SettlerRetreatRanker(),
      _revealRanker = const _SettlerRevealRanker(),
      _unassignedMoveRanker = const _UnassignedSettlerMoveRanker(),
      _thirdCityPushPolicy = const _ActiveThirdCitySettlerPushPolicy();

  final _SettlerMoveSafetyPolicy _moveSafety;
  final _SettlerRetreatRanker _retreatRanker;
  final _SettlerRevealRanker _revealRanker;
  final _UnassignedSettlerMoveRanker _unassignedMoveRanker;
  final _ActiveThirdCitySettlerPushPolicy _thirdCityPushPolicy;

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    return switch (command) {
      FoundCityCommand() => _rankFoundCity(command, view, context, plan),
      MoveUnitCommand() => _rankMoveCommand(command, view, context, plan),
      _ => null,
    };
  }

  CommandRanking? _rankMoveCommand(
    MoveUnitCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null || !CityFoundingRules.canFoundCityWith(unit)) return null;
    if (_moveSafety.isUnsafe(command, unit, view, context, plan)) {
      return const CommandRanking(CandidatePriority.fallback, -1000);
    }
    return _rankMove(command, unit, view, context, plan);
  }

  CommandRanking? _rankFoundCity(
    FoundCityCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final founder = ownUnitById(view, command.founderId);
    if (founder == null || !CityFoundingRules.canFoundCityWith(founder)) {
      return null;
    }

    final assignment = plan.settlerAssignments[founder.id];
    if (assignment == null) {
      final score = coreDefenseCovered(view, context, plan) ? 840.0 : 760.0;
      if (plan.mode == StrategicMode.expand) {
        return CommandRanking(CandidatePriority.settler, score + 30);
      }
      return CommandRanking(CandidatePriority.settler, score);
    }

    final distance = HexDistance.between(
      HexCoordinate(col: founder.col, row: founder.row),
      assignment.toCoordinate(),
    );
    return CommandRanking(CandidatePriority.settler, 860 - distance * 8);
  }

  CommandRanking? _rankMove(
    MoveUnitCommand command,
    GameUnit unit,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final retreatRank = _retreatRanker.rank(
      command: command,
      unit: unit,
      view: view,
      context: context,
    );
    if (retreatRank != null) return retreatRank;

    final assignment = plan.settlerAssignments[unit.id];
    if (assignment == null) {
      return _unassignedMoveRanker.rank(
        command: command,
        unit: unit,
        view: view,
        context: context,
        plan: plan,
      );
    }

    return _rankAssignedMove(
      command: command,
      unit: unit,
      view: view,
      context: context,
      plan: plan,
      assignment: assignment,
    );
  }

  CommandRanking? _rankAssignedMove({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required StrategicPlan plan,
    required CityHex assignment,
  }) {
    final assignmentTarget = assignment.toCoordinate();
    final currentDistance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      assignmentTarget,
    );
    final revealRank = currentDistance == 0
        ? _revealRanker.rank(
            command: command,
            unit: unit,
            view: view,
            assignment: assignment,
          )
        : null;
    if (revealRank != null) {
      return _rankAssignedRevealMove(
        command: command,
        view: view,
        context: context,
        plan: plan,
        revealRank: revealRank,
      );
    }

    final improvement = distanceImprovement(
      fromCol: unit.col,
      fromRow: unit.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: assignmentTarget,
    );
    if (improvement <= 0) return null;

    final targetSafety = _SettlerTargetSafetyReport.forMove(
      command: command,
      view: view,
      context: context,
      enemySearchRadius: 2,
    );
    if (!targetSafety.canEnterAssignedTarget) return null;

    final activeThirdCityPush = _thirdCityPushPolicy.allowsPush(
      view,
      context,
      plan,
      enemyNearTarget: targetSafety.enemyNearTarget,
    );
    if (_canUseOpeningPriority(
      view: view,
      context: context,
      plan: plan,
      targetEscorted: targetSafety.targetEscorted,
      activeThirdCityPush: activeThirdCityPush,
    )) {
      return CommandRanking(
        CandidatePriority.opening,
        1218 + improvement * 20 - targetSafety.dangerPenalty,
      );
    }

    return CommandRanking(CandidatePriority.settler, 820 + improvement * 20);
  }

  CommandRanking? _rankAssignedRevealMove({
    required MoveUnitCommand command,
    required GameView view,
    required AiContext context,
    required StrategicPlan plan,
    required CommandRanking revealRank,
  }) {
    final targetSafety = _SettlerTargetSafetyReport.forMove(
      command: command,
      view: view,
      context: context,
      enemySearchRadius: 3,
    );
    if (!targetSafety.canEnterAssignedTarget) return null;

    final activeThirdCityPush = _thirdCityPushPolicy.allowsPush(
      view,
      context,
      plan,
      enemyNearTarget: targetSafety.enemyNearTarget,
    );
    if (_canUseOpeningPriority(
      view: view,
      context: context,
      plan: plan,
      targetEscorted: targetSafety.targetEscorted,
      activeThirdCityPush: activeThirdCityPush,
    )) {
      return CommandRanking(
        CandidatePriority.opening,
        1236 +
            (revealRank.score - 900).clamp(0, 120) * 0.25 -
            targetSafety.dangerPenalty,
      );
    }

    return revealRank;
  }

  bool _canUseOpeningPriority({
    required GameView view,
    required AiContext context,
    required StrategicPlan plan,
    required bool targetEscorted,
    required bool activeThirdCityPush,
  }) {
    return coreDefenseCovered(view, context, plan) ||
        targetEscorted ||
        activeThirdCityPush;
  }
}

final class _UnassignedSettlerMoveRanker {
  const _UnassignedSettlerMoveRanker()
    : _thirdCityPushPolicy = const _ActiveThirdCitySettlerPushPolicy();

  final _ActiveThirdCitySettlerPushPolicy _thirdCityPushPolicy;

  CommandRanking? rank({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required StrategicPlan plan,
  }) {
    final currentEscorted = ownMilitaryNear(
      view,
      unit.col,
      unit.row,
      2,
      context,
    );
    final targetSafety = _SettlerTargetSafetyReport.forMove(
      command: command,
      view: view,
      context: context,
      enemySearchRadius: 3,
    );
    if (!targetSafety.canEnterUnassignedTarget) return null;
    if (!_canRetreatFromCurrentDanger(command, unit, view)) return null;

    final currentDistance = nearestOwnCityDistance(view, unit.col, unit.row);
    final targetDistance = nearestOwnCityDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    if (!_allowsSpacingStep(view, currentDistance, targetDistance)) return null;

    final improvement = targetDistance - currentDistance;
    final coreCovered = coreDefenseCovered(view, context, plan);
    final hasEscort = currentEscorted || targetSafety.targetEscorted;
    final activeThirdCityPush = _thirdCityPushPolicy.allowsPush(
      view,
      context,
      plan,
      enemyNearTarget: targetSafety.enemyNearTarget,
    );
    final priority = coreCovered || hasEscort || activeThirdCityPush
        ? CandidatePriority.opening
        : CandidatePriority.settler;

    if (improvement <= 0) {
      return _rankFrontierGain(
        command: command,
        unit: unit,
        view: view,
        targetDistance: targetDistance,
        coreCovered: coreCovered,
        hasEscort: hasEscort,
        activeThirdCityPush: activeThirdCityPush,
        priority: priority,
      );
    }

    return _rankDistanceGain(
      improvement: improvement,
      targetDistance: targetDistance,
      targetSafety: targetSafety,
      coreCovered: coreCovered,
      hasEscort: hasEscort,
      activeThirdCityPush: activeThirdCityPush,
      priority: priority,
    );
  }

  bool _canRetreatFromCurrentDanger(
    MoveUnitCommand command,
    GameUnit unit,
    GameView view,
  ) {
    final currentEnemyDistance = nearestVisibleMilitaryDistance(
      view,
      unit.col,
      unit.row,
    );
    final targetEnemyDistance = nearestVisibleMilitaryDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    final minimumSafeDistance =
        currentEnemyDistance != null && currentEnemyDistance <= 1 ? 4 : 5;
    return currentEnemyDistance == null ||
        currentEnemyDistance > 2 ||
        targetEnemyDistance == null ||
        targetEnemyDistance >= minimumSafeDistance;
  }

  bool _allowsSpacingStep(
    GameView view,
    int currentDistance,
    int targetDistance,
  ) {
    if (view.ownCities.length < 2) return true;
    if (targetDistance >= CityFoundingRules.minimumCenterDistance) return true;
    return view.ownCities.length == 2 && targetDistance > currentDistance;
  }

  CommandRanking? _rankFrontierGain({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required int targetDistance,
    required bool coreCovered,
    required bool hasEscort,
    required bool activeThirdCityPush,
    required CandidatePriority priority,
  }) {
    final frontierGain =
        _settlerFrontierScore(view, command.targetCol, command.targetRow) -
        _settlerFrontierScore(view, unit.col, unit.row);
    if (frontierGain <= 0) return null;

    return CommandRanking(
      priority,
      _frontierGainBaseScore(
            coreCovered: coreCovered,
            hasEscort: hasEscort,
            activeThirdCityPush: activeThirdCityPush,
          ) +
          frontierGain * 18 +
          targetDistance * 2,
    );
  }

  CommandRanking _rankDistanceGain({
    required int improvement,
    required int targetDistance,
    required _SettlerTargetSafetyReport targetSafety,
    required bool coreCovered,
    required bool hasEscort,
    required bool activeThirdCityPush,
    required CandidatePriority priority,
  }) {
    final reachesLegalSpacing =
        targetDistance >= CityFoundingRules.minimumCenterDistance;
    return CommandRanking(
      priority,
      _distanceGainBaseScore(
            coreCovered: coreCovered,
            hasEscort: hasEscort,
            activeThirdCityPush: activeThirdCityPush,
          ) +
          improvement * 20 +
          (reachesLegalSpacing ? 52.0 : 0.0) +
          targetDistance * 2 -
          targetSafety.dangerPenalty,
    );
  }

  double _frontierGainBaseScore({
    required bool coreCovered,
    required bool hasEscort,
    required bool activeThirdCityPush,
  }) {
    if (coreCovered || hasEscort) return 1180.0;
    if (activeThirdCityPush) return 1140.0;
    return 760.0;
  }

  double _distanceGainBaseScore({
    required bool coreCovered,
    required bool hasEscort,
    required bool activeThirdCityPush,
  }) {
    if (coreCovered || hasEscort) return 1242.0;
    if (activeThirdCityPush) return 1210.0;
    return 800.0;
  }

  double _settlerFrontierScore(GameView view, int col, int row) {
    return const AiFrontierExplorationScorer().genericFrontierScore(
      view: view,
      origin: HexCoordinate(col: col, row: row),
    );
  }
}
