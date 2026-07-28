import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/view.dart';

/// Projects canonical match state into a recipient-scoped nominal view.
final class PlayerViewStateProjector {
  const PlayerViewStateProjector();

  PlayerViewState project({
    required DomainState domain,
    required MatchSessionState session,
    required PersistedInteractionState interaction,
    required String recipientPlayerId,
    required Set<String> knownDiplomacyPlayerIds,
  }) {
    final visibility = FogVisibilityQuery(
      playerId: recipientPlayerId,
      state: domain.fogOfWar,
    );
    final ownCityIds = _ownCityIds(domain, recipientPlayerId);
    final ownUnitIds = _ownUnitIds(domain, recipientPlayerId);
    return PlayerViewState(
      recipientPlayerId: recipientPlayerId,
      projectedState: _projectedState(
        domain,
        session,
        interaction,
        recipientPlayerId,
        knownDiplomacyPlayerIds: knownDiplomacyPlayerIds,
        visibility: visibility,
        ownCityIds: ownCityIds,
        ownUnitIds: ownUnitIds,
      ),
    );
  }
}

PersistentGameState _projectedState(
  DomainState domain,
  MatchSessionState session,
  PersistedInteractionState interaction,
  String playerId, {
  required Set<String> knownDiplomacyPlayerIds,
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
}) {
  return PersistentGameState.snapshot(
    playerColors: domain.playerColors,
    playerCountries: domain.playerCountries,
    playerGold: _ownEntry(domain.playerGold, playerId),
    playerWarWeariness: _ownEntry(domain.playerWarWeariness, playerId),
    playerStabilityNet: _ownEntry(domain.playerStabilityNet, playerId),
    units: _unitsFor(domain, playerId, visibility),
    cities: _citiesFor(domain, playerId, visibility),
    artifacts: _artifactsFor(
      domain,
      visibility: visibility,
      ownCityIds: ownCityIds,
      ownUnitIds: ownUnitIds,
    ),
    fieldImprovements: _fieldImprovementsFor(
      domain,
      visibility: visibility,
      ownCityIds: ownCityIds,
    ),
    fogOfWar: FogOfWarState(
      players: {playerId: domain.fogOfWar.fogForPlayer(playerId)},
    ),
    research: ResearchState(
      players: {playerId: domain.research.forPlayer(playerId)},
    ),
    runtimeState: _runtimeFor(
      domain: domain,
      session: session,
      interaction: interaction,
      playerId: playerId,
      knownPlayerIds: knownDiplomacyPlayerIds,
    ),
    wonderRegistry: domain.wonderRegistry,
  );
}

Set<String> _ownCityIds(DomainState state, String playerId) {
  return {
    for (final city in state.cities)
      if (city.ownerPlayerId == playerId) city.id,
  };
}

Set<String> _ownUnitIds(DomainState state, String playerId) {
  return {
    for (final unit in state.units)
      if (unit.ownerPlayerId == playerId) unit.id,
  };
}

List<GameUnit> _unitsFor(
  DomainState state,
  String playerId,
  FogVisibilityQuery visibility,
) {
  return [
    for (final unit in state.units)
      if (unit.ownerPlayerId == playerId)
        unit
      else if (visibility.canSeeDynamicAt(unit.col, unit.row))
        _visibleOpponentUnit(unit),
  ];
}

List<GameCity> _citiesFor(
  DomainState state,
  String playerId,
  FogVisibilityQuery visibility,
) {
  return [
    for (final city in state.cities)
      if (city.ownerPlayerId == playerId)
        city
      else if (visibility.canSeeDynamicAt(city.center.col, city.center.row))
        _visibleOpponentCity(city, visibility),
  ];
}

List<WorldArtifact> _artifactsFor(
  DomainState state, {
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
}) {
  return [
    for (final artifact in state.artifacts)
      if (_artifactVisible(
        artifact,
        visibility: visibility,
        ownCityIds: ownCityIds,
        ownUnitIds: ownUnitIds,
      ))
        artifact,
  ];
}

List<FieldImprovement> _fieldImprovementsFor(
  DomainState state, {
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
}) {
  return [
    for (final improvement in state.fieldImprovements)
      if (ownCityIds.contains(improvement.builtByCityId))
        improvement
      else if (visibility.canSeeDynamicAt(
        improvement.hex.col,
        improvement.hex.row,
      ))
        FieldImprovement(hex: improvement.hex, type: improvement.type),
  ];
}

