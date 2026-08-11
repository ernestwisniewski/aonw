import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

WorldMap kbMinimalMap() => WorldMap(
  cols: 2,
  rows: 2,
  tiles: [
    for (int r = 0; r < 2; r++)
      for (int c = 0; c < 2; c++)
        WorldTile(
          col: c,
          row: r,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldMap kbMap(int cols, int rows) => WorldMap(
  cols: cols,
  rows: rows,
  tiles: [
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        WorldTile(
          col: c,
          row: r,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldMap kbObjectiveMap() => WorldMap(
  cols: 3,
  rows: 3,
  objectives: const [
    MapObjectiveDefinition(
      id: 'pass_1',
      type: MapObjectiveType.strategicPass,
      hex: HexCoord(col: 1, row: 1),
      requiredHoldTurns: 2,
    ),
  ],
  tiles: [
    for (int r = 0; r < 3; r++)
      for (int c = 0; c < 3; c++)
        WorldTile(
          col: c,
          row: r,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldTile kbTile(WorldMap map, int col, int row) =>
    map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);
