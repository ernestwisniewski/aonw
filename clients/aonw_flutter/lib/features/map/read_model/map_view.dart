typedef MapHexCoordinate = ({int col, int row});

enum MapGridLayout { oddQFlatTop }

enum MapTerrain {
  ocean,
  coast,
  lake,
  plains,
  grassland,
  desert,
  tundra,
  snow,
  mountain,
  hills,
  wetlands,
  jungle,
  forest,
  river,
}

final class MapTileView {
  MapTileView({
    required this.coordinate,
    required this.displayTerrain,
    required this.yieldTerrain,
    required List<MapTerrain> movementTerrains,
    required List<MapTerrain> terrainTags,
    required List<String> resources,
    required this.height,
  }) : movementTerrains = List.unmodifiable(movementTerrains),
       terrainTags = List.unmodifiable(terrainTags),
       resources = List.unmodifiable(resources);

  final MapHexCoordinate coordinate;
  final MapTerrain displayTerrain;
  final MapTerrain yieldTerrain;
  final List<MapTerrain> movementTerrains;
  final List<MapTerrain> terrainTags;
  final List<String> resources;
  final int height;
}

final class MapObjectiveView {
  const MapObjectiveView({
    required this.id,
    required this.type,
    required this.coordinate,
    required this.requiredHoldTurns,
    required this.victoryPoints,
    required this.goldPerTurn,
  });

  final String id;
  final String type;
  final MapHexCoordinate coordinate;
  final int requiredHoldTurns;
  final int victoryPoints;
  final int goldPerTurn;
}

final class MapView {
  MapView({
    required this.mapId,
    required this.contentHash,
    required this.gridLayout,
    required this.cols,
    required this.rows,
    required this.defaultZoom,
    required List<MapTileView> tiles,
    required List<MapObjectiveView> objectives,
  }) : tiles = List.unmodifiable(tiles),
       objectives = List.unmodifiable(objectives) {
    _tilesByCoordinate = Map.unmodifiable({
      for (final tile in this.tiles) tile.coordinate: tile,
    });
  }

  final String mapId;
  final String contentHash;
  final MapGridLayout gridLayout;
  final int cols;
  final int rows;
  final double defaultZoom;
  final List<MapTileView> tiles;
  final List<MapObjectiveView> objectives;
  late final Map<MapHexCoordinate, MapTileView> _tilesByCoordinate;

  MapTileView? tileAt(MapHexCoordinate coordinate) =>
      _tilesByCoordinate[coordinate];

  bool contains(MapHexCoordinate coordinate) =>
      coordinate.col >= 0 &&
      coordinate.col < cols &&
      coordinate.row >= 0 &&
      coordinate.row < rows;
}
