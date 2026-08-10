part of 'basic_strategy_founding_planner.dart';

extension _BasicStrategyFoundingRules on BasicStrategyFoundingPlanner {
  bool _shouldFoundOpeningSite({
    required GameView view,
    required AiCitySiteScore? currentSite,
  }) {
    if (view.ownCities.isNotEmpty || currentSite == null) return false;
    return currentSite.score >= 0;
  }

  int _secondCityPressureTurn(AiContext context) {
    final raw =
        20 *
        context.ruleset.paceBalance.unitProductionCostMultiplier *
        context.civProfile.expansionDistance;
    return raw.round().clamp(14, 24).toInt();
  }

  int _thirdCityPressureTurn(AiContext context) {
    final raw =
        28 *
        context.ruleset.paceBalance.unitProductionCostMultiplier *
        context.civProfile.expansionDistance;
    return raw.round().clamp(24, 36).toInt();
  }

  bool _canFoundSiteNow({
    required GameView view,
    required AiCitySiteScore? site,
  }) {
    if (site == null || !site.hasKnownExclusionZone) return false;
    return movePlanner.isFounderMoveSafe(
      target: site.center.toCoordinate(),
      view: view,
    );
  }

  GameCity _plannedCityFor(GameUnit founder, AiCitySiteScore site) {
    return GameCity.snapshot(
      id: 'planned_${founder.id}_${site.center.col}_${site.center.row}',
      ownerPlayerId: founder.ownerPlayerId,
      name: 'Planned',
      center: site.center,
      controlledHexes: site.controlledHexes,
    );
  }

  List<GameCity> _knownCities(GameView view) {
    final byId = <String, GameCity>{};
    for (final city in view.ownCities) {
      byId[city.id] = city;
    }
    for (final city in view.rememberedEnemyCities) {
      byId[city.id] = city;
    }
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  String _key(int col, int row) => '$col:$row';
}
