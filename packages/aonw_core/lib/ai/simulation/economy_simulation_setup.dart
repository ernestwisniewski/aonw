part of 'economy_simulation.dart';

abstract final class _EconomySimulationSetup {
  static PersistentGameState initialState({
    required Player player,
    required List<Player> opponents,
    required MapData mapData,
  }) {
    final players = [player, ...opponents];
    final units = StartingUnits.unitsForPlayers(players, mapData: mapData);
    final state = PersistentGameState(
      playerColors: {
        for (final simulationPlayer in players)
          simulationPlayer.id: simulationPlayer.colorValue,
      },
      playerGold: {
        for (final simulationPlayer in players) simulationPlayer.id: 0,
      },
      units: units,
    );
    final fogOfWar = const FogOfWarService().recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: [for (final simulationPlayer in players) simulationPlayer.id],
      units: state.units,
      cities: state.cities,
    );
    return state.copyWith(fogOfWar: fogOfWar);
  }

  static MapData simulationMap() {
    const size = 9;
    return MapData(
      cols: size,
      rows: size,
      mapName: 'economy_simulation',
      tiles: [
        for (var row = 0; row < size; row++)
          for (var col = 0; col < size; col++) _tile(col, row),
      ],
    );
  }

  static MapData mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static MapDefinition mapDefinitionFrom(MapData mapData) {
    return MapDefinition(
      cols: mapData.cols,
      rows: mapData.rows,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
      tiles: [
        for (final tile in mapData.tiles)
          MapTileDefinition(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static TileData _tile(int col, int row) {
    final resource = switch ((col, row)) {
      (3, 2) || (7, 7) => ResourceType.wheat,
      (2, 4) || (8, 6) => ResourceType.iron,
      (4, 3) => ResourceType.deer,
      _ => null,
    };
    final terrain = switch ((col + row) % 7) {
      0 => TerrainType.hills,
      1 => TerrainType.forest,
      2 => TerrainType.grassland,
      _ => TerrainType.plains,
    };
    return TileData(
      col: col,
      row: row,
      terrains: [terrain],
      resources: [?resource],
      height: terrain == TerrainType.hills ? 1 : 0,
    );
  }
}
