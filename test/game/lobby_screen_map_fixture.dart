part of 'lobby_screen_test.dart';

WorldMap _map({
  int cols = 8,
  int rows = 8,
  TerrainType terrain = TerrainType.grassland,
  List<ResourceType> resources = const [
    ResourceType.wheat,
    ResourceType.iron,
    ResourceType.gold,
  ],
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: [terrain],
            resources: resources,
            height: 0,
          ),
    ],
  );
}
