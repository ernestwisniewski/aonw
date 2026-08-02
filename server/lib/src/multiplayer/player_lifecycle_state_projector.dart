import 'package:aonw_core/domain.dart';

/// Projects recipient-owned action, turn, diplomacy, and victory lifecycle.
final class PlayerLifecycleStateProjector {
  const PlayerLifecycleStateProjector();

  Map<String, dynamic> project(
    DomainState domain,
    String playerId,
    Set<String> knownPlayerIds,
  ) {
    return {
      ..._actionLifecycleFor(domain, playerId),
      ..._turnLifecycleFor(domain, playerId),
      ..._diplomacyLifecycleFor(domain, playerId, knownPlayerIds),
      ..._victoryLifecycleFor(domain, playerId),
    };
  }
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
  final timeoutStreaks = _ownIntEntry(
    domain.timeoutStreaksByPlayerId,
    playerId,
  );
  return {
    if (domain.submittedPlayerIds.isNotEmpty)
      'submittedPlayerIds': _sortedStrings(domain.submittedPlayerIds),
    if (timeoutStreaks.isNotEmpty)
      'timeoutStreaksByPlayerId': _sortedIntMap(timeoutStreaks),
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
  final intendedAttacks = _intendedAttacksFor(domain, playerId);
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

List<IntendedAttack> _intendedAttacksFor(DomainState domain, String playerId) =>
    [
      for (final attack in domain.intendedAttacks)
        if (attack.declaringPlayerId == playerId) attack,
    ];

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
  final domination = _ownIntEntry(
    domain.dominationHoldTurnsByPlayerId,
    playerId,
  );
  final cultural = _ownIntEntry(
    domain.culturalVictoryHoldTurnsByPlayerId,
    playerId,
  );
  final mapObjectiveHolds = [
    for (final entry in domain.mapObjectiveHoldStatesByObjectiveId.entries)
      if (entry.value.playerId == playerId) entry.value,
  ]..sort((left, right) => left.objectiveId.compareTo(right.objectiveId));
  return {
    if (domination.isNotEmpty)
      'dominationHoldTurnsByPlayerId': _sortedIntMap(domination),
    if (cultural.isNotEmpty)
      'culturalVictoryHoldTurnsByPlayerId': _sortedIntMap(cultural),
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
) => {
  for (final relation in state.relations.values)
    if (relation.other(playerId) != null) relation.key,
  for (final otherPlayerId in knownPlayerIds)
    if (state.hasContact(playerId, otherPlayerId))
      DiplomacyState.relationKey(playerId, otherPlayerId),
};

Map<String, DiplomaticRelation> _relationsFor(
  DiplomacyState state,
  String playerId,
) => {
  for (final entry in state.relations.entries)
    if (entry.value.other(playerId) != null) entry.key: entry.value,
};

Map<String, DiplomaticProposal> _proposalsFor(
  DiplomacyState state,
  String playerId,
) => {
  for (final entry in state.pendingProposals.entries)
    if (entry.value.involves(playerId)) entry.key: entry.value,
};

Map<String, DiplomaticMessage> _messagesFor(
  DiplomacyState state,
  String playerId,
) => {
  for (final entry in state.messages.entries)
    if (entry.value.involves(playerId)) entry.key: entry.value,
};

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

Map<String, int> _ownIntEntry(Map<String, int> values, String playerId) {
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
