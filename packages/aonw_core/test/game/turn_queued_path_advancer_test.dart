import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_queued_path_advancer.dart';
import 'package:test/test.dart';

void main() {
  group('TurnQueuedPathAdvancer', () {
    test('exhausts movement on the first costly boundary step', () {
      final unit = _queuedWarrior(
        targetCol: 3,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
          UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 4),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 5),
        ],
      );

      final result = _advance(unit, _roughLineMap());

      expect((result.unit.col, result.unit.movementPoints), (2, 0));
      expect(result.unit.queuedPath?.targetCol, 3);
      expect(result.execution?.steps.map((step) => step.col), [1, 2]);
    });

    test('clears an infeasible queued route without partial movement', () {
      final unit = _queuedWarrior(
        targetCol: 2,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 4, cumulativeCost: 5),
        ],
      );

      final result = _advance(unit, _overCapacityLineMap());

      expect((result.unit.col, result.unit.row), (0, 0));
      expect(result.unit.movementPoints, 3);
      expect(result.unit.queuedPath, isNull);
      expect(result.execution, isNull);
    });

    test('replans an infeasible shortcut onto a feasible detour', () {
      final unit = _queuedWarrior(
        targetCol: 2,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 4, cumulativeCost: 4),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 5),
        ],
      );

      final result = _advance(unit, _capacityDetourMap());

      expect(
        (result.unit.col, result.unit.row, result.unit.movementPoints),
        (1, 2, 0),
      );
      expect(
        (result.unit.queuedPath?.targetCol, result.unit.queuedPath?.targetRow),
        (2, 0),
      );
      expect(result.execution?.steps.map((step) => step.coord), const [
        (col: 0, row: 1),
        (col: 0, row: 2),
        (col: 1, row: 2),
      ]);
    });

    test('keeps the queue when a hidden unit blocks the boundary step', () {
      final unit = _queuedWarrior(
        targetCol: 3,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
          UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 4),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 5),
        ],
      );
      final blocker = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 2,
      );
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
              const HexCoordinate(col: 3, row: 0),
            },
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      );

      final result = _advance(
        unit,
        _roughLineMap(),
        additionalUnits: [blocker],
        fogOfWar: fog,
      );

      expect(result.unit, same(unit));
      expect(result.unit.queuedPath, isNotNull);
      expect(result.execution, isNull);
    });
  });
}

TurnQueuedPathAdvance _advance(
  GameUnit unit,
  WorldMap map, {
  List<GameUnit> additionalUnits = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
}) {
  return TurnQueuedPathAdvancer.advance(
    unit: unit,
    mapData: map,
    allUnits: [unit, ...additionalUnits],
    cities: const [],
    diplomacy: DiplomacyState.empty,
    fogOfWar: fogOfWar,
  );
}

GameUnit _queuedWarrior({
  required int targetCol,
  required List<UnitMovementStep> steps,
}) {
  return GameUnit.startingWarrior(ownerPlayerId: 'player_1').copyWithQueuedPath(
    QueuedMovePath(targetCol: targetCol, targetRow: 0, steps: steps),
  );
}

WorldMap _roughLineMap() {
  return _lineMap(
    cols: 4,
    terrainOverrides: const {
      1: [TerrainType.plains, TerrainType.forest],
      2: [TerrainType.plains, TerrainType.forest],
    },
  );
}

WorldMap _overCapacityLineMap() {
  return _lineMap(
    cols: 3,
    terrainOverrides: const {
      2: [
        TerrainType.grassland,
        TerrainType.forest,
        TerrainType.jungle,
        TerrainType.hills,
      ],
    },
  );
}

WorldMap _capacityDetourMap() {
  const passable = <({int col, int row}), List<TerrainType>>{
    (col: 0, row: 0): [TerrainType.grassland],
    (col: 1, row: 0): [
      TerrainType.grassland,
      TerrainType.forest,
      TerrainType.jungle,
      TerrainType.hills,
    ],
    (col: 2, row: 0): [TerrainType.grassland],
    (col: 0, row: 1): [TerrainType.grassland],
    (col: 0, row: 2): [TerrainType.grassland],
    (col: 1, row: 2): [TerrainType.grassland],
    (col: 2, row: 2): [TerrainType.grassland],
    (col: 2, row: 1): [TerrainType.grassland],
  };
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains:
                passable[(col: col, row: row)] ??
                const [TerrainType.grassland, TerrainType.mountain],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

WorldMap _lineMap({
  required int cols,
  required Map<int, List<TerrainType>> terrainOverrides,
}) {
  return WorldMap(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: terrainOverrides[col] ?? const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
