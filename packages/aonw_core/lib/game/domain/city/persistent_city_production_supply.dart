part of 'persistent_city_production_resolver.dart';

bool _canQueuePersistentCityUnit({
  required PersistentGameState state,
  required GameCity city,
  required GameUnitType unitType,
  required MapReadView mapView,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
}) {
  return CityUnitSupplyRules.canQueueUnit(
    playerId: city.ownerPlayerId,
    unitType: unitType,
    cities: state.cities,
    units: state.units,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    mapView: mapView,
    cityRuleset: cityRuleset,
    research: state.research,
    technologyRuleset: technologyRuleset,
    replacingCityId: city.id,
  );
}
