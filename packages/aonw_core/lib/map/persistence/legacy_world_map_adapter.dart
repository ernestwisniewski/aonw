import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_data.dart';

/// Temporary boundary from pre-WorldMap map models to the canonical model.
///
/// Removal condition: gameplay, AI, renderer, server, and editor persistence
/// no longer expose [MapData] or [MapDefinition]. Add conversions here instead
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

  /// Imports the spatial subset represented by [MapDefinition].
  ///
  /// This legacy type has no objectives, so callers that own full map data
  /// must use [fromMapData] instead.
  static WorldMap fromMapDefinition(MapDefinition definition) {
    return WorldMap(
      cols: definition.cols,
      rows: definition.rows,
      tiles: definition.tiles.map(_worldTileFromDefinition),
      mapName: definition.mapName,
      defaultZoom: definition.defaultZoom,
    );
  }

  /// Projects the spatial subset represented by [MapDefinition] to [MapData].
  ///
  /// Keep this direct rather than routing high-frequency legacy simulation
  /// paths through [WorldMap]. [MapDefinition] has no objectives, so the
  /// returned [MapData] intentionally has none.
  static MapData mapDataFromDefinition(MapDefinition definition) {
    return MapData(
      cols: definition.cols,
      rows: definition.rows,
      tiles: definition.tiles.map(_tileDataFromDefinition).toList(),
      mapName: definition.mapName,
      defaultZoom: definition.defaultZoom,
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

  static WorldTile _worldTileFromDefinition(MapTileDefinition tile) {
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

  static TileData _tileDataFromDefinition(MapTileDefinition tile) {
    return TileData(
      col: tile.col,
      row: tile.row,
      terrains: List.of(tile.terrains),
      resources: List.of(tile.resources),
      height: tile.height,
    );
  }
}
