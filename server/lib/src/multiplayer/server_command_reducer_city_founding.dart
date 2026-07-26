part of 'server_command_reducer.dart';

extension _ServerCityFoundingCommandReducer on ServerCommandReducer {
  _CommandApplication _applyCityFoundingCommand({
    required CanonicalGameSnapshot snapshot,
    required FoundCityCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final domain = snapshot.domain;
    final result = CityFoundingCommandResolver.foundCity(
      units: domain.units,
      cities: domain.cities,
      cityFoundingDraft: snapshot.interaction.cityFoundingDraft,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _cityFoundingApplication(snapshot: snapshot, result: result);
  }

  _CommandApplication _cityFoundingApplication({
    required CanonicalGameSnapshot snapshot,
    required CityFoundingCommandResult result,
  }) {
    if (!result.accepted) {
      return _CommandApplication.reject(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final domain = snapshot.domain;
    final interaction = snapshot.interaction;
    final unitsChanged = !identical(result.units, domain.units);
    final interactionChanged =
        result.cityFoundingDraft != interaction.cityFoundingDraft;
    final nextInteraction = interactionChanged
        ? interaction.copyWith(cityFoundingDraft: result.cityFoundingDraft)
        : interaction;
    return _CommandApplication.accept(
      snapshot: _snapshotWithChanges(
        snapshot,
        domain: unitsChanged ? domain.copyWith(units: result.units) : null,
        interaction: interactionChanged ? nextInteraction : null,
      ),
    );
  }
}
