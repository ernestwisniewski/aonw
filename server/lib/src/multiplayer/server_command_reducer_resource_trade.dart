part of 'server_command_reducer.dart';

extension _ServerCommandReducerResourceTrade on ServerCommandReducer {
  _CommandApplication _applyOpenResourceTrade({
    required GameSave save,
    required PersistentGameState state,
    required OpenResourceTradeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
      playerGold: state.playerGold,
      cities: state.cities,
      research: state.research,
      diplomacy: state.runtimeState.diplomacy,
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _applyResourceTradeResult(save, state, result);
  }

  _CommandApplication _applyOpenResourceExchange({
    required GameSave save,
    required PersistentGameState state,
    required OpenResourceExchangeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = ResourceTradeCommandResolver.openResourceForResourceTrade(
      cities: state.cities,
      research: state.research,
      diplomacy: state.runtimeState.diplomacy,
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _applyResourceTradeResult(save, state, result);
  }

  _CommandApplication _applyResourceTradeResult(
    GameSave save,
    PersistentGameState state,
    ResourceTradeCommandResult result,
  ) {
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: result.accepted
          ? state.copyWith(
              runtimeState: state.runtimeState.copyWith(
                resourceTradeAgreements: result.resourceTradeAgreements,
              ),
            )
          : state,
      reason: result.reason,
    );
  }
}
