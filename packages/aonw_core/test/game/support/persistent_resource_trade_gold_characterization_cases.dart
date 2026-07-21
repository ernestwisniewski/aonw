part of '../persistent_resource_trade_resolver_characterization_test.dart';

void _registerGoldResourceTradeCharacterizationTests() {
  group('gold-for-resource validation precedence', () {
    _registerGoldPlayerAndTermsPrecedenceTests();
    _registerGoldAvailabilityPrecedenceTests();
    _registerGeneratedGoldTradeIdTest();
  });
}

void _registerGoldPlayerAndTermsPrecedenceTests() {
  test('empty importer wins over every later rejection', () {
    final state = _tradeState(
      importerGold: 0,
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(
      state,
      importerPlayerId: '',
      resource: ResourceType.coal,
      goldPerTurn: -1,
      durationTurns: 0,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_player');
  });

  test('empty exporter wins over every later rejection', () {
    final state = _tradeState(
      importerGold: 0,
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(
      state,
      exporterPlayerId: '',
      resource: ResourceType.coal,
      goldPerTurn: -1,
      durationTurns: 0,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_player');
  });

  test('self target wins over invalid terms and availability', () {
    final state = _tradeState(importerGold: 0);

    final result = _openGoldTrade(
      state,
      exporterPlayerId: _importerId,
      resource: ResourceType.coal,
      goldPerTurn: -1,
      durationTurns: 0,
    );

    _expectRejectedTrade(result, state, 'invalid_resource_trade_target');
  });

  test('negative gold wins over war and resource checks', () {
    final state = _tradeState(
      importerGold: 0,
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(state, goldPerTurn: -1);

    _expectRejectedTrade(result, state, 'invalid_resource_trade_terms');
  });

  test('non-positive duration wins over war and resource checks', () {
    final state = _tradeState(
      importerGold: 0,
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(state, durationTurns: 0);

    _expectRejectedTrade(result, state, 'invalid_resource_trade_terms');
  });
}

void _registerGoldAvailabilityPrecedenceTests() {
  test('war wins over gold, duplicate, and export availability', () {
    final state = _tradeState(
      importerGold: 0,
      exporterRevealsHorses: false,
      atWar: true,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(state);

    _expectRejectedTrade(result, state, 'resource_trade_blocked_by_war');
  });

  test('gold availability wins over duplicate and export availability', () {
    final state = _tradeState(
      importerGold: 2,
      exporterRevealsHorses: false,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(state);

    _expectRejectedTrade(result, state, 'resource_trade_gold_unavailable');
  });

  test('active duplicate wins over export availability', () {
    final state = _tradeState(
      exporterRevealsHorses: false,
      agreements: const [_requestedHorsesTrade],
    );

    final result = _openGoldTrade(state);

    _expectRejectedTrade(result, state, 'resource_trade_already_active');
  });

  test('missing revealed export is the final rejection', () {
    final state = _tradeState(exporterRevealsHorses: false);

    final result = _openGoldTrade(state);

    _expectRejectedTrade(result, state, 'resource_trade_export_unavailable');
  });
}

void _registerGeneratedGoldTradeIdTest() {
  test('generated id is deterministic and only agreements change', () {
    final state = _tradeState(
      agreements: const [_unrelatedTrade, _expiredRequestedHorsesTrade],
    );

    final result = _openGoldTrade(state, durationTurns: 5);

    _expectOnlyTradeAgreementsChanged(result, state, const [
      _unrelatedTrade,
      _expiredRequestedHorsesTrade,
      ResourceTradeAgreement(
        id: 'resource_trade_player_1_player_2_horses_2',
        exporterPlayerId: _exporterId,
        importerPlayerId: _importerId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        remainingTurns: 5,
      ),
    ]);
    expect(state.runtimeState.resourceTradeAgreements, const [
      _unrelatedTrade,
      _expiredRequestedHorsesTrade,
    ]);
  });

  test('gold equal to the available balance is accepted', () {
    final state = _tradeState(importerGold: 3);

    final result = _openGoldTrade(state, agreementId: 'exact_balance_trade');

    _expectOnlyTradeAgreementsChanged(result, state, const [
      ResourceTradeAgreement(
        id: 'exact_balance_trade',
        exporterPlayerId: _exporterId,
        importerPlayerId: _importerId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        remainingTurns: 4,
      ),
    ]);
  });

  test('free trade accepts a missing importer balance', () {
    final state = _tradeState(includeImporterGold: false);

    final result = _openGoldTrade(
      state,
      goldPerTurn: 0,
      agreementId: 'free_trade',
    );

    _expectOnlyTradeAgreementsChanged(result, state, const [
      ResourceTradeAgreement(
        id: 'free_trade',
        exporterPlayerId: _exporterId,
        importerPlayerId: _importerId,
        resource: ResourceType.horses,
        goldPerTurn: 0,
        remainingTurns: 4,
      ),
    ]);
  });

  test('free trade accepts an explicit zero importer balance', () {
    final state = _tradeState(importerGold: 0);

    final result = _openGoldTrade(
      state,
      goldPerTurn: 0,
      agreementId: 'zero_balance_free_trade',
    );

    _expectOnlyTradeAgreementsChanged(result, state, const [
      ResourceTradeAgreement(
        id: 'zero_balance_free_trade',
        exporterPlayerId: _exporterId,
        importerPlayerId: _importerId,
        resource: ResourceType.horses,
        goldPerTurn: 0,
        remainingTurns: 4,
      ),
    ]);
  });
}

PersistentResourceTradeResult _openGoldTrade(
  PersistentGameState state, {
  String importerPlayerId = _importerId,
  String exporterPlayerId = _exporterId,
  ResourceType resource = ResourceType.horses,
  int goldPerTurn = 3,
  int durationTurns = 4,
  String? agreementId,
}) {
  return _resolver.openGoldForResourceTrade(
    state: state,
    importerPlayerId: importerPlayerId,
    exporterPlayerId: exporterPlayerId,
    resource: resource,
    goldPerTurn: goldPerTurn,
    durationTurns: durationTurns,
    mapTiles: _tradeMap(),
    agreementId: agreementId,
  );
}
