part of 'server_command_reducer.dart';

extension _ServerCommandReducerMovement on ServerCommandReducer {
  _CommandApplication _applyMoveUnit({
    required GameSave save,
    required PersistentGameState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapView,
  }) {
    final result = const MovementCommandResolver().resolve(
      state: MovementCommandState(
        units: state.units,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
        diplomacy: state.runtimeState.diplomacy,
        playerIds: state.knownPlayerIds,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapView,
    );
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }

    final unitsChanged = !identical(result.units, state.units);
    final fogChanged = !identical(result.fogOfWar, state.fogOfWar);
    final diplomacyChanged = !identical(
      result.diplomacy,
      state.runtimeState.diplomacy,
    );
    final runtimeState = diplomacyChanged
        ? state.runtimeState.copyWith(diplomacy: result.diplomacy)
        : state.runtimeState;
    final nextState = unitsChanged || fogChanged || diplomacyChanged
        ? state.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            runtimeState: diplomacyChanged ? runtimeState : null,
          )
        : state;
    return _applicationFrom(
      save: save,
      accepted: true,
      state: nextState,
      events: result.events,
    );
  }
}
