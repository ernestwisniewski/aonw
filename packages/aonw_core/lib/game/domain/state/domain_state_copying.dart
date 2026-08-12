part of 'domain_state.dart';

final class _DomainStateChanges {
  const _DomainStateChanges({
    this.turn,
    this.matchRules,
    this.participants,
    this.gameMode,
    this.turnStatesByPlayerId,
    this.submittedPlayerIds,
    this.timeoutStreaksByPlayerId,
    this.afkPlayerIds,
    this.kickedPlayerIds,
    this.turnStartedAt = _unsetDomainValue,
    this.actions,
    this.playerGold,
    this.playerWarWeariness,
    this.playerStabilityNet,
    this.strategicResources,
    this.units,
    this.cities,
    this.artifacts,
    this.fieldImprovements,
    this.transportNetwork,
    this.fogOfWar,
    this.research,
    this.wonderRegistry,
    this.intendedAttacks,
    this.diplomacy,
    this.resourceTradeAgreements,
    this.dominationHoldTurnsByPlayerId,
    this.culturalVictoryHoldTurnsByPlayerId,
    this.mapObjectiveHoldStatesByObjectiveId,
  });

  final int? turn;
  final MatchRules? matchRules;
  final List<Player>? participants;
  final GameMode? gameMode;
  final Map<String, PlayerTurnState>? turnStatesByPlayerId;
  final Set<String>? submittedPlayerIds;
  final Map<String, int>? timeoutStreaksByPlayerId;
  final Set<String>? afkPlayerIds;
  final Set<String>? kickedPlayerIds;
  final Object? turnStartedAt;
  final DomainActionState? actions;
  final Map<String, int>? playerGold;
  final Map<String, int>? playerWarWeariness;
  final Map<String, int>? playerStabilityNet;
  final StrategicResourceAccounts? strategicResources;
  final List<GameUnit>? units;
  final List<GameCity>? cities;
  final List<WorldArtifact>? artifacts;
  final List<FieldImprovement>? fieldImprovements;
  final TransportNetworkState? transportNetwork;
  final FogOfWarState? fogOfWar;
  final ResearchState? research;
  final WonderRegistry? wonderRegistry;
  final List<IntendedAttack>? intendedAttacks;
  final DiplomacyState? diplomacy;
  final List<ResourceTradeAgreement>? resourceTradeAgreements;
  final Map<String, int>? dominationHoldTurnsByPlayerId;
  final Map<String, int>? culturalVictoryHoldTurnsByPlayerId;
  final Map<String, MapObjectiveHoldState>? mapObjectiveHoldStatesByObjectiveId;
}

DomainState _copyDomainState(DomainState source, _DomainStateChanges changes) {
  final replacementParticipants = changes.participants;
  final participants = replacementParticipants == null
      ? source.participants
      : _ownDomainParticipants(replacementParticipants);
  return DomainState._owned(
    identity: _copiedDomainIdentity(
      source,
      changes,
      participants,
      replacedParticipants: replacementParticipants != null,
    ),
    content: _copiedDomainContent(source, changes),
  );
}

_DomainStateIdentity _copiedDomainIdentity(
  DomainState source,
  _DomainStateChanges changes,
  List<Player> participants, {
  required bool replacedParticipants,
}) {
  return _DomainStateIdentity(
    turn: changes.turn ?? source.turn,
    matchRules: changes.matchRules ?? source.matchRules,
    participants: participants,
    gameMode: changes.gameMode ?? source.gameMode,
    turnStatesByPlayerId: _domainMapCopy(
      changes.turnStatesByPlayerId,
      source.turnStatesByPlayerId,
    ),
    submittedPlayerIds: _domainSetCopy(
      changes.submittedPlayerIds,
      source.submittedPlayerIds,
    ),
    timeoutStreaksByPlayerId: _domainMapCopy(
      changes.timeoutStreaksByPlayerId,
      source.timeoutStreaksByPlayerId,
    ),
    afkPlayerIds: _domainSetCopy(changes.afkPlayerIds, source.afkPlayerIds),
    kickedPlayerIds: _domainSetCopy(
      changes.kickedPlayerIds,
      source.kickedPlayerIds,
    ),
    turnStartedAt: identical(changes.turnStartedAt, _unsetDomainValue)
        ? source.turnStartedAt
        : (changes.turnStartedAt as DateTime?)?.toUtc(),
    actions: changes.actions ?? source.actions,
    playerColors: replacedParticipants
        ? _domainPlayerColors(participants)
        : source._playerColors,
    playerCountries: replacedParticipants
        ? _domainPlayerCountries(participants)
        : source._playerCountries,
  );
}

_DomainStateContent _copiedDomainContent(
  DomainState source,
  _DomainStateChanges changes,
) {
  return _DomainStateContent(
    playerGold: _domainMapCopy(changes.playerGold, source.playerGold),
    playerWarWeariness: _domainMapCopy(
      changes.playerWarWeariness,
      source.playerWarWeariness,
    ),
    playerStabilityNet: _domainMapCopy(
      changes.playerStabilityNet,
      source.playerStabilityNet,
    ),
    strategicResources: changes.strategicResources ?? source.strategicResources,
    units: _domainListCopy(changes.units, source.units),
    cities: _domainCityListCopy(changes.cities, source.cities),
    artifacts: _domainListCopy(changes.artifacts, source.artifacts),
    fieldImprovements: _domainListCopy(
      changes.fieldImprovements,
      source.fieldImprovements,
    ),
    transportNetwork: changes.transportNetwork ?? source.transportNetwork,
    fogOfWar: changes.fogOfWar ?? source.fogOfWar,
    research: changes.research ?? source.research,
    wonderRegistry: changes.wonderRegistry ?? source.wonderRegistry,
    intendedAttacks: _domainListCopy(
      changes.intendedAttacks,
      source.intendedAttacks,
    ),
    diplomacy: changes.diplomacy ?? source.diplomacy,
    resourceTradeAgreements: _domainListCopy(
      changes.resourceTradeAgreements,
      source.resourceTradeAgreements,
    ),
    dominationHoldTurnsByPlayerId: _domainMapCopy(
      changes.dominationHoldTurnsByPlayerId,
      source.dominationHoldTurnsByPlayerId,
    ),
    culturalVictoryHoldTurnsByPlayerId: _domainMapCopy(
      changes.culturalVictoryHoldTurnsByPlayerId,
      source.culturalVictoryHoldTurnsByPlayerId,
    ),
    mapObjectiveHoldStatesByObjectiveId: _domainMapCopy(
      changes.mapObjectiveHoldStatesByObjectiveId,
      source.mapObjectiveHoldStatesByObjectiveId,
    ),
  );
}

Map<K, V> _domainMapCopy<K, V>(Map<K, V>? replacement, Map<K, V> current) {
  return replacement == null ? current : _immutableDomainMap(replacement);
}

Set<T> _domainSetCopy<T>(Set<T>? replacement, Set<T> current) {
  return replacement == null ? current : _immutableDomainSet(replacement);
}

List<T> _domainListCopy<T>(List<T>? replacement, List<T> current) {
  return replacement == null ? current : _immutableDomainList(replacement);
}

List<GameCity> _domainCityListCopy(
  List<GameCity>? replacement,
  List<GameCity> current,
) {
  return replacement == null ? current : _immutableDomainCities(replacement);
}
