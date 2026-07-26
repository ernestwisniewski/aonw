part of 'server_command_reducer.dart';

extension _ServerCommandReducerMovement on ServerCommandReducer {
  _CommandApplication _applyMoveUnit({
    required CanonicalGameSnapshot snapshot,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapView,
  }) {
    final domain = snapshot.domain;
    final result = const MovementCommandResolver().resolve(
      state: MovementCommandState(
        units: domain.units,
        cities: domain.cities,
        fogOfWar: domain.fogOfWar,
        diplomacy: domain.diplomacy,
        playerIds: domain.participants.map((participant) => participant.id),
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapView,
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
    final nextDomain = unitsChanged || fogChanged || diplomacyChanged
        ? domain.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            diplomacy: diplomacyChanged ? result.diplomacy : null,
          )
        : domain;
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: identical(nextDomain, domain) ? null : nextDomain,
      events: result.events,
      movementExecutions: [?result.execution],
    );
  }
}
