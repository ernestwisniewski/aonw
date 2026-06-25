import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile({
  int col = 0,
  int row = 0,
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

void main() {
  group('CityTileYieldRules', () {
    test('uses standard city terrain yields', () {
      expect(
        CityTileYieldRules.terrainYield(TerrainType.grassland),
        const TileYield(food: 2, production: 0, gold: 0, defense: 0),
      );
      expect(
        CityTileYieldRules.terrainYield(TerrainType.plains),
        const TileYield(food: 1, production: 1, gold: 0, defense: 0),
      );
      expect(
        CityTileYieldRules.terrainYield(TerrainType.forest),
        const TileYield(food: 1, production: 1, gold: 0, defense: 0),
      );
      expect(
        CityTileYieldRules.terrainYield(TerrainType.hills),
        const TileYield(food: 0, production: 2, gold: 0, defense: 0),
      );
      expect(
        CityTileYieldRules.terrainYield(TerrainType.desert),
        TileYield.zero,
      );
    });

    test('adds river, resource and improvement bonuses', () {
      final value = CityTileYieldRules.forTile(
        _tile(
          terrains: const [TerrainType.grassland, TerrainType.river],
          resources: const [ResourceType.wheat],
        ),
        improvement: FieldImprovementType.riverFarm,
      );

      expect(
        value,
        const TileYield(food: 7, production: 0, gold: 0, defense: 0),
      );
    });

    test('city center has fixed yield regardless of terrain', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      final value = CityTileYieldRules.forCityHex(
        city: city,
        hex: city.center,
        tile: _tile(terrains: const [TerrainType.desert]),
      );

      expect(value, CityRulesets.standard.cityCenterYield);
    });

    test('reads center and terrain yields from an injected ruleset', () {
      final ruleset = CityRulesets.standard.copyWith(
        cityCenterYield: const TileYield(
          food: 1,
          production: 2,
          gold: 3,
          defense: 4,
        ),
        terrainYields: {
          ...CityRulesets.standard.terrainYields,
          TerrainType.desert: const TileYield(
            food: 0,
            production: 0,
            gold: 2,
            defense: 0,
          ),
        },
      );
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      expect(
        CityTileYieldRules.forCityHex(
          city: city,
          hex: city.center,
          tile: _tile(terrains: const [TerrainType.desert]),
          ruleset: ruleset,
        ),
        const TileYield(food: 1, production: 2, gold: 3, defense: 4),
      );
      expect(
        CityTileYieldRules.forTile(
          _tile(terrains: const [TerrainType.desert]),
          ruleset: ruleset,
        ),
        const TileYield(food: 0, production: 0, gold: 2, defense: 0),
      );
    });

    test('allows city control on every existing tile terrain', () {
      for (final terrain in TerrainType.values) {
        expect(
          CityTileYieldRules.canCityControlTile(_tile(terrains: [terrain])),
          isTrue,
          reason: '${terrain.name} should be claimable by a city',
        );
      }

      expect(
        CityTileYieldRules.canCityControlTile(_tile(terrains: const [])),
        isTrue,
      );
    });
  });
}
