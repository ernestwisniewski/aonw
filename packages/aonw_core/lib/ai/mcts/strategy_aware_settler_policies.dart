part of 'strategy_aware_settler_ranker.dart';

final class _SettlerMoveSafetyPolicy {
  const _SettlerMoveSafetyPolicy();

  bool isUnsafe(
    MoveUnitCommand command,
    GameUnit unit,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    if (view.ownCities.isEmpty) return false;

    final target = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    if (AiCityFoundingSafety.isKnownEnemyCityHex(view: view, hex: target)) {
      return true;
    }

    final targetEscorted = ownMilitaryNear(
      view,
      command.targetCol,
      command.targetRow,
      2,
      context,
    );
    final needsDestinationEscort = _needsDestinationEscort(
      command: command,
      unit: unit,
      view: view,
      plan: plan,
      target: target,
      targetEscorted: targetEscorted,
    );
    if (_enemyCityPressureBlocksMove(
      command: command,
      unit: unit,
      view: view,
      target: target,
      targetEscorted: targetEscorted,
      needsDestinationEscort: needsDestinationEscort,
    )) {
      return true;
    }

    final targetEnemyDistance = nearestVisibleMilitaryDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    if (targetEnemyDistance != null && targetEnemyDistance <= 1) return true;

    final targetThreatRadius = needsDestinationEscort ? 3 : 2;
    final enemyNearTarget =
        targetEnemyDistance != null &&
        targetEnemyDistance <= targetThreatRadius;
    return enemyNearTarget && !targetEscorted;
  }

  bool _needsDestinationEscort({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required StrategicPlan plan,
    required HexCoordinate target,
    required bool targetEscorted,
  }) {
    final currentOwnCityDistance = nearestOwnCityDistance(
      view,
      unit.col,
      unit.row,
    );
    final targetOwnCityDistance = nearestOwnCityDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    return view.ownCities.length >= 2 &&
        targetOwnCityDistance >= currentOwnCityDistance &&
        !targetEscorted &&
        !_isLocalAssignedReveal(unit, target, plan);
  }

  bool _isLocalAssignedReveal(
    GameUnit unit,
    HexCoordinate target,
    StrategicPlan plan,
  ) {
    final assignment = plan.settlerAssignments[unit.id];
    if (assignment == null) return false;

    final assignmentTarget = assignment.toCoordinate();
    final founderAtAssignment =
        HexDistance.between(
          HexCoordinate(col: unit.col, row: unit.row),
          assignmentTarget,
        ) ==
        0;
    return founderAtAssignment &&
        HexDistance.between(target, assignmentTarget) <= 1;
  }

  bool _enemyCityPressureBlocksMove({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required HexCoordinate target,
    required bool targetEscorted,
    required bool needsDestinationEscort,
  }) {
    final targetEnemyCityDistance =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: target,
        );
    if (targetEnemyCityDistance != null) {
      if (targetEnemyCityDistance <= 1) return true;
      if (targetEnemyCityDistance <= 2 && !targetEscorted) return true;
      if (needsDestinationEscort && targetEnemyCityDistance <= 3) return true;
    }

    if (!needsDestinationEscort) return false;
    final currentEnemyCityDistance =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: HexCoordinate(col: unit.col, row: unit.row),
        );
    return currentEnemyCityDistance != null && currentEnemyCityDistance <= 3;
  }
}

final class _SettlerRetreatRanker {
  const _SettlerRetreatRanker();

