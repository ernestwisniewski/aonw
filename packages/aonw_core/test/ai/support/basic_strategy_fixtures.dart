part of '../basic_strategy_test.dart';

abstract final class _TestCities {
  static const capital = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Capital',
    center: CityHex(col: 1, row: 1),
  );
}

const _testExpectations = EconomyExpectations(
  expectedCityCount: 2,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 1,
  goldReserveTarget: 8,
  minimumSciencePerTurn: 2,
);

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int col,
  required int row,
  int? hitPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    hitPoints: hitPoints,
  );
}

String _debugCommand(DomainCommand command) {
  return switch (command) {
    MoveUnitCommand(:final unitId, :final targetCol, :final targetRow) =>
      'MoveUnit($unitId,$targetCol,$targetRow)',
    FoundCityCommand(:final founderId) => 'FoundCity($founderId)',
    StartUnitProductionCommand(:final cityId, :final unitType) =>
      'StartUnit($cityId,${unitType.name})',
    StartBuildingCommand(:final cityId, :final buildingType) =>
      'StartBuilding($cityId,${buildingType.name})',
    StartCityProjectCommand(:final cityId, :final projectType) =>
      'StartProject($cityId,${projectType.name})',
    SelectTechnologyCommand(:final technologyId) =>
      'SelectTechnology(${technologyId.name})',
    _ => command.runtimeType.toString(),
  };
}

ResearchState _researchWithUnlocked(TechnologyId technologyId) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        unlockedTechnologyIds: {technologyId},
        activeTechnologyId: TechnologyId.mining,
      ),
    },
  );
}

ResearchState _researchWithActiveTarget() {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        activeTechnologyId: TechnologyId.agriculture,
      ),
    },
  );
}

AiContext _contextFor(WorldMap mapData, {int turn = 1}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: turn,
    rng: AiRng.fromTurn(turn: turn, playerId: 'player_1', baseSeed: 1001),
  );
}

WorldMap _foundingScenarioMap() {
  final tiles = <WorldTile>[];
  for (var col = 0; col < 3; col++) {
    for (var row = 0; row < 3; row++) {
      tiles.add(
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return WorldMap(cols: 3, rows: 3, tiles: tiles);
}

WorldMap _roomyExpansionMap() {
  final tiles = <WorldTile>[];
  for (var col = 0; col < 8; col++) {
    for (var row = 0; row < 8; row++) {
      tiles.add(
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return WorldMap(cols: 8, rows: 8, tiles: tiles);
}

WorldMap _hiddenRichSiteMap() {
  final richHexes = {
    const HexCoordinate(col: 5, row: 3): ResourceType.wheat,
    const HexCoordinate(col: 5, row: 2): ResourceType.deer,
    const HexCoordinate(col: 5, row: 4): ResourceType.iron,
    const HexCoordinate(col: 6, row: 3): ResourceType.gold,
  };
  final tiles = <WorldTile>[];
  for (var col = 0; col < 8; col++) {
    for (var row = 0; row < 8; row++) {
      final hex = HexCoordinate(col: col, row: row);
      final resource = richHexes[hex];
      tiles.add(
        WorldTile(
          col: col,
          row: row,
          terrains: [
            resource == ResourceType.iron
                ? TerrainType.hills
                : TerrainType.plains,
          ],
          resources: resource == null ? const [] : [resource],
          height: 0,
        ),
      );
    }
  }
  return WorldMap(cols: 8, rows: 8, tiles: tiles);
}

WorldMap _largeExpansionMap() {
  final tiles = <WorldTile>[];
  for (var col = 0; col < 10; col++) {
    for (var row = 0; row < 10; row++) {
      tiles.add(
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return WorldMap(cols: 10, rows: 10, tiles: tiles);
}

WorldMap _citySiteChoiceMap() {
  const features = <(int, int), (TerrainType, List<ResourceType>)>{
    (0, 1): (TerrainType.plains, []),
    (2, 0): (TerrainType.grassland, [ResourceType.wheat]),
    (2, 1): (TerrainType.plains, [ResourceType.wheat]),
    (2, 2): (TerrainType.plains, [ResourceType.deer]),
    (3, 1): (TerrainType.hills, [ResourceType.iron]),
  };
  final tiles = <WorldTile>[];
  for (var col = 0; col < 5; col++) {
    for (var row = 0; row < 3; row++) {
      final feature = features[(col, row)];
      tiles.add(
        WorldTile(
          col: col,
          row: row,
          terrains: [feature?.$1 ?? TerrainType.desert],
          resources: feature?.$2 ?? const [],
          height: 0,
        ),
      );
    }
  }
  return WorldMap(cols: 5, rows: 3, tiles: tiles);
}

WorldMap _combatPressureMap() {
  return WorldMap(
    cols: 5,
    rows: 1,
    tiles: [
      for (var col = 0; col < 5; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

WorldMap _pastureResourceMap() {
  return WorldMap(
    cols: 2,
    rows: 2,
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
        terrains: [TerrainType.grassland],
        resources: [ResourceType.sheep],
        height: 0,
      ),
      WorldTile(
        col: 0,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

Set<HexCoordinate> _allHexesIn(WorldMap mapData) {
  return {
    for (var col = 0; col < mapData.cols; col++)
      for (var row = 0; row < mapData.rows; row++)
        HexCoordinate(col: col, row: row),
  };
}
