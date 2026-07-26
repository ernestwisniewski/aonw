part of 'server_command_reducer.dart';

extension _ServerCommandReducerResourceTrade on ServerCommandReducer {
  _CommandApplication _applyOpenResourceTrade({
    required CanonicalGameSnapshot snapshot,
    required OpenResourceTradeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final domain = snapshot.domain;
    final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
      playerGold: domain.playerGold,
      cities: domain.cities,
      research: domain.research,
      diplomacy: domain.diplomacy,
      resourceTradeAgreements: domain.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _applyResourceTradeResult(snapshot, result);
  }

  _CommandApplication _applyOpenResourceExchange({
    required CanonicalGameSnapshot snapshot,
    required OpenResourceExchangeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final domain = snapshot.domain;
    final result = ResourceTradeCommandResolver.openResourceForResourceTrade(
      cities: domain.cities,
      research: domain.research,
      diplomacy: domain.diplomacy,
      resourceTradeAgreements: domain.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _applyResourceTradeResult(snapshot, result);
  }

  _CommandApplication _applyResourceTradeResult(
    CanonicalGameSnapshot snapshot,
    ResourceTradeCommandResult result,
  ) {
    final domain = snapshot.domain;
    final agreementsChanged =
        result.accepted &&
        !identical(
          result.resourceTradeAgreements,
          domain.resourceTradeAgreements,
        );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: agreementsChanged
          ? domain.copyWith(
              resourceTradeAgreements: result.resourceTradeAgreements,
            )
          : null,
      reason: result.reason,
    );
  }
}
