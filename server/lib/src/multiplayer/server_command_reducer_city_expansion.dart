part of 'server_command_reducer.dart';

extension _ServerCommandReducerCityExpansion on ServerCommandReducer {
  _CommandApplication _applySelectCityExpansionHexCommand({
    required GameSave save,
    required PersistentGameState state,
    required SelectCityExpansionHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final result = CityExpansionCommandResolver.selectExpansionHex(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
    );
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return _applicationFrom(
      save: save,
      accepted: true,
      state: identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
    );
  }
}
