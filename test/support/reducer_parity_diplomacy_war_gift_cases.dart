part of 'reducer_parity_diplomacy_characterization.dart';

List<ReducerParityFixture> _warAndGiftParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  return [
    ..._warParityCases(template, baseState),
    ..._giftParityCases(template, baseState),
  ];
}

List<ReducerParityFixture> _warParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  const pairProposal = DiplomaticProposal(
    id: 'war_cleared_pair_proposal',
    fromPlayerId: _diplomacyTargetId,
    toPlayerId: _diplomacyActorId,
    kind: DiplomaticProposalKind.friendship,
    createdTurn: 5,
    expiresOnTurn: 10,
  );
  final selectiveState = _addProposalOracle(baseState, pairProposal);
  final expiredTruce = _withPairStatus(
    baseState,
    DiplomaticRelationStatus.truce,
    expiresOnTurn: _diplomacyTurn,
  );
  return [
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-war-wrong-actor-rejected',
      tickOffset: 220,
      state: _withoutPairContact(baseState),
      command: const DeclareWarCommand(
        playerId: _diplomacyTargetId,
        targetPlayerId: _diplomacyTargetId,
      ),
      reason: 'diplomacy_player_not_controlled',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-war-target-rejected',
      tickOffset: 221,
      state: _withoutPairContact(baseState),
      command: const DeclareWarCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
      ),
      reason: 'diplomacy_target_not_discovered',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-war-active-truce-rejected',
      tickOffset: 222,
      state: _withPairStatus(
        baseState,
        DiplomaticRelationStatus.truce,
        expiresOnTurn: _diplomacyTurn + 1,
      ),
      command: const DeclareWarCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
      ),
      reason: 'diplomacy_truce_active',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-war-already-active-rejected',
      tickOffset: 223,
      state: _withPairStatus(baseState, DiplomaticRelationStatus.war),
      command: const DeclareWarCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
      ),
      reason: 'diplomacy_war_already_active',
    ),
    _acceptedWarFixture(
      template,
      id: 'diplomacy-characterization-war-expired-truce-accepted',
      tickOffset: 224,
      state: expiredTruce,
      oldStatus: DiplomaticRelationStatus.truce,
    ),
    _acceptedWarFixture(
      template,
      id: 'diplomacy-characterization-war-selective-effects-accepted',
      tickOffset: 225,
      state: selectiveState,
      oldStatus: DiplomaticRelationStatus.neutral,
    ),
  ];
}

ReducerParityFixture _acceptedWarFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required DomainState state,
  required DiplomaticRelationStatus oldStatus,
}) {
  return _acceptedDiplomacyFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    state: state,
    command: const DeclareWarCommand(
      playerId: _diplomacyActorId,
      targetPlayerId: _diplomacyTargetId,
    ),
    expectedState: _warOracle(state),
    expectedEvents: [
      DiplomaticRelationChangedEvent(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        oldStatus: oldStatus,
        newStatus: DiplomaticRelationStatus.war,
        reason: DiplomaticRelationChangeReason.declarationOfWar,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: -25,
        scoreAfter: -25,
        reason: DiplomaticScoreChangeReason.declarationOfWar,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyObserverId,
        playerBId: _diplomacyActorId,
        delta: DiplomaticWarmongerReputation.declarationOfWarPenalty,
        scoreAfter: -4,
        reason: DiplomaticScoreChangeReason.warmongerPenalty,
        sourceId: 'warmonger.7.declarationOfWar.player_1.player_2',
      ),
    ],
  );
}

List<ReducerParityFixture> _giftParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  final cooldownState = _giftCooldownState(baseState);
  return [
    ..._giftRejectionCases(template, baseState, cooldownState),
    _giftAcceptanceCase(template, baseState),
  ];
}

List<ReducerParityFixture> _giftRejectionCases(
  ReducerParityFixture template,
  DomainState baseState,
  DomainState cooldownState,
) {
  return [
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-wrong-actor-rejected',
      tickOffset: 230,
      state: _withoutPairContact(baseState),
      command: const SendGoldGiftCommand(
        playerId: _diplomacyTargetId,
        targetPlayerId: _diplomacyTargetId,
        amount: -1,
      ),
      reason: 'diplomacy_player_not_controlled',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-target-rejected',
      tickOffset: 231,
      state: _withoutPairContact(baseState),
      command: const SendGoldGiftCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        amount: -1,
      ),
      reason: 'diplomacy_target_not_discovered',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-negative-rejected',
      tickOffset: 232,
      state: _withPairStatus(baseState, DiplomaticRelationStatus.war),
      command: const SendGoldGiftCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        amount: -1,
      ),
      reason: 'diplomacy_invalid_gold_amount',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-relation-rejected',
      tickOffset: 233,
      state: _withPairStatus(baseState, DiplomaticRelationStatus.war),
      command: const SendGoldGiftCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        amount: 50,
      ),
      reason: 'diplomacy_gold_gift_blocked_by_relation',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-gold-rejected',
      tickOffset: 234,
      state: baseState,
      command: const SendGoldGiftCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        amount: 50,
      ),
      reason: 'diplomacy_gold_unavailable',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-below-minimum-rejected',
      tickOffset: 235,
      state: baseState,
      command: const SendGoldGiftCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        amount: 4,
      ),
      reason: 'diplomacy_gold_gift_unavailable',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-gift-cooldown-rejected',
      tickOffset: 236,
      state: cooldownState,
      command: const SendGoldGiftCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        amount: 10,
      ),
      reason: 'diplomacy_gold_gift_unavailable',
    ),
  ];
}

ReducerParityFixture _giftAcceptanceCase(
  ReducerParityFixture template,
  DomainState baseState,
) {
  return _acceptedDiplomacyFixture(
    template,
    id: 'diplomacy-characterization-gift-transfer-accepted',
    tickOffset: 237,
    state: baseState,
    command: const SendGoldGiftCommand(
      playerId: _diplomacyActorId,
      targetPlayerId: _diplomacyTargetId,
      amount: 10,
    ),
    expectedState: _giftOracle(baseState, 10),
    expectedEvents: [
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: 2,
        scoreAfter: 2,
        reason: DiplomaticScoreChangeReason.goldGift,
        sourceId: 'gold_gift.7.player_1.player_2',
      ),
    ],
  );
}

DomainState _giftCooldownState(DomainState state) {
  final diplomacy = state.diplomacy;
  final key = DiplomacyState.relationKey(_diplomacyActorId, _diplomacyTargetId);
  final entry = DiplomaticScoreEntry.between(
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyTargetId,
    turn: 5,
    delta: 2,
    scoreAfter: 2,
    reason: DiplomaticScoreChangeReason.goldGift,
    sourceId: 'earlier_gift',
  );
  final relation = DiplomaticRelation.between(
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyTargetId,
    relationScore: 2,
  );
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      contactKeys: {...diplomacy.contactKeys, key},
      relations: {...diplomacy.relations, key: relation},
      scoreHistory: {
        ...diplomacy.scoreHistory,
        key: [entry],
      },
    ),
  );
}
