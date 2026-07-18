part of 'server_command_reducer.dart';

extension _ServerCityFoundingCommandReducer on ServerCommandReducer {
  _CommandApplication _applyCityFoundingCommand({
    required GameSave save,
    required PersistentGameState state,
    required FoundCityCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = CityFoundingCommandResolver.foundCity(
      units: state.units,
      cities: state.cities,
      cityFoundingDraft: state.runtimeState.cityFoundingDraft,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _cityFoundingApplication(save: save, state: state, result: result);
  }

  _CommandApplication _cityFoundingApplication({
    required GameSave save,
    required PersistentGameState state,
    required CityFoundingCommandResult result,
  }) {
    if (!result.accepted) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final runtimeState =
        identical(
          result.cityFoundingDraft,
          state.runtimeState.cityFoundingDraft,
        )
        ? null
        : state.runtimeState.copyWith(
            cityFoundingDraft: result.cityFoundingDraft,
          );
    return _CommandApplication.accept(
      save: save,
      state: state.copyWith(units: result.units, runtimeState: runtimeState),
    );
  }
}
