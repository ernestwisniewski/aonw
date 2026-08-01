part of 'reducer_parity_resource_trade_characterization.dart';

List<ReducerParityFixture> _goldTradeParityCases(
  ReducerParityFixture template,
  DomainState baseState,
) {
  final unavailable = _tradeParityWithoutTargetHorses(baseState);
  final duplicate = _tradeParityWithAgreements(unavailable, const [
    _parityUnrelatedTrade,
    _parityRequestedTrade,
  ]);
  final insufficientGold = _tradeParityWithGold(duplicate, 2);
  final atWar = _tradeParityAtWar(_tradeParityWithGold(duplicate, 0));
  final acceptedState = _tradeParityWithAgreements(baseState, const [
    _parityUnrelatedTrade,
    ResourceTradeAgreement(
      id: 'resource_trade_player_1_player_2_horses_1',
      exporterPlayerId: _tradeTargetId,
      importerPlayerId: _tradeActorId,
      resource: ResourceType.horses,
      goldPerTurn: 3,
      remainingTurns: 5,
    ),
  ]);
  return [
    _goldActorParityCase(template, baseState),
    _goldTargetParityCase(template, baseState),
    _goldTermsParityCase(template, atWar),
    _goldWarParityCase(template, atWar),
    _goldBalanceParityCase(template, insufficientGold),
    _goldDuplicateParityCase(template, duplicate),
    _goldExportParityCase(template, unavailable),
    _acceptedTradeParityFixture(
      template,
      id: 'resource-trade-characterization-gold-generated-id-accepted',
      tickOffset: 107,
      state: baseState,
      command: const OpenResourceTradeCommand(
        playerId: _tradeActorId,
        targetPlayerId: _tradeTargetId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        durationTurns: 5,
      ),
      expectedState: acceptedState,
    ),
  ];
}

ReducerParityFixture _goldActorParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-wrong-actor-rejected',
    tickOffset: 100,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeTargetId,
      targetPlayerId: _tradeTargetId,
      resource: ResourceType.coal,
      goldPerTurn: -1,
      durationTurns: 0,
    ),
    reason: 'resource_trade_player_not_controlled',
  );
}

ReducerParityFixture _goldTargetParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-self-target-rejected',
    tickOffset: 101,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeActorId,
      resource: ResourceType.coal,
      goldPerTurn: -1,
      durationTurns: 0,
    ),
    reason: 'invalid_resource_trade_target',
  );
}

ReducerParityFixture _goldTermsParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-invalid-terms-rejected',
    tickOffset: 102,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      resource: ResourceType.horses,
      goldPerTurn: -1,
      durationTurns: 0,
    ),
    reason: 'invalid_resource_trade_terms',
  );
}

ReducerParityFixture _goldWarParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-war-rejected',
    tickOffset: 103,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      resource: ResourceType.horses,
      goldPerTurn: 3,
      durationTurns: 4,
    ),
    reason: 'resource_trade_blocked_by_war',
  );
}

ReducerParityFixture _goldBalanceParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-unavailable-rejected',
    tickOffset: 104,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      resource: ResourceType.horses,
      goldPerTurn: 3,
      durationTurns: 4,
    ),
    reason: 'resource_trade_gold_unavailable',
  );
}

ReducerParityFixture _goldDuplicateParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-duplicate-rejected',
    tickOffset: 105,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      resource: ResourceType.horses,
      goldPerTurn: 3,
      durationTurns: 4,
    ),
    reason: 'resource_trade_already_active',
  );
}

ReducerParityFixture _goldExportParityCase(
  ReducerParityFixture template,
  DomainState state,
) {
  return _rejectedTradeParityFixture(
    template,
    id: 'resource-trade-characterization-gold-export-rejected',
    tickOffset: 106,
    state: state,
    command: const OpenResourceTradeCommand(
      playerId: _tradeActorId,
      targetPlayerId: _tradeTargetId,
      resource: ResourceType.horses,
      goldPerTurn: 3,
      durationTurns: 4,
    ),
    reason: 'resource_trade_export_unavailable',
  );
}
