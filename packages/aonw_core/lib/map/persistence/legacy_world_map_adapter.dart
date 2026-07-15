import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_data.dart';

/// Temporary boundary from pre-WorldMap map models to the canonical model.
///
/// Removal condition: gameplay, AI, renderer, server, and editor persistence
/// no longer expose [MapData]. Add conversions here instead of creating another
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
    return _WorldMapTileLookup(worldMap);
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

final class _WorldMapTileLookup implements MapTileLookup {
  const _WorldMapTileLookup(this._worldMap);

  final WorldMap _worldMap;

  @override
  TileData? tileAt(int col, int row) {
    return LegacyWorldMapAdapter.tileDataAt(_worldMap, col, row);
  }
}
