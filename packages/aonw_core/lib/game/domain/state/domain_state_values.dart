part of 'domain_state.dart';

final class _DomainStateIdentity {
  const _DomainStateIdentity({
    required this.turn,
    required this.matchRules,
    required this.participants,
    required this.gameMode,
    required this.turnStatesByPlayerId,
    required this.submittedPlayerIds,
    required this.timeoutStreaksByPlayerId,
    required this.afkPlayerIds,
    required this.kickedPlayerIds,
    required this.turnStartedAt,
    required this.actions,
    required this.playerColors,
    required this.playerCountries,
  });

  final int turn;
  final MatchRules matchRules;
  final List<Player> participants;
  final GameMode gameMode;
  final Map<String, PlayerTurnState> turnStatesByPlayerId;
  final Set<String> submittedPlayerIds;
  final Map<String, int> timeoutStreaksByPlayerId;
  final Set<String> afkPlayerIds;
  final Set<String> kickedPlayerIds;
  final DateTime? turnStartedAt;
  final DomainActionState actions;
  final Map<String, int> playerColors;
  final Map<String, PlayerCountry> playerCountries;
}

final class _DomainStateContent {
  const _DomainStateContent({
    required this.playerGold,
    required this.playerWarWeariness,
    required this.playerStabilityNet,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fieldImprovements,
    required this.fogOfWar,
    required this.research,
    required this.wonderRegistry,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.resourceTradeAgreements,
    required this.dominationHoldTurnsByPlayerId,
    required this.culturalVictoryHoldTurnsByPlayerId,
    required this.mapObjectiveHoldStatesByObjectiveId,
  });

  final Map<String, int> playerGold;
  final Map<String, int> playerWarWeariness;
  final Map<String, int> playerStabilityNet;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final FogOfWarState fogOfWar;
  final ResearchState research;
  final WonderRegistry wonderRegistry;
  final List<IntendedAttack> intendedAttacks;
  final DiplomacyState diplomacy;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final Map<String, int> dominationHoldTurnsByPlayerId;
  final Map<String, int> culturalVictoryHoldTurnsByPlayerId;
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;
}
