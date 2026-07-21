part of '../persistent_resource_trade_resolver_characterization_test.dart';

void _registerResourceExchangeCharacterizationTests() {
  group('resource exchange validation precedence', () {
    _registerExchangePlayerAndTermsPrecedenceTests();
    _registerExchangeDuplicatePrecedenceTests();
    _registerExchangeAvailabilityPrecedenceTests();
    _registerGeneratedExchangeIdTest();
  });
}

void _registerExchangePlayerAndTermsPrecedenceTests() {
  test('empty initiator wins over every later rejection', () {
    final state = _tradeState(
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade, _offeredIronTrade],
    );

    final result = _openResourceExchange(
      state,
      playerId: '',
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.coal,
      durationTurns: 0,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_player');
  });

  test('empty target wins over every later rejection', () {
    final state = _tradeState(
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade, _offeredIronTrade],
    );

    final result = _openResourceExchange(
      state,
      targetPlayerId: '',
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.coal,
      durationTurns: 0,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_player');
  });

  test('self target wins over invalid terms and availability', () {
    final state = _tradeState(exporterRevealsHorses: false);

    final result = _openResourceExchange(
      state,
      targetPlayerId: _importerId,
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.coal,
      durationTurns: 0,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_target');
  });

  test('matching resources win over war and availability', () {
    final state = _tradeState(exporterRevealsHorses: false, atWar: true);

    final result = _openResourceExchange(
      state,
      offeredResource: ResourceType.coal,
      requestedResource: ResourceType.coal,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_terms');
  });

  test('non-positive duration wins over war and availability', () {
    final state = _tradeState(exporterRevealsHorses: false, atWar: true);

    final result = _openResourceExchange(state, durationTurns: 0);

    _expectRejectedTrade(result, state, 'invalid_resource_trade_terms');
  });

  test('war wins over duplicates and both availability checks', () {
    final state = _tradeState(
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade, _offeredIronTrade],
    );

    final result = _openResourceExchange(state);

    _expectRejectedTrade(result, state, 'resource_trade_blocked_by_war');
  });
}

void _registerExchangeDuplicatePrecedenceTests() {
  test('requested-resource duplicate wins over availability', () {
    final state = _tradeState(
      exporterRevealsHorses: false,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openResourceExchange(state);

    _expectRejectedTrade(result, state, 'resource_trade_already_active');
  });

  test('offered-resource duplicate wins over availability', () {
    final state = _tradeState(
      exporterRevealsHorses: false,
      agreements: const [_offeredIronTrade],
    );

    final result = _openResourceExchange(state);

    _expectRejectedTrade(result, state, 'resource_trade_already_active');
  });
}

void _registerExchangeAvailabilityPrecedenceTests() {
  test('unavailable offer wins when both resources are unavailable', () {
    final state = _tradeState(exporterRevealsHorses: false);

    final result = _openResourceExchange(
      state,
      offeredResource: ResourceType.coal,
    );

    _expectRejectedTrade(result, state, 'resource_trade_offer_unavailable');
  });

  test('unavailable request is checked after an available offer', () {
    final state = _tradeState(exporterRevealsHorses: false);

    final result = _openResourceExchange(state);

    _expectRejectedTrade(result, state, 'resource_trade_request_unavailable');
  });

  test('committed offer capacity is unavailable to another importer', () {
    final state = _tradeState(agreements: const [_otherImporterIronTrade]);

    final result = _openResourceExchange(state);

    _expectRejectedTrade(result, state, 'resource_trade_offer_unavailable');
  });

  test('committed request capacity is unavailable to another importer', () {
    final state = _tradeState(agreements: const [_otherImporterHorsesTrade]);

    final result = _openResourceExchange(state);

    _expectRejectedTrade(result, state, 'resource_trade_request_unavailable');
  });
}

void _registerGeneratedExchangeIdTest() {
  test('generated ids are deterministic and only agreements change', () {
    final state = _tradeState(
      agreements: const [_unrelatedTrade, _expiredRequestedHorsesTrade],
    );

    final result = _openResourceExchange(state, durationTurns: 6);

    _expectOnlyTradeAgreementsChanged(result, state, const [
      _unrelatedTrade,
      _expiredRequestedHorsesTrade,
      ResourceTradeAgreement(
        id: 'resource_exchange_player_1_player_2_iron_horses_2_requested',
        exporterPlayerId: _exporterId,
        importerPlayerId: _importerId,
        resource: ResourceType.horses,
        goldPerTurn: 0,
        remainingTurns: 6,
      ),
      ResourceTradeAgreement(
        id: 'resource_exchange_player_1_player_2_iron_horses_2_offered',
        exporterPlayerId: _importerId,
        importerPlayerId: _exporterId,
        resource: ResourceType.iron,
        goldPerTurn: 0,
        remainingTurns: 6,
      ),
    ]);
    expect(state.runtimeState.resourceTradeAgreements, const [
      _unrelatedTrade,
      _expiredRequestedHorsesTrade,
    ]);
  });
}

PersistentResourceTradeResult _openResourceExchange(
  PersistentGameState state, {
  String playerId = _importerId,
  String targetPlayerId = _exporterId,
  ResourceType offeredResource = ResourceType.iron,
  ResourceType requestedResource = ResourceType.horses,
  int durationTurns = 4,
}) {
  return _resolver.openResourceForResourceTrade(
    state: state,
    playerId: playerId,
    targetPlayerId: targetPlayerId,
    offeredResource: offeredResource,
    requestedResource: requestedResource,
    durationTurns: durationTurns,
    mapTiles: _tradeMap(),
  );
}
