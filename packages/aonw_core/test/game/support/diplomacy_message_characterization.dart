part of '../diplomacy_command_router_characterization_test.dart';

void _registerMessageCharacterizationTests() {
  _registerMessageAuthorityValidationTests();
  _registerMessageStorageValidationTests();
  _registerMessageCooldownTests();
  _registerMessageSuccessTests();
}

void _registerMessageAuthorityValidationTests() {
  group('message authority validation precedence and identity', () {
    test('canAct=false wins before target, cooldown, and add checks', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.addMessage(
          _message(
            id: 'cooldown',
            topic: DiplomaticMessageTopic.blockedRoutes,
            createdTurn: 8,
          ),
        ),
      );
      final result = _route(
        state,
        const SendDiplomaticMessageCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          topic: DiplomaticMessageTopic.withdrawScouts,
          messageId: '',
        ),
        actorPlayerId: _player1,
        turn: 10,
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
        const SendDiplomaticMessageCommand(
          playerId: _player1,
          targetPlayerId: '',
          topic: DiplomaticMessageTopic.peacefulPraise,
        ),
        actorPlayerId: _player2,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('unknown target wins even when a stored message would cool down', () {
      final state = _diplomacyState(
        playerColors: const {_player1: 1},
        playerCountries: const {},
        playerGold: const {_player1: 10},
        diplomacy: DiplomacyState.empty.addMessage(
          _message(
            id: 'cooldown',
            topic: DiplomaticMessageTopic.blockedRoutes,
            createdTurn: 8,
          ),
        ),
      );
      final result = _route(
        state,
        const SendDiplomaticMessageCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          topic: DiplomaticMessageTopic.withdrawScouts,
        ),
        actorPlayerId: _player1,
        turn: 10,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_target_not_discovered',
      );
    });
  });
}

void _registerMessageStorageValidationTests() {
  group('message storage validation precedence and identity', () {
    test('category cooldown wins before an empty-id add failure', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.addMessage(
          _message(
            id: 'cooldown',
            topic: DiplomaticMessageTopic.blockedRoutes,
            createdTurn: 8,
          ),
        ),
      );
      final result = _route(
        state,
        const SendDiplomaticMessageCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          topic: DiplomaticMessageTopic.withdrawScouts,
          messageId: '',
        ),
        actorPlayerId: _player1,
        turn: 10,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_message_cooldown');
    });

    test('empty custom id is the final message rejection', () {
      final state = _diplomacyState();
      final result = _route(
        state,
        const SendDiplomaticMessageCommand(
          playerId: _player1,
          targetPlayerId: _player2,
          topic: DiplomaticMessageTopic.peacefulPraise,
          messageId: '',
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(result, state, 'diplomacy_message_not_added');
    });
  });
}

void _registerMessageCooldownTests() {
  test('message cooldown is directed, category-based, and time-exact', () {
    final existing = _message(
      id: 'existing',
      topic: DiplomaticMessageTopic.blockedRoutes,
      createdTurn: 7,
      expiresOnTurn: 8,
    );
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty.addMessage(existing),
    );
    final sameCategory = _sendMessage(
      state,
      topic: DiplomaticMessageTopic.withdrawScouts,
      turn: 10,
    );
    final differentCategory = _sendMessage(
      state,
      topic: DiplomaticMessageTopic.peacefulPraise,
      turn: 10,
    );
    final reverse = _route(
      state,
      const SendDiplomaticMessageCommand(
        playerId: _player2,
        targetPlayerId: _player1,
        topic: DiplomaticMessageTopic.withdrawScouts,
        messageId: 'reverse',
      ),
      actorPlayerId: _player2,
      turn: 10,
    );
    final boundary = _sendMessage(
      state,
      topic: DiplomaticMessageTopic.withdrawScouts,
      turn: 12,
    );
    final futureState = _diplomacyState(
      diplomacy: DiplomacyState.empty.addMessage(
        _message(
          id: 'future',
          topic: DiplomaticMessageTopic.blockedRoutes,
          createdTurn: 15,
          expiresOnTurn: 20,
        ),
      ),
    );
    final future = _sendMessage(
      futureState,
      topic: DiplomaticMessageTopic.withdrawScouts,
      turn: 10,
    );

    _expectRejectedDiplomacy(sameCategory, state, 'diplomacy_message_cooldown');
    expect(differentCategory.accepted, isTrue);
    expect(reverse.accepted, isTrue);
    expect(boundary.accepted, isTrue);
    _expectRejectedDiplomacy(future, futureState, 'diplomacy_message_cooldown');
  });

  test('responded messages still cool down their category', () {
    final responded = _message(
      id: 'responded',
      topic: DiplomaticMessageTopic.blockedRoutes,
      createdTurn: 7,
      expiresOnTurn: 8,
    ).copyWith(response: DiplomaticMessageResponse.neutral, respondedTurn: 8);
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty.addMessage(responded),
    );
    final result = _sendMessage(
      state,
      topic: DiplomaticMessageTopic.withdrawScouts,
      turn: 10,
    );

    _expectRejectedDiplomacy(result, state, 'diplomacy_message_cooldown');
  });
}

