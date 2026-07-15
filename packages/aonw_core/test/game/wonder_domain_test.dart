import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Wonder domain', () {
    test(
      'standard catalog defines every wonder with fixed costs and tech gates',
      () {
        const ruleset = WonderRuleset.standard;

        expect(ruleset.wonders.keys.toSet(), WonderType.values.toSet());
        expect(
          ruleset.definitionFor(WonderType.greatLibrary).unlockTech,
          TechnologyId.writing,
        );
        expect(
          ruleset.definitionFor(WonderType.greatLibrary).productionCost,
          120,
        );
        expect(
          ruleset.definitionFor(WonderType.motherFactory).unlockTech,
          TechnologyId.steamPower,
        );
        expect(
          ruleset.definitionFor(WonderType.grandExposition).productionCost,
          400,
        );
      },
    );

    test(
      'availability checks tech, terrain, river, registry, and one-at-a-time',
      () {
        final city = _city();
        final research = _researchWithAll({
          TechnologyId.writing,
          TechnologyId.waterEngineering,
          TechnologyId.stoneworking,
        });

        expect(
          WonderAvailabilityPolicy.availabilityFor(
            city: city,
            wonderType: WonderType.greatLibrary,
            cities: [city],
            registry: WonderRegistry.empty,
            research: research,
            mapTiles: _mapData(),
          ).status,
          WonderAvailabilityStatus.available,
        );
        expect(
          WonderAvailabilityPolicy.availabilityFor(
            city: city,
            wonderType: WonderType.centralBank,
            cities: [city],
            registry: WonderRegistry.empty,
            research: research,
            mapTiles: _mapData(),
          ).status,
          WonderAvailabilityStatus.technologyLocked,
        );
        expect(
          WonderAvailabilityPolicy.availabilityFor(
            city: city,
            wonderType: WonderType.petra,
            cities: [city],
            registry: WonderRegistry.empty,
            research: research,
            mapTiles: _mapData(),
          ).status,
          WonderAvailabilityStatus.requirementsMissing,
        );
        expect(
          WonderAvailabilityPolicy.availabilityFor(
            city: city,
            wonderType: WonderType.hangingGardens,
            cities: [city],
            registry: WonderRegistry.empty,
            research: research,
            mapTiles: _mapData(withAdjacentRiver: true),
          ).status,
          WonderAvailabilityStatus.available,
        );
        expect(
          WonderAvailabilityPolicy.availabilityFor(
            city: city,
            wonderType: WonderType.greatLibrary,
            cities: [city],
            registry: WonderRegistry.empty.complete(
              type: WonderType.greatLibrary,
              playerId: 'rival',
            ),
            research: research,
            mapTiles: _mapData(),
          ).status,
          WonderAvailabilityStatus.completed,
        );
        expect(
          WonderAvailabilityPolicy.availabilityFor(
            city: city,
            wonderType: WonderType.hangingGardens,
            cities: [
              city,
              _city(
                id: 'city_2',
                center: const CityHex(col: 3, row: 3),
                productionQueue: CityProductionQueue.wonder(
                  wonderType: WonderType.greatLibrary,
                  investedProduction: 1,
                ),
              ),
            ],
            registry: WonderRegistry.empty,
            research: research,
            mapTiles: _mapData(withAdjacentRiver: true),
          ).status,
          WonderAvailabilityStatus.playerAlreadyBuildingWonder,
        );
      },
    );

    test('target, command, event, and registry serialize by stable names', () {
      const target = WonderProductionTarget(WonderType.greatWall);
      expect(CityProductionTarget.fromJson(target.toJson()), target);

      const command = StartWonderCommand('city_1', WonderType.greatWall);
      expect(
        GameCommandSerializer.fromJson(GameCommandSerializer.toJson(command)),
        command,
      );

      const built = CityBuiltWonderEvent(
        cityId: 'city_1',
        ownerPlayerId: 'player_1',
        wonderType: WonderType.greatWall,
      );
      expect(
        GameEventSerializer.toJson(
          GameEventSerializer.fromJson(GameEventSerializer.toJson(built)),
        ),
        GameEventSerializer.toJson(built),
      );

      final registry = WonderRegistry.empty.complete(
        type: WonderType.greatWall,
        playerId: 'player_1',
      );
      expect(WonderRegistry.fromJson(registry.toJson()), registry);
    });

    test(
      'completion claims wonder, refunds losing queues, and keeps effects active by host',
      () {
        final cost = CityProductionRules.wonderProductionCost(
          WonderType.hangingGardens,
        );
        final host = _city(
          productionQueue: CityProductionQueue.wonder(
            wonderType: WonderType.hangingGardens,
            investedProduction: cost,
          ),
        );
        final loser = _city(
          id: 'city_2',
          center: const CityHex(col: 3, row: 3),
          productionQueue: CityProductionQueue.wonder(
            wonderType: WonderType.hangingGardens,
            investedProduction: 30,
          ),
        );

        final result = WonderCompletionResolver.resolveCompletedForPlayer(
          playerId: 'player_1',
          cities: [host, loser],
          registry: WonderRegistry.empty,
          playerGold: const {},
          research: ResearchState.empty,
        );

        expect(result.registry.ownerOf(WonderType.hangingGardens), 'player_1');
        expect(result.cities[0].wonders, contains(WonderType.hangingGardens));
        expect(result.cities[0].productionQueue, isNull);
        expect(result.cities[1].productionQueue, isNull);
        expect(result.cities[1].productionOverflow, 30);
        expect(result.events.whereType<CityBuiltWonderEvent>(), hasLength(1));
        expect(
          result.events.whereType<WonderProductionRefundedEvent>(),
          hasLength(1),
        );

        expect(
          WonderEffectResolver.yieldForCity(
            city: result.cities[0],
            cities: result.cities,
            registry: result.registry,
          ).food,
          3,
        );
        expect(
          WonderEffectResolver.yieldForCity(
            city: result.cities[1],
            cities: [result.cities[1]],
            registry: result.registry,
          ),
          TileYield.zero,
        );
      },
    );

    test('captured host city transfers active wonder effects', () {
      final originalHost = _city(wonders: const {WonderType.hangingGardens});
      final capturedHost = originalHost.copyWith(ownerPlayerId: 'player_2');
      final capturedEmpireCity = _city(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        center: const CityHex(col: 3, row: 3),
      );
      final originalOwnerCity = _city(
        id: 'city_3',
        center: const CityHex(col: 4, row: 4),
      );
      final registry = WonderRegistry.empty.complete(
        type: WonderType.hangingGardens,
        playerId: 'player_1',
      );

      expect(
        WonderEffectResolver.yieldForCity(
          city: capturedEmpireCity,
          cities: [capturedHost, capturedEmpireCity, originalOwnerCity],
          registry: registry,
        ).food,
        1,
      );
      expect(
        WonderEffectResolver.yieldForCity(
          city: originalOwnerCity,
          cities: [capturedHost, capturedEmpireCity, originalOwnerCity],
          registry: registry,
        ),
        TileYield.zero,
      );
    });
  });
}

GameCity _city({
  String id = 'city_1',
  String ownerPlayerId = 'player_1',
  CityHex center = const CityHex(col: 1, row: 1),
  CityProductionQueue? productionQueue,
  Set<WonderType> wonders = const {},
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    productionQueue: productionQueue,
    wonders: wonders,
  );
}

ResearchState _researchWithAll(Set<TechnologyId> technologyIds) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: technologyIds),
    },
  );
}

MapData _mapData({bool withAdjacentRiver = false}) {
  return MapData(
    cols: 5,
    rows: 5,
    tiles: [
      for (var row = 0; row < 5; row++)
        for (var col = 0; col < 5; col++)
          TileData(
            col: col,
            row: row,
            terrains: col == 2 && row == 1 && withAdjacentRiver
                ? const [TerrainType.grassland, TerrainType.river]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
