part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerResourceTradeTests() {
  group('ServerCommandReducer resource trade', () {
    test('opens gold-for-resource trade authoritatively', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(
          _RawTileLookupRejectingMapData(_resourceTradeMap()),
        ),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(
          PersistentGameState(
            playerGold: const {'player_1': 8},
            cities: _tradeCities(),
            research: _researchWithMany({
              'player_2': {TechnologyId.animalHusbandry},
            }),
          ),
        ),
        wireCommand: _wireCommand(
          const OpenResourceTradeCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            durationTurns: 5,
            agreementId: 'server_trade_1',
          ),
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      final nextState = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(nextState.runtimeState.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'server_trade_1',
          exporterPlayerId: 'player_2',
          importerPlayerId: 'player_1',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          remainingTurns: 5,
        ),
      ]);
    });

    test('opens resource exchange authoritatively', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(
          _RawTileLookupRejectingMapData(_resourceTradeMap()),
        ),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: _snapshot(
          PersistentGameState(
            cities: _tradeCities(),
            research: _researchWithMany({
              'player_1': {TechnologyId.ironWorking},
              'player_2': {TechnologyId.animalHusbandry},
            }),
          ),
        ),
        wireCommand: _wireCommand(
          const OpenResourceExchangeCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            offeredResource: ResourceType.iron,
            requestedResource: ResourceType.horses,
            durationTurns: 6,
            agreementId: 'server_exchange_1',
          ),
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      final nextState = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(
        nextState.runtimeState.resourceTradeAgreements
            .map((agreement) => agreement.toJson())
            .toList(),
        [
          {
            'id': 'server_exchange_1_offered',
            'exporterPlayerId': 'player_1',
            'importerPlayerId': 'player_2',
            'resource': ResourceType.iron.name,
            'remainingTurns': 6,
          },
          {
            'id': 'server_exchange_1_requested',
            'exporterPlayerId': 'player_2',
            'importerPlayerId': 'player_1',
            'resource': ResourceType.horses.name,
            'remainingTurns': 6,
          },
        ],
      );
    });

    test('rejects resource trade issued for another player', () async {
      final reducer = ServerCommandReducer(
        mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
      );
      final snapshot = _snapshot(
        PersistentGameState(
          playerGold: const {'player_2': 8},
          cities: _tradeCities(),
          research: _researchWithMany({
            'player_1': {TechnologyId.ironWorking},
          }),
        ),
      );

      final reduction = await reducer.reduce(
        match: _runningMatch(),
        snapshot: snapshot,
        wireCommand: _wireCommand(
          const OpenResourceTradeCommand(
            playerId: 'player_2',
            targetPlayerId: 'player_1',
            resource: ResourceType.iron,
            goldPerTurn: 3,
            durationTurns: 5,
          ),
          actorPlayerId: 'player_1',
        ),
        actorPlayerId: 'player_1',
        now: DateTime.utc(2026, 6, 30, 12),
      );

      expect(reduction.accepted, isFalse);
      expect(reduction.reason, 'resource_trade_player_not_controlled');
      expect(reduction.snapshot.toJson(), snapshot.toJson());
    });
  });
}
