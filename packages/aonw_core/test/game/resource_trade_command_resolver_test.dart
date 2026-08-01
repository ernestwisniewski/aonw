import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceTradeCommandResolver', () {
    test('opens gold-for-resource trade when exporter controls resource', () {
      final state = DomainState.snapshot(
        playerGold: const {'player_1': 8},
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_2',
            name: 'Exporter',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        research: _researchWith('player_2', TechnologyId.animalHusbandry),
      );

      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: state.playerGold,
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: const OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
          agreementId: 'trade_1',
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(ResourceType.horses),
      );

      expect(result.accepted, isTrue);
      expect(result.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'player_2',
          importerPlayerId: 'player_1',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          remainingTurns: 5,
        ),
      ]);
    });

    test('rejects trade when exporter does not reveal the resource', () {
      final state = DomainState.snapshot(
        playerGold: {'player_1': 8},
        cities: [
          const GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_2',
            name: 'Exporter',
            center: CityHex(col: 1, row: 1),
          ),
        ],
      );

      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: state.playerGold,
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: const OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
        ),
        actorPlayerId: 'player_1',
        mapTiles: _resourceMap(ResourceType.horses),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_export_unavailable');
      expect(
        result.resourceTradeAgreements,
        same(state.resourceTradeAgreements),
      );
    });

    test('rejects trade when all matching exports are already committed', () {
      final state = DomainState.snapshot(
        playerGold: const {'player_1': 8, 'player_3': 8},
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_2',
            name: 'Exporter',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        research: _researchWith('player_2', TechnologyId.animalHusbandry),

        resourceTradeAgreements: [
          const ResourceTradeAgreement(
            id: 'trade_1',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 5,
          ),
        ],
      );

      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: state.playerGold,
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: const OpenResourceTradeCommand(
          playerId: 'player_3',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
        ),
        actorPlayerId: 'player_3',
        mapTiles: _resourceMap(ResourceType.horses),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_export_unavailable');
    });

    test('actor rejection wins over every trade-rule rejection', () {
      final state = DomainState.snapshot(
        playerGold: const {'player_1': 8},

        diplomacy: DiplomacyState.empty.setStatus(
          'player_1',
          'player_2',
          DiplomaticRelationStatus.war,
        ),
      );

      final result = ResourceTradeCommandResolver.openGoldForResourceTrade(
        playerGold: state.playerGold,
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: const OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.iron,
          goldPerTurn: 3,
          durationTurns: 5,
        ),
        actorPlayerId: 'player_3',
        mapTiles: _resourceMap(ResourceType.iron),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_player_not_controlled');
    });

    test(
      'opens resource-for-resource trade when both exports are available',
      () {
        final state = DomainState.snapshot(
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Iron City',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Horse City',
              center: CityHex(col: 2, row: 2),
            ),
          ],
          research: _researchWithMany({
            'player_1': {TechnologyId.ironWorking},
            'player_2': {TechnologyId.animalHusbandry},
          }),
        );

        final result =
            ResourceTradeCommandResolver.openResourceForResourceTrade(
              cities: state.cities,
              research: state.research,
              diplomacy: state.diplomacy,
              resourceTradeAgreements: state.resourceTradeAgreements,
              command: const OpenResourceExchangeCommand(
                playerId: 'player_1',
                targetPlayerId: 'player_2',
                offeredResource: ResourceType.iron,
                requestedResource: ResourceType.horses,
                durationTurns: 6,
                agreementId: 'exchange_1',
              ),
              actorPlayerId: 'player_1',
              mapTiles: _exchangeResourceMap(),
            );

        expect(result.accepted, isTrue);
        expect(result.resourceTradeAgreements, [
          const ResourceTradeAgreement(
            id: 'exchange_1_requested',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 0,
            remainingTurns: 6,
          ),
          const ResourceTradeAgreement(
            id: 'exchange_1_offered',
            exporterPlayerId: 'player_1',
            importerPlayerId: 'player_2',
            resource: ResourceType.iron,
            goldPerTurn: 0,
            remainingTurns: 6,
          ),
        ]);
      },
    );

    test('rejects resource exchange when offered resource is unavailable', () {
      final state = DomainState.snapshot(
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Plain City',
            center: CityHex(col: 0, row: 1),
          ),
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Horse City',
            center: CityHex(col: 2, row: 2),
          ),
        ],
        research: _researchWithMany({
          'player_2': {TechnologyId.animalHusbandry},
        }),
      );

      final result = ResourceTradeCommandResolver.openResourceForResourceTrade(
        cities: state.cities,
        research: state.research,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
        command: const OpenResourceExchangeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          offeredResource: ResourceType.iron,
          requestedResource: ResourceType.horses,
          durationTurns: 6,
        ),
        actorPlayerId: 'player_1',
        mapTiles: _exchangeResourceMap(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_offer_unavailable');
      expect(
        result.resourceTradeAgreements,
        same(state.resourceTradeAgreements),
      );
    });
  });
}

ResearchState _researchWith(String playerId, TechnologyId technologyId) {
  return _researchWithMany({
    playerId: {technologyId},
  });
}

ResearchState _researchWithMany(Map<String, Set<TechnologyId>> technologies) {
  return ResearchState(
    players: {
      for (final entry in technologies.entries)
        entry.key: PlayerResearchState(unlockedTechnologyIds: entry.value),
    },
  );
}

MapTileLookup _resourceMap(ResourceType resource) {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: col == 1 && row == 1 ? [resource] : const [],
            height: 0,
          ),
    ],
  );
}

MapTileLookup _exchangeResourceMap() {
  return WorldMap(
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
}
