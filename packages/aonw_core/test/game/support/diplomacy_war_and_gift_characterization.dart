part of '../diplomacy_command_router_characterization_test.dart';

void _registerWarAndGiftCharacterizationTests() {
  _registerWarValidationTests();
  _registerWarSuccessTests();
  _registerGoldGiftValidationTests();
  _registerGoldGiftSuccessTests();
}

void _registerWarValidationTests() {
  group('war declaration validation precedence and identity', () {
    test('canAct=false wins before target and relation checks', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.setStatus(
          _player1,
          _player2,
          DiplomaticRelationStatus.war,
        ),
      );
      final result = _route(
        state,
        const DeclareWarCommand(playerId: _player1, targetPlayerId: _player2),
        actorPlayerId: _player1,
        canAct: false,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('actor mismatch wins before target validation', () {
      final state = _diplomacyState(diplomacy: DiplomacyState.empty);
      final result = _route(
        state,
        const DeclareWarCommand(playerId: _player1, targetPlayerId: ''),
        actorPlayerId: _player2,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('unknown target wins before relation checks', () {
      final state = _diplomacyState(
        playerColors: const {_player1: 1},
        playerCountries: const {},
        playerGold: const {_player1: 10},
        diplomacy: DiplomacyState.empty,
      );
      final result = _route(
        state,
        const DeclareWarCommand(playerId: _player1, targetPlayerId: _player2),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_target_not_discovered',
      );
    });

    test('active truce blocks before already-war check', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.setStatus(
          _player1,
          _player2,
          DiplomaticRelationStatus.truce,
          statusExpiresOnTurn: 12,
        ),
      );
      final result = _route(
        state,
        const DeclareWarCommand(playerId: _player1, targetPlayerId: _player2),
        actorPlayerId: _player1,
        turn: 10,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_truce_active');
    });

    test('existing war is the final rejection', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.setStatus(
          _player1,
          _player2,
          DiplomaticRelationStatus.war,
        ),
      );
      final result = _route(
        state,
        const DeclareWarCommand(playerId: _player1, targetPlayerId: _player2),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_war_already_active');
    });
  });

  for (final expiry in <int?>[10, null]) {
    test('truce expiry $expiry permits war at turn 10', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.setStatus(
          _player1,
          _player2,
          DiplomaticRelationStatus.truce,
          statusExpiresOnTurn: expiry,
        ),
      );
      final result = _route(
        state,
        const DeclareWarCommand(playerId: _player1, targetPlayerId: _player2),
        actorPlayerId: _player1,
        turn: 10,
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.runtimeState.diplomacy.statusBetween(_player1, _player2),
        DiplomaticRelationStatus.war,
      );
    });
  }
}

