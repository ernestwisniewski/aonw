import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile({
  List<TerrainType> terrains = const [TerrainType.grassland],
  List<ResourceType> resources = const [],
}) {
  return TileData(
    col: 0,
    row: 0,
    terrains: terrains,
    resources: resources,
    height: 0,
  );
}

void main() {
  group('TileYieldRules terrain yields', () {
    test('returns base yield for each terrain', () {
      expect(
        TileYieldRules.terrainYield(TerrainType.grassland),
        const TileYield(food: 2, production: 0, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.terrainYield(TerrainType.plains),
        const TileYield(food: 1, production: 1, gold: 0, defense: 0),
      );
      expect(TileYieldRules.terrainYield(TerrainType.desert), TileYield.zero);
      expect(
        TileYieldRules.terrainYield(TerrainType.tundra),
        const TileYield(food: 1, production: 0, gold: 0, defense: 0),
      );
      expect(TileYieldRules.terrainYield(TerrainType.snow), TileYield.zero);
      expect(
        TileYieldRules.terrainYield(TerrainType.forest),
        const TileYield(food: 1, production: 1, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.terrainYield(TerrainType.jungle),
        const TileYield(food: 1, production: 0, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.terrainYield(TerrainType.hills),
        const TileYield(food: 0, production: 2, gold: 0, defense: 0),
      );
      expect(TileYieldRules.terrainYield(TerrainType.mountain), TileYield.zero);
      expect(
        TileYieldRules.terrainYield(TerrainType.coast),
        const TileYield(food: 1, production: 0, gold: 0, defense: 0),
      );
      expect(TileYieldRules.terrainYield(TerrainType.ocean), TileYield.zero);
    });

    test('river is a tile modifier', () {
      final value = TileYieldRules.forTile(
        _tile(terrains: const [TerrainType.plains, TerrainType.river]),
      );

      expect(
        value,
        const TileYield(food: 2, production: 1, gold: 0, defense: 0),
      );
    });

    test('uses first non-river terrain as base terrain', () {
      final tile = _tile(
        terrains: const [TerrainType.river, TerrainType.desert],
      );

      expect(TileYieldRules.baseTerrainFor(tile), TerrainType.desert);
      expect(
        TileYieldRules.forTile(tile),
        const TileYield(food: 1, production: 0, gold: 0, defense: 0),
      );
    });

    test('river-only tile has no implicit base terrain yield', () {
      final value = TileYieldRules.forTile(
        _tile(terrains: const [TerrainType.river]),
      );

      expect(value, TileYieldRules.riverModifier);
    });
  });

  group('TileYieldRules resource yields', () {
    test('adds bonus resource yields', () {
      expect(
        TileYieldRules.resourceYield(ResourceType.wheat),
        const TileYield(food: 2, production: 0, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.resourceYield(ResourceType.fish),
        const TileYield(food: 2, production: 0, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.resourceYield(ResourceType.deer),
        const TileYield(food: 1, production: 1, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.resourceYield(ResourceType.sheep),
        const TileYield(food: 1, production: 1, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.resourceYield(ResourceType.rice),
        const TileYield(food: 2, production: 0, gold: 0, defense: 0),
      );
    });

    test('luxury resources do not add direct city yields', () {
      expect(TileYieldRules.resourceYield(ResourceType.gold), TileYield.zero);
      expect(TileYieldRules.resourceYield(ResourceType.silver), TileYield.zero);
      expect(TileYieldRules.resourceYield(ResourceType.silk), TileYield.zero);
      expect(TileYieldRules.resourceYield(ResourceType.spices), TileYield.zero);
      expect(TileYieldRules.resourceYield(ResourceType.coffee), TileYield.zero);
    });

    test('strategic and production resources use city resource yields', () {
      expect(
        TileYieldRules.resourceYield(ResourceType.iron),
        const TileYield(food: 0, production: 2, gold: 0, defense: 0),
      );
      expect(
        TileYieldRules.resourceYield(ResourceType.marble),
        const TileYield(food: 0, production: 2, gold: 0, defense: 0),
      );
      expect(TileYieldRules.resourceYield(ResourceType.horses), TileYield.zero);
      expect(TileYieldRules.resourceYield(ResourceType.coal), TileYield.zero);
      expect(TileYieldRules.resourceYield(ResourceType.oil), TileYield.zero);
    });

    test('sums terrain, river and resource yields for a tile', () {
      final value = TileYieldRules.forTile(
        _tile(
          terrains: const [TerrainType.grassland, TerrainType.river],
          resources: const [ResourceType.wheat, ResourceType.gold],
        ),
      );

      expect(
        value,
        const TileYield(food: 5, production: 0, gold: 0, defense: 0),
      );
    });

    test('matches city tile yield rules for unimproved tiles', () {
      final tiles = [
        _tile(),
        _tile(terrains: const [TerrainType.plains, TerrainType.river]),
        _tile(resources: const [ResourceType.wheat, ResourceType.iron]),
        _tile(
          terrains: const [TerrainType.coast],
          resources: const [ResourceType.fish],
        ),
      ];

      for (final tile in tiles) {
        expect(
          TileYieldRules.forTile(tile),
          CityTileYieldRules.forTile(tile),
          reason: 'Expected unified yield for ${tile.terrains}',
        );
      }
    });

    test('reads injected city ruleset values', () {
      final ruleset = CityRulesets.standard.copyWith(
        riverYield: const TileYield(
          food: 0,
          production: 0,
          gold: 2,
          defense: 0,
        ),
        terrainYields: {
          ...CityRulesets.standard.terrainYields,
          TerrainType.desert: const TileYield(
            food: 0,
            production: 0,
            gold: 3,
            defense: 0,
          ),
        },
        resourceYields: {
          ...CityRulesets.standard.resourceYields,
          ResourceType.gold: const TileYield(
            food: 0,
            production: 0,
            gold: 4,
            defense: 0,
          ),
        },
      );

      final value = TileYieldRules.forTile(
        _tile(
          terrains: const [TerrainType.desert, TerrainType.river],
          resources: const [ResourceType.gold],
        ),
        ruleset: ruleset,
      );

      expect(
        value,
        const TileYield(food: 0, production: 0, gold: 9, defense: 0),
      );
    });
  });
}
