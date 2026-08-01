part of 'reducer_parity_diplomacy_characterization.dart';

DomainState _withDiplomacyOracle(DomainState state, DiplomacyState diplomacy) {
  return state.copyWith(diplomacy: diplomacy);
}

DomainState _withRelationOracle(
  DomainState state, {
  required String playerAId,
  required String playerBId,
  required DiplomaticRelationStatus status,
  int? statusExpiresOnTurn,
  int? lastChangedTurn,
  DiplomaticRelationChangeReason? lastChangeReason,
}) {
  final diplomacy = state.diplomacy;
  final key = DiplomacyState.relationKey(playerAId, playerBId);
  final existing = diplomacy.relations[key];
  final relation = DiplomaticRelation.between(
    playerAId: playerAId,
    playerBId: playerBId,
    status: status,
    relationScore: existing?.relationScore ?? 0,
    statusExpiresOnTurn: statusExpiresOnTurn,
    lastChangedTurn: lastChangedTurn,
    lastChangeReason: lastChangeReason,
  );
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      contactKeys: {...diplomacy.contactKeys, key},
      relations: {...diplomacy.relations, key: relation},
    ),
  );
}

({DomainState state, DiplomaticScoreEntry entry}) _adjustScoreOracle(
  DomainState state, {
  required String playerAId,
  required String playerBId,
  required int delta,
  required DiplomaticScoreChangeReason reason,
  String? sourceId,
}) {
  final diplomacy = state.diplomacy;
  final key = DiplomacyState.relationKey(playerAId, playerBId);
  final existing =
      diplomacy.relations[key] ??
      DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
  final scoreAfter = (existing.relationScore + delta).clamp(
    DiplomacyState.minRelationScore,
    DiplomacyState.maxRelationScore,
  );
  final appliedDelta = scoreAfter - existing.relationScore;
  final relation = DiplomaticRelation.between(
    playerAId: existing.playerAId,
    playerBId: existing.playerBId,
    status: existing.status,
    relationScore: scoreAfter,
    statusExpiresOnTurn: existing.statusExpiresOnTurn,
    lastChangedTurn: existing.lastChangedTurn,
    lastChangeReason: existing.lastChangeReason,
  );
  final entry = DiplomaticScoreEntry.between(
    playerAId: playerAId,
    playerBId: playerBId,
    turn: _diplomacyTurn,
    delta: appliedDelta,
    scoreAfter: scoreAfter,
    reason: reason,
    sourceId: sourceId,
  );
  final history = <String, List<DiplomaticScoreEntry>>{
    for (final historyEntry in diplomacy.scoreHistory.entries)
      historyEntry.key: [...historyEntry.value],
  }..putIfAbsent(key, () => []).add(entry);
  return (
    state: _withDiplomacyOracle(
      state,
      diplomacy.copyWith(
        contactKeys: {...diplomacy.contactKeys, key},
        relations: {...diplomacy.relations, key: relation},
        scoreHistory: history,
      ),
    ),
    entry: entry,
  );
}

DomainState _addProposalOracle(DomainState state, DiplomaticProposal proposal) {
  final diplomacy = state.diplomacy;
  final key = DiplomacyState.relationKey(
    proposal.fromPlayerId,
    proposal.toPlayerId,
  );
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      contactKeys: {...diplomacy.contactKeys, key},
      pendingProposals: {...diplomacy.pendingProposals, proposal.id: proposal},
    ),
  );
}

DomainState _removeProposalOracle(DomainState state, String proposalId) {
  final diplomacy = state.diplomacy;
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      pendingProposals: {...diplomacy.pendingProposals}..remove(proposalId),
    ),
  );
}

DomainState _addMessageOracle(DomainState state, DiplomaticMessage message) {
  final diplomacy = state.diplomacy;
  final key = DiplomacyState.relationKey(
    message.fromPlayerId,
    message.toPlayerId,
  );
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      contactKeys: {...diplomacy.contactKeys, key},
      messages: {...diplomacy.messages, message.id: message},
    ),
  );
}

DomainState _updateMessageOracle(DomainState state, DiplomaticMessage message) {
  final diplomacy = state.diplomacy;
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(messages: {...diplomacy.messages, message.id: message}),
  );
}

