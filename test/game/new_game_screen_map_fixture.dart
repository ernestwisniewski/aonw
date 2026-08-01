part of 'new_game_screen_test.dart';

WorldMap _map() => WorldMap(
  cols: 20,
  rows: 20,
  mapName: 'verdantia',
  tiles: [
    for (var row = 0; row < 20; row++)
      for (var col = 0; col < 20; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: [TerrainType.grassland],
          resources: const [
            ResourceType.wheat,
            ResourceType.iron,
            ResourceType.gold,
          ],
          height: 0,
        ),
  ],
);
