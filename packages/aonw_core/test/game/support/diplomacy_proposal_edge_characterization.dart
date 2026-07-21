part of '../diplomacy_command_router_characterization_test.dart';

void _registerProposalEdgeCharacterizationTests() {
  _registerProposalPaymentNormalizationTests();
  _registerProposalDuplicateDirectionTests();
  _registerProposalIdTests();
}

void _registerProposalPaymentNormalizationTests() {
  group('proposal payment normalization', () {
    const cases =
        <(String, DiplomaticProposalKind, DiplomaticRelationStatus, int)>[
          (
            'friendship ignores positive payment',
            DiplomaticProposalKind.friendship,
            DiplomaticRelationStatus.neutral,
            99,
          ),
          (
            'truce normalizes zero payment',
            DiplomaticProposalKind.truce,
            DiplomaticRelationStatus.war,
            0,
          ),
          (
            'truce normalizes negative payment',
            DiplomaticProposalKind.truce,
            DiplomaticRelationStatus.war,
            -7,
          ),
        ];

    for (final (name, kind, status, requestedPayment) in cases) {
      test(name, () {
        final diplomacy = status == DiplomaticRelationStatus.neutral
            ? DiplomacyState.empty.addContact(_player1, _player2)
            : DiplomacyState.empty.setStatus(_player1, _player2, status);
        final state = _diplomacyState(diplomacy: diplomacy);
        final result = _route(
          state,
          SendDiplomaticProposalCommand(
            playerId: _player1,
            targetPlayerId: _player2,
            kind: kind,
            proposalId: 'normalized_payment',
            goldPayment: requestedPayment,
          ),
          actorPlayerId: _player1,
          turn: 8,
        );

        expect(result.accepted, isTrue);
        expect(
          result
              .state
              .runtimeState
              .diplomacy
              .pendingProposals['normalized_payment']!
              .goldPayment,
          0,
        );
      });
    }
  });
}

void _registerProposalDuplicateDirectionTests() {
  test('reverse-direction proposal of the same kind is not a duplicate', () {
    final reverse = _proposal(
      id: 'reverse_proposal',
      fromPlayerId: _player2,
      toPlayerId: _player1,
      kind: DiplomaticProposalKind.friendship,
    );
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty.addProposal(reverse),
    );
    final result = _route(
      state,
      const SendDiplomaticProposalCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
        proposalId: 'forward_proposal',
      ),
      actorPlayerId: _player1,
    );

    expect(result.accepted, isTrue);
    expect(result.state.runtimeState.diplomacy.pendingProposals, {
      'reverse_proposal': reverse,
      'forward_proposal': const DiplomaticProposal(
        id: 'forward_proposal',
        fromPlayerId: _player1,
        toPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
        createdTurn: 10,
        expiresOnTurn: 15,
      ),
    });
  });
}

void _registerProposalIdTests() {
  test('generated truce id, duration, and clamped payment are exact', () {
    final unrelated = _proposal(
      id: 'unrelated_proposal',
      fromPlayerId: _player3,
      toPlayerId: _player4,
      kind: DiplomaticProposalKind.friendship,
    );
    final diplomacy = DiplomacyState.empty
        .setStatus(_player1, _player2, DiplomaticRelationStatus.war)
        .addProposal(unrelated);
    final state = _diplomacyState(
      playerGold: const {_player1: 6, _player2: 3, _sentinelPlayer: 97},
      diplomacy: diplomacy,
    );
    final result = _route(
      state,
      const SendDiplomaticProposalCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        kind: DiplomaticProposalKind.truce,
        goldPayment: 20,
      ),
      actorPlayerId: _player1,
      turn: 7,
    );

    const generatedId = 'proposal.7.p1.p2.truce.1';
    final proposal =
        result.state.runtimeState.diplomacy.pendingProposals[generatedId];
    expect(
      proposal,
      const DiplomaticProposal(
        id: generatedId,
        fromPlayerId: _player1,
        toPlayerId: _player2,
        kind: DiplomaticProposalKind.truce,
        createdTurn: 7,
        expiresOnTurn: 12,
        goldPayment: 6,
      ),
    );
    expect(
      result
          .state
          .runtimeState
          .diplomacy
          .pendingProposals['unrelated_proposal'],
      same(unrelated),
    );
    expect(result.state.playerGold, same(state.playerGold));
    expect(result.events, hasLength(1));
    final event = result.events.single as DiplomaticProposalSentEvent;
    expect(event.proposalId, generatedId);
    expect(event.fromPlayerId, _player1);
    expect(event.toPlayerId, _player2);
    expect(event.kind, DiplomaticProposalKind.truce);
    expect(event.expiresOnTurn, 12);
    _expectOuterSentinelsUnchanged(result, state);
    _expectRuntimeSentinelsUnchanged(result, state);
  });

  test('custom proposal id collision overwrites an unrelated entry', () {
    final unrelated = _proposal(
      id: 'shared_id',
      fromPlayerId: _player3,
      toPlayerId: _player4,
      kind: DiplomaticProposalKind.friendship,
    );
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty
          .addContact(_player1, _player2)
          .addProposal(unrelated),
    );
    final result = _route(
      state,
      const SendDiplomaticProposalCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
        proposalId: 'shared_id',
      ),
      actorPlayerId: _player1,
      turn: 8,
    );

    expect(result.accepted, isTrue);
    expect(result.state.runtimeState.diplomacy.pendingProposals, {
      'shared_id': const DiplomaticProposal(
        id: 'shared_id',
        fromPlayerId: _player1,
        toPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
        createdTurn: 8,
        expiresOnTurn: 13,
      ),
    });
    expect(result.events.single, isA<DiplomaticProposalSentEvent>());
  });
}
