part of 'basic_strategy_founding_move_planner.dart';

final class _FounderSafetyPolicy {
  const _FounderSafetyPolicy(this.militaryAwareness);

  final BasicStrategyMilitaryAwareness militaryAwareness;

  int? visibleEnemyMilitaryDistance(HexCoordinate hex, GameView view) {
    return militaryAwareness.nearestVisibleEnemyMilitaryDistance(hex, view);
  }

  bool hasEscort(HexCoordinate hex, GameView view) {
    return militaryAwareness.ownMilitaryNear(hex, view, 2);
  }

  bool shouldRetreatFrom(int? currentThreat, GameView view) {
    if (currentThreat == null || currentThreat > 2) return false;
    return view.ownCities.isNotEmpty || currentThreat <= 1;
  }

  bool isThreatened(HexCoordinate origin, GameView view) {
    final nearestEnemy = visibleEnemyMilitaryDistance(origin, view);
    if (view.ownCities.isEmpty) {
      return nearestEnemy != null && nearestEnemy <= 1;
    }
    if (nearestEnemy != null && nearestEnemy <= 2) return true;

    final nearestEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: origin,
        );
    return nearestEnemyCity != null && nearestEnemyCity <= 1;
  }

  bool canEnter(HexCoordinate target, GameView view) {
    if (view.ownCities.isEmpty) return _canEnterBeforeFirstCity(target, view);
    if (AiCityFoundingSafety.isKnownEnemyCityHex(view: view, hex: target)) {
      return false;
    }

    final escorted = hasEscort(target, view);
    final nearestEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: target,
        );
    if (_knownEnemyCityBlocksFounder(
      nearestEnemyCity: nearestEnemyCity,
      escorted: escorted,
    )) {
      return false;
    }

    final nearestEnemy = visibleEnemyMilitaryDistance(target, view);
    if (nearestEnemy == null) return true;
    if (nearestEnemy <= 1) return false;
    if (nearestEnemy > 2) return true;
    return escorted;
  }

  bool shouldWaitForEscort({
    required HexCoordinate current,
    required HexCoordinate target,
    required GameView view,
    bool requireDestinationEscort = false,
  }) {
    if (view.ownCities.isEmpty) return false;
    if (_escortAlreadyCoversMove(
      current: current,
      target: target,
      view: view,
      requireDestinationEscort: requireDestinationEscort,
    )) {
      return false;
    }
    if (_moveHeadsBackTowardOwnSupport(
      current: current,
      target: target,
      view: view,
    )) {
      return false;
    }

    final currentEnemy = visibleEnemyMilitaryDistance(current, view);
    final targetEnemy = visibleEnemyMilitaryDistance(target, view);
    if (_hasCloseThreat(currentEnemy, targetEnemy)) {
      return !_largeEmpireReducesThreat(
        view: view,
        currentEnemy: currentEnemy,
        targetEnemy: targetEnemy,
      );
    }

    final currentEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: current,
        );
    final targetEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: target,
        );
    if (_largeEmpireReducesThreat(
      view: view,
      currentEnemy: currentEnemyCity,
      targetEnemy: targetEnemyCity,
    )) {
      return false;
    }
    return _hasCloseThreat(currentEnemyCity, targetEnemyCity);
  }

  int nearestOwnCityDistance(HexCoordinate origin, GameView view) {
    var nearest = _unreachableDistance;
    for (final city in view.ownCities) {
      final distance = HexDistance.between(origin, city.center.toCoordinate());
      if (distance < nearest) nearest = distance;
    }
    if (nearest != _unreachableDistance) return nearest;

    for (final unit in view.ownUnits) {
      if (CityFoundingRules.canFoundCityWith(unit)) continue;
      final distance = HexDistance.between(origin, unit.hex);
      if (distance < nearest) nearest = distance;
    }
    return nearest == _unreachableDistance ? 0 : nearest;
  }

  bool _canEnterBeforeFirstCity(HexCoordinate target, GameView view) {
    final nearestEnemy = visibleEnemyMilitaryDistance(target, view);
    return nearestEnemy == null || nearestEnemy > 1;
  }

  bool _knownEnemyCityBlocksFounder({
    required int? nearestEnemyCity,
    required bool escorted,
  }) {
    if (nearestEnemyCity == null) return false;
    if (nearestEnemyCity <= 1) return true;
    return nearestEnemyCity <= 2 && !escorted;
  }

  bool _escortAlreadyCoversMove({
    required HexCoordinate current,
    required HexCoordinate target,
    required GameView view,
    required bool requireDestinationEscort,
  }) {
    final targetEscorted = hasEscort(target, view);
    final currentEscorted = hasEscort(current, view);
    return targetEscorted || (currentEscorted && !requireDestinationEscort);
  }

  bool _moveHeadsBackTowardOwnSupport({
    required HexCoordinate current,
    required HexCoordinate target,
    required GameView view,
  }) {
    final currentOwnCityDistance = nearestOwnCityDistance(current, view);
    final targetOwnCityDistance = nearestOwnCityDistance(target, view);
    return targetOwnCityDistance < currentOwnCityDistance;
  }

  bool _hasCloseThreat(int? currentEnemy, int? targetEnemy) {
    return (currentEnemy != null && currentEnemy <= 3) ||
        (targetEnemy != null && targetEnemy <= 3);
  }

  bool _largeEmpireReducesThreat({
    required GameView view,
    required int? currentEnemy,
    required int? targetEnemy,
  }) {
    return view.ownCities.length >= 2 &&
        _isThreatReducedByMove(
          currentEnemy: currentEnemy,
          targetEnemy: targetEnemy,
        );
  }

  bool _isThreatReducedByMove({
    required int? currentEnemy,
    required int? targetEnemy,
  }) {
    if (currentEnemy == null || currentEnemy > 3) return false;
    final targetDistance = targetEnemy ?? _veryFarEnemyDistance;
    return targetDistance > currentEnemy && targetDistance > 2;
  }
}
