import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TileTerrainProfileRules', () {
    test('classifies base terrain, features, modifiers, and blockers', () {
      final profile = TileTerrainProfileRules.fromTerrains(const [
        TerrainType.ocean,
        TerrainType.plains,
        TerrainType.forest,
        TerrainType.river,
        TerrainType.mountain,
      ]);

      expect(profile.base, TerrainType.plains);
      expect(profile.hasForest, isTrue);
      expect(profile.hasRiver, isTrue);
      expect(profile.hasMountain, isTrue);
    });
  });

  group('TileYieldRules', () {
    test('combines base terrain, river, and resources', () {
      const tile = TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland, TerrainType.river],
        resources: [ResourceType.wheat],
        height: 0,
      );

      expect(
        TileYieldRules.forTile(tile),
        const TileYield(food: 5, production: 0, gold: 0, defense: 0),
      );
      expect(TileYieldRules.forTile(tile), CityTileYieldRules.forTile(tile));
    });

    test('builds assessment input from tile', () {
      const tile = TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.river, TerrainType.hills],
        resources: [ResourceType.iron],
        height: 2,
      );

      final input = HexAssessmentInput.fromTile(tile);

      expect(input.baseTerrain, TerrainType.hills);
      expect(input.hasRiver, isTrue);
      expect(input.resources, [ResourceType.iron]);
      expect(input.height, 2);
    });
  });
}
