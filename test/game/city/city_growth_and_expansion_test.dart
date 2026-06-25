import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile({
  required int col,
  required int row,
  List<TerrainType> terrains = const [TerrainType.grassland],
  List<ResourceType> resources = const [],
}) {
  return TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: 0,
  );
}

MapData _map(List<TileData> tiles) => MapData(cols: 5, rows: 5, tiles: tiles);

void main() {
  group('CityGrowthRules', () {
    test('growth cost scales with population and controlled territory', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)],
      );

      expect(
        CityGrowthRules.growthCost(city, paceBalance: PaceBalance.long120),
        31,
      );
    });

    test('net food never goes below zero', () {
      expect(CityGrowthRules.netFood(totalFood: 2, population: 5), 0);
    });

    test('reads growth and upkeep values from an injected ruleset', () {
      final ruleset = CityRulesets.standard.copyWith(
        progression: const CityProgression(
          startPopulation: 3,
          startStoredFood: 0,
          startMaxHexes: 6,
          midGameMaxHexes: 8,
          lateGameMaxHexes: 10,
          startTerritoryRadius: 2,
          expandedTerritoryRadius: 3,
          foodUpkeepPerPopulation: 2,
          growthBaseCost: 5,
          growthCostPerPopulation: 3,
          growthCostPerControlledHex: 1,
        ),
      );
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 4,
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)],
      );

      expect(
        CityGrowthRules.growthCost(
          city,
          ruleset: ruleset,
          paceBalance: PaceBalance.long120,
        ),
        20,
      );
      expect(CityGrowthRules.populationUpkeep(city, ruleset: ruleset), 8);
      expect(
        CityGrowthRules.netFood(totalFood: 10, population: 4, ruleset: ruleset),
        2,
      );
    });
  });

  group('CityInitialTerritorySelector', () {
    test('selects the best two neighbouring hexes by food-first scoring', () {
      const center = CityHex(col: 2, row: 2);
      final mapData = _map([
        _tile(col: 2, row: 2),
        _tile(col: 3, row: 1, resources: const [ResourceType.wheat]),
        _tile(col: 3, row: 2, terrains: const [TerrainType.hills]),
        _tile(
          col: 2,
          row: 3,
          terrains: const [TerrainType.plains, TerrainType.river],
        ),
        _tile(col: 1, row: 2, terrains: const [TerrainType.desert]),
        _tile(col: 1, row: 1, terrains: const [TerrainType.forest]),
        _tile(col: 2, row: 1, terrains: const [TerrainType.tundra]),
      ]);

      final selected = CityInitialTerritorySelector.select(
        center: center,
        mapData: mapData,
        cities: const [],
      );

      expect(selected, const [
        CityHex(col: 3, row: 1),
        CityHex(col: 2, row: 3),
      ]);
    });

    test('uses injected terrain yields when scoring starting territory', () {
      const center = CityHex(col: 2, row: 2);
      final ruleset = CityRulesets.standard.copyWith(
        terrainYields: {
          ...CityRulesets.standard.terrainYields,
          TerrainType.desert: const TileYield(
            food: 8,
            production: 0,
            gold: 0,
            defense: 0,
          ),
        },
      );
      final mapData = _map([
        _tile(col: 2, row: 2),
        _tile(col: 3, row: 1, resources: const [ResourceType.wheat]),
        _tile(col: 1, row: 2, terrains: const [TerrainType.desert]),
      ]);

      final selected = CityInitialTerritorySelector.select(
        center: center,
        mapData: mapData,
        cities: const [],
        count: 1,
        ruleset: ruleset,
      );

      expect(selected, const [CityHex(col: 1, row: 2)]);
    });
  });

  group('CityExpansionSelector', () {
    test('offers mountain and water hexes while ignoring owned territory', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1)],
      );
      const otherCity = GameCity(
        id: 'other',
        ownerPlayerId: 'player_2',
        name: 'Other',
        center: CityHex(col: 0, row: 1),
      );
      final mapData = _map([
        _tile(col: 1, row: 1),
        _tile(col: 2, row: 1),
        _tile(col: 2, row: 2, terrains: const [TerrainType.mountain]),
        _tile(col: 1, row: 2, terrains: const [TerrainType.coast]),
        _tile(col: 0, row: 2, resources: const [ResourceType.wheat]),
        _tile(col: 0, row: 1),
      ]);

      final candidates = CityExpansionSelector.candidatesFor(
        city: city,
        mapData: mapData,
        cities: [city, otherCity],
      ).map((candidate) => candidate.hex).toSet();

      expect(
        candidates,
        containsAll(const [
          CityHex(col: 2, row: 2),
          CityHex(col: 1, row: 2),
          CityHex(col: 0, row: 2),
        ]),
      );
      expect(candidates, isNot(contains(const CityHex(col: 2, row: 1))));
      expect(candidates, isNot(contains(const CityHex(col: 0, row: 1))));

      final selected = CityExpansionSelector.bestHex(
        city: city,
        mapData: mapData,
        cities: [city, otherCity],
      );

      expect(selected, const CityHex(col: 0, row: 2));
    });

    test('uses preferred expansion hex when it is still available', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1)],
        preferredExpansionHex: CityHex(col: 1, row: 2),
      );
      final mapData = _map([
        _tile(col: 1, row: 1),
        _tile(col: 2, row: 1),
        _tile(col: 2, row: 2, resources: const [ResourceType.wheat]),
        _tile(col: 1, row: 2, terrains: const [TerrainType.plains]),
      ]);

      final selected = CityExpansionSelector.preferredOrBestHex(
        city: city,
        mapData: mapData,
        cities: const [city],
      );

      expect(selected, const CityHex(col: 1, row: 2));
    });

    test('falls back to best hex when preferred expansion is unavailable', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1)],
        preferredExpansionHex: CityHex(col: 4, row: 4),
      );
      final mapData = _map([
        _tile(col: 1, row: 1),
        _tile(col: 2, row: 1),
        _tile(col: 2, row: 2, resources: const [ResourceType.wheat]),
        _tile(col: 1, row: 2, terrains: const [TerrainType.plains]),
      ]);

      final selected = CityExpansionSelector.preferredOrBestHex(
        city: city,
        mapData: mapData,
        cities: const [city],
      );

      expect(selected, const CityHex(col: 2, row: 2));
    });

    test(
      'requires two previous-ring neighbours before offering outer expansion',
      () {
        const city = GameCity(
          id: 'city',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          controlledHexes: [CityHex(col: 3, row: 2)],
        );
        final mapData = _map([
          _tile(col: 2, row: 2),
          _tile(col: 3, row: 2),
          _tile(col: 3, row: 1),
          _tile(col: 4, row: 2, resources: const [ResourceType.wheat]),
        ]);

        final unsupportedCandidates = CityExpansionSelector.candidatesFor(
          city: city,
          mapData: mapData,
          cities: const [city],
        ).map((candidate) => candidate.hex).toSet();

        expect(
          unsupportedCandidates,
          isNot(contains(const CityHex(col: 4, row: 2))),
        );

        const supportedCity = GameCity(
          id: 'city',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          controlledHexes: [CityHex(col: 3, row: 2), CityHex(col: 3, row: 1)],
        );

        final supportedCandidates = CityExpansionSelector.candidatesFor(
          city: supportedCity,
          mapData: mapData,
          cities: const [supportedCity],
        ).map((candidate) => candidate.hex).toSet();

        expect(supportedCandidates, contains(const CityHex(col: 4, row: 2)));
      },
    );
  });

  group('CityTerritoryRules expansion support', () {
    test('allows first-ring expansion without extra support', () {
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [],
          target: const CityHex(col: 3, row: 2),
          maxDistance: 2,
        ),
        isTrue,
      );
    });

    test('requires two adjacent previous-ring hexes for outer rings', () {
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [CityHex(col: 3, row: 2)],
          target: const CityHex(col: 4, row: 2),
          maxDistance: 2,
        ),
        isFalse,
      );
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 3, row: 1),
          ],
          target: const CityHex(col: 4, row: 2),
          maxDistance: 2,
        ),
        isTrue,
      );
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [CityHex(col: 4, row: 2)],
          target: const CityHex(col: 5, row: 2),
          maxDistance: 3,
        ),
        isFalse,
      );
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 4, row: 2),
            CityHex(col: 4, row: 3),
          ],
          target: const CityHex(col: 5, row: 2),
          maxDistance: 3,
        ),
        isTrue,
      );
    });
  });

  group('CityTurnProcessor expansion', () {
    test('claims the best neighbouring hex when food grows the city', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        storedFood: 28,
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1)],
      );
      final mapData = _map([
        _tile(col: 1, row: 1),
        _tile(col: 2, row: 1),
        _tile(col: 2, row: 2, resources: const [ResourceType.wheat]),
        _tile(col: 1, row: 2, terrains: const [TerrainType.plains]),
        _tile(col: 0, row: 1, terrains: const [TerrainType.desert]),
        _tile(col: 0, row: 0, terrains: const [TerrainType.forest]),
        _tile(col: 1, row: 0, terrains: const [TerrainType.tundra]),
        _tile(col: 2, row: 0, terrains: const [TerrainType.hills]),
        _tile(col: 3, row: 1, terrains: const [TerrainType.grassland]),
      ]);

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: const [city],
        fieldImprovements: const [],
        mapData: mapData,
        paceBalance: PaceBalance.long120,
      );

      final updatedCity = result.cities.single;
      expect(updatedCity.population, 4);
      expect(
        updatedCity.controlledHexes,
        contains(const CityHex(col: 2, row: 2)),
      );
      expect(
        result.events.map((event) => event.type),
        containsAll([CityTurnEventType.grew, CityTurnEventType.claimedHex]),
      );
      expect(
        result.events
            .where((event) => event.type == CityTurnEventType.claimedHex)
            .single
            .hex,
        const CityHex(col: 2, row: 2),
      );
    });

    test(
      'claims preferred neighbouring hex and clears preference on growth',
      () {
        const city = GameCity(
          id: 'city',
          ownerPlayerId: 'player_1',
          name: 'City',
          population: 3,
          storedFood: 28,
          center: CityHex(col: 1, row: 1),
          controlledHexes: [CityHex(col: 2, row: 1)],
          preferredExpansionHex: CityHex(col: 1, row: 2),
        );
        final mapData = _map([
          _tile(col: 1, row: 1),
          _tile(col: 2, row: 1),
          _tile(col: 2, row: 2, resources: const [ResourceType.wheat]),
          _tile(col: 1, row: 2, terrains: const [TerrainType.plains]),
        ]);

        final result = CityTurnProcessor.advanceForPlayer(
          playerId: 'player_1',
          cities: const [city],
          fieldImprovements: const [],
          mapData: mapData,
          paceBalance: PaceBalance.long120,
        );

        final updatedCity = result.cities.single;
        expect(
          updatedCity.controlledHexes,
          contains(const CityHex(col: 1, row: 2)),
        );
        expect(updatedCity.preferredExpansionHex, isNull);
        expect(
          result.events
              .where((event) => event.type == CityTurnEventType.claimedHex)
              .single
              .hex,
          const CityHex(col: 1, row: 2),
        );
      },
    );
  });
}
