part of 'reducer_parity_diplomacy_characterization.dart';

List<ReducerParityFixture> _proposalParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  return [
    ..._proposalSendParityCases(template, baseState),
    ..._proposalResponseParityCases(template, baseState),
  ];
}

List<ReducerParityFixture> _proposalSendParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  const duplicateProposal = DiplomaticProposal(
    id: 'pair_duplicate_proposal',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    kind: DiplomaticProposalKind.friendship,
    createdTurn: 3,
    expiresOnTurn: 10,
  );
  final duplicateState = _addProposalOracle(baseState, duplicateProposal);
  const generatedFriendship = DiplomaticProposal(
    id: 'proposal.7.player_1.player_2.friendship.1',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    kind: DiplomaticProposalKind.friendship,
    createdTurn: _diplomacyTurn,
    expiresOnTurn: _diplomacyTurn + DiplomacyState.defaultProposalDurationTurns,
  );
  final warState = _withPairStatus(baseState, DiplomaticRelationStatus.war);
  const generatedPaidTruce = DiplomaticProposal(
    id: 'proposal.7.player_1.player_2.truce.1',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    kind: DiplomaticProposalKind.truce,
    createdTurn: _diplomacyTurn,
    expiresOnTurn: _diplomacyTurn + DiplomacyState.defaultProposalDurationTurns,
    goldPayment: 17,
  );
  return [
    ..._proposalSendRejections(template, baseState, duplicateState),
    ..._proposalSendAcceptances(
      template,
      baseState,
      warState,
      generatedFriendship,
      generatedPaidTruce,
    ),
  ];
}

List<ReducerParityFixture> _proposalSendRejections(
  ReducerParityFixture template,
  DomainState baseState,
  DomainState duplicateState,
) {
  return [
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-send-wrong-actor-rejected',
      tickOffset: 200,
      state: _withoutPairContact(baseState),
      command: const SendDiplomaticProposalCommand(
        playerId: _diplomacyTargetId,
        targetPlayerId: _diplomacyTargetId,
        kind: DiplomaticProposalKind.truce,
      ),
      reason: 'diplomacy_player_not_controlled',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-send-target-rejected',
      tickOffset: 201,
      state: _withoutPairContact(duplicateState),
      command: const SendDiplomaticProposalCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        kind: DiplomaticProposalKind.friendship,
      ),
      reason: 'diplomacy_target_not_discovered',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-send-not-allowed-rejected',
      tickOffset: 202,
      state: baseState,
      command: const SendDiplomaticProposalCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        kind: DiplomaticProposalKind.truce,
      ),
      reason: 'diplomacy_proposal_not_allowed',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-send-duplicate-rejected',
      tickOffset: 203,
      state: duplicateState,
      command: const SendDiplomaticProposalCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        kind: DiplomaticProposalKind.friendship,
        proposalId: 'ignored_duplicate_id',
      ),
      reason: 'diplomacy_duplicate_proposal',
    ),
  ];
}

List<ReducerParityFixture> _proposalSendAcceptances(
  ReducerParityFixture template,
  DomainState baseState,
  DomainState warState,
  DiplomaticProposal generatedFriendship,
  DiplomaticProposal generatedPaidTruce,
) {
  return [
    _acceptedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-send-generated-id-accepted',
      tickOffset: 204,
      state: baseState,
      command: const SendDiplomaticProposalCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        kind: DiplomaticProposalKind.friendship,
      ),
      expectedState: _addProposalOracle(baseState, generatedFriendship),
      expectedEvents: [
        DiplomaticProposalSentEvent(
          proposalId: generatedFriendship.id,
          fromPlayerId: _diplomacyActorId,
          toPlayerId: _diplomacyTargetId,
          kind: DiplomaticProposalKind.friendship,
          expiresOnTurn: generatedFriendship.expiresOnTurn,
        ),
      ],
    ),
    _acceptedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-send-paid-truce-accepted',
      tickOffset: 205,
      state: warState,
      command: const SendDiplomaticProposalCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        kind: DiplomaticProposalKind.truce,
        goldPayment: 50,
      ),
      expectedState: _addProposalOracle(warState, generatedPaidTruce),
      expectedEvents: [
        DiplomaticProposalSentEvent(
          proposalId: generatedPaidTruce.id,
          fromPlayerId: _diplomacyActorId,
          toPlayerId: _diplomacyTargetId,
          kind: DiplomaticProposalKind.truce,
          expiresOnTurn: generatedPaidTruce.expiresOnTurn,
        ),
      ],
    ),
  ];
}

