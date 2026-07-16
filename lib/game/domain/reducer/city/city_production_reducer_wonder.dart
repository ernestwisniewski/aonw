part of 'city_production_reducer.dart';

GameStateTransition _startWonderProduction(
  GameState state,
  StartWonderCommand command,
  MapTileLookup mapTiles, {
  required GameCommandContext context,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required StabilityRuleset stabilityRuleset,
  required WonderRuleset wonderRuleset,
}) {
  final target = CityProductionReducer._controlledCityTarget(
    state,
    command.cityId,
    context,
  );
  if (target == null) return GameStateTransition(state: state);
  final city = target.city;

  final availability = WonderAvailabilityPolicy.availabilityFor(
    city: city,
    wonderType: command.wonderType,
    cities: state.cities,
    registry: state.wonderRegistry,
    research: state.research,
    mapTiles: mapTiles,
    ruleset: wonderRuleset,
  );
  if (!availability.isAvailable) return GameStateTransition(state: state);

  final updatedCity = CityProductionReducer._queueProduction(
    city,
    WonderProductionTarget(command.wonderType),
    cityRuleset,
    context.paceBalance,
    wonderRuleset: wonderRuleset,
  );

  return CityProductionReducer._finishQueuedProductionUpdate(
    state,
    updatedCity: updatedCity,
    cityIndex: target.index,
    cityId: command.cityId,
    mapTiles: mapTiles,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    stabilityRuleset: stabilityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: context.paceBalance,
  );
}
