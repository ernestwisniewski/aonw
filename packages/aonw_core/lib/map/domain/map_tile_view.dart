import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/tile_terrain_semantics.dart';

/// Read-only gameplay view of one map tile.
///
/// Implementations may expose borrowed collections to keep this contract
/// zero-copy. Consumers must not mutate values reached through the view.
abstract interface class MapTileView {
  int get col;
  int get row;
  TileTerrainSemantics get terrain;
  Iterable<ResourceType> get resources;
  int get height;
}

extension MapTileTerrainView on MapTileView {
  Iterable<TerrainType> get terrains => terrain.movementTerrains;
  TerrainType get displayTerrain => terrain.displayTerrain;
  TerrainType get yieldTerrain => terrain.yieldTerrain;
  Iterable<TerrainType> get terrainTags => terrain.terrainTags;
}

/// Read-only catalog preserving the canonical tile iteration order.
///
/// Sparse maps expose only their existing tiles; consumers must not infer a
/// dense `cols * rows` layout from this iterable.
abstract interface class MapTileCatalog {
  Iterable<MapTileView> get tileViews;
}