List<ReducerParityFixture> _proposalResponseParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  const friendship = DiplomaticProposal(
    id: 'pair_friendship_proposal',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    kind: DiplomaticProposalKind.friendship,
    createdTurn: 5,
    expiresOnTurn: 10,
  );
  const paidTruce = DiplomaticProposal(
    id: 'pair_paid_truce_proposal',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    kind: DiplomaticProposalKind.truce,
    createdTurn: 5,
    expiresOnTurn: 10,
    goldPayment: 7,
  );
  final friendshipState = _addProposalOracle(baseState, friendship);
  final truceState = _addProposalOracle(
    _withPairStatus(baseState, DiplomaticRelationStatus.war),
    paidTruce,
  );
  final underfundedState = _addProposalOracle(
    _withPairStatus(
      baseState.copyWith(
        playerGold: {...baseState.playerGold, _diplomacyActorId: 4},
      ),
      DiplomaticRelationStatus.war,
    ),
    paidTruce,
  );
  return [
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-response-wrong-actor-rejected',
      tickOffset: 210,
      state: baseState,
      command: const RespondDiplomaticProposalCommand(
        playerId: _diplomacyTargetId,
        proposalId: 'missing_proposal',
        accepted: true,
      ),
      reason: 'diplomacy_player_not_controlled',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-response-not-found-rejected',
      tickOffset: 211,
      actorPlayerId: _diplomacyTargetId,
      state: baseState,
      command: const RespondDiplomaticProposalCommand(
        playerId: _diplomacyTargetId,
        proposalId: 'missing_proposal',
        accepted: true,
      ),
      reason: 'diplomacy_proposal_not_found',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-proposal-response-payment-rejected',
      tickOffset: 212,
      actorPlayerId: _diplomacyTargetId,
      state: underfundedState,
      command: RespondDiplomaticProposalCommand(
        playerId: _diplomacyTargetId,
        proposalId: paidTruce.id,
        accepted: true,
      ),
      reason: 'diplomacy_proposal_payment_unavailable',
    ),
    _acceptedProposalDeclineFixture(template, friendshipState, friendship),
    _acceptedProposalFriendshipFixture(template, friendshipState, friendship),
    _acceptedProposalTruceFixture(template, truceState, paidTruce),
  ];
}

ReducerParityFixture _acceptedProposalDeclineFixture(
  ReducerParityFixture template,
  DomainState state,
  DiplomaticProposal proposal,
) {
  return _acceptedDiplomacyFixture(
    template,
    id: 'diplomacy-characterization-proposal-response-declined-accepted',
    tickOffset: 213,
    actorPlayerId: _diplomacyTargetId,
    state: state,
    command: RespondDiplomaticProposalCommand(
      playerId: _diplomacyTargetId,
      proposalId: proposal.id,
      accepted: false,
    ),
    expectedState: _declinedProposalResponseOracle(state, proposal),
    expectedEvents: [
      DiplomaticProposalRespondedEvent(
        proposalId: proposal.id,
        fromPlayerId: _diplomacyActorId,
        toPlayerId: _diplomacyTargetId,
        kind: proposal.kind,
        accepted: false,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: -6,
        scoreAfter: -6,
        reason: DiplomaticScoreChangeReason.proposalRejected,
        sourceId: proposal.id,
      ),
    ],
  );
}

ReducerParityFixture _acceptedProposalFriendshipFixture(
  ReducerParityFixture template,
  DomainState state,
  DiplomaticProposal proposal,
) {
  return _acceptedDiplomacyFixture(
    template,
    id: 'diplomacy-characterization-proposal-response-friendship-accepted',
    tickOffset: 214,
    actorPlayerId: _diplomacyTargetId,
    state: state,
    command: RespondDiplomaticProposalCommand(
      playerId: _diplomacyTargetId,
      proposalId: proposal.id,
      accepted: true,
    ),
    expectedState: _acceptedProposalResponseOracle(
      state,
      proposal,
      status: DiplomaticRelationStatus.friendly,
      relationDelta: 18,
    ),
    expectedEvents: [
      DiplomaticProposalRespondedEvent(
        proposalId: proposal.id,
        fromPlayerId: _diplomacyActorId,
        toPlayerId: _diplomacyTargetId,
        kind: proposal.kind,
        accepted: true,
      ),
      const DiplomaticRelationChangedEvent(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        oldStatus: DiplomaticRelationStatus.neutral,
        newStatus: DiplomaticRelationStatus.friendly,
        reason: DiplomaticRelationChangeReason.proposalAccepted,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: 18,
        scoreAfter: 18,
        reason: DiplomaticScoreChangeReason.proposalAccepted,
        sourceId: proposal.id,
      ),
    ],
  );
}

ReducerParityFixture _acceptedProposalTruceFixture(
  ReducerParityFixture template,
  DomainState state,
  DiplomaticProposal proposal,
) {
  return _acceptedDiplomacyFixture(
    template,
    id: 'diplomacy-characterization-proposal-response-paid-truce-accepted',
    tickOffset: 215,
    actorPlayerId: _diplomacyTargetId,
    state: state,
    command: RespondDiplomaticProposalCommand(
      playerId: _diplomacyTargetId,
      proposalId: proposal.id,
      accepted: true,
    ),
    expectedState: _acceptedProposalResponseOracle(
      state,
      proposal,
      status: DiplomaticRelationStatus.truce,
      relationDelta: 10,
    ),
    expectedEvents: [
      DiplomaticProposalRespondedEvent(
        proposalId: proposal.id,
        fromPlayerId: _diplomacyActorId,
        toPlayerId: _diplomacyTargetId,
        kind: proposal.kind,
        accepted: true,
      ),
      const DiplomaticRelationChangedEvent(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        oldStatus: DiplomaticRelationStatus.war,
        newStatus: DiplomaticRelationStatus.truce,
        reason: DiplomaticRelationChangeReason.proposalAccepted,
        expiresOnTurn:
            _diplomacyTurn + DiplomacyState.defaultTruceDurationTurns,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: 10,
        scoreAfter: 10,
        reason: DiplomaticScoreChangeReason.proposalAccepted,
        sourceId: proposal.id,
      ),
    ],
  );
}
