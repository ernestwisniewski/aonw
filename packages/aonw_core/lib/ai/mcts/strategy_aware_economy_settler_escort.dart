part of 'strategy_aware_economy_ranker.dart';

final class _ActiveSettlerEscortProductionPolicy {
  const _ActiveSettlerEscortProductionPolicy();

  bool needsEscortProduction(GameView view, AiContext context) {
    final founders = _availableFounders(view);
    return view.ownCities.isNotEmpty &&
        founders.isNotEmpty &&
        !_hasEnoughMilitaryForFounders(view, context, founders.length) &&
        founders.any((founder) => _founderNeedsEscort(founder, view, context));
  }

  Iterable<GameUnit> _availableFounders(GameView view) {
    return view.ownUnits.where(
      (unit) =>
          CityFoundingRules.canFoundCityWith(unit) &&
          !unit.isWorking &&
          unit.queuedPath == null,
    );
  }

  bool _hasEnoughMilitaryForFounders(
    GameView view,
    AiContext context,
    int founderCount,
  ) {
    return _military.countWithQueues(view, context) >=
        view.ownCities.length + founderCount;
  }

  bool _founderNeedsEscort(GameUnit founder, GameView view, AiContext context) {
    final origin = HexCoordinate(col: founder.col, row: founder.row);
    if (ownMilitaryNear(view, origin.col, origin.row, 2, context)) {
      return false;
    }
    return visibleMilitaryNear(view, origin.col, origin.row, 3) ||
        _assignedDestinationHasVisibleMilitary(founder, view, context) ||
        _rememberedEnemyCityThreatens(view, origin);
  }

  bool _assignedDestinationHasVisibleMilitary(
    GameUnit founder,
    GameView view,
    AiContext context,
  ) {
    final assignment = context.strategicPlan?.settlerAssignments[founder.id];
    return assignment != null &&
        visibleMilitaryNear(view, assignment.col, assignment.row, 3);
  }

  bool _rememberedEnemyCityThreatens(GameView view, HexCoordinate origin) {
    final nearestEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: origin,
        );
    return nearestEnemyCity != null && nearestEnemyCity <= 3;
  }
}
