part of 'server_command_reducer.dart';

extension _ServerCityCommandReducer on ServerCommandReducer {
  _CommandApplication _applyToggleWorkedHexCommand({
    required GameSave save,
    required PersistentGameState state,
    required ToggleWorkedHexCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    final result = ToggleWorkedHexResolver.toggleWorkedHex(
      cities: state.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: ruleset.city,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: result.accepted ? state.copyWith(cities: result.cities) : state,
      reason: result.reason,
    );
  }
}
