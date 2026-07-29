part of 'local_command_transport_test.dart';

MapData _map({int cols = 3, int rows = 3}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _damagedCity = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City 1',
  center: CityHex(col: 0, row: 0),
  hitPoints: 10,
);
