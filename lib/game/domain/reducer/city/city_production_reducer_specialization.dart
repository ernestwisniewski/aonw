part of 'city_production_reducer.dart';

GameStateTransition _setCitySpecialization(
  GameState state,
  SetCitySpecializationCommand command,
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

  final result = CityProductionCommandResolver.setCitySpecialization(
    cities: cities,
    research: state.research,
    command: command,
    actorPlayerId: city.ownerPlayerId,
  );
  if (!result.accepted) return GameStateTransition(state: state);

  final next = state.copyWith(cities: result.cities);
  return GameStateTransition(
    state: CityProductionReducer._refreshCitySelectionIfSelected(
      next,
      cityId: command.cityId,
      city: result.cities[cityIndex],
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    ),
  );
}
