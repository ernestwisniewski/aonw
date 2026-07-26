part of 'server_command_reducer.dart';

extension _ServerCommandReducerDiplomacy on ServerCommandReducer {
  _CommandApplication _applyDiplomacyCommand({
    required CanonicalGameSnapshot snapshot,
    required DiplomaticCommand command,
    required String actorPlayerId,
  }) {
    final domain = snapshot.domain;
    final playerGold = domain.playerGold;
    final result = _resolveDiplomacyCommand(
      domain: domain,
      playerGold: playerGold,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: domain.turn,
    );
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }

    final nextDomain = _domainWithDiplomacyResult(domain, playerGold, result);
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: identical(nextDomain, domain) ? null : nextDomain,
      events: result.events,
    );
  }

  DiplomacyCommandResult _resolveDiplomacyCommand({
    required DomainState domain,
    required Map<String, int> playerGold,
    required DiplomaticCommand command,
    required String actorPlayerId,
    required int turn,
  }) {
    return DiplomacyCommandResolver.resolve(
      state: DiplomacyCommandState(
        playerColors: domain.playerColors,
        playerCountries: domain.playerCountries,
        playerGold: playerGold,
        units: domain.units,
        cities: domain.cities,
        fogOfWar: domain.fogOfWar,
        diplomacy: domain.diplomacy,
        intendedAttacks: domain.intendedAttacks,
        resourceTradeAgreements: domain.resourceTradeAgreements,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
    );
  }

  DomainState _domainWithDiplomacyResult(
    DomainState domain,
    Map<String, int> playerGold,
    DiplomacyCommandResult result,
  ) {
    final nextPlayerGold = identical(result.playerGold, playerGold)
        ? null
        : result.playerGold;
    final nextDiplomacy = identical(result.diplomacy, domain.diplomacy)
        ? null
        : result.diplomacy;
    final nextAttacks =
        identical(result.intendedAttacks, domain.intendedAttacks)
        ? null
        : result.intendedAttacks;
    final nextTrades =
        identical(
          result.resourceTradeAgreements,
          domain.resourceTradeAgreements,
        )
        ? null
        : result.resourceTradeAgreements;
    if (nextPlayerGold == null &&
        nextDiplomacy == null &&
        nextAttacks == null &&
        nextTrades == null) {
      return domain;
    }
    return domain.copyWith(
      playerGold: nextPlayerGold,
      diplomacy: nextDiplomacy,
      intendedAttacks: nextAttacks,
      resourceTradeAgreements: nextTrades,
    );
  }
}
