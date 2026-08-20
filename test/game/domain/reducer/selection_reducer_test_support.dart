part of 'selection_reducer_test.dart';

WorldTile _tile(int col, int row) => WorldTile(
  col: col,
  row: row,
  terrains: const [TerrainType.grassland],
  resources: const [],
  height: 0,
);

WorldMap _mapWith(List<WorldTile> tiles) =>
    WorldMap(cols: 10, rows: 10, tiles: tiles);

GameUnit _unit({
  String id = 'u1',
  String ownerPlayerId = 'p1',
  GameUnitType type = GameUnitType.commander,
  int col = 0,
  int row = 0,
}) => GameUnit(
  id: id,
  ownerPlayerId: ownerPlayerId,
  type: type,
  name: type.defaultNameToken,
  col: col,
  row: row,
);

GameCity _city({
  String id = 'c1',
  String ownerPlayerId = 'p1',
  int col = 2,
  int row = 2,
}) => GameCity(
  id: id,
  ownerPlayerId: ownerPlayerId,
  name: 'City',
  center: CityHex(col: col, row: row),
);

FieldImprovement _improvement({
  int col = 3,
  int row = 3,
  FieldImprovementType type = FieldImprovementType.farm,
}) => FieldImprovement(
  hex: CityHex(col: col, row: row),
  type: type,
);

/// Creates fog where all listed tiles are visible for the player.
FogOfWarState _fogVisible(String playerId, List<WorldTile> tiles) {
  final hexes = {
    for (final tile in tiles) HexCoordinate(col: tile.col, row: tile.row),
  };
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: hexes),
    },
  );
}

/// Creates fog where all tiles are hidden for the player.
FogOfWarState _fogHidden(String playerId) {
  return FogOfWarState(players: {playerId: PlayerFogOfWar(playerId: playerId)});
}