void _registerMessageSuccessTests() {
  _registerGeneratedMessageTest();
  _registerMessageIdReuseTest();
}

void _registerGeneratedMessageTest() {
  test('generated message id, category, duration, and event are exact', () {
    final unrelated1 = _message(
      id: 'unrelated_1',
      fromPlayerId: _player3,
      toPlayerId: _player4,
      topic: DiplomaticMessageTopic.commonEnemy,
    );
    final unrelated2 = _message(
      id: 'unrelated_2',
      fromPlayerId: _player4,
      toPlayerId: _player3,
      topic: DiplomaticMessageTopic.peacefulPraise,
    );
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty
          .addContact(_player1, _player2)
          .addMessage(unrelated1)
          .addMessage(unrelated2),
    );
    final result = _route(
      state,
      const SendDiplomaticMessageCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        topic: DiplomaticMessageTopic.blockedRoutes,
      ),
      actorPlayerId: _player1,
      turn: 9,
    );

    const generatedId = 'message.9.p1.p2.blockedRoutes.2';
    final next = result.state.diplomacy.messages[generatedId];
    expect(
      next,
      const DiplomaticMessage(
        id: generatedId,
        fromPlayerId: _player1,
        toPlayerId: _player2,
        topic: DiplomaticMessageTopic.blockedRoutes,
        category: DiplomaticMessageCategory.request,
        createdTurn: 9,
        expiresOnTurn: 14,
        response: null,
        respondedTurn: null,
        relationScoreDelta: 0,
        relationScoreAfter: null,
        promiseDueTurn: null,
        promiseBroken: false,
      ),
    );
    expect(result.state.diplomacy.messages['unrelated_1'], same(unrelated1));
    expect(result.state.diplomacy.messages['unrelated_2'], same(unrelated2));
    expect(result.events, hasLength(1));
    final event = result.events.single as DiplomaticMessageSentEvent;
    expect(event.messageId, generatedId);
    expect(event.fromPlayerId, _player1);
    expect(event.toPlayerId, _player2);
    expect(event.topic, DiplomaticMessageTopic.blockedRoutes);
    expect(event.category, DiplomaticMessageCategory.request);
    expect(event.expiresOnTurn, 14);
    _expectOuterSentinelsUnchanged(result, state);
    _expectRuntimeSentinelsUnchanged(result, state);
  });
}

void _registerMessageIdReuseTest() {
  test('reusing a message id overwrites an unrelated entry', () {
    final unrelated = _message(
      id: 'shared_id',
      fromPlayerId: _player3,
      toPlayerId: _player4,
      topic: DiplomaticMessageTopic.commonEnemy,
    );
    final state = _diplomacyState(
      diplomacy: DiplomacyState.empty
          .addContact(_player1, _player2)
          .addMessage(unrelated),
    );
    final result = _route(
      state,
      const SendDiplomaticMessageCommand(
        playerId: _player1,
        targetPlayerId: _player2,
        topic: DiplomaticMessageTopic.peacefulPraise,
        messageId: 'shared_id',
      ),
      actorPlayerId: _player1,
      turn: 8,
    );

    expect(result.accepted, isTrue);
    expect(result.state.diplomacy.messages, {
      'shared_id': const DiplomaticMessage(
        id: 'shared_id',
        fromPlayerId: _player1,
        toPlayerId: _player2,
        topic: DiplomaticMessageTopic.peacefulPraise,
        category: DiplomaticMessageCategory.praise,
        createdTurn: 8,
        expiresOnTurn: 13,
        response: null,
        respondedTurn: null,
        relationScoreDelta: 0,
        relationScoreAfter: null,
        promiseDueTurn: null,
        promiseBroken: false,
      ),
    });
    expect(result.events.single, isA<DiplomaticMessageSentEvent>());
  });
}

_DiplomacyTestResult _sendMessage(
  DomainState state, {
  required DiplomaticMessageTopic topic,
  required int turn,
}) {
  return _route(
    state,
    SendDiplomaticMessageCommand(
      playerId: _player1,
      targetPlayerId: _player2,
      topic: topic,
      messageId: 'message_at_$turn',
    ),
    actorPlayerId: _player1,
    turn: turn,
  );
}
