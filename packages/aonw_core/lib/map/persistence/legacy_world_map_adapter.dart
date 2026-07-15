import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_data.dart';

/// Temporary boundary from pre-WorldMap map models to the canonical model.
///
/// Removal condition: production has no [fromMapData] or [toMapData] calls,
/// and gameplay, AI, renderer, server, save/replay, fixtures, and editor
/// persistence use canonical models. Add full-model conversions here instead
/// of creating another point-to-point map adapter.
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
