part of 'domain_state.dart';

typedef _DomainStateChanges = ({
  int? turn,
  MatchRules? matchRules,
  List<Player>? participants,
  GameMode? gameMode,
  Map<String, PlayerTurnState>? turnStatesByPlayerId,
  Set<String>? submittedPlayerIds,
  Map<String, int>? timeoutStreaksByPlayerId,
  Set<String>? afkPlayerIds,
  Set<String>? kickedPlayerIds,
  Object? turnStartedAt,
  DomainActionState? actions,
  Map<String, int>? playerGold,
  Map<String, int>? playerWarWeariness,
  Map<String, int>? playerStabilityNet,
  List<GameUnit>? units,
  List<GameCity>? cities,
  List<WorldArtifact>? artifacts,
  List<FieldImprovement>? fieldImprovements,
  FogOfWarState? fogOfWar,
  ResearchState? research,
  WonderRegistry? wonderRegistry,
  List<IntendedAttack>? intendedAttacks,
  DiplomacyState? diplomacy,
  List<ResourceTradeAgreement>? resourceTradeAgreements,
  Map<String, int>? dominationHoldTurnsByPlayerId,
  Map<String, int>? culturalVictoryHoldTurnsByPlayerId,
  Map<String, MapObjectiveHoldState>? mapObjectiveHoldStatesByObjectiveId,
});

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
    units: _domainListCopy(changes.units, source.units),
    cities: _domainCityListCopy(changes.cities, source.cities),
    artifacts: _domainListCopy(changes.artifacts, source.artifacts),
    fieldImprovements: _domainListCopy(
      changes.fieldImprovements,
      source.fieldImprovements,
    ),
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
