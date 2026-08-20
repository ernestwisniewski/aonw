import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class HexAssessmentInput {
  final TerrainType baseTerrain;
  final bool hasRiver;
  final List<ResourceType> resources;
  final int height;
  final bool hasAdjacentMountain;
  final bool hasAdjacentCity;
  final bool isChokePoint;

  const HexAssessmentInput({
    required this.baseTerrain,
    required this.hasRiver,
    required this.resources,
    required this.height,
    this.hasAdjacentMountain = false,
    this.hasAdjacentCity = false,
    this.isChokePoint = false,
  });

  factory HexAssessmentInput.fromTile(
    MapTileView tile, {
    bool hasAdjacentMountain = false,
    bool hasAdjacentCity = false,
    bool isChokePoint = false,
  }) {
    return HexAssessmentInput(
      baseTerrain: tile.yieldTerrain,
      hasRiver: hasRiverIn(tile.terrainTags),
      resources: List.unmodifiable(tile.resources),
      height: tile.height,
      hasAdjacentMountain: hasAdjacentMountain,
      hasAdjacentCity: hasAdjacentCity,
      isChokePoint: isChokePoint,
    );
  }

  static bool hasRiverIn(Iterable<TerrainType> terrains) {
    return terrains.contains(TerrainType.river);
  }
}
