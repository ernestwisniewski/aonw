part of '../diplomacy_command_router_characterization_test.dart';

void _registerMessageResponseCharacterizationTests() {
  _registerMessageResponseValidationTests();
  _registerBaseMessageEffectTests();
  _registerCommonEnemyMessageEffectTests();
  _registerMessagePromiseTests();
  _registerMessageScoreSaturationTest();
}

void _registerMessageResponseValidationTests() {
  group('message response validation precedence and identity', () {
    test('canAct=false wins before message lookup', () {
      final state = _diplomacyState();
      final result = _route(
        state,
        const RespondDiplomaticMessageCommand(
          playerId: _player2,
          messageId: 'missing',
          response: DiplomaticMessageResponse.conciliatory,
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

    test('actor mismatch wins before message lookup', () {
      final state = _diplomacyState();
      final result = _route(
        state,
        const RespondDiplomaticMessageCommand(
          playerId: _player2,
          messageId: 'missing',
          response: DiplomaticMessageResponse.conciliatory,
        ),
        actorPlayerId: _player1,
      );

      _expectRejectedDiplomacy(
        result,
        state,
        'diplomacy_player_not_controlled',
      );
    });

    test('missing message wins before availability checks', () {
      final state = _diplomacyState();
      final result = _respondToMessage(state);

      _expectRejectedDiplomacy(result, state, 'diplomacy_message_not_found');
    });

    test('message addressed to another player is treated as missing', () {
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.addMessage(
          _message(toPlayerId: _player3),
        ),
      );
      final result = _respondToMessage(state);

      _expectRejectedDiplomacy(result, state, 'diplomacy_message_not_found');
    });

    test('already responded and expired messages are unavailable', () {
      final respondedMessage = _message().copyWith(
        response: DiplomaticMessageResponse.neutral,
        respondedTurn: 5,
      );
      final respondedState = _diplomacyState(
        diplomacy: DiplomacyState.empty.addMessage(respondedMessage),
      );
      final expiredState = _diplomacyState(
        diplomacy: DiplomacyState.empty.addMessage(_message(expiresOnTurn: 10)),
      );
      final responded = _respondToMessage(respondedState, turn: 10);
      final expired = _respondToMessage(expiredState, turn: 10);

      _expectRejectedDiplomacy(
        responded,
        respondedState,
        'diplomacy_message_unavailable',
      );
      _expectRejectedDiplomacy(
        expired,
        expiredState,
        'diplomacy_message_unavailable',
      );
    });
  });
}

void _registerBaseMessageEffectTests() {
  group('base message response effects', () {
    const cases = <(DiplomaticMessageResponse, int)>[
      (DiplomaticMessageResponse.conciliatory, 12),
      (DiplomaticMessageResponse.neutral, 2),
      (DiplomaticMessageResponse.evasive, -8),
      (DiplomaticMessageResponse.aggressive, -18),
    ];

    for (final (response, expectedDelta) in cases) {
      test('${response.name} applies $expectedDelta and exact events', () {
        final original = _message(topic: DiplomaticMessageTopic.peacefulPraise);
        final state = _diplomacyState(
          diplomacy: DiplomacyState.empty.addMessage(original),
        );
        final result = _respondToMessage(state, response: response, turn: 10);

        _expectMessageResponseSuccess(
          result,
          input: state,
          original: original,
          response: response,
          expectedDelta: expectedDelta,
          expectedScore: expectedDelta,
          expectedReason: DiplomaticScoreChangeReason.messageResponse,
        );
      });
    }
  });
}

void _registerCommonEnemyMessageEffectTests() {
  group('common-enemy response effects', () {
    const cases =
        <(DiplomaticMessageResponse, int, DiplomaticScoreChangeReason)>[
          (
            DiplomaticMessageResponse.conciliatory,
            20,
            DiplomaticScoreChangeReason.commonEnemyCooperation,
          ),
          (
            DiplomaticMessageResponse.neutral,
            6,
            DiplomaticScoreChangeReason.commonEnemyCooperation,
          ),
          (
            DiplomaticMessageResponse.evasive,
            -8,
            DiplomaticScoreChangeReason.messageResponse,
          ),
          (
            DiplomaticMessageResponse.aggressive,
            -18,
            DiplomaticScoreChangeReason.messageResponse,
          ),
        ];

    for (final (response, expectedDelta, expectedReason) in cases) {
      test('${response.name} applies exact shared-war effect', () {
        final original = _message(topic: DiplomaticMessageTopic.commonEnemy);
        final diplomacy = DiplomacyState.empty
            .setStatus(_player1, _player3, DiplomaticRelationStatus.war)
            .setStatus(_player2, _player3, DiplomaticRelationStatus.war)
            .addMessage(original);
        final state = _diplomacyState(diplomacy: diplomacy);
        final result = _respondToMessage(state, response: response, turn: 10);

        _expectMessageResponseSuccess(
          result,
          input: state,
          original: original,
          response: response,
          expectedDelta: expectedDelta,
          expectedScore: expectedDelta,
          expectedReason: expectedReason,
        );
      });
    }
  });
}

void _registerMessagePromiseTests() {
  group('message promise eligibility', () {
    for (final topic in DiplomaticMessageTopic.values) {
      final createsPromise =
          topic == DiplomaticMessageTopic.troopsNearCities ||
          topic == DiplomaticMessageTopic.blockedRoutes ||
          topic == DiplomaticMessageTopic.withdrawScouts;
      test('${topic.name} promise => $createsPromise', () {
        final original = _message(topic: topic);
        final state = _diplomacyState(
          diplomacy: DiplomacyState.empty.addMessage(original),
        );
        final result = _respondToMessage(
          state,
          response: DiplomaticMessageResponse.conciliatory,
          turn: 10,
        );
        final updated =
            result.state.runtimeState.diplomacy.messages['message_1']!;
        final event = result.events[0] as DiplomaticMessageRespondedEvent;

        expect(updated.promiseDueTurn, createsPromise ? 13 : isNull);
        expect(event.promiseDueTurn, createsPromise ? 13 : isNull);
      });
    }

    test('non-conciliatory response never creates a promise', () {
      final original = _message(topic: DiplomaticMessageTopic.troopsNearCities);
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.addMessage(original),
      );
      final result = _respondToMessage(
        state,
        response: DiplomaticMessageResponse.neutral,
        turn: 10,
      );

      expect(
        result
            .state
            .runtimeState
            .diplomacy
            .messages['message_1']!
            .promiseDueTurn,
        isNull,
      );
    });
  });
}

void _registerMessageScoreSaturationTest() {
  test('message and events report the applied clamped score delta', () {
    final original = _message(topic: DiplomaticMessageTopic.peacefulPraise);
    final diplomacy = DiplomacyState.empty
        .adjustRelationScore(
          _player1,
          _player2,
          95,
          turn: 1,
          reason: DiplomaticScoreChangeReason.manual,
        )
        .addMessage(original);
    final state = _diplomacyState(diplomacy: diplomacy);
    final result = _respondToMessage(
      state,
      response: DiplomaticMessageResponse.conciliatory,
      turn: 10,
    );

    _expectMessageResponseSuccess(
      result,
      input: state,
      original: original,
      response: DiplomaticMessageResponse.conciliatory,
      expectedDelta: 5,
      expectedScore: 100,
      expectedReason: DiplomaticScoreChangeReason.messageResponse,
    );
  });
}

_DiplomacyTestResult _respondToMessage(
  PersistentGameState state, {
  DiplomaticMessageResponse response = DiplomaticMessageResponse.conciliatory,
  int turn = 10,
}) {
  return _route(
    state,
    RespondDiplomaticMessageCommand(
      playerId: _player2,
      messageId: 'message_1',
      response: response,
    ),
    actorPlayerId: _player2,
    turn: turn,
  );
}

void _expectMessageResponseSuccess(
  _DiplomacyTestResult result, {
  required PersistentGameState input,
  required DiplomaticMessage original,
  required DiplomaticMessageResponse response,
  required int expectedDelta,
  required int expectedScore,
  required DiplomaticScoreChangeReason expectedReason,
}) {
  final updated = result.state.runtimeState.diplomacy.messages[original.id]!;
  expect(updated.id, original.id);
  expect(updated.fromPlayerId, original.fromPlayerId);
  expect(updated.toPlayerId, original.toPlayerId);
  expect(updated.topic, original.topic);
  expect(updated.category, original.category);
  expect(updated.createdTurn, original.createdTurn);
  expect(updated.expiresOnTurn, original.expiresOnTurn);
  expect(updated.response, response);
  expect(updated.respondedTurn, 10);
  expect(updated.relationScoreDelta, expectedDelta);
  expect(updated.relationScoreAfter, expectedScore);
  expect(updated.promiseDueTurn, isNull);
  expect(result.events, hasLength(2));
  final responded = result.events[0] as DiplomaticMessageRespondedEvent;
  expect(responded.messageId, original.id);
  expect(responded.fromPlayerId, original.fromPlayerId);
  expect(responded.toPlayerId, original.toPlayerId);
  expect(responded.topic, original.topic);
  expect(responded.response, response);
  expect(responded.relationDelta, expectedDelta);
  expect(responded.relationScoreAfter, expectedScore);
  expect(responded.promiseDueTurn, isNull);
  final score = result.events[1] as DiplomaticScoreChangedEvent;
  expect(score.playerAId, _player1);
  expect(score.playerBId, _player2);
  expect(score.delta, expectedDelta);
  expect(score.scoreAfter, expectedScore);
  expect(score.reason, expectedReason);
  expect(score.sourceId, original.id);
  _expectOuterSentinelsUnchanged(result, input);
  _expectRuntimeSentinelsUnchanged(result, input);
}
