part of 'server_command_reducer.dart';

extension _ServerCommandReducerWorker on ServerCommandReducer {
  _CommandApplication _applySelectWorkerImprovement(
    GameSave save,
    PersistentGameState state,
    SelectWorkerImprovementCommand command,
    String actorPlayerId,
    MapTileLookup mapTiles,
    GameRuleset ruleset,
  ) {
    return _applyWorkerResult(
      save,
      state,
      WorkerCommandResolver.selectWorkerImprovement(
        units: state.units,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        research: state.research,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: ruleset.paceBalance,
      ),
    );
  }

  _CommandApplication _applyConfirmWorkerImprovement(
    GameSave save,
    PersistentGameState state,
    ConfirmWorkerImprovementCommand command,
    String actorPlayerId,
    MapTileLookup mapTiles,
    GameRuleset ruleset,
  ) {
    return _applyWorkerResult(
      save,
      state,
      WorkerCommandResolver.confirmWorkerImprovement(
        units: state.units,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        research: state.research,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: ruleset.paceBalance,
      ),
    );
  }

  _CommandApplication _applyCancelWorkerJob(
    GameSave save,
    PersistentGameState state,
    CancelWorkerJobCommand command,
    String actorPlayerId,
  ) {
    return _applyWorkerResult(
      save,
      state,
      WorkerCommandResolver.cancelWorkerJob(
        units: state.units,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyAssignWorkerToHex(
    GameSave save,
    PersistentGameState state,
    AssignWorkerToHexCommand command,
    String actorPlayerId,
    MapTileLookup mapTiles,
  ) {
    return _applyWorkerResult(
      save,
      state,
      WorkerCommandResolver.assignWorkerToHex(
        units: state.units,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
      ),
    );
  }

  _CommandApplication _applyCancelWorkerAssignment(
    GameSave save,
    PersistentGameState state,
    CancelWorkerAssignmentCommand command,
    String actorPlayerId,
  ) {
    return _applyWorkerResult(
      save,
      state,
      WorkerCommandResolver.cancelWorkerAssignment(
        units: state.units,
        interaction: _persistedInteraction(state),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyWorkerResult(
    GameSave save,
    PersistentGameState state,
    WorkerCommandResult result,
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
    final runtimeState = _runtimeStateWithInteraction(
      state.runtimeState,
      result.interaction,
    );
    return _applicationFrom(
      save: save,
      accepted: true,
      state: unitsChanged || !identical(runtimeState, state.runtimeState)
          ? state.copyWith(
              units: unitsChanged ? result.units : null,
              runtimeState: identical(runtimeState, state.runtimeState)
                  ? null
                  : runtimeState,
            )
          : state,
    );
  }
}
