part of 'city_production_reducer.dart';

GameStateTransition _startWonderProduction(
  GameState state,
  StartWonderCommand command,
  MapTileLookup mapTiles, {
  required GameCommandContext context,
  required GameRuleset ruleset,
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
    ruleset: ruleset.wonders,
  );
  if (!availability.isAvailable) return GameStateTransition(state: state);

  final updatedCity = CityProductionReducer._queueProduction(
    city,
    WonderProductionTarget(command.wonderType),
    ruleset,
    context.paceBalance,
  );

  return CityProductionReducer._finishQueuedProductionUpdate(
    state,
    updatedCity: updatedCity,
    cityIndex: target.index,
    cityId: command.cityId,
    mapTiles: mapTiles,
    ruleset: ruleset,
    paceBalance: context.paceBalance,
  );
}
