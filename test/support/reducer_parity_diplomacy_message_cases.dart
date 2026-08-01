part of 'reducer_parity_diplomacy_characterization.dart';

List<ReducerParityFixture> _messageParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  return [
    ..._messageSendParityCases(template, baseState),
    ..._messageResponseParityCases(template, baseState),
  ];
}

List<ReducerParityFixture> _messageSendParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  final cooldownMessage = DiplomaticMessage.create(
    id: 'pair_message_on_cooldown',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    topic: DiplomaticMessageTopic.blockedRoutes,
    createdTurn: 4,
    expiresOnTurn: 9,
  );
  final cooldownState = _addMessageOracle(baseState, cooldownMessage);
  final generatedMessage = DiplomaticMessage.create(
    id: 'message.7.player_1.player_2.blockedRoutes.1',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    topic: DiplomaticMessageTopic.blockedRoutes,
    createdTurn: _diplomacyTurn,
    expiresOnTurn: _diplomacyTurn + DiplomacyState.defaultMessageDurationTurns,
  );
  return [
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-send-wrong-actor-rejected',
      tickOffset: 240,
      state: _withoutPairContact(baseState),
      command: const SendDiplomaticMessageCommand(
        playerId: _diplomacyTargetId,
        targetPlayerId: _diplomacyTargetId,
        topic: DiplomaticMessageTopic.blockedRoutes,
      ),
      reason: 'diplomacy_player_not_controlled',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-send-target-rejected',
      tickOffset: 241,
      state: _withoutPairContact(cooldownState),
      command: const SendDiplomaticMessageCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        topic: DiplomaticMessageTopic.blockedRoutes,
      ),
      reason: 'diplomacy_target_not_discovered',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-send-cooldown-rejected',
      tickOffset: 242,
      state: cooldownState,
      command: const SendDiplomaticMessageCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        topic: DiplomaticMessageTopic.withdrawScouts,
      ),
      reason: 'diplomacy_message_cooldown',
    ),
    _acceptedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-send-generated-id-accepted',
      tickOffset: 243,
      state: baseState,
      command: const SendDiplomaticMessageCommand(
        playerId: _diplomacyActorId,
        targetPlayerId: _diplomacyTargetId,
        topic: DiplomaticMessageTopic.blockedRoutes,
      ),
      expectedState: _addMessageOracle(baseState, generatedMessage),
      expectedEvents: [
        DiplomaticMessageSentEvent(
          messageId: generatedMessage.id,
          fromPlayerId: _diplomacyActorId,
          toPlayerId: _diplomacyTargetId,
          topic: generatedMessage.topic,
          category: generatedMessage.category,
          expiresOnTurn: generatedMessage.expiresOnTurn,
        ),
      ],
    ),
  ];
}

List<ReducerParityFixture> _messageResponseParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  final responded =
      DiplomaticMessage.create(
        id: 'pair_message_responded',
        fromPlayerId: _diplomacyActorId,
        toPlayerId: _diplomacyTargetId,
        topic: DiplomaticMessageTopic.blockedRoutes,
        createdTurn: 4,
        expiresOnTurn: 9,
      ).copyWith(
        response: DiplomaticMessageResponse.neutral,
        respondedTurn: 6,
        relationScoreDelta: 2,
        relationScoreAfter: 2,
      );
  final expired = DiplomaticMessage.create(
    id: 'pair_message_expired',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    topic: DiplomaticMessageTopic.blockedRoutes,
    createdTurn: 2,
    expiresOnTurn: _diplomacyTurn,
  );
  return [
    ..._messageResponseRejections(template, baseState, responded, expired),
    ..._messageResponseAcceptances(template, baseState),
  ];
}

List<ReducerParityFixture> _messageResponseRejections(
  ReducerParityFixture template,
  DomainState baseState,
  DiplomaticMessage responded,
  DiplomaticMessage expired,
) {
  return [
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-response-wrong-actor-rejected',
      tickOffset: 250,
      state: baseState,
      command: const RespondDiplomaticMessageCommand(
        playerId: _diplomacyTargetId,
        messageId: 'missing_message',
        response: DiplomaticMessageResponse.conciliatory,
      ),
      reason: 'diplomacy_player_not_controlled',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-response-not-found-rejected',
      tickOffset: 251,
      actorPlayerId: _diplomacyTargetId,
      state: baseState,
      command: const RespondDiplomaticMessageCommand(
        playerId: _diplomacyTargetId,
        messageId: 'missing_message',
        response: DiplomaticMessageResponse.conciliatory,
      ),
      reason: 'diplomacy_message_not_found',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-response-responded-rejected',
      tickOffset: 252,
      actorPlayerId: _diplomacyTargetId,
      state: _addMessageOracle(baseState, responded),
      command: RespondDiplomaticMessageCommand(
        playerId: _diplomacyTargetId,
        messageId: responded.id,
        response: DiplomaticMessageResponse.aggressive,
      ),
      reason: 'diplomacy_message_unavailable',
    ),
    _rejectedDiplomacyFixture(
      template,
      id: 'diplomacy-characterization-message-response-expired-rejected',
      tickOffset: 253,
      actorPlayerId: _diplomacyTargetId,
      state: _addMessageOracle(baseState, expired),
      command: RespondDiplomaticMessageCommand(
        playerId: _diplomacyTargetId,
        messageId: expired.id,
        response: DiplomaticMessageResponse.conciliatory,
      ),
      reason: 'diplomacy_message_unavailable',
    ),
  ];
}

