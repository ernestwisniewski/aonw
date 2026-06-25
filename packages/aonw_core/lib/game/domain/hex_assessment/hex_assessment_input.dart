import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class HexAssessmentInput {
  final TerrainType? baseTerrain;
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
    TileData tile, {
    bool hasAdjacentMountain = false,
    bool hasAdjacentCity = false,
    bool isChokePoint = false,
  }) {
    return HexAssessmentInput(
      baseTerrain: baseTerrainFrom(tile.terrains),
      hasRiver: hasRiverIn(tile.terrains),
      resources: List.unmodifiable(tile.resources),
      height: tile.height,
      hasAdjacentMountain: hasAdjacentMountain,
      hasAdjacentCity: hasAdjacentCity,
      isChokePoint: isChokePoint,
    );
  }

  static TerrainType? baseTerrainFrom(Iterable<TerrainType> terrains) {
    for (final terrain in terrains) {
      if (terrain != TerrainType.river) return terrain;
    }
    return null;
  }

  static bool hasRiverIn(Iterable<TerrainType> terrains) {
    return terrains.contains(TerrainType.river);
  }
}
