part of 'server_command_reducer.dart';

extension _ServerResearchCommandReducer on ServerCommandReducer {
  _CommandApplication _applySelectTechnologyCommand({
    required GameSave save,
    required PersistentGameState state,
    required SelectTechnologyCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final result = SelectTechnologyResolver.selectTechnology(
      research: state.research,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      ruleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }

    final pendingAction =
        ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
          pendingAction: state.runtimeState.pendingAction,
          playerId: command.playerId,
        );
    final runtimeState =
        identical(pendingAction, state.runtimeState.pendingAction)
        ? null
        : state.runtimeState.copyWith(pendingAction: pendingAction);
    return _applicationFrom(
      save: save,
      accepted: true,
      state: state.copyWith(
        research: result.research,
        runtimeState: runtimeState,
      ),
    );
  }
}