  CommandRanking? rank({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required AiContext context,
  }) {
    if (view.ownCities.isEmpty) return null;

    final currentEnemyDistance = nearestVisibleMilitaryDistance(
      view,
      unit.col,
      unit.row,
    );
    if (currentEnemyDistance == null || currentEnemyDistance > 2) return null;

    final targetEnemyDistance = nearestVisibleMilitaryDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    if (!_isSaferRetreatTarget(currentEnemyDistance, targetEnemyDistance)) {
      return null;
    }

    final targetEscorted = ownMilitaryNear(
      view,
      command.targetCol,
      command.targetRow,
      2,
      context,
    );
    final distanceGain =
        (targetEnemyDistance ?? currentEnemyDistance + 3) -
        currentEnemyDistance;
    final cityDistance = nearestOwnCityDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    return CommandRanking(
      CandidatePriority.opening,
      1260 + distanceGain * 28 + (targetEscorted ? 18 : 0) - cityDistance * 2,
    );
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
}

final class _SettlerRevealRanker {
  const _SettlerRevealRanker();

  CommandRanking? rank({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
    required CityHex assignment,
  }) {
    final unknown = AiCityFoundingSafety.unknownCenterExclusionTiles(
      view: view,
      center: assignment,
    );
    if (unknown.isEmpty) return null;

    final targetTile = view.mapData.tileAt(
      command.targetCol,
      command.targetRow,
    );
    if (targetTile == null) return null;

    final revealGain =
        AiCityFoundingSafety.revealableUnknownCenterExclusionTileCount(
          view: view,
          center: assignment,
          observer: unit.copyWith(
            col: command.targetCol,
            row: command.targetRow,
          ),
        );
    if (revealGain <= 0) return null;

    final centerDistance = HexDistance.between(
      HexCoordinate.fromTile(targetTile),
      assignment.toCoordinate(),
    );
    return CommandRanking(
      CandidatePriority.settler,
      900 + revealGain * 42 - centerDistance * 8,
    );
  }
}

final class _ActiveThirdCitySettlerPushPolicy {
  const _ActiveThirdCitySettlerPushPolicy();

  bool allowsPush(
    GameView view,
    AiContext context,
    StrategicPlan plan, {
    required bool enemyNearTarget,
  }) {
    if (view.ownCities.length != 2 || enemyNearTarget) return false;
    for (final defense in plan.defenses.values) {
      if (defense.threatLevel >= 6) return false;
    }
    final assessment = AiEmpireAssessment.fromView(view, context);
    if (!assessment.wantsExpansion || assessment.netGoldPerTurn < 0) {
      return false;
    }
    return assessment.desiredCityCount - assessment.cityCount >= 1;
  }
}

final class _SettlerTargetSafetyReport {
  const _SettlerTargetSafetyReport({
    required this.targetEscorted,
    required this.enemyNearTarget,
    required this.targetEnemyDistance,
  });

  factory _SettlerTargetSafetyReport.forMove({
    required MoveUnitCommand command,
    required GameView view,
    required AiContext context,
    required int enemySearchRadius,
  }) {
    final targetEnemyDistance = nearestVisibleMilitaryDistance(
      view,
      command.targetCol,
      command.targetRow,
    );
    return _SettlerTargetSafetyReport(
      targetEscorted: ownMilitaryNear(
        view,
        command.targetCol,
        command.targetRow,
        2,
        context,
      ),
      enemyNearTarget: visibleMilitaryNear(
        view,
        command.targetCol,
        command.targetRow,
        enemySearchRadius,
      ),
      targetEnemyDistance: targetEnemyDistance,
    );
  }

  final bool targetEscorted;
  final bool enemyNearTarget;
  final int? targetEnemyDistance;

  bool get canEnterAssignedTarget {
    if (hasAdjacentEnemy) return false;
    return !hasImmediateEnemyWithoutEscort;
  }

  bool get canEnterUnassignedTarget => canEnterAssignedTarget;

  bool get hasAdjacentEnemy =>
      targetEnemyDistance != null && targetEnemyDistance! <= 1;

  bool get hasImmediateEnemyWithoutEscort =>
      targetEnemyDistance != null &&
      targetEnemyDistance! <= 2 &&
      !targetEscorted;

  double get dangerPenalty => enemyNearTarget ? 32.0 : 0.0;
}
