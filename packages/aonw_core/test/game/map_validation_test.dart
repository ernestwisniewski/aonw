import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MapValidator', () {
    test('accepts a map with playable starts and resource density', () {
      final result = MapValidator.validate(
        mapData: _map(
          cols: 8,
          rows: 8,
          terrain: TerrainType.grassland,
          resourcesFor: (_) => const [
            ResourceType.wheat,
            ResourceType.iron,
            ResourceType.gold,
          ],
        ),
        playerCount: 2,
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.startSites, hasLength(2));
      expect(result.resources.foodResources, greaterThanOrEqualTo(4));
    });

    test('reports unplayable start sites', () {
      final result = MapValidator.validate(
        mapData: _map(
          cols: 6,
          rows: 6,
          terrain: TerrainType.ocean,
          resourcesFor: (_) => const [
            ResourceType.wheat,
            ResourceType.iron,
            ResourceType.gold,
          ],
        ),
        playerCount: 2,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        containsAll([
          'low_passable_tile_ratio',
          'start_site_not_foundable',
          'start_site_low_land_ring',
        ]),
      );
    });

    test('reports maps with thin food, luxury, and strategic resources', () {
      final result = MapValidator.validate(
        mapData: _map(
          cols: 8,
          rows: 8,
          terrain: TerrainType.grassland,
          resourcesFor: (_) => const [],
        ),
        playerCount: 2,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        containsAll([
          'low_food_resource_density',
          'low_strategic_resource_density',
          'low_luxury_resource_density',
          'start_site_low_food',
        ]),
      );
    });

    test('warns when a large sparse-contact map is used for 60m pace', () {
      final result = MapValidator.validate(
        mapData: _map(
          cols: 30,
          rows: 20,
          terrain: TerrainType.grassland,
          resourcesFor: (_) => const [
            ResourceType.wheat,
            ResourceType.iron,
            ResourceType.gold,
          ],
        ),
        playerCount: 2,
        gameLength: GameLengthConfig.standard60,
      );

      expect(result.isValid, isTrue);
      expect(
        result.warnings.map((issue) => issue.code),
        containsAll(['short_game_slow_first_contact', 'short_game_large_map']),
      );
    });
  });
}

MapData _map({
  required int cols,
  required int rows,
  required TerrainType terrain,
  required List<ResourceType> Function(({int col, int row}) coordinate)
  resourcesFor,
}) {
  return MapData(
    cols: cols,
    rows: rows,
    mapName: 'fixture',
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: [terrain],
            resources: resourcesFor((col: col, row: row)),
            height: 1,
          ),
    ],
  );
}
