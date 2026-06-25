import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile(List<TerrainType> terrains) {
  return TileData(
    col: 0,
    row: 0,
    terrains: terrains,
    resources: const [],
    height: 0,
  );
}

void main() {
  group('CitySiteRules', () {
    test('allows cities on land terrains', () {
      for (final terrain in [
        TerrainType.grassland,
        TerrainType.plains,
        TerrainType.desert,
        TerrainType.tundra,
        TerrainType.snow,
        TerrainType.forest,
        TerrainType.jungle,
        TerrainType.wetlands,
        TerrainType.hills,
        TerrainType.coast,
      ]) {
        expect(CitySiteRules.canFoundCityOn(_tile([terrain])), isTrue);
      }
    });

    test('river does not block founding when paired with land', () {
      final tile = _tile([TerrainType.grassland, TerrainType.river]);

      expect(CitySiteRules.canFoundCityOn(tile), isTrue);
      expect(CitySiteRules.foundingFailure(tile), isNull);
    });

    test('rejects open water and mountain city sites', () {
      expect(
        CitySiteRules.foundingFailure(_tile([TerrainType.ocean])),
        CitySiteFailure.water,
      );
      expect(
        CitySiteRules.foundingFailure(_tile([TerrainType.lake])),
        CitySiteFailure.water,
      );
      expect(
        CitySiteRules.foundingFailure(_tile([TerrainType.mountain])),
        CitySiteFailure.mountain,
      );
    });

    test('rejects river-only tiles because river is only a modifier', () {
      expect(
        CitySiteRules.foundingFailure(_tile([TerrainType.river])),
        CitySiteFailure.noBaseTerrain,
      );
    });
  });
}
