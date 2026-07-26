part of 'server_command_reducer.dart';

extension _ServerCommandReducerAutoExplore on ServerCommandReducer {
  _CommandApplication _applyAutoExplore({
    required GameSave save,
    required PersistentGameState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapView,
  }) {
    final result = const AutoExploreCommandResolver().resolve(
      state: AutoExploreCommandState(
        movement: MovementCommandState(
          units: state.units,
          cities: state.cities,
          fogOfWar: state.fogOfWar,
          diplomacy: state.runtimeState.diplomacy,
          playerIds: state.knownPlayerIds,
        ),
        interaction: _persistedInteraction(state),
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapView,
      phase: AutoExploreCommandPhase.direct,
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
    final runtimeState = _autoExploreRuntimeState(state.runtimeState, result);
    final runtimeChanged = !identical(runtimeState, state.runtimeState);
    final nextState = unitsChanged || fogChanged || runtimeChanged
        ? state.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            runtimeState: runtimeChanged ? runtimeState : null,
          )
        : state;
    return _applicationFrom(
      save: save,
      accepted: true,
      state: nextState,
      events: result.events,
      movementExecutions: [?result.execution],
    );
  }
}

GameRuntimeState _autoExploreRuntimeState(
  GameRuntimeState input,
  AutoExploreCommandResult result,
) {
  var current = input;
  if (result.interaction.cityFoundingDraft != input.cityFoundingDraft) {
    current = current.copyWith(
      cityFoundingDraft: result.interaction.cityFoundingDraft,
    );
  }
  if (result.interaction.pendingAction != input.pendingAction) {
    current = current.copyWith(pendingAction: result.interaction.pendingAction);
  }
  if (!identical(result.diplomacy, input.diplomacy)) {
    current = current.copyWith(diplomacy: result.diplomacy);
  }
  return current;
}
