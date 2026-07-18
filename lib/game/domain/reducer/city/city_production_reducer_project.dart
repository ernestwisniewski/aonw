part of 'city_production_reducer.dart';

GameStateTransition _startCityProject(
  GameState state,
  StartCityProjectCommand command,
  MapTileLookup mapTiles, {
  required GameCommandContext context,
  required GameRuleset ruleset,
}) {
  final cities = state.cities;
  final cityIndex = cities.indexWhere((city) => city.id == command.cityId);
  if (cityIndex == -1) return GameStateTransition(state: state);

  final city = cities[cityIndex];
  if (!context.canControlCity(state, city)) {
    return GameStateTransition(state: state);
  }

  final result = CityProductionCommandResolver.startCityProject(
    cities: cities,
    command: command,
    actorPlayerId: city.ownerPlayerId,
    cityRuleset: ruleset.city,
    paceBalance: context.paceBalance,
  );
  if (!result.accepted) return GameStateTransition(state: state);

  final cityIsSelected =
      state.selection?.type == GameSelectionType.city &&
      state.selection?.city?.id == command.cityId;
  if (identical(result.cities, cities) && !cityIsSelected) {
    return GameStateTransition(state: state);
  }

  final updatedCity = result.cities[cityIndex];
  final next = identical(result.cities, cities)
      ? state
      : state.copyWith(cities: result.cities);
  return GameStateTransition(
    state: CityProductionReducer._refreshCitySelectionIfSelected(
      next,
      cityId: command.cityId,
      city: updatedCity,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    ),
  );
}