List<ReducerParityFixture> _messageResponseAcceptances(
  ReducerParityFixture template,
  DomainState baseState,
) {
  return [
    _acceptedMessageResponseFixture(
      template,
      baseState,
      id: 'diplomacy-characterization-message-response-conciliatory-accepted',
      tickOffset: 254,
      topic: DiplomaticMessageTopic.troopsNearCities,
      response: DiplomaticMessageResponse.conciliatory,
      delta: 12,
      reason: DiplomaticScoreChangeReason.messageResponse,
      promiseDueTurn:
          _diplomacyTurn + DiplomacyState.defaultPromiseDurationTurns,
    ),
    _acceptedMessageResponseFixture(
      template,
      baseState,
      id: 'diplomacy-characterization-message-response-neutral-accepted',
      tickOffset: 255,
      topic: DiplomaticMessageTopic.blockedRoutes,
      response: DiplomaticMessageResponse.neutral,
      delta: 2,
      reason: DiplomaticScoreChangeReason.messageResponse,
    ),
    _acceptedMessageResponseFixture(
      template,
      baseState,
      id: 'diplomacy-characterization-message-response-evasive-accepted',
      tickOffset: 256,
      topic: DiplomaticMessageTopic.blockedRoutes,
      response: DiplomaticMessageResponse.evasive,
      delta: -8,
      reason: DiplomaticScoreChangeReason.messageResponse,
    ),
    _acceptedMessageResponseFixture(
      template,
      baseState,
      id: 'diplomacy-characterization-message-response-aggressive-accepted',
      tickOffset: 257,
      topic: DiplomaticMessageTopic.blockedRoutes,
      response: DiplomaticMessageResponse.aggressive,
      delta: -18,
      reason: DiplomaticScoreChangeReason.messageResponse,
    ),
    _acceptedCommonEnemyResponseFixture(template, baseState),
  ];
}

ReducerParityFixture _acceptedMessageResponseFixture(
  ReducerParityFixture template,
  DomainState baseState, {
  required String id,
  required int tickOffset,
  required DiplomaticMessageTopic topic,
  required DiplomaticMessageResponse response,
  required int delta,
  required DiplomaticScoreChangeReason reason,
  int? promiseDueTurn,
}) {
  final message = DiplomaticMessage.create(
    id: 'pair_message_${response.name}',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    topic: topic,
    createdTurn: 5,
    expiresOnTurn: 10,
  );
  final state = _addMessageOracle(baseState, message);
  return _acceptedDiplomacyFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    actorPlayerId: _diplomacyTargetId,
    state: state,
    command: RespondDiplomaticMessageCommand(
      playerId: _diplomacyTargetId,
      messageId: message.id,
      response: response,
    ),
    expectedState: _messageResponseOracle(
      state,
      message,
      response,
      delta: delta,
      reason: reason,
    ),
    expectedEvents: [
      DiplomaticMessageRespondedEvent(
        messageId: message.id,
        fromPlayerId: _diplomacyActorId,
        toPlayerId: _diplomacyTargetId,
        topic: topic,
        response: response,
        relationDelta: delta,
        relationScoreAfter: delta,
        promiseDueTurn: promiseDueTurn,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: delta,
        scoreAfter: delta,
        reason: reason,
        sourceId: message.id,
      ),
    ],
  );
}

ReducerParityFixture _acceptedCommonEnemyResponseFixture(
  ReducerParityFixture template,
  DomainState baseState,
) {
  final sharedWarState = _withRelationOracle(
    _withRelationOracle(
      baseState,
      playerAId: _diplomacyActorId,
      playerBId: _diplomacyObserverId,
      status: DiplomaticRelationStatus.war,
    ),
    playerAId: _diplomacyTargetId,
    playerBId: _diplomacyObserverId,
    status: DiplomaticRelationStatus.war,
  );
  final message = DiplomaticMessage.create(
    id: 'pair_message_common_enemy',
    fromPlayerId: _diplomacyActorId,
    toPlayerId: _diplomacyTargetId,
    topic: DiplomaticMessageTopic.commonEnemy,
    createdTurn: 5,
    expiresOnTurn: 10,
  );
  final state = _addMessageOracle(sharedWarState, message);
  return _acceptedDiplomacyFixture(
    template,
    id: 'diplomacy-characterization-message-response-common-enemy-accepted',
    tickOffset: 258,
    actorPlayerId: _diplomacyTargetId,
    state: state,
    command: RespondDiplomaticMessageCommand(
      playerId: _diplomacyTargetId,
      messageId: message.id,
      response: DiplomaticMessageResponse.conciliatory,
    ),
    expectedState: _messageResponseOracle(
      state,
      message,
      DiplomaticMessageResponse.conciliatory,
      delta: 20,
      reason: DiplomaticScoreChangeReason.commonEnemyCooperation,
    ),
    expectedEvents: [
      DiplomaticMessageRespondedEvent(
        messageId: message.id,
        fromPlayerId: _diplomacyActorId,
        toPlayerId: _diplomacyTargetId,
        topic: message.topic,
        response: DiplomaticMessageResponse.conciliatory,
        relationDelta: 20,
        relationScoreAfter: 20,
      ),
      _scoreEventOracle(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyTargetId,
        delta: 20,
        scoreAfter: 20,
        reason: DiplomaticScoreChangeReason.commonEnemyCooperation,
        sourceId: message.id,
      ),
    ],
  );
}
