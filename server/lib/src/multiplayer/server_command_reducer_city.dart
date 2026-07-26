part of 'server_command_reducer.dart';

extension _ServerCityCommandReducer on ServerCommandReducer {
  _CommandApplication _applyToggleWorkedHexCommand({
    required CanonicalGameSnapshot snapshot,
    required ToggleWorkedHexCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    final domain = snapshot.domain;
    final result = ToggleWorkedHexResolver.toggleWorkedHex(
      cities: domain.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: ruleset.city,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: result.accepted && !identical(result.cities, domain.cities)
          ? domain.copyWith(cities: result.cities)
          : null,
      reason: result.reason,
    );
  }
}
