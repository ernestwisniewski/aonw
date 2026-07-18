part of 'server_command_reducer.dart';

extension _ServerCommandReducerMerchantRouting on ServerCommandReducer {
  _CommandApplication _applyAssignMerchantRoute(
    GameSave save,
    PersistentGameState state,
    AssignMerchantTradeRouteCommand command,
    String actorPlayerId,
    MapTraversalView mapData,
  ) {
    return _applyMerchantRoutingResult(
      save,
      state,
      MerchantRoutingCommandResolver.assignRoute(
        units: state.units,
        cities: state.cities,
        mapData: mapData,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyMoveMerchantToCity(
    GameSave save,
    PersistentGameState state,
    MoveMerchantToCityCommand command,
    String actorPlayerId,
    MapTraversalView mapData,
  ) {
    return _applyMerchantRoutingResult(
      save,
      state,
      MerchantRoutingCommandResolver.moveToCity(
        units: state.units,
        cities: state.cities,
        mapData: mapData,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyMerchantRoutingResult(
    GameSave save,
    PersistentGameState state,
    MerchantRoutingCommandResult result,
  ) {
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
      state: identical(result.units, state.units)
          ? state
          : state.copyWith(units: result.units),
    );
  }
}
