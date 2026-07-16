part of 'persistent_city_production_resolver.dart';

int _rushProductionPerTurn({
  required PersistentGameState state,
  required GameCity city,
  required CityProductionTarget target,
  required MapTileLookup mapTiles,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required StabilityRuleset stabilityRuleset,
  required WonderRuleset wonderRuleset,
  required PaceBalance paceBalance,
}) {
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: city.ownerPlayerId,
    research: state.research,
    ruleset: technologyRuleset,
  );
  final economy = _rushProductionEconomy(
    state: state,
    city: city,
    mapTiles: mapTiles,
    cityRuleset: cityRuleset,
    stabilityRuleset: stabilityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
    technologyEffects: technologyEffects,
  );
  var productionPerTurn = CityProductionRules.productionPerTurn(
    economy.netYield.production,
  );
  if (target is UnitProductionTarget) {
    productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
      productionPerTurn,
      effects: technologyEffects,
    );
  }
  return CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: productionPerTurn,
    target: target,
    specialization: city.specialization,
  );
}

CityEconomyBreakdown _rushProductionEconomy({
  required PersistentGameState state,
  required GameCity city,
  required MapTileLookup mapTiles,
  required CityRuleset cityRuleset,
  required StabilityRuleset stabilityRuleset,
  required WonderRuleset wonderRuleset,
  required PaceBalance paceBalance,
  required TechnologyEffectSummary technologyEffects,
}) {
  final cityYield = CityYieldCalculator.totalFor(
    city,
    mapTiles,
    fieldImprovements: state.fieldImprovements,
    units: state.units,
    artifacts: state.artifacts,
    ruleset: cityRuleset,
  );
  return CityEconomyBreakdown.from(
    city: city,
    tileYield: cityYield,
    mapTiles: mapTiles,
    ruleset: cityRuleset,
    technologyEffects: technologyEffects,
    paceBalance: paceBalance,
    cities: state.cities,
    wonderRegistry: state.wonderRegistry,
    wonderRuleset: wonderRuleset,
    stabilityModifier: StabilityPolicy.modifierForNet(
      state.playerStabilityNet[city.ownerPlayerId] ?? 0,
      ruleset: stabilityRuleset,
    ),
  );
}
