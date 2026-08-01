part of 'mcts_simulator_parity_test.dart';

WorldMap _highCostMapData() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 0,
        terrains: [TerrainType.snow, TerrainType.forest, TerrainType.tundra],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}
