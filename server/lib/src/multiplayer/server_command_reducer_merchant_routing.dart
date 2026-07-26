part of 'server_command_reducer.dart';

extension _ServerCommandReducerMerchantRouting on ServerCommandReducer {
  _CommandApplication _applyAssignMerchantRoute(
    CanonicalGameSnapshot snapshot,
    AssignMerchantTradeRouteCommand command,
    String actorPlayerId,
    MapTraversalView mapData,
  ) {
    return _applyMerchantRoutingResult(
      snapshot,
      MerchantRoutingCommandResolver.assignRoute(
        units: snapshot.domain.units,
        cities: snapshot.domain.cities,
        mapData: mapData,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyMoveMerchantToCity(
    CanonicalGameSnapshot snapshot,
    MoveMerchantToCityCommand command,
    String actorPlayerId,
    MapTraversalView mapData,
  ) {
    return _applyMerchantRoutingResult(
      snapshot,
      MerchantRoutingCommandResolver.moveToCity(
        units: snapshot.domain.units,
        cities: snapshot.domain.cities,
        mapData: mapData,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyMerchantRoutingResult(
    CanonicalGameSnapshot snapshot,
    MerchantRoutingCommandResult result,
  ) {
    final domain = snapshot.domain;
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: identical(result.units, domain.units)
          ? null
          : domain.copyWith(units: result.units),
    );
  }
}
