part of 'basic_strategy_founding_move_planner.dart';

extension _BasicStrategyFoundingMoveQueries
    on BasicStrategyFoundingMovePlanner {
  double _foundingFrontierScore(
    HexCoordinate origin,
    GameView view, {
    bool citySiteDiscoveryFocus = false,
  }) {
    final nearestCityDistance = _nearestOwnCityDistance(origin, view);
    final spacingScore =
        nearestCityDistance >= CityFoundingRules.minimumCenterDistance
        ? 18.0 + nearestCityDistance * 0.5
        : nearestCityDistance * 4.0;
    return frontierScorer.score(
          view: view,
          origin: origin,
          citySiteDiscoveryFocus: citySiteDiscoveryFocus,
        ) +
        spacingScore;
  }

  bool _isFounderPathSafe({
    required UnitMovementPlan plan,
    required GameView view,
  }) {
    return plan.steps
        .skip(1)
        .map((step) => step.hex)
        .every((target) => isFounderMoveSafe(target: target, view: view));
  }

  UnitMovementStep? _furthestSafeReachableStep({
    required UnitMovementPlan plan,
    required GameView view,
    required GameUnit unit,
  }) {
    final reachable = plan.reachableSteps.reversed;
    for (final step in reachable) {
      if (unit.occupies(step.col, step.row)) continue;
      if (isFounderMoveSafe(target: step.hex, view: view)) {
        return step;
      }
    }
    return null;
  }

  Iterable<_ReachableFounderMove> _reachableImmediateMoves({
    required GameUnit unit,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
    bool requireVisibleDestination = false,
  }) sync* {
    for (final tile in view.mapData.tileViews) {
      if (unit.occupies(tile.col, tile.row)) continue;
      if (occupied.contains(_key(tile.col, tile.row))) continue;
      if (requireVisibleDestination &&
          !view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        continue;
      }

      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null || !_canUseImmediatePlan(unit: unit, plan: plan)) {
        continue;
      }

      yield _ReachableFounderMove(
        tile: tile,
        target: HexCoordinate.fromTile(tile),
        plan: plan,
      );
    }
  }

  _FounderRetreatCandidate? _retreatCandidateFor({
    required _ReachableFounderMove move,
    required int currentThreat,
    required GameView view,
  }) {
    final targetThreat = _safetyPolicy.visibleEnemyMilitaryDistance(
      move.target,
      view,
    );
    if (targetThreat != null && targetThreat <= 1) return null;
    if (targetThreat != null && targetThreat <= currentThreat) return null;

    final nearestEnemyDistance = targetThreat ?? _veryFarEnemyDistance;
    final minimumRetreatDistance = currentThreat <= 1 ? 4 : 5;
    if (targetThreat != null &&
        targetThreat < minimumRetreatDistance &&
        view.ownCities.length < 2) {
      return null;
    }

    return _FounderRetreatCandidate(
      move: move,
      nearestEnemyDistance: nearestEnemyDistance,
      nearestOwnCityDistance: _nearestOwnCityDistance(move.target, view),
      escorted: _safetyPolicy.hasEscort(move.target, view),
    );
  }

  bool _canUseImmediatePlan({
    required GameUnit unit,
    required UnitMovementPlan plan,
  }) {
    return plan.totalCost <= unit.movementPoints &&
        UnitMovementFeasibility.canEventuallyTraverse(unit: unit, plan: plan);
  }

  bool _canEventuallyUsePlan({
    required GameUnit unit,
    required UnitMovementPlan plan,
  }) {
    return UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
    );
  }

  int _nearestOwnCityDistance(HexCoordinate origin, GameView view) {
    return _safetyPolicy.nearestOwnCityDistance(origin, view);
  }

  bool _needsFounderLedCitySiteDiscovery({
    required GameView view,
    required AiContext context,
  }) {
    return AiFrontierExplorationScorer.needsCitySiteDiscovery(
          view: view,
          plan: context.strategicPlan,
        ) &&
        !_hasAvailableReconFrontierExplorer(view);
  }

  bool _hasAvailableReconFrontierExplorer(GameView view) {
    for (final unit in view.ownUnits) {
      if (AiUnitRoles.isReconUnit(unit) && unit.isReadyToAct) {
        return true;
      }
    }
    return false;
  }

  String _key(int col, int row) => '$col:$row';
}
