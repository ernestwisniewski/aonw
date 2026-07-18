part of 'server_command_reducer.dart';

extension _ServerCommandReducerDetachment on ServerCommandReducer {
  _CommandApplication _applyDetachTroopCommand({
    required GameSave save,
    required PersistentGameState state,
    required DetachTroopCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = DetachTroopResolver.detachTroop(
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.runtimeState.diplomacy,
      playerIds: state.knownPlayerIds,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (!result.accepted) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: result.reason ?? 'command_rejected',
      );
    }

    return _CommandApplication.accept(
      save: save,
      state: state.copyWith(
        units: result.units,
        fogOfWar: result.fogOfWar,
        runtimeState: state.runtimeState.copyWith(diplomacy: result.diplomacy),
      ),
    );
  }
}