void _registerWarSuccessTests() {
  test('war cleanup, warmonger scores, and event order are exact', () {
    final pairProposal = _proposal(
      id: 'pair_forward',
      kind: DiplomaticProposalKind.friendship,
    );
    final reverseProposal = _proposal(
      id: 'pair_reverse',
      fromPlayerId: _player2,
      toPlayerId: _player1,
      kind: DiplomaticProposalKind.truce,
    );
    final unrelatedProposal = _proposal(
      id: 'unrelated_proposal',
      fromPlayerId: _player3,
      toPlayerId: _player4,
      kind: DiplomaticProposalKind.friendship,
    );
    final diplomacy = DiplomacyState.empty
        .addContact(_player1, _player2)
        .addContact(_player1, _player4)
        .addContact(_player2, _player4)
        .addContact(_player1, _player3)
        .addContact(_player2, _player3)
        .addContact(_player1, 'p5')
        .addProposal(pairProposal)
        .addProposal(reverseProposal)
        .addProposal(unrelatedProposal);
    const pairForwardTrade = ResourceTradeAgreement(
      id: 'pair_forward_trade',
      exporterPlayerId: _player1,
      importerPlayerId: _player2,
      resource: ResourceType.iron,
      goldPerTurn: 2,
      remainingTurns: 4,
    );
    const unrelatedTrade = ResourceTradeAgreement(
      id: 'unrelated_trade',
      exporterPlayerId: _player1,
      importerPlayerId: _player3,
      resource: ResourceType.horses,
      goldPerTurn: 1,
      remainingTurns: 5,
    );
    const pairReverseTrade = ResourceTradeAgreement(
      id: 'pair_reverse_trade',
      exporterPlayerId: _player2,
      importerPlayerId: _player1,
      resource: ResourceType.coal,
      goldPerTurn: 3,
      remainingTurns: 6,
    );
    final state = _diplomacyState(
      diplomacy: diplomacy,
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'sentinel_attacker',
          defenderCol: 8,
          defenderRow: 8,
          declaredAtTick: 41,
          declaringPlayerId: _sentinelPlayer,
        ),
      ],
      resourceTradeAgreements: const [
        pairForwardTrade,
        unrelatedTrade,
        pairReverseTrade,
        _sentinelTrade,
      ],
    );
    final result = _route(
      state,
      const DeclareWarCommand(playerId: _player1, targetPlayerId: _player2),
      actorPlayerId: _player1,
      turn: 9,
    );

    final next = result.state.runtimeState.diplomacy;
    expect(
      next.statusBetween(_player1, _player2),
      DiplomaticRelationStatus.war,
    );
    expect(next.relationScoreBetween(_player1, _player2), -25);
    expect(next.relationScoreBetween(_player1, _player3), -8);
    expect(next.relationScoreBetween(_player1, _player4), -8);
    expect(next.relationScoreBetween(_player1, 'p5'), 0);
    expect(next.pendingProposals, {'unrelated_proposal': unrelatedProposal});
    expect(result.state.runtimeState.resourceTradeAgreements, const [
      unrelatedTrade,
      _sentinelTrade,
    ]);
    expect(
      result.state.runtimeState.intendedAttacks,
      same(state.runtimeState.intendedAttacks),
    );
    _expectWarEvents(result.events);
    _expectOuterSentinelsUnchanged(result, state);
    _expectRuntimeSentinelsUnchanged(result, state, tradesChanged: true);
  });
}

void _registerGoldGiftValidationTests() {
  group('gold gift validation precedence and identity', () {
    test('canAct=false wins before target, amount, and relation checks', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.setStatus(
          _player1,
          _player2,
          DiplomaticRelationStatus.war,
        ),
      );
      final result = _route(
        state,
        const SendGoldGiftCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          amount: -1,
        ),
        actorPlayerId: _player1,
        canAct: false,
      );
      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('actor mismatch wins before target and amount validation', () {
      final state = _diplomacyState(diplomacy: DiplomacyState.empty);
      final result = _route(
        state,
        const SendGoldGiftCommand(
          playerId: _player1,
          targetPlayerId: '',
          amount: -1,
        ),
        actorPlayerId: _player2,
      );
      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('unknown target wins before invalid amount', () {
      final state = _diplomacyState(
        playerColors: const {_player1: 1},
        playerCountries: const {},
        playerGold: const {_player1: 100},
        diplomacy: DiplomacyState.empty,
      );
      final result = _route(
        state,
        const SendGoldGiftCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          amount: -1,
        ),
        actorPlayerId: _player1,
      );
      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_target_not_discovered',
      );
    });

    test('negative amount wins before a blocked relation', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.setStatus(
          _player1,
          _player2,
          DiplomaticRelationStatus.war,
        ),
      );
      final result = _sendGift(state, amount: -1);
      _expectRejectedDiplomacy(result, state, 'diplomacy_invalid_gold_amount');
    });

    for (final status in [
      DiplomaticRelationStatus.war,
      DiplomaticRelationStatus.truce,
    ]) {
      test('${status.name} wins before gold availability', () {
        final state = _diplomacyState(
          playerGold: const {_player1: 0},
          diplomacy: DiplomacyState.empty.setStatus(_player1, _player2, status),
        );
        final result = _sendGift(state, amount: 10);
        _expectRejectedDiplomacy(
          result,
          state,
          'diplomacy_gold_gift_blocked_by_relation',
        );
      });
    }

    test('insufficient gold wins before the minimum gift rule', () {
      final state = _diplomacyState(playerGold: const {_player1: 3});
      final result = _sendGift(state, amount: 4);
      _expectRejectedDiplomacy(result, state, 'diplomacy_gold_unavailable');
    });

    test('below-minimum amount is the final non-cooldown rejection', () {
      final state = _diplomacyState(playerGold: const {_player1: 100});
      final result = _sendGift(state, amount: 4);
      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_gold_gift_unavailable',
      );
    });
  });
}

