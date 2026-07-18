part of 'city_production_reducer.dart';

GameStateTransition _rushCityProduction(
  GameState state,
  RushProductionCommand command,
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
  final result = RushProductionCommandResolver.resolve(
    cities: state.cities,
    units: state.units,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    playerGold: state.playerGold,
    playerStabilityNet: state.playerStabilityNet,
    research: state.research,
    wonderRegistry: state.wonderRegistry,
    command: command,
    actorPlayerId: target.city.ownerPlayerId,
    mapTiles: mapTiles,
    cityRuleset: ruleset.city,
    technologyRuleset: ruleset.technology,
    stabilityRuleset: ruleset.stability,
    wonderRuleset: ruleset.wonders,
    paceBalance: context.paceBalance,
  );
  if (!result.accepted) return GameStateTransition(state: state);

  final refreshedCity = result.cities[target.index];
  var next = state.copyWith(
    cities: result.cities,
    units: result.units,
    playerGold: result.playerGold,
    research: result.research,
    wonderRegistry: result.wonderRegistry,
  );

  next = CityProductionReducer._refreshCitySelectionIfSelected(
    next,
    cityId: command.cityId,
    city: refreshedCity,
    mapTiles: mapTiles,
    ruleset: ruleset,
    paceBalance: context.paceBalance,
  );

  return GameStateTransition(state: next, events: result.events);
}
