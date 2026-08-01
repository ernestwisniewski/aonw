part of '../diplomacy_command_router_characterization_test.dart';

void _registerProposalResponseCharacterizationTests() {
  _registerProposalResponseValidationTests();
  _registerAcceptedProposalResponseTests();
  _registerRejectedProposalResponseTests();
}

void _registerProposalResponseValidationTests() {
  group('proposal response validation precedence and identity', () {
    test('canAct=false wins before proposal lookup', () {
      final state = _diplomacyState();
      final result = _route(
        state,
        const RespondDiplomaticProposalCommand(
          playerId: _player2,
          proposalId: 'missing',
          accepted: true,
        ),
        actorPlayerId: _player2,
        canAct: false,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('actor mismatch wins before proposal lookup', () {
      final state = _diplomacyState();
      final result = _route(
        state,
        const RespondDiplomaticProposalCommand(
          playerId: _player2,
          proposalId: 'missing',
          accepted: true,
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('missing proposal wins before payment validation', () {
      final state = _diplomacyState(playerGold: const {_player1: 0});
      final result = _route(
        state,
        const RespondDiplomaticProposalCommand(
          playerId: _player2,
          proposalId: 'missing',
          accepted: true,
        ),
        actorPlayerId: _player2,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_proposal_not_found');
    });

    test('proposal addressed to another player is treated as missing', () {
      final diplomacy = DiplomacyState.empty.addProposal(
        _proposal(toPlayerId: _player3, goldPayment: 50),
      );
      final state = _diplomacyState(
        playerGold: const {_player1: 0},
        diplomacy: diplomacy,
      );
      final result = _route(
        state,
        const RespondDiplomaticProposalCommand(
          playerId: _player2,
          proposalId: 'proposal_1',
          accepted: true,
        ),
        actorPlayerId: _player2,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_proposal_not_found');
    });

    test('accepted payment is checked before any proposal mutation', () {
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
          accepted: true,
        ),
        actorPlayerId: _player2,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_proposal_payment_unavailable',
      );
      expect(
        result.state.diplomacy.pendingProposals['proposal_1'],
        same(proposal),
      );
    });
  });
}

void _registerAcceptedProposalResponseTests() {
  test('paid truce applies exact state, attack cleanup, and event order', () {
    final fixture = _paidTruceFixture();
    final result = _route(
      fixture.state,
      const RespondDiplomaticProposalCommand(
        playerId: _player2,
        proposalId: 'proposal_1',
        accepted: true,
      ),
      actorPlayerId: _player2,
      turn: 5,
    );

    _expectPaidTruceState(result, fixture);
  });

  test('accepted friendship applies +18 with no status expiry', () {
    final selected = _proposal(kind: DiplomaticProposalKind.friendship);
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty.addProposal(selected),
    );
    final result = _route(
      state,
      const RespondDiplomaticProposalCommand(
        playerId: _player2,
        proposalId: 'proposal_1',
        accepted: true,
      ),
      actorPlayerId: _player2,
      turn: 6,
    );

    final next = result.state.diplomacy;
    final relation = next.relationBetween(_player1, _player2);
    expect(next.pendingProposals, isEmpty);
    expect(relation.status, DiplomaticRelationStatus.friendly);
    expect(relation.statusExpiresOnTurn, isNull);
    expect(relation.lastChangedTurn, 6);
    expect(
      relation.lastChangeReason,
      DiplomaticRelationChangeReason.proposalAccepted,
    );
    expect(relation.relationScore, 18);
    expect(result.events, hasLength(3));
    expect(result.events[0], isA<DiplomaticProposalRespondedEvent>());
    final changed = result.events[1] as DiplomaticRelationChangedEvent;
    expect(changed.oldStatus, DiplomaticRelationStatus.neutral);
    expect(changed.newStatus, DiplomaticRelationStatus.friendly);
    expect(changed.expiresOnTurn, isNull);
    final score = result.events[2] as DiplomaticScoreChangedEvent;
    expect(score.delta, 18);
    expect(score.scoreAfter, 18);
    expect(score.reason, DiplomaticScoreChangeReason.proposalAccepted);
    expect(score.sourceId, 'proposal_1');
    _expectOuterSentinelsUnchanged(result, state);
    _expectRuntimeSentinelsUnchanged(result, state);
  });
}

void _registerRejectedProposalResponseTests() {
  test('a still-stored expired proposal remains respondable', () {
    final selected = _proposal(
      kind: DiplomaticProposalKind.friendship,
      expiresOnTurn: 5,
    );
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty.addProposal(selected),
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
    expect(result.state.diplomacy.pendingProposals, isEmpty);
    expect(result.events, hasLength(2));
  });

  test('rejection removes only the proposal and emits response then score', () {
    final selected = _proposal(kind: DiplomaticProposalKind.friendship);
    final unrelated = _proposal(
      id: 'unrelated_proposal',
      fromPlayerId: _player3,
      toPlayerId: _player4,
      kind: DiplomaticProposalKind.friendship,
    );
    final state = _diplomacyState(
      playerGold: const {_player1: 0, _player2: 3, _sentinelPlayer: 97},
      diplomacy: DiplomacyState.empty
          .addProposal(selected)
          .addProposal(unrelated),
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

    final next = result.state.diplomacy;
    expect(next.pendingProposals, {'unrelated_proposal': unrelated});
    expect(
      next.statusBetween(_player1, _player2),
      DiplomaticRelationStatus.neutral,
    );
    expect(next.relationScoreBetween(_player1, _player2), -6);
    expect(result.state.playerGold, same(state.playerGold));
    expect(result.events, hasLength(2));
    final responded = result.events[0] as DiplomaticProposalRespondedEvent;
    expect(responded.proposalId, 'proposal_1');
    expect(responded.fromPlayerId, _player1);
    expect(responded.toPlayerId, _player2);
    expect(responded.kind, DiplomaticProposalKind.friendship);
    expect(responded.accepted, isFalse);
    final score = result.events[1] as DiplomaticScoreChangedEvent;
    expect(score.playerAId, _player1);
    expect(score.playerBId, _player2);
    expect(score.delta, -6);
    expect(score.scoreAfter, -6);
    expect(score.reason, DiplomaticScoreChangeReason.proposalRejected);
    expect(score.sourceId, 'proposal_1');
    _expectOuterSentinelsUnchanged(result, state);
    _expectRuntimeSentinelsUnchanged(result, state);
  });
}

({
  DomainState state,
  DiplomaticProposal unrelatedProposal,
  List<IntendedAttack> preservedAttacks,
})
_paidTruceFixture() {
  final unrelatedProposal = _proposal(
    id: 'unrelated_proposal',
    fromPlayerId: _player3,
    toPlayerId: _player4,
    kind: DiplomaticProposalKind.friendship,
  );
  const preservedAttacks = [
    IntendedAttack(
      attackerUnitId: 'p1_unit',
      defenderCol: 2,
      defenderRow: 0,
      declaredAtTick: 4,
      declaringPlayerId: _player1,
    ),
    IntendedAttack(
      attackerUnitId: 'missing_unit',
      defenderCol: 1,
      defenderRow: 0,
      declaredAtTick: 5,
      declaringPlayerId: _player1,
    ),
    IntendedAttack(
      attackerUnitId: 'p1_unit',
      defenderCol: 9,
      defenderRow: 9,
      declaredAtTick: 6,
      declaringPlayerId: _player1,
    ),
  ];
  final diplomacy = DiplomacyState.empty
      .setStatus(_player1, _player2, DiplomaticRelationStatus.war)
      .addProposal(_proposal(goldPayment: 7))
      .addProposal(unrelatedProposal);
  final state = _diplomacyState(
    playerGold: const {_player1: 20, _player2: 3, _sentinelPlayer: 97},
    diplomacy: diplomacy,
    units: _proposalResponseUnits(),
    cities: const [
      GameCity(
        id: 'p2_city',
        ownerPlayerId: _player2,
        name: 'P2 City',
        center: CityHex(col: 3, row: 0),
      ),
    ],
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'p1_unit',
        defenderCol: 1,
        defenderRow: 0,
        declaredAtTick: 1,
        declaringPlayerId: _player1,
      ),
      IntendedAttack(
        attackerUnitId: 'p2_unit',
        defenderCol: 0,
        defenderRow: 0,
        declaredAtTick: 2,
        declaringPlayerId: _player2,
      ),
      IntendedAttack(
        attackerUnitId: 'p1_unit',
        defenderCol: 3,
        defenderRow: 0,
        declaredAtTick: 3,
        declaringPlayerId: _player1,
      ),
      ...preservedAttacks,
    ],
  );
  return (
    state: state,
    unrelatedProposal: unrelatedProposal,
    preservedAttacks: preservedAttacks,
  );
}

void _expectPaidTruceState(
  _DiplomacyTestResult result,
  ({
    DomainState state,
    DiplomaticProposal unrelatedProposal,
    List<IntendedAttack> preservedAttacks,
  })
  fixture,
) {
  expect(result.state.playerGold, const {
    _player1: 13,
    _player2: 10,
    _sentinelPlayer: 97,
  });
  final nextDiplomacy = result.state.diplomacy;
  expect(nextDiplomacy.pendingProposals, {
    'unrelated_proposal': fixture.unrelatedProposal,
  });
  final relation = nextDiplomacy.relationBetween(_player1, _player2);
  expect(relation.status, DiplomaticRelationStatus.truce);
  expect(relation.statusExpiresOnTurn, 15);
  expect(relation.lastChangedTurn, 5);
  expect(
    relation.lastChangeReason,
    DiplomaticRelationChangeReason.proposalAccepted,
  );
  expect(relation.relationScore, 10);
  expect(nextDiplomacy.scoreEntriesBetween(_player1, _player2), const [
    DiplomaticScoreEntry(
      playerAId: _player1,
      playerBId: _player2,
      turn: 5,
      delta: 10,
      scoreAfter: 10,
      reason: DiplomaticScoreChangeReason.proposalAccepted,
      sourceId: 'proposal_1',
    ),
  ]);
  expect(result.state.intendedAttacks, fixture.preservedAttacks);
  _expectAcceptedTruceEvents(result.events);
  _expectOuterSentinelsUnchanged(result, fixture.state, goldChanged: true);
  _expectRuntimeSentinelsUnchanged(
    result,
    fixture.state,
    intendedAttacksChanged: true,
  );
}

List<GameUnit> _proposalResponseUnits() {
  return [
    GameUnit.produced(
      id: 'p1_unit',
      ownerPlayerId: _player1,
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    ),
    GameUnit.produced(
      id: 'p2_unit',
      ownerPlayerId: _player2,
      type: GameUnitType.warrior,
      col: 1,
      row: 0,
    ),
    GameUnit.produced(
      id: 'p3_unit',
      ownerPlayerId: _player3,
      type: GameUnitType.warrior,
      col: 2,
      row: 0,
    ),
  ];
}

void _expectAcceptedTruceEvents(List<GameEvent> events) {
  expect(events, hasLength(3));
  final responded = events[0] as DiplomaticProposalRespondedEvent;
  expect(responded.proposalId, 'proposal_1');
  expect(responded.fromPlayerId, _player1);
  expect(responded.toPlayerId, _player2);
  expect(responded.kind, DiplomaticProposalKind.truce);
  expect(responded.accepted, isTrue);
  final relation = events[1] as DiplomaticRelationChangedEvent;
  expect(relation.playerAId, _player1);
  expect(relation.playerBId, _player2);
  expect(relation.oldStatus, DiplomaticRelationStatus.war);
  expect(relation.newStatus, DiplomaticRelationStatus.truce);
  expect(relation.reason, DiplomaticRelationChangeReason.proposalAccepted);
  expect(relation.expiresOnTurn, 15);
  final score = events[2] as DiplomaticScoreChangedEvent;
  expect(score.playerAId, _player1);
  expect(score.playerBId, _player2);
  expect(score.delta, 10);
  expect(score.scoreAfter, 10);
  expect(score.reason, DiplomaticScoreChangeReason.proposalAccepted);
  expect(score.sourceId, 'proposal_1');
}
