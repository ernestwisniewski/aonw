part of '../game_renderer_keyboard_test.dart';

WorldMap _minimalMap() => WorldMap(
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

WorldMap _map(int cols, int rows) => WorldMap(
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

WorldMap _mapWithObjective() => WorldMap(
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

WorldTile _tile(WorldMap map, int col, int row) =>
    map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);
