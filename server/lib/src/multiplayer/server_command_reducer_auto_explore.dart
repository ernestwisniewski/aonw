part of 'server_command_reducer.dart';

extension _ServerCommandReducerAutoExplore on ServerCommandReducer {
  _CommandApplication _applyAutoExplore({
    required CanonicalGameSnapshot snapshot,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapView,
  }) {
    final domain = snapshot.domain;
    final interaction = snapshot.interaction;
    final result = const AutoExploreCommandResolver().resolve(
      state: AutoExploreCommandState(
        movement: MovementCommandState(
          units: domain.units,
          cities: domain.cities,
          fogOfWar: domain.fogOfWar,
          diplomacy: domain.diplomacy,
          playerIds: domain.participants.map((player) => player.id),
        ),
        interaction: interaction,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapView,
      phase: AutoExploreCommandPhase.direct,
    );
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }

    final unitsChanged = !identical(result.units, domain.units);
    final fogChanged = !identical(result.fogOfWar, domain.fogOfWar);
    final diplomacyChanged = !identical(result.diplomacy, domain.diplomacy);
    final domainChanged = unitsChanged || fogChanged || diplomacyChanged;
    final nextDomain = domainChanged
        ? domain.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            diplomacy: diplomacyChanged ? result.diplomacy : null,
          )
        : domain;
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: domainChanged ? nextDomain : null,
      interaction: _interactionReplacement(interaction, result.interaction),
      events: result.events,
      movementExecutions: [?result.execution],
    );
  }
}
