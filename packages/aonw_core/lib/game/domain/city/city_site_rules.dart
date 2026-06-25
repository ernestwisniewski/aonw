import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum CitySiteFailure { noBaseTerrain, water, mountain }

abstract final class CitySiteRules {
  static bool canFoundCityOn(TileData tile) => foundingFailure(tile) == null;

  static bool canFoundCityForInput(HexAssessmentInput input) {
    return foundingFailureForInput(input) == null;
  }

  static CitySiteFailure? foundingFailure(TileData tile) {
    return foundingFailureForInput(HexAssessmentInput.fromTile(tile));
  }

  static CitySiteFailure? foundingFailureForInput(HexAssessmentInput input) {
    final terrain = input.baseTerrain;
    if (terrain == null) return CitySiteFailure.noBaseTerrain;
    return switch (terrain) {
      TerrainType.ocean || TerrainType.lake => CitySiteFailure.water,
      TerrainType.mountain => CitySiteFailure.mountain,
      TerrainType.grassland ||
      TerrainType.plains ||
      TerrainType.desert ||
      TerrainType.tundra ||
      TerrainType.snow ||
      TerrainType.forest ||
      TerrainType.jungle ||
      TerrainType.wetlands ||
      TerrainType.coast ||
      TerrainType.hills => null,
      TerrainType.river => CitySiteFailure.noBaseTerrain,
    };
  }
}
