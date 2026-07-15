import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Temporary boundary from pre-WorldMap map models to the canonical model.
///
/// Removal condition: production has no [fromMapData], [toMapData], or bounded
/// [TileData] projection calls, and gameplay, AI, renderer, server,
/// save/replay, fixtures, and editor persistence use canonical models or
/// canonical read views. Add conversions here instead of creating another
/// point-to-point map adapter.
abstract final class LegacyWorldMapAdapter {
  static WorldMap fromMapData(MapData mapData) {
    return WorldMap(
      cols: mapData.cols,
      rows: mapData.rows,
      tiles: mapData.tiles.map(_worldTileFromData),
      objectives: mapData.objectives,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
    );
  }

  static MapData toMapData(WorldMap worldMap) {
    return MapData(
      cols: worldMap.cols,
      rows: worldMap.rows,
      tiles: worldMap.tiles.map(_tileDataFromWorld).toList(),
      objectives: worldMap.objectives,
      mapName: worldMap.mapName,
      defaultZoom: worldMap.defaultZoom,
    );
  }

  /// Exposes bounded legacy tile projections without materializing a full
  /// [MapData] graph.
  static MapTileLookup asTileLookup(WorldMap worldMap) {
    return _WorldMapReadView(worldMap);
  }

  /// Exposes bounded tile reads and aggregate metadata without materializing
  /// a full [MapData] graph.
  static MapReadView asReadView(WorldMap worldMap) {
    return _WorldMapReadView(worldMap);
  }

  /// Exposes map bounds and request-scoped, cached tile projections for
  /// traversal algorithms without materializing every legacy tile.
  static MapTraversalView asTraversalView(WorldMap worldMap) {
    return _WorldMapTraversalView(worldMap);
  }

  /// Projects a canonical tile to the legacy tile shape expected by older
  /// gameplay services.
  ///
  /// Keeping this lookup here prevents individual migration slices from
  /// recreating lossy WorldMap-to-MapData conversions just to inspect one
  /// coordinate.
  static TileData? tileDataAt(WorldMap? worldMap, int col, int row) {
    final tile = worldMap?.tileAt(HexCoord(col: col, row: row));
    return tile == null ? null : _tileDataFromWorld(tile);
  }

  static WorldTile _worldTileFromData(TileData tile) {
    return WorldTile(
      coordinate: HexCoord(col: tile.col, row: tile.row),
      terrains: tile.terrains,
      resources: tile.resources,
      height: tile.height,
    );
  }

  static TileData _tileDataFromWorld(WorldTile tile) {
    return TileData(
      col: tile.coordinate.col,
      row: tile.coordinate.row,
      terrains: List.of(tile.terrains),
      resources: List.of(tile.resources),
      height: tile.height,
    );
  }
}

final class _WorldMapReadView implements MapReadView, MapTileLookup {
  const _WorldMapReadView(this._worldMap);

  final WorldMap _worldMap;

  @override
  String? get mapName => _worldMap.mapName;

  @override
  MapTileLookup get mapTiles => this;

  @override
  int get tileCount => _worldMap.indexedTileCount;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains =>
      _worldMap.tiles.map((tile) => tile.terrains);

  @override
  TileData? tileAt(int col, int row) {
    return LegacyWorldMapAdapter.tileDataAt(_worldMap, col, row);
  }
}

final class _WorldMapTraversalView implements MapTraversalView {
  _WorldMapTraversalView(this._worldMap);

  final WorldMap _worldMap;
  final Map<HexCoord, TileData> _projectedTiles = {};
  final Set<HexCoord> _missingTiles = {};

  @override
  int get cols => _worldMap.cols;

  @override
  int get rows => _worldMap.rows;

  @override
  TileData? tileAt(int col, int row) {
    final coordinate = HexCoord(col: col, row: row);
    final cached = _projectedTiles[coordinate];
    if (cached != null) return cached;
    if (_missingTiles.contains(coordinate)) return null;

    final tile = _worldMap.tileAt(coordinate);
    if (tile == null) {
      _missingTiles.add(coordinate);
      return null;
    }
    return _projectedTiles[coordinate] =
        LegacyWorldMapAdapter._tileDataFromWorld(tile);
  }
}
