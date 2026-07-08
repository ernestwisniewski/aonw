part of 'production_scoring_cache.dart';

CityEconomyBreakdown _economyFor(
  AiProductionScoringCache cache,
  GameCity city,
) {
  return cache._economyByCityId.putIfAbsent(city.id, () {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      cache.view.mapData,
      fieldImprovements: cache.view.ownImprovements,
      units: cache.view.ownUnits,
      ruleset: cache.view.ruleset.city,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: cache.view.mapData,
      ruleset: cache.view.ruleset.city,
      paceBalance: cache.view.ruleset.paceBalance,
      technologyEffects: cache.technologyEffects,
      cities: cache.view.ownCities,
      wonderRegistry: cache.view.wonderRegistry,
      wonderRuleset: cache.view.ruleset.wonders,
    );
  });
}
