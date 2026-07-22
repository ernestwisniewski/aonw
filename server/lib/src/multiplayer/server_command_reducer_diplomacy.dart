part of 'server_command_reducer.dart';

extension _ServerCommandReducerDiplomacy on ServerCommandReducer {
  _CommandApplication _applyDiplomacyCommand({
    required GameSave save,
    required PersistentGameState state,
    required DiplomaticCommand command,
    required String actorPlayerId,
  }) {
    final playerGold = state.playerGold;
    final result = _resolveDiplomacyCommand(
      state: state,
      playerGold: playerGold,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: save.turn,
    );
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }

    return _applicationFrom(
      save: save,
      accepted: true,
      state: _stateWithDiplomacyResult(state, playerGold, result),
      events: result.events,
    );
  }

  DiplomacyCommandResult _resolveDiplomacyCommand({
    required PersistentGameState state,
    required Map<String, int> playerGold,
    required DiplomaticCommand command,
    required String actorPlayerId,
    required int turn,
  }) {
    final runtimeState = state.runtimeState;
    return DiplomacyCommandResolver.resolve(
      state: DiplomacyCommandState(
        playerColors: state.playerColors,
        playerCountries: state.playerCountries,
        playerGold: playerGold,
        units: state.units,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
        diplomacy: runtimeState.diplomacy,
        intendedAttacks: runtimeState.intendedAttacks,
        resourceTradeAgreements: runtimeState.resourceTradeAgreements,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
    );
  }

  PersistentGameState _stateWithDiplomacyResult(
    PersistentGameState state,
    Map<String, int> playerGold,
    DiplomacyCommandResult result,
  ) {
    final runtimeState = state.runtimeState;
    final nextRuntimeState = _runtimeStateWithDiplomacyResult(
      runtimeState,
      result,
    );
    final nextPlayerGold = identical(result.playerGold, playerGold)
        ? null
        : result.playerGold;
    final runtimeUnchanged = identical(nextRuntimeState, runtimeState);
    if (nextPlayerGold == null && runtimeUnchanged) return state;
    return state.copyWith(
      playerGold: nextPlayerGold,
      runtimeState: runtimeUnchanged ? null : nextRuntimeState,
    );
  }

  GameRuntimeState _runtimeStateWithDiplomacyResult(
    GameRuntimeState runtimeState,
    DiplomacyCommandResult result,
  ) {
    final nextDiplomacy = identical(result.diplomacy, runtimeState.diplomacy)
        ? null
        : result.diplomacy;
    final nextAttacks =
        identical(result.intendedAttacks, runtimeState.intendedAttacks)
        ? null
        : result.intendedAttacks;
    final nextTrades =
        identical(
          result.resourceTradeAgreements,
          runtimeState.resourceTradeAgreements,
        )
        ? null
        : result.resourceTradeAgreements;
    if (nextDiplomacy == null && nextAttacks == null && nextTrades == null) {
      return runtimeState;
    }
    return runtimeState.copyWith(
      diplomacy: nextDiplomacy,
      intendedAttacks: nextAttacks,
      resourceTradeAgreements: nextTrades,
    );
  }
}
