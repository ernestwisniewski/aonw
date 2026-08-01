part of 'domain_state.dart';

bool _sameDomainState(DomainState left, DomainState right) {
  return _sameDomainIdentity(left, right) &&
      _sameDomainEconomy(left, right) &&
      _sameDomainEntities(left, right) &&
      _sameDomainSystems(left, right) &&
      _sameDomainOutcomes(left, right);
}

bool _sameDomainIdentity(DomainState left, DomainState right) {
  return left.turn == right.turn &&
      left.matchRules == right.matchRules &&
      listEquals(left.participants, right.participants) &&
      left.gameMode == right.gameMode &&
      _sameDomainTurnLifecycle(left, right);
}

bool _sameDomainTurnLifecycle(DomainState left, DomainState right) {
  return mapEquals(left.turnStatesByPlayerId, right.turnStatesByPlayerId) &&
      setEquals(left.submittedPlayerIds, right.submittedPlayerIds) &&
      mapEquals(
        left.timeoutStreaksByPlayerId,
        right.timeoutStreaksByPlayerId,
      ) &&
      setEquals(left.afkPlayerIds, right.afkPlayerIds) &&
      setEquals(left.kickedPlayerIds, right.kickedPlayerIds) &&
      left.turnStartedAt == right.turnStartedAt &&
      left.actions == right.actions;
}

bool _sameDomainEconomy(DomainState left, DomainState right) {
  return mapEquals(left.playerGold, right.playerGold) &&
      mapEquals(left.playerWarWeariness, right.playerWarWeariness) &&
      mapEquals(left.playerStabilityNet, right.playerStabilityNet);
}

bool _sameDomainEntities(DomainState left, DomainState right) {
  return listEquals(left.units, right.units) &&
      listEquals(left.cities, right.cities) &&
      listEquals(left.artifacts, right.artifacts) &&
      listEquals(left.fieldImprovements, right.fieldImprovements);
}

bool _sameDomainSystems(DomainState left, DomainState right) {
  return left.fogOfWar == right.fogOfWar &&
      left.research == right.research &&
      left.wonderRegistry == right.wonderRegistry &&
      listEquals(left.intendedAttacks, right.intendedAttacks) &&
      left.diplomacy == right.diplomacy &&
      listEquals(left.resourceTradeAgreements, right.resourceTradeAgreements);
}

bool _sameDomainOutcomes(DomainState left, DomainState right) {
  return mapEquals(
        left.dominationHoldTurnsByPlayerId,
        right.dominationHoldTurnsByPlayerId,
      ) &&
      mapEquals(
        left.culturalVictoryHoldTurnsByPlayerId,
        right.culturalVictoryHoldTurnsByPlayerId,
      ) &&
      mapEquals(
        left.mapObjectiveHoldStatesByObjectiveId,
        right.mapObjectiveHoldStatesByObjectiveId,
      );
}

int _domainStateHash(DomainState state) {
  return Object.hash(
    _domainIdentityHash(state),
    _domainEconomyHash(state),
    _domainEntityHash(state),
    _domainSystemsHash(state),
    _domainOutcomeHash(state),
  );
}

int _domainIdentityHash(DomainState state) => Object.hash(
  state.turn,
  state.matchRules,
  Object.hashAll(state.participants),
  state.gameMode,
  mapHash(state.turnStatesByPlayerId),
  Object.hashAllUnordered(state.submittedPlayerIds),
  mapHash(state.timeoutStreaksByPlayerId),
  Object.hashAllUnordered(state.afkPlayerIds),
  Object.hashAllUnordered(state.kickedPlayerIds),
  state.turnStartedAt,
  state.actions,
);

int _domainEconomyHash(DomainState state) => Object.hash(
  mapHash(state.playerGold),
  mapHash(state.playerWarWeariness),
  mapHash(state.playerStabilityNet),
);

int _domainEntityHash(DomainState state) => Object.hash(
  Object.hashAll(state.units),
  Object.hashAll(state.cities),
  Object.hashAll(state.artifacts),
  Object.hashAll(state.fieldImprovements),
);

int _domainSystemsHash(DomainState state) => Object.hash(
  state.fogOfWar,
  state.research,
  state.wonderRegistry,
  Object.hashAll(state.intendedAttacks),
  state.diplomacy,
  Object.hashAll(state.resourceTradeAgreements),
);

int _domainOutcomeHash(DomainState state) => Object.hash(
  mapHash(state.dominationHoldTurnsByPlayerId),
  mapHash(state.culturalVictoryHoldTurnsByPlayerId),
  mapHash(state.mapObjectiveHoldStatesByObjectiveId),
);
