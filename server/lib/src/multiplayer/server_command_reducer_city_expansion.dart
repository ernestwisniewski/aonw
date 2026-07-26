part of 'server_command_reducer.dart';

extension _ServerCommandReducerCityExpansion on ServerCommandReducer {
  _CommandApplication _applySelectCityExpansionHexCommand({
    required CanonicalGameSnapshot snapshot,
    required SelectCityExpansionHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final domain = snapshot.domain;
    final result = CityExpansionCommandResolver.selectExpansionHex(
      cities: domain.cities,
      research: domain.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
    );
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: identical(result.cities, domain.cities)
          ? null
          : domain.copyWith(cities: result.cities),
    );
  }
}
