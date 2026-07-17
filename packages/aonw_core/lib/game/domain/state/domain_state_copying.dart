part of 'domain_state.dart';

typedef _DomainStateChanges = ({
  int? turn,
  MatchRules? matchRules,
  List<Player>? participants,
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
    turn: changes.turn ?? source.turn,
    matchRules: changes.matchRules ?? source.matchRules,
    participants: participants,
    playerColors: replacementParticipants == null
        ? source._playerColors
        : _domainPlayerColors(participants),
    playerCountries: replacementParticipants == null
        ? source._playerCountries
        : _domainPlayerCountries(participants),
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

List<T> _domainListCopy<T>(List<T>? replacement, List<T> current) {
  return replacement == null ? current : _immutableDomainList(replacement);
}

List<GameCity> _domainCityListCopy(
  List<GameCity>? replacement,
  List<GameCity> current,
) {
  return replacement == null ? current : _immutableDomainCities(replacement);
}