GameRuntimeState _runtimeFor({
  required DomainState domain,
  required MatchSessionState session,
  required PersistedInteractionState interaction,
  required String playerId,
  required Set<String> knownPlayerIds,
}) {
  return GameRuntimeState.snapshot(
    cityFoundingDraft: interaction.cityFoundingDraft?.ownerPlayerId == playerId
        ? interaction.cityFoundingDraft
        : null,
    pendingAction: interaction.pendingAction?.ownerPlayerId == playerId
        ? interaction.pendingAction
        : null,
    submittedPlayerIds: session.submittedPlayerIds,
    timeoutStreaksByPlayerId: _ownEntry(
      session.timeoutStreaksByPlayerId,
      playerId,
    ),
    afkPlayerIds: session.afkPlayerIds,
    kickedPlayerIds: session.kickedPlayerIds,
    intendedAttacks: [
      for (final attack in domain.intendedAttacks)
        if (attack.declaringPlayerId == playerId) attack,
    ],
    diplomacy: _diplomacyFor(domain.diplomacy, playerId, knownPlayerIds),
    dominationHoldTurnsByPlayerId: _ownEntry(
      domain.dominationHoldTurnsByPlayerId,
      playerId,
    ),
    culturalVictoryHoldTurnsByPlayerId: _ownEntry(
      domain.culturalVictoryHoldTurnsByPlayerId,
      playerId,
    ),
    mapObjectiveHoldStatesByObjectiveId: {
      for (final entry in domain.mapObjectiveHoldStatesByObjectiveId.entries)
        if (entry.value.playerId == playerId) entry.key: entry.value,
    },
    resourceTradeAgreements: [
      for (final agreement in domain.resourceTradeAgreements)
        if (agreement.exporterPlayerId == playerId ||
            agreement.importerPlayerId == playerId)
          agreement,
    ],
    turnStartedAt: session.turnStartedAt,
  );
}

DiplomacyState _diplomacyFor(
  DiplomacyState canonical,
  String playerId,
  Set<String> knownPlayerIds,
) {
  return DiplomacyState(
    contactKeys: _contactKeysFor(canonical, playerId, knownPlayerIds),
    relations: _relationsFor(canonical, playerId),
    pendingProposals: _proposalsFor(canonical, playerId),
    messages: _messagesFor(canonical, playerId),
    scoreHistory: _scoreHistoryFor(canonical.scoreHistory, playerId),
  );
}

Set<String> _contactKeysFor(
  DiplomacyState state,
  String playerId,
  Set<String> knownPlayerIds,
) {
  return {
    for (final relation in state.relations.values)
      if (relation.other(playerId) != null) relation.key,
    for (final otherPlayerId in knownPlayerIds)
      if (state.hasContact(playerId, otherPlayerId))
        DiplomacyState.relationKey(playerId, otherPlayerId),
  };
}

Map<String, DiplomaticRelation> _relationsFor(
  DiplomacyState state,
  String playerId,
) {
  return {
    for (final entry in state.relations.entries)
      if (entry.value.other(playerId) != null) entry.key: entry.value,
  };
}

Map<String, DiplomaticProposal> _proposalsFor(
  DiplomacyState state,
  String playerId,
) {
  return {
    for (final entry in state.pendingProposals.entries)
      if (entry.value.involves(playerId)) entry.key: entry.value,
  };
}

Map<String, DiplomaticMessage> _messagesFor(
  DiplomacyState state,
  String playerId,
) {
  return {
    for (final entry in state.messages.entries)
      if (entry.value.involves(playerId)) entry.key: entry.value,
  };
}

Map<String, List<DiplomaticScoreEntry>> _scoreHistoryFor(
  Map<String, List<DiplomaticScoreEntry>> canonical,
  String playerId,
) {
  final projected = <String, List<DiplomaticScoreEntry>>{};
  for (final scores in canonical.values) {
    for (final score in scores) {
      if (score.playerAId != playerId && score.playerBId != playerId) continue;
      projected.putIfAbsent(score.key, () => []).add(score);
    }
  }
  return {
    for (final entry in projected.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}

GameUnit _visibleOpponentUnit(GameUnit unit) {
  return GameUnit(
    id: unit.id,
    ownerPlayerId: unit.ownerPlayerId,
    type: unit.type,
    name: unit.name,
    col: unit.col,
    row: unit.row,
    movementPoints: 0,
    workerBuildCharges: 0,
    hitPoints: unit.hitPoints,
  );
}

GameCity _visibleOpponentCity(GameCity city, FogVisibilityQuery visibility) {
  return GameCity.snapshot(
    id: city.id,
    ownerPlayerId: city.ownerPlayerId,
    name: city.name,
    center: city.center,
    controlledHexes: [
      for (final hex in city.controlledHexes)
        if (visibility.canSeeDynamicAt(hex.col, hex.row)) hex,
    ],
    hitPoints: city.hitPoints,
  );
}

bool _artifactVisible(
  WorldArtifact artifact, {
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
}) {
  final location = artifact.location;
  return switch (location.kind) {
    WorldArtifactLocationKind.map =>
      location.col != null &&
          location.row != null &&
          visibility.canSeeDynamicAt(location.col!, location.row!),
    WorldArtifactLocationKind.excavation =>
      location.unitId != null && ownUnitIds.contains(location.unitId),
    WorldArtifactLocationKind.carried =>
      location.unitId != null && ownUnitIds.contains(location.unitId),
    WorldArtifactLocationKind.stored =>
      location.cityId != null && ownCityIds.contains(location.cityId),
  };
}

Map<String, int> _ownEntry(Map<String, int> values, String playerId) {
  final value = values[playerId];
  return value == null ? const {} : {playerId: value};
}
