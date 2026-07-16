import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Zero-copy gameplay view over the canonical [WorldMap].
///
/// Tile lookups return the immutable [WorldTile] owned by the map. The view
/// deliberately does not project or cache persistence tile DTOs.
final class WorldMapReadView implements MapReadView {
  const WorldMapReadView(this._worldMap);

  final WorldMap _worldMap;

  @override
  int get cols => _worldMap.cols;

  @override
  int get rows => _worldMap.rows;

  @override
  String? get mapName => _worldMap.mapName;

  @override
  MapTileLookup get mapTiles => this;

  @override
  Iterable<MapObjectiveDefinition> get objectives => _worldMap.objectives;

  @override
  Iterable<WorldTile> get tileViews => _worldMap.tiles;

  @override
  int get tileCount => _worldMap.indexedTileCount;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains =>
      _worldMap.tiles.map((tile) => tile.terrains);

  @override
  WorldTile? tileAt(int col, int row) =>
      _worldMap.tileAt(HexCoord(col: col, row: row));
}
