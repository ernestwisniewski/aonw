part of 'server_command_reducer.dart';

extension _ServerCommandReducerUnitAction on ServerCommandReducer {
  _CommandApplication _applyCancelUnitAction(
    GameSave save,
    PersistentGameState state,
    CancelUnitActionCommand command,
    String actorPlayerId,
  ) {
    return _applyUnitActionResult(
      save,
      state,
      UnitActionCommandResolver.cancelUnitAction(
        units: state.units,
        artifacts: state.artifacts,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applySkipUnitTurn(
    GameSave save,
    PersistentGameState state,
    SkipUnitTurnCommand command,
    String actorPlayerId,
  ) {
    return _applyUnitActionResult(
      save,
      state,
      UnitActionCommandResolver.skipUnitTurn(
        units: state.units,
        artifacts: state.artifacts,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyFortifyUnit(
    GameSave save,
    PersistentGameState state,
    FortifyUnitCommand command,
    String actorPlayerId,
  ) {
    return _applyUnitActionResult(
      save,
      state,
      UnitActionCommandResolver.fortifyUnit(
        units: state.units,
        artifacts: state.artifacts,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyUnitActionResult(
    GameSave save,
    PersistentGameState state,
    UnitActionCommandResult result,
  ) {
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final artifactsChanged = !identical(result.artifacts, state.artifacts);
    final runtimeState = _runtimeStateWithInteraction(
      state.runtimeState,
      result.interaction,
    );
    return _applicationFrom(
      save: save,
      accepted: true,
      state:
          unitsChanged ||
              artifactsChanged ||
              !identical(runtimeState, state.runtimeState)
          ? state.copyWith(
              units: unitsChanged ? result.units : null,
              artifacts: artifactsChanged ? result.artifacts : null,
              runtimeState: identical(runtimeState, state.runtimeState)
                  ? null
                  : runtimeState,
            )
          : state,
    );
  }
}
