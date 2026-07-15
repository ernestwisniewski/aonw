import 'package:aonw_core/map/domain/terrain_type.dart';

/// Read-only gameplay view of one map tile.
///
/// Implementations may expose borrowed collections to keep this contract
/// zero-copy. Consumers must not mutate values reached through the view.
abstract interface class MapTileView {
  int get col;
  int get row;
  Iterable<TerrainType> get terrains;
  Iterable<ResourceType> get resources;
  int get height;
  TerrainType get primaryTerrain;
}

/// Read-only catalog preserving the canonical tile iteration order.
///
/// Sparse maps expose only their existing tiles; consumers must not infer a
/// dense `cols * rows` layout from this iterable.
abstract interface class MapTileCatalog {
  Iterable<MapTileView> get tileViews;
}
