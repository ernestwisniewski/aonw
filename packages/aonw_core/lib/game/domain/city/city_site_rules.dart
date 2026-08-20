import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum CitySiteFailure { noBaseTerrain, water, mountain }

abstract final class CitySiteRules {
  static bool canFoundCityOn(MapTileView tile) => foundingFailure(tile) == null;

  static bool canFoundCityForInput(HexAssessmentInput input) {
    return foundingFailureForInput(input) == null;
  }

  static CitySiteFailure? foundingFailure(MapTileView tile) {
    return foundingFailureForInput(HexAssessmentInput.fromTile(tile));
  }

  static CitySiteFailure? foundingFailureForInput(HexAssessmentInput input) {
    final terrain = input.baseTerrain;
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
