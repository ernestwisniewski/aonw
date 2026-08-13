import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('resource trade agreement id validation', () {
    test('rejects a client id colliding with an exchange group', () {
      const existing = ResourceTradeAgreement(
        id: 'victim_requested',
        exporterPlayerId: 'player_4',
        importerPlayerId: 'player_3',
        resource: ResourceType.uranium,
        goldPerTurn: 0,
        remainingTurns: 4,
        exchangeGroupId: 'victim',
      );
      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: const {'player_1': 8},
        cities: const [_horseCity],
        research: _research(),
        diplomacy: DiplomacyState.empty,
        resourceTradeAgreements: const [existing],
        command: const OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
          agreementId: 'victim',
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_agreement_id_conflict');
      expect(result.resourceTradeAgreements, same(const [existing]));
    });

    test('rejects unsafe client agreement ids', () {
      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: const {'player_1': 8},
        cities: const [],
        research: ResearchState.empty,
        diplomacy: DiplomacyState.empty,
        resourceTradeAgreements: const [],
        command: const OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.iron,
          goldPerTurn: 1,
          durationTurns: 5,
          agreementId: ' invalid id ',
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'invalid_resource_trade_agreement_id');
    });

    test('rejects exchange child id colliding with an agreement', () {
      const existing = ResourceTradeAgreement(
        id: 'exchange_1_requested',
        exporterPlayerId: 'player_4',
        importerPlayerId: 'player_3',
        resource: ResourceType.uranium,
        goldPerTurn: 0,
        remainingTurns: 4,
        exchangeGroupId: 'unrelated',
      );
      final result = ResourceTradeCommandResolver.openResourceForResourceTrade(
        cities: const [_ironCity, _horseCity],
        research: _research(),
        diplomacy: DiplomacyState.empty,
        resourceTradeAgreements: const [existing],
        command: const OpenResourceExchangeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          offeredResource: ResourceType.iron,
          requestedResource: ResourceType.horses,
          durationTurns: 6,
          agreementId: 'exchange_1',
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_agreement_id_conflict');
    });

    test('advances an automatic gold agreement id past collisions', () {
      const existing = ResourceTradeAgreement(
        id: 'resource_trade_player_1_player_2_horses_1',
        exporterPlayerId: 'player_4',
        importerPlayerId: 'player_3',
        resource: ResourceType.uranium,
        goldPerTurn: 0,
        remainingTurns: 4,
      );
      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: const {'player_1': 8},
        cities: const [_horseCity],
        research: _research(),
        diplomacy: DiplomacyState.empty,
        resourceTradeAgreements: const [existing],
        command: const OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(),
      );

      expect(result.accepted, isTrue);
      expect(
        result.resourceTradeAgreements.last.id,
        'resource_trade_player_1_player_2_horses_2',
      );
    });

    test('advances an automatic exchange id past child collisions', () {
      const existing = ResourceTradeAgreement(
        id: 'resource_exchange_player_1_player_2_iron_horses_1_requested',
        exporterPlayerId: 'player_4',
        importerPlayerId: 'player_3',
        resource: ResourceType.uranium,
        goldPerTurn: 0,
        remainingTurns: 4,
      );
      final result = ResourceTradeCommandResolver.openResourceForResourceTrade(
        cities: const [_ironCity, _horseCity],
        research: _research(),
        diplomacy: DiplomacyState.empty,
        resourceTradeAgreements: const [existing],
        command: const OpenResourceExchangeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          offeredResource: ResourceType.iron,
          requestedResource: ResourceType.horses,
          durationTurns: 6,
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(),
      );

      expect(result.accepted, isTrue);
      expect(
        result.resourceTradeAgreements
            .skip(1)
            .map((agreement) => agreement.exchangeGroupId),
        everyElement('resource_exchange_player_1_player_2_iron_horses_2'),
      );
    });
  });
}

const _ironCity = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Iron City',
  center: CityHex(col: 0, row: 0),
);
const _horseCity = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_2',
  name: 'Horse City',
  center: CityHex(col: 2, row: 2),
);

ResearchState _research() => ResearchState(
  players: {
    'player_1': PlayerResearchState(
      unlockedTechnologyIds: {TechnologyId.ironWorking},
    ),
    'player_2': PlayerResearchState(
      unlockedTechnologyIds: {TechnologyId.animalHusbandry},
    ),
  },
);

MapTileLookup _resourceMap() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: row),
          terrains: const [TerrainType.plains],
          resources: switch ((col, row)) {
            (0, 0) => const [ResourceType.iron],
            (2, 2) => const [ResourceType.horses],
            _ => const [],
          },
          height: 0,
        ),
  ],
);