DomainState _acceptedProposalResponseOracle(
  DomainState state,
  DiplomaticProposal proposal, {
  required DiplomaticRelationStatus status,
  required int relationDelta,
}) {
  var next = _removeProposalOracle(state, proposal.id);
  next = _withRelationOracle(
    next,
    playerAId: proposal.fromPlayerId,
    playerBId: proposal.toPlayerId,
    status: status,
    statusExpiresOnTurn: proposal.kind == DiplomaticProposalKind.truce
        ? _diplomacyTurn + DiplomacyState.defaultTruceDurationTurns
        : null,
    lastChangedTurn: _diplomacyTurn,
    lastChangeReason: DiplomaticRelationChangeReason.proposalAccepted,
  );
  next = _adjustScoreOracle(
    next,
    playerAId: proposal.fromPlayerId,
    playerBId: proposal.toPlayerId,
    delta: relationDelta,
    reason: DiplomaticScoreChangeReason.proposalAccepted,
    sourceId: proposal.id,
  ).state;
  final retainedAttacks = state.intendedAttacks.sublist(2);
  next = next.copyWith(intendedAttacks: retainedAttacks);
  if (proposal.goldPayment <= 0) return next;
  return next.copyWith(
    playerGold: {
      ...next.playerGold,
      proposal.fromPlayerId:
          next.playerGold[proposal.fromPlayerId]! - proposal.goldPayment,
      proposal.toPlayerId:
          next.playerGold[proposal.toPlayerId]! + proposal.goldPayment,
    },
  );
}

DomainState _declinedProposalResponseOracle(
  DomainState state,
  DiplomaticProposal proposal,
) {
  return _adjustScoreOracle(
    _removeProposalOracle(state, proposal.id),
    playerAId: proposal.fromPlayerId,
    playerBId: proposal.toPlayerId,
    delta: -6,
    reason: DiplomaticScoreChangeReason.proposalRejected,
    sourceId: proposal.id,
  ).state;
}

DomainState _warOracle(DomainState state) {
  final pairKey = DiplomacyState.relationKey(
    _diplomacyActorId,
    _diplomacyTargetId,
  );
  var next = _withRelationOracle(
    state,
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyTargetId,
    status: DiplomaticRelationStatus.war,
    lastChangedTurn: _diplomacyTurn,
    lastChangeReason: DiplomaticRelationChangeReason.declarationOfWar,
  );
  final diplomacy = next.diplomacy;
  next = _withDiplomacyOracle(
    next,
    diplomacy.copyWith(
      pendingProposals: {
        for (final entry in diplomacy.pendingProposals.entries)
          if (DiplomacyState.relationKey(
                entry.value.fromPlayerId,
                entry.value.toPlayerId,
              ) !=
              pairKey)
            entry.key: entry.value,
      },
    ),
  );
  next = _adjustScoreOracle(
    next,
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyTargetId,
    delta: -25,
    reason: DiplomaticScoreChangeReason.declarationOfWar,
    sourceId: null,
  ).state;
  next = _adjustScoreOracle(
    next,
    playerAId: _diplomacyObserverId,
    playerBId: _diplomacyActorId,
    delta: DiplomaticWarmongerReputation.declarationOfWarPenalty,
    reason: DiplomaticScoreChangeReason.warmongerPenalty,
    sourceId: 'warmonger.7.declarationOfWar.player_1.player_2',
  ).state;
  return next.copyWith(resourceTradeAgreements: const [_unrelatedTrade]);
}

DomainState _giftOracle(DomainState state, int amount) {
  final next = _adjustScoreOracle(
    state,
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyTargetId,
    delta: amount ~/ DiplomaticGoldGiftRules.minimumAmount,
    reason: DiplomaticScoreChangeReason.goldGift,
    sourceId: 'gold_gift.7.player_1.player_2',
  ).state;
  return next.copyWith(
    playerGold: {
      ...next.playerGold,
      _diplomacyActorId: next.playerGold[_diplomacyActorId]! - amount,
      _diplomacyTargetId: next.playerGold[_diplomacyTargetId]! + amount,
    },
  );
}

DomainState _messageResponseOracle(
  DomainState state,
  DiplomaticMessage message,
  DiplomaticMessageResponse response, {
  required int delta,
  required DiplomaticScoreChangeReason reason,
}) {
  final adjusted = _adjustScoreOracle(
    state,
    playerAId: message.fromPlayerId,
    playerBId: message.toPlayerId,
    delta: delta,
    reason: reason,
    sourceId: message.id,
  );
  final promiseDueTurn =
      response == DiplomaticMessageResponse.conciliatory &&
          message.topic.canCreateWithdrawalPromise
      ? _diplomacyTurn + DiplomacyState.defaultPromiseDurationTurns
      : null;
  final updated = message.copyWith(
    response: response,
    respondedTurn: _diplomacyTurn,
    relationScoreDelta: adjusted.entry.delta,
    relationScoreAfter: adjusted.entry.scoreAfter,
    promiseDueTurn: promiseDueTurn,
  );
  return _updateMessageOracle(adjusted.state, updated);
}

DiplomaticScoreChangedEvent _scoreEventOracle({
  required String playerAId,
  required String playerBId,
  required int delta,
  required int scoreAfter,
  required DiplomaticScoreChangeReason reason,
  String? sourceId,
}) {
  final pair = DiplomacyState.normalizedPair(playerAId, playerBId);
  return DiplomaticScoreChangedEvent(
    playerAId: pair.$1,
    playerBId: pair.$2,
    delta: delta,
    scoreAfter: scoreAfter,
    reason: reason,
    sourceId: sourceId,
  );
}
