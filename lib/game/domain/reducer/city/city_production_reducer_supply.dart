part of 'city_production_reducer.dart';

bool _canQueueCityUnit({
  required GameState state,
  required GameCity city,
  required GameUnitType unitType,
  required MapReadView mapView,
  required GameRuleset ruleset,
}) {
  return CityUnitSupplyRules.canQueueUnit(
    playerId: city.ownerPlayerId,
    unitType: unitType,
    cities: state.cities,
    units: state.units,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    mapView: mapView,
    cityRuleset: ruleset.city,
    research: state.research,
    technologyRuleset: ruleset.technology,
    replacingCityId: city.id,
  );
}
