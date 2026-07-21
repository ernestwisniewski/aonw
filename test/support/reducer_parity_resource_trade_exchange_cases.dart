part of 'reducer_parity_resource_trade_characterization.dart';

List<ReducerParityFixture> _resourceExchangeParityCases(
  ReducerParityFixture template,
  PersistentGameState baseState,
) {
  final unavailable = _tradeParityWithoutTargetHorses(baseState);
  final requestedDuplicate = _tradeParityWithAgreements(unavailable, const [
    _parityUnrelatedTrade,
    _parityRequestedTrade,
  ]);
  final offeredDuplicate = _tradeParityWithAgreements(unavailable, const [
    _parityUnrelatedTrade,
    _parityOfferedTrade,
  ]);
  final atWar = _tradeParityAtWar(
    _tradeParityWithAgreements(unavailable, const [
      _parityUnrelatedTrade,
      _parityRequestedTrade,
      _parityOfferedTrade,
    ]),
  );
  final acceptedState = _tradeParityWithAgreements(baseState, const [
    _parityUnrelatedTrade,
    ResourceTradeAgreement(
      id: 'resource_exchange_player_1_player_2_iron_horses_1_requested',
      exporterPlayerId: _tradeTargetId,
      importerPlayerId: _tradeActorId,
      resource: ResourceType.horses,
      goldPerTurn: 0,
      remainingTurns: 6,
    ),
    ResourceTradeAgreement(
      id: 'resource_exchange_player_1_player_2_iron_horses_1_offered',
      exporterPlayerId: _tradeActorId,
      importerPlayerId: _tradeTargetId,
      resource: ResourceType.iron,
      goldPerTurn: 0,
      remainingTurns: 6,
    ),
  ]);
  return [
    _exchangeActorParityCase(template, baseState),
    _exchangeTargetParityCase(template, baseState),
    _exchangeTermsParityCase(template, atWar),
    _exchangeWarParityCase(template, atWar),
    _exchangeRequestedDuplicateParityCase(template, requestedDuplicate),
    _exchangeOfferedDuplicateParityCase(template, offeredDuplicate),
    _exchangeOfferParityCase(template, unavailable),
    _exchangeRequestParityCase(template, unavailable),
    _acceptedTradeParityFixture(
      template,
      id: 'resource-trade-characterization-exchange-generated-id-accepted',
      tickOffset: 118,
      state: baseState,
      command: const OpenResourceExchangeCommand(
        playerId: _tradeActorId,
        targetPlayerId: _tradeTargetId,
        offeredResource: ResourceType.iron,
        requestedResource: ResourceType.horses,
        durationTurns: 6,
      ),
      expectedState: acceptedState,
    ),
  ];
}

ReducerParityFixture _exchangeActorParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-wrong-actor-rejected',
    tickOffset: 110,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeTargetId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.coal,
      durationTurns: 0,
    ),
    reason: 'resource_trade_player_not_controlled',
  );
}

ReducerParityFixture _exchangeTargetParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-self-target-rejected',
    tickOffset: 111,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeActorId,
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.coal,
      durationTurns: 0,
    ),
    reason: 'invalid_resource_trade_target',
  );
}

ReducerParityFixture _exchangeTermsParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-invalid-terms-rejected',
    tickOffset: 112,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.horses,
      requestedResource: ResourceType.horses,
      durationTurns: 0,
    ),
    reason: 'invalid_resource_trade_terms',
  );
}

ReducerParityFixture _exchangeWarParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-war-rejected',
    tickOffset: 113,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.iron,
      requestedResource: ResourceType.horses,
      durationTurns: 4,
    ),
    reason: 'resource_trade_blocked_by_war',
  );
}

ReducerParityFixture _exchangeRequestedDuplicateParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-requested-duplicate-rejected',
    tickOffset: 114,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.iron,
      requestedResource: ResourceType.horses,
      durationTurns: 4,
    ),
    reason: 'resource_trade_already_active',
  );
}

ReducerParityFixture _exchangeOfferedDuplicateParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-offered-duplicate-rejected',
    tickOffset: 115,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.iron,
      requestedResource: ResourceType.horses,
      durationTurns: 4,
    ),
    reason: 'resource_trade_already_active',
  );
}

ReducerParityFixture _exchangeOfferParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-offer-rejected',
    tickOffset: 116,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.horses,
      durationTurns: 4,
    ),
    reason: 'resource_trade_offer_unavailable',
  );
}

ReducerParityFixture _exchangeRequestParityCase(
  ReducerParityFixture template,
  PersistentGameState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-exchange-request-rejected',
    tickOffset: 117,
    state: state,
    command: const OpenResourceExchangeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      offeredResource: ResourceType.iron,
      requestedResource: ResourceType.horses,
      durationTurns: 4,
    ),
    reason: 'resource_trade_request_unavailable',
  );
}
