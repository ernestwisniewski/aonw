part of 'production_scorer.dart';

bool _canProduceUnit(
  GameView view, {
  required GameCity city,
  required GameUnitType unitType,
  required int reservedSupply,
  required AiProductionScoringCache cache,
}) {
  final research = cache.research;
  final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
    playerId: view.forPlayerId,
    unitType: unitType,
    research: research,
    ruleset: view.ruleset.technology,
  );
  final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
    playerId: view.forPlayerId,
    unitType: unitType,
    cities: view.ownCities,
    mapTiles: view.mapData,
    ruleset: view.ruleset.city,
    research: research,
    resourceTradeAgreements: view.resourceTradeAgreements,
  );
  if (!CityProductionRules.canProduceUnit(
    unitType,
    ruleset: view.ruleset.city,
    technologyUnlocked: technologyUnlocked,
    requirementsMet: requirementsMet,
  )) {
    return false;
  }
  if (!CityUnitProductionRules.canProduceInCity(
    city: city,
    unitType: unitType,
    mapTiles: view.mapData,
  )) {
    return false;
  }
  return CityUnitSupplyRules.canQueueUnit(
    playerId: view.forPlayerId,
    unitType: unitType,
    cities: view.ownCities,
    units: view.ownUnits,
    artifacts: view.artifacts,
    fieldImprovements: view.ownImprovements,
    mapView: view.mapData,
    cityRuleset: view.ruleset.city,
    research: research,
    technologyRuleset: view.ruleset.technology,
    replacingCityId: city.id,
    reservedSupply: reservedSupply,
  );
}

bool _canBuild(
  GameView view, {
  required GameCity city,
  required CityBuildingType buildingType,
  required AiProductionScoringCache cache,
}) {
  final research = cache.research;
  final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
    playerId: view.forPlayerId,
    buildingType: buildingType,
    research: research,
    ruleset: view.ruleset.technology,
  );
  final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
    city: city,
    buildingType: buildingType,
    mapTiles: view.mapData,
    ruleset: view.ruleset.city,
    research: research,
  );
  return CityProductionRules.canBuild(
    city.buildings,
    buildingType,
    ruleset: view.ruleset.city,
    technologyUnlocked: technologyUnlocked,
    requirementsMet: requirementsMet,
  );
}
