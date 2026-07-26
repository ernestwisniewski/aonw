part of 'server_command_reducer.dart';

extension _ServerCommandReducerDetachment on ServerCommandReducer {
  _CommandApplication _applyDetachTroopCommand({
    required CanonicalGameSnapshot snapshot,
    required DetachTroopCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final domain = snapshot.domain;
    final result = DetachTroopResolver.detachTroop(
      units: domain.units,
      cities: domain.cities,
      fogOfWar: domain.fogOfWar,
      diplomacy: domain.diplomacy,
      playerIds: domain.participants.map((participant) => participant.id),
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (!result.accepted) {
      return _CommandApplication.reject(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }

    final unitsChanged = !identical(result.units, domain.units);
    final fogChanged = !identical(result.fogOfWar, domain.fogOfWar);
    final diplomacyChanged = !identical(result.diplomacy, domain.diplomacy);
    return _CommandApplication.accept(
      snapshot: unitsChanged || fogChanged || diplomacyChanged
          ? snapshot.copyWith(
              domain: domain.copyWith(
                units: unitsChanged ? result.units : null,
                fogOfWar: fogChanged ? result.fogOfWar : null,
                diplomacy: diplomacyChanged ? result.diplomacy : null,
              ),
            )
          : snapshot,
    );
  }
}
