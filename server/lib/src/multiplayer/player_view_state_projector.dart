import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/view.dart';

/// Projects canonical match state into a recipient-scoped nominal view.
final class PlayerViewStateProjector {
  const PlayerViewStateProjector();

  PlayerViewState project({
    required DomainState domain,
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
        recipientPlayerId,
        knownDiplomacyPlayerIds: knownDiplomacyPlayerIds,
        visibility: visibility,
        ownCityIds: ownCityIds,
        ownUnitIds: ownUnitIds,
      ),
    );
  }
}

Map<String, dynamic> _projectedState(
  DomainState domain,
  String playerId, {
  required Set<String> knownDiplomacyPlayerIds,
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
}) {
  final units = _unitsFor(domain, playerId, visibility);
  final cities = _citiesFor(domain, playerId, visibility);
  final artifacts = _artifactsFor(
    domain,
    visibility: visibility,
    ownCityIds: ownCityIds,
    ownUnitIds: ownUnitIds,
  );
  final fieldImprovements = _fieldImprovementsFor(
    domain,
    visibility: visibility,
    ownCityIds: ownCityIds,
  );
  final fogOfWar = FogOfWarState(
    players: {playerId: domain.fogOfWar.fogForPlayer(playerId)},
  );
  final research = ResearchState(
    players: {playerId: domain.research.forPlayer(playerId)},
  );
  return {
    'playerColors': {...domain.playerColors},
    'playerCountries': domain.playerCountries.map(
      (id, country) => MapEntry(id, country.name),
    ),
    'playerGold': _ownEntry(domain.playerGold, playerId),
    'playerWarWeariness': _ownEntry(domain.playerWarWeariness, playerId),
    'playerStabilityNet': _ownEntry(domain.playerStabilityNet, playerId),
    'units': [for (final unit in units) unit.toJson()],
    'cities': [for (final city in cities) city.toJson()],
    'artifacts': [for (final artifact in artifacts) artifact.toJson()],
    'fieldImprovements': [
      for (final improvement in fieldImprovements) improvement.toJson(),
    ],
    'fogOfWar': fogOfWar.toJson(),
    'research': research.toJson(),
    'lifecycle': _runtimeFor(
      domain: domain,
      playerId: playerId,
      knownPlayerIds: knownDiplomacyPlayerIds,
    ),
    if (domain.wonderRegistry.completedBy.isNotEmpty)
      'wonderRegistry': domain.wonderRegistry.toJson(),
  };
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

Map<String, dynamic> _runtimeFor({
  required DomainState domain,
  required String playerId,
  required Set<String> knownPlayerIds,
}) {
  return {
    ..._actionLifecycleFor(domain, playerId),
    ..._turnLifecycleFor(domain, playerId),
    ..._diplomacyLifecycleFor(domain, playerId, knownPlayerIds),
    ..._victoryLifecycleFor(domain, playerId),
  };
}

Map<String, dynamic> _actionLifecycleFor(DomainState domain, String playerId) {
  final cityFoundingDraft =
      domain.actions.cityFoundingDraft?.ownerPlayerId == playerId
      ? domain.actions.cityFoundingDraft
      : null;
  final pendingAction = domain.actions.pendingAction?.ownerPlayerId == playerId
      ? domain.actions.pendingAction
      : null;
  return {
    if (cityFoundingDraft != null)
      'cityFoundingDraft': cityFoundingDraft.toJson(),
    if (pendingAction != null) 'pendingAction': pendingAction.toJson(),
  };
}

Map<String, dynamic> _turnLifecycleFor(DomainState domain, String playerId) {
  final timeoutStreaksByPlayerId = _ownEntry(
    domain.timeoutStreaksByPlayerId,
    playerId,
  );
  return {
    if (domain.submittedPlayerIds.isNotEmpty)
      'submittedPlayerIds': _sortedStrings(domain.submittedPlayerIds),
    if (timeoutStreaksByPlayerId.isNotEmpty)
      'timeoutStreaksByPlayerId': _sortedIntMap(timeoutStreaksByPlayerId),
    if (domain.afkPlayerIds.isNotEmpty)
      'afkPlayerIds': _sortedStrings(domain.afkPlayerIds),
    if (domain.kickedPlayerIds.isNotEmpty)
      'kickedPlayerIds': _sortedStrings(domain.kickedPlayerIds),
    if (domain.turnStartedAt != null)
      'turnStartedAt': domain.turnStartedAt!.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> _diplomacyLifecycleFor(
  DomainState domain,
  String playerId,
  Set<String> knownPlayerIds,
) {
  final intendedAttacks = [
    for (final attack in domain.intendedAttacks)
      if (attack.declaringPlayerId == playerId) attack,
  ];
  final diplomacy = _diplomacyFor(domain.diplomacy, playerId, knownPlayerIds);
  final resourceTrades = _resourceTradesFor(domain, playerId);
  return {
    if (intendedAttacks.isNotEmpty)
      'intendedAttacks': [
        for (final attack in intendedAttacks) attack.toJson(),
      ],
    if (diplomacy.isNotEmpty) 'diplomacy': diplomacy.toJson(),
    if (resourceTrades.isNotEmpty)
      'resourceTradeAgreements': [
        for (final agreement in resourceTrades) agreement.toJson(),
      ],
  };
}

List<ResourceTradeAgreement> _resourceTradesFor(
  DomainState domain,
  String playerId,
) {
  return [
    for (final agreement in domain.resourceTradeAgreements)
      if (agreement.exporterPlayerId == playerId ||
          agreement.importerPlayerId == playerId)
        agreement,
  ]..sort((left, right) => left.id.compareTo(right.id));
}

Map<String, dynamic> _victoryLifecycleFor(DomainState domain, String playerId) {
  final dominationHoldTurnsByPlayerId = _ownEntry(
    domain.dominationHoldTurnsByPlayerId,
    playerId,
  );
  final culturalVictoryHoldTurnsByPlayerId = _ownEntry(
    domain.culturalVictoryHoldTurnsByPlayerId,
    playerId,
  );
  final mapObjectiveHolds = [
    for (final entry in domain.mapObjectiveHoldStatesByObjectiveId.entries)
      if (entry.value.playerId == playerId) entry.value,
  ]..sort((left, right) => left.objectiveId.compareTo(right.objectiveId));
  return {
    if (dominationHoldTurnsByPlayerId.isNotEmpty)
      'dominationHoldTurnsByPlayerId': _sortedIntMap(
        dominationHoldTurnsByPlayerId,
      ),
    if (culturalVictoryHoldTurnsByPlayerId.isNotEmpty)
      'culturalVictoryHoldTurnsByPlayerId': _sortedIntMap(
        culturalVictoryHoldTurnsByPlayerId,
      ),
    if (mapObjectiveHolds.isNotEmpty)
      'mapObjectiveHoldStates': [
        for (final hold in mapObjectiveHolds) hold.toJson(),
      ],
  };
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

List<String> _sortedStrings(Iterable<String> values) {
  return values.toList()..sort();
}

Map<String, int> _sortedIntMap(Map<String, int> values) {
  final entries = values.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return {for (final entry in entries) entry.key: entry.value};
}
