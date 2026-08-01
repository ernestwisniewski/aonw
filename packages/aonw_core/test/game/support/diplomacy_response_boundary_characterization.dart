part of '../diplomacy_command_router_characterization_test.dart';

void _registerResponseBoundaryCharacterizationTests() {
  _registerDeclinedProposalFundingBoundaryTest();
  _registerProposalResponseWithoutDiscoveryTest();
  _registerMessageResponseWithoutDiscoveryTest();
}

void _registerDeclinedProposalFundingBoundaryTest() {
  test('declining a paid proposal does not require available payment', () {
    final proposal = _proposal(goldPayment: 7);
    final state = _diplomacyState(
      playerGold: const {_player1: 4, _player2: 3},
      diplomacy: DiplomacyState.empty.addProposal(proposal),
    );
    final result = _route(
      state,
      const RespondDiplomaticProposalCommand(
        playerId: _player2,
        proposalId: 'proposal_1',
        accepted: false,
      ),
      actorPlayerId: _player2,
      turn: 6,
    );

    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(result.state.playerGold, same(state.playerGold));
    expect(result.state.diplomacy.pendingProposals, isEmpty);
    expect(result.state.diplomacy.relationScoreBetween(_player1, _player2), -6);
    expect(result.events, hasLength(2));
    expect(result.events[0], isA<DiplomaticProposalRespondedEvent>());
    final score = result.events[1] as DiplomaticScoreChangedEvent;
    expect(score.delta, -6);
    expect(score.reason, DiplomaticScoreChangeReason.proposalRejected);
  });
}

void _registerProposalResponseWithoutDiscoveryTest() {
  test('proposal response needs neither known players nor contact', () {
    final proposal = _proposal(kind: DiplomaticProposalKind.friendship);
    final diplomacy = DiplomacyState(
      pendingProposals: {'proposal_1': proposal},
    );
    final state = _stateWithoutKnownDiplomacyPlayers(diplomacy);
    expect(diplomacy.contactKeys, isEmpty);
    expect(state.knownPlayerIds, isNot(contains(_player1)));
    expect(state.knownPlayerIds, isNot(contains(_player2)));

    final result = _route(
      state,
      const RespondDiplomaticProposalCommand(
        playerId: _player2,
        proposalId: 'proposal_1',
        accepted: false,
      ),
      actorPlayerId: _player2,
      turn: 6,
    );

    expect(result.accepted, isTrue);
    expect(result.state.diplomacy.pendingProposals, isEmpty);
    expect(result.events, hasLength(2));
  });
}

void _registerMessageResponseWithoutDiscoveryTest() {
  test('message response needs neither known players nor contact', () {
    const message = DiplomaticMessage(
      id: 'message_1',
      fromPlayerId: _player1,
      toPlayerId: _player2,
      topic: DiplomaticMessageTopic.peacefulPraise,
      category: DiplomaticMessageCategory.praise,
      createdTurn: 4,
      expiresOnTurn: 12,
    );
    final diplomacy = DiplomacyState(messages: const {'message_1': message});
    final state = _stateWithoutKnownDiplomacyPlayers(diplomacy);
    expect(diplomacy.contactKeys, isEmpty);
    expect(state.knownPlayerIds, isNot(contains(_player1)));
    expect(state.knownPlayerIds, isNot(contains(_player2)));

    final result = _route(
      state,
      const RespondDiplomaticMessageCommand(
        playerId: _player2,
        messageId: 'message_1',
        response: DiplomaticMessageResponse.neutral,
      ),
      actorPlayerId: _player2,
      turn: 6,
    );

    expect(result.accepted, isTrue);
    final updated = result.state.diplomacy.messages['message_1']!;
    expect(updated.response, DiplomaticMessageResponse.neutral);
    expect(updated.relationScoreDelta, 2);
    expect(updated.relationScoreAfter, 2);
    expect(result.events, hasLength(2));
  });
}

DomainState _stateWithoutKnownDiplomacyPlayers(DiplomacyState diplomacy) {
  return _diplomacyState(
    playerColors: const {_sentinelPlayer: 99},
    playerCountries: const {_sentinelPlayer: PlayerCountry.greece},
    playerGold: const {_sentinelPlayer: 97},
    playerWarWeariness: const {_sentinelPlayer: 5},
    playerStabilityNet: const {_sentinelPlayer: 8},
    diplomacy: diplomacy,
  );
}
