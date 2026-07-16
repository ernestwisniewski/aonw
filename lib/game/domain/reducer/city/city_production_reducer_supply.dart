part of 'city_production_reducer.dart';

bool _canQueueCityUnit({
  required GameState state,
  required GameCity city,
  required GameUnitType unitType,
  required MapData mapData,
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
    mapView: mapData,
    cityRuleset: cityRuleset,
    research: state.research,
    technologyRuleset: technologyRuleset,
    replacingCityId: city.id,
  );
}