void _registerGoldGiftSuccessTests() {
  test('gift transfer, capped score, source id, and event are exact', () {
    final state = _diplomacyState(
      playerGold: const {_player1: 100, _sentinelPlayer: 97},
    );
    final result = _sendGift(state, amount: 100, turn: 6);

    expect(result.state.playerGold, const {
      _player1: 0,
      _player2: 100,
      _sentinelPlayer: 97,
    });
    expect(
      result.state.runtimeState.diplomacy.relationScoreBetween(
        _player1,
        _player2,
      ),
      12,
    );
    expect(result.events, hasLength(1));
    final score = result.events.single as DiplomaticScoreChangedEvent;
    expect(score.playerAId, _player1);
    expect(score.playerBId, _player2);
    expect(score.delta, 12);
    expect(score.scoreAfter, 12);
    expect(score.reason, DiplomaticScoreChangeReason.goldGift);
    expect(score.sourceId, 'gold_gift.6.p1.p2');
    _expectOuterSentinelsUnchanged(result, state, goldChanged: true);
    _expectRuntimeSentinelsUnchanged(result, state);
  });

  test('reverse gift cooldown, boundary, and future entries are exact', () {
    final recent = DiplomacyState.empty
        .addContact(_player1, _player2)
        .adjustRelationScore(
          _player2,
          _player1,
          2,
          turn: 8,
          reason: DiplomaticScoreChangeReason.goldGift,
          sourceId: 'reverse_gift',
        );
    final recentState = _diplomacyState(diplomacy: recent);
    final blocked = _sendGift(recentState, amount: 5, turn: 10);
    final boundary = _sendGift(recentState, amount: 5, turn: 13);
    final futureState = _diplomacyState(
      diplomacy: DiplomacyState.empty
          .addContact(_player1, _player2)
          .adjustRelationScore(
            _player2,
            _player1,
            2,
            turn: 20,
            reason: DiplomaticScoreChangeReason.goldGift,
            sourceId: 'future_gift',
          ),
    );
    final future = _sendGift(futureState, amount: 5, turn: 10);

    _expectRejectedDiplomacy(
      blocked,
      recentState,
      'diplomacy_gold_gift_unavailable',
    );
    expect(boundary.accepted, isTrue);
    expect(future.accepted, isTrue);
  });
}

PersistentDiplomacyResult _sendGift(
  PersistentGameState state, {
  required int amount,
  int turn = 10,
}) {
  return _route(
    state,
    SendGoldGiftCommand(
      playerId: _player1,
      targetPlayerId: _player2,
      amount: amount,
    ),
    actorPlayerId: _player1,
    turn: turn,
  );
}

void _expectWarEvents(List<GameEvent> events) {
  expect(events, hasLength(4));
  final relation = events[0] as DiplomaticRelationChangedEvent;
  expect(relation.playerAId, _player1);
  expect(relation.playerBId, _player2);
  expect(relation.oldStatus, DiplomaticRelationStatus.neutral);
  expect(relation.newStatus, DiplomaticRelationStatus.war);
  expect(relation.reason, DiplomaticRelationChangeReason.declarationOfWar);
  expect(relation.expiresOnTurn, isNull);
  final declaration = events[1] as DiplomaticScoreChangedEvent;
  expect(declaration.playerAId, _player1);
  expect(declaration.playerBId, _player2);
  expect(declaration.delta, -25);
  expect(declaration.scoreAfter, -25);
  expect(declaration.reason, DiplomaticScoreChangeReason.declarationOfWar);
  expect(declaration.sourceId, isNull);
  _expectWarmongerEvent(events[2], observerId: _player3);
  _expectWarmongerEvent(events[3], observerId: _player4);
}

void _expectWarmongerEvent(GameEvent event, {required String observerId}) {
  final score = event as DiplomaticScoreChangedEvent;
  expect(score.playerAId, _player1);
  expect(score.playerBId, observerId);
  expect(score.delta, -8);
  expect(score.scoreAfter, -8);
  expect(score.reason, DiplomaticScoreChangeReason.warmongerPenalty);
  expect(score.sourceId, 'warmonger.9.declarationOfWar.p1.p2');
}
