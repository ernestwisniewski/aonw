import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/map/domain/map_survey.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Read-only lookup for legacy tile data at a single coordinate.
///
/// Returned [TileData] can be a borrowed legacy value. Consumers must treat it
/// as read-only even when its collections are structurally mutable.
abstract interface class MapTileLookup {
  TileData? tileAt(int col, int row);
}

/// Read-only dimensions and bounded tile reads for spatial algorithms.
///
/// Unlike [MapTileSource], this contract intentionally does not expose every
/// tile. Traversal code can therefore operate on canonical maps without first
/// materializing a complete legacy [MapData] graph.
abstract interface class MapTraversalView implements MapTileLookup {
  int get cols;
  int get rows;
}

/// Composite read-only view for gameplay rules that need bounded reads,
/// traversal, aggregate metadata, objectives, or a zero-copy tile catalog.
///
/// This access contract does not make legacy [TileData] deeply immutable.
abstract interface class MapReadView
    implements MapSurvey, MapTraversalView, MapTileCatalog {
  MapTileLookup get mapTiles;

  Iterable<MapObjectiveDefinition> get objectives;
}

/// Read-only spatial data consumed by map renderers.
///
/// [MapData] remains the legacy persistence model. Editor-only mutable state
/// can implement this narrow contract without becoming a second persistence
/// representation.
abstract interface class MapTileSource implements MapTraversalView {
  Iterable<TileData> get tiles;

  @override
  TileData? tileAt(int col, int row);
}

/// Data for a single hex tile.
class TileData implements MapTileView {
  @override
  final int col;

  @override
  final int row;

  @override
  final List<TerrainType> terrains;

  @override
  final List<ResourceType> resources;

  /// Integer height 0–5; drives depth effect scaling at render sites.
  @override
  final int height;

  const TileData({
    required this.col,
    required this.row,
    required this.terrains,
    required this.resources,
    required this.height,
  });

  /// Primary terrain: first in list, or ocean if empty.
  TerrainType get primaryTerrain =>
      terrains.isNotEmpty ? terrains.first : TerrainType.ocean;

  /// Returns a copy with the given fields replaced.
  TileData copyWith({
    List<TerrainType>? terrains,
    List<ResourceType>? resources,
    int? height,
  }) => TileData(
    col: col,
    row: row,
    terrains: terrains ?? List.of(this.terrains),
    resources: resources ?? List.of(this.resources),
    height: height ?? this.height,
  );

  Map<String, dynamic> toJson() => {
    'col': col,
    'row': row,
    'terrains': terrains.map((t) => t.name).toList(),
    'resources': resources.map((r) => r.name).toList(),
    'height': height,
  };
}

/// Legacy persistence and compatibility DTO.
///
/// It remains structurally mutable for legacy consumers; editor mutation is
/// owned by the editor's draft model. Its [MapReadView] implementation is a
/// zero-copy borrowed view: [mapTiles] and [tileTerrains] can expose aliases,
/// which read-view consumers must not mutate.
class MapData implements MapTileSource, MapReadView {
  @override
  int cols;

  @override
  int rows;

  @override
  final List<TileData> tiles;
  List<MapObjectiveDefinition> _objectives;

  /// Filename stem (no extension) — e.g. "map23" links to "map23.json" + "map23.png".
  @override
  String? mapName;

  /// Default zoom level restored on long-tap in the editor and game.
  double defaultZoom;

  MapData({
    required this.cols,
    required this.rows,
    required this.tiles,
    Iterable<MapObjectiveDefinition> objectives = const [],
    this.mapName,
    this.defaultZoom = 1.0,
  }) : _objectives = List.unmodifiable(objectives);

  @override
  List<MapObjectiveDefinition> get objectives => _objectives;

  @override
  MapTileLookup get mapTiles => this;

  @override
  Iterable<MapTileView> get tileViews => tiles;

  @override
  int get tileCount => tiles.length;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains =>
      tiles.map((tile) => tile.terrains);

  set objectives(Iterable<MapObjectiveDefinition> value) {
    _objectives = List.unmodifiable(value);
  }

  /// Returns the tile at [col], [row], or null if not found.
  @override
  TileData? tileAt(int col, int row) {
    for (final tile in tiles) {
      if (tile.col == col && tile.row == row) return tile;
    }
    return null;
  }
}
