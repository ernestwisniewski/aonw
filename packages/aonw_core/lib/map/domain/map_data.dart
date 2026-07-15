import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/domain/world_map_invariants.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

export 'package:aonw_core/map/domain/map_read_view.dart';

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
  @override
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

  /// Builds a request-scoped read view with constant-time coordinate lookup.
  ///
  /// The view snapshots tile membership and metadata, but borrows the existing
  /// [TileData] values. Building it is therefore linear in the tile count
  /// without converting the map to another tile representation.
  MapReadView indexedReadView() => _IndexedMapDataReadView(this);

  /// Returns the tile at [col], [row], or null if not found.
  @override
  TileData? tileAt(int col, int row) {
    for (final tile in tiles) {
      if (tile.col == col && tile.row == row) return tile;
    }
    return null;
  }
}

final class _IndexedMapDataReadView implements MapReadView {
  _IndexedMapDataReadView(MapData source)
    : cols = source.cols,
      rows = source.rows,
      mapName = source.mapName,
      objectives = source.objectives,
      _tiles = List.unmodifiable(source.tiles) {
    _tilesByCoordinate = buildValidatedWorldMapIndex(
      cols: cols,
      rows: rows,
      defaultZoom: source.defaultZoom,
      tiles: _tiles,
      objectives: objectives,
      reject: _rejectWorldMapInvariant,
    );
  }

  @override
  final int cols;

  @override
  final int rows;

  @override
  final String? mapName;

  @override
  final List<MapObjectiveDefinition> objectives;

  final List<TileData> _tiles;
  late final Map<HexCoord, TileData> _tilesByCoordinate;

  @override
  MapTileLookup get mapTiles => this;

  @override
  int get tileCount => _tiles.length;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains =>
      _tiles.map((tile) => tile.terrains);

  @override
  Iterable<MapTileView> get tileViews => _tiles;

  @override
  TileData? tileAt(int col, int row) =>
      _tilesByCoordinate[HexCoord(col: col, row: row)];
}

Never _rejectWorldMapInvariant(String message) {
  throw WorldMapException(message);
}
