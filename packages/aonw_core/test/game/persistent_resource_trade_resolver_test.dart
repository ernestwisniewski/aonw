import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentResourceTradeResolver', () {
    test('opens gold-for-resource trade when exporter controls resource', () {
      final state = PersistentGameState(
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

      final result = const PersistentResourceTradeResolver()
          .openGoldForResourceTrade(
            state: state,
            importerPlayerId: 'player_1',
            exporterPlayerId: 'player_2',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            durationTurns: 5,
            mapData: _resourceMap(ResourceType.horses),
            agreementId: 'trade_1',
          );

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState.resourceTradeAgreements, [
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
      const state = PersistentGameState(
        playerGold: {'player_1': 8},
        cities: [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_2',
            name: 'Exporter',
            center: CityHex(col: 1, row: 1),
          ),
        ],
      );

      final result = const PersistentResourceTradeResolver()
          .openGoldForResourceTrade(
            state: state,
            importerPlayerId: 'player_1',
            exporterPlayerId: 'player_2',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            durationTurns: 5,
            mapData: _resourceMap(ResourceType.horses),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_export_unavailable');
      expect(result.state, state);
    });

    test('rejects trade when all matching exports are already committed', () {
      final state = PersistentGameState(
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
        runtimeState: const GameRuntimeState(
          resourceTradeAgreements: [
            ResourceTradeAgreement(
              id: 'trade_1',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.horses,
              goldPerTurn: 3,
              remainingTurns: 5,
            ),
          ],
        ),
      );

      final result = const PersistentResourceTradeResolver()
          .openGoldForResourceTrade(
            state: state,
            importerPlayerId: 'player_3',
            exporterPlayerId: 'player_2',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            durationTurns: 5,
            mapData: _resourceMap(ResourceType.horses),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_export_unavailable');
    });

    test('rejects trade while players are at war', () {
      final state = PersistentGameState(
        playerGold: const {'player_1': 8},
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.war,
          ),
        ),
      );

      final result = const PersistentResourceTradeResolver()
          .openGoldForResourceTrade(
            state: state,
            importerPlayerId: 'player_1',
            exporterPlayerId: 'player_2',
            resource: ResourceType.iron,
            goldPerTurn: 3,
            durationTurns: 5,
            mapData: _resourceMap(ResourceType.iron),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_blocked_by_war');
    });

    test(
      'opens resource-for-resource trade when both exports are available',
      () {
        final state = PersistentGameState(
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

        final result = const PersistentResourceTradeResolver()
            .openResourceForResourceTrade(
              state: state,
              playerId: 'player_1',
              targetPlayerId: 'player_2',
              offeredResource: ResourceType.iron,
              requestedResource: ResourceType.horses,
              durationTurns: 6,
              mapData: _exchangeResourceMap(),
              agreementId: 'exchange_1',
            );

        expect(result.accepted, isTrue);
        expect(result.state.runtimeState.resourceTradeAgreements, [
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
      final state = PersistentGameState(
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

      final result = const PersistentResourceTradeResolver()
          .openResourceForResourceTrade(
            state: state,
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            offeredResource: ResourceType.iron,
            requestedResource: ResourceType.horses,
            durationTurns: 6,
            mapData: _exchangeResourceMap(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_offer_unavailable');
      expect(result.state, state);
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

MapData _resourceMap(ResourceType resource) {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: col == 1 && row == 1 ? [resource] : const [],
            height: 0,
          ),
    ],
  );
}

MapData _exchangeResourceMap() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
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
