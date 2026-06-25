part of 'strategy_aware_settler_ranker.dart';

final class _CitySiteDiscoveryRanker {
  const _CitySiteDiscoveryRanker();

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    if (command is! MoveUnitCommand) return null;
    if (!AiFrontierExplorationScorer.needsCitySiteDiscovery(
      view: view,
      plan: plan,
    )) {
      return null;
    }

    final unit = ownUnitById(view, command.unitId);
    if (unit == null || !_canDiscoverCitySites(unit, view, context, plan)) {
      return null;
    }
    if (_hasHigherPriorityAssignment(unit.id, plan)) return null;

    final scoreImprovement = _citySiteDiscoveryImprovement(
      command: command,
      unit: unit,
      view: view,
    );
    if (scoreImprovement <= 0) return null;

    final distanceFromCore = AiFrontierExplorationScorer.nearestOwnCityDistance(
      view: view,
      origin: HexCoordinate(col: command.targetCol, row: command.targetRow),
    );
    return CommandRanking(
      CandidatePriority.settler,
      742 +
          scoreImprovement * 14 +
          distanceFromCore.clamp(0, 8).toDouble() * 1.5,
    );
  }

  bool _canDiscoverCitySites(
    GameUnit unit,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    if (unit.isWorking || unit.movementPoints <= 0 || unit.queuedPath != null) {
      return false;
    }
    if (unit.isWorker ||
        unit.type == GameUnitType.settler ||
        unit.hasSettlers) {
      return false;
    }
    if (isReconUnit(unit)) return true;
    if (!_military.isType(unit.type, context)) return false;
    return !hasAvailableReconCitySiteScout(view, plan);
  }

  bool _hasHigherPriorityAssignment(String unitId, StrategicPlan plan) {
    if (assignedDefenseFor(plan, unitId) != null) return true;
    if (plan.frontierClearingAssignments.containsKey(unitId)) return true;
    return plan.warGoals.any((goal) => goal.assignedUnitIds.contains(unitId));
  }

  double _citySiteDiscoveryImprovement({
    required MoveUnitCommand command,
    required GameUnit unit,
    required GameView view,
  }) {
    const scorer = AiFrontierExplorationScorer();
    final current = scorer.citySiteDiscoveryScore(
      view: view,
      origin: HexCoordinate(col: unit.col, row: unit.row),
    );
    final target = scorer.citySiteDiscoveryScore(
      view: view,
      origin: HexCoordinate(col: command.targetCol, row: command.targetRow),
    );
    return target - current;
  }
}

final class _SettlerEscortRanker {
  const _SettlerEscortRanker();

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    return switch (command) {
      MoveUnitCommand() => _rankMove(command, view, context, plan),
      _ => null,
    };
  }

  CommandRanking? _rankMove(
    MoveUnitCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null || !_military.isUnit(unit, context)) return null;

    CommandRanking? best;
    for (final founder in view.ownUnits) {
      final option = _escortOptionForFounder(
        command: command,
        escort: unit,
        founder: founder,
        view: view,
        plan: plan,
      );
      if (option == null) continue;
      if (best == null || option.score > best.score) best = option;
    }
    return best;
  }

  CommandRanking? _escortOptionForFounder({
    required MoveUnitCommand command,
    required GameUnit escort,
    required GameUnit founder,
    required GameView view,
    required StrategicPlan plan,
  }) {
    if (!CityFoundingRules.canFoundCityWith(founder)) return null;

    final assignment = plan.settlerAssignments[founder.id];
    final focus =
        assignment?.toCoordinate() ??
        HexCoordinate(col: founder.col, row: founder.row);
    final commandTarget = HexCoordinate(
      col: command.targetCol,
      row: command.targetRow,
    );
    final founderHex = HexCoordinate(col: founder.col, row: founder.row);
    final improvement = _escortImprovement(
      command: command,
      escort: escort,
      founderHex: founderHex,
      focus: focus,
      commandTarget: commandTarget,
    );
    if (improvement <= 0) return null;
    if (!_canStayNearFounderOrFocus(commandTarget, founderHex, focus)) {
      return null;
    }

    final assignmentNeedsReveal =
        assignment != null &&
        AiCityFoundingSafety.unknownCenterExclusionTiles(
          view: view,
          center: assignment,
        ).isNotEmpty;
    final nearbyEnemy =
        visibleMilitaryNear(view, founder.col, founder.row, 3) ||
        visibleMilitaryNear(view, focus.col, focus.row, 3);
    if (!assignmentNeedsReveal && !nearbyEnemy) return null;

    final nearCityPenalty =
        nearestOwnCityDistance(view, command.targetCol, command.targetRow) > 2
        ? 18.0
        : 0.0;
    final score =
        1212 +
        improvement * 22 +
        (assignmentNeedsReveal ? 18 : 0) +
        (nearbyEnemy ? 20 : 0) -
        nearCityPenalty;
    return CommandRanking(CandidatePriority.opening, score);
  }

  int _escortImprovement({
    required MoveUnitCommand command,
    required GameUnit escort,
    required HexCoordinate founderHex,
    required HexCoordinate focus,
    required HexCoordinate commandTarget,
  }) {
    final founderDistanceBefore = HexDistance.between(
      HexCoordinate(col: escort.col, row: escort.row),
      founderHex,
    );
    final founderDistanceAfter = HexDistance.between(commandTarget, founderHex);
    final focusImprovement = distanceImprovement(
      fromCol: escort.col,
      fromRow: escort.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: focus,
    );
    final founderImprovement = founderDistanceBefore - founderDistanceAfter;
    return focusImprovement > founderImprovement
        ? focusImprovement
        : founderImprovement;
  }

  bool _canStayNearFounderOrFocus(
    HexCoordinate commandTarget,
    HexCoordinate founderHex,
    HexCoordinate focus,
  ) {
    if (HexDistance.between(commandTarget, founderHex) <= 2) return true;
    return HexDistance.between(commandTarget, focus) <= 2;
  }
}
