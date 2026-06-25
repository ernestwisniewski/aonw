import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ScoutAutoExplorePlanner', () {
    test('chooses a legal move that reveals undiscovered hexes', () {
      final map = _grassMap(cols: 6, rows: 1);
      final scout = _scout(col: 1, row: 0);
      final fog = _fog(
        discovered: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
        },
        visible: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
        },
      );

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: scout,
        mapData: map,
        units: [scout],
        fogOfWar: fog,
      );

      expect(command, isNotNull);
      expect(command!.unitId, scout.id);
      expect(command.targetCol, greaterThan(scout.col));
      expect(command.targetRow, scout.row);
    });

    test('plans a route to distant fog beyond current movement', () {
      final map = _grassMap(cols: 8, rows: 1);
      final scout = _scout(col: 1, row: 0).copyWith(movementPoints: 1);
      final fog = _fog(
        discovered: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
          const HexCoordinate(col: 3, row: 0),
        },
        visible: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
          const HexCoordinate(col: 3, row: 0),
        },
      );

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: scout,
        mapData: map,
        units: [scout],
        fogOfWar: fog,
      );
      expect(command, isNotNull);
      final plan = UnitMovementPathfinder(mapData: map, units: [scout]).plan(
        unit: scout,
        targetTile: map.tileAt(command!.targetCol, command.targetRow)!,
      );

      expect(command.unitId, scout.id);
      expect(command.targetCol, greaterThan(scout.col + scout.movementPoints));
      expect(command.targetRow, scout.row);
      expect(plan, isNotNull);
      expect(plan!.canMoveNow, isFalse);
    });

    test('avoids another auto-exploring scout queued route', () {
      final map = _grassMap(cols: 8, rows: 2);
      final reservedPath = QueuedMovePath(
        targetCol: 7,
        targetRow: 0,
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 2),
          UnitMovementStep(col: 4, row: 0, enterCost: 1, cumulativeCost: 3),
          UnitMovementStep(col: 5, row: 0, enterCost: 1, cumulativeCost: 4),
          UnitMovementStep(col: 6, row: 0, enterCost: 1, cumulativeCost: 5),
          UnitMovementStep(col: 7, row: 0, enterCost: 1, cumulativeCost: 6),
        ],
      );
      final firstScout = _scout(id: 'scout_1', col: 2, row: 0)
          .copyWithPosture(UnitPosture.autoExploring)
          .copyWithQueuedPath(reservedPath);
      final secondScout = _scout(id: 'scout_2', col: 1, row: 1);
      final fog = _fog(
        discovered: {
          for (var col = 0; col <= 3; col++)
            for (var row = 0; row <= 1; row++)
              HexCoordinate(col: col, row: row),
        },
        visible: {
          for (var col = 0; col <= 3; col++)
            for (var row = 0; row <= 1; row++)
              HexCoordinate(col: col, row: row),
        },
      );

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: secondScout,
        mapData: map,
        units: [firstScout, secondScout],
        fogOfWar: fog,
      );
      final reservedHexes = {
        for (final step in reservedPath.steps.skip(2))
          HexCoordinate(col: step.col, row: step.row),
        const HexCoordinate(col: 7, row: 0),
      };

      expect(command, isNotNull);
      expect(
        reservedHexes,
        isNot(
          contains(
            HexCoordinate(col: command!.targetCol, row: command.targetRow),
          ),
        ),
      );
    });

    test('does not move non-scout units', () {
      final map = _grassMap(cols: 4, rows: 1);
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
      );

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: warrior,
        mapData: map,
        units: [warrior],
        fogOfWar: _fog(),
      );

      expect(command, isNull);
    });

    test('does not move exhausted scouts', () {
      final map = _grassMap(cols: 4, rows: 1);
      final scout = _scout(col: 1, row: 0).copyWith(movementPoints: 0);

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: scout,
        mapData: map,
        units: [scout],
        fogOfWar: _fog(),
      );

      expect(command, isNull);
    });

    test('does not issue a movement command through blocked tiles', () {
      final map = MapData(
        cols: 3,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.mountain],
            resources: [],
            height: 3,
          ),
          TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [],
            height: 0,
          ),
          TileData(
            col: 2,
            row: 0,
            terrains: [TerrainType.mountain],
            resources: [],
            height: 3,
          ),
        ],
      );
      final scout = _scout(col: 1, row: 0);
      final fog = _fog(
        discovered: {const HexCoordinate(col: 1, row: 0)},
        visible: {const HexCoordinate(col: 1, row: 0)},
      );

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: scout,
        mapData: map,
        units: [scout],
        fogOfWar: fog,
      );

      expect(command, isNull);
    });

    test('returns null when no movement reveals new territory', () {
      final map = _grassMap(cols: 4, rows: 1);
      final scout = _scout(col: 1, row: 0);
      final fullyKnown = {
        for (final tile in map.tiles) HexCoordinate.fromTile(tile),
      };

      final command = const ScoutAutoExplorePlanner().commandFor(
        unit: scout,
        mapData: map,
        units: [scout],
        fogOfWar: _fog(discovered: fullyKnown, visible: fullyKnown),
      );

      expect(command, isNull);
    });
  });
}

MapData _grassMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

GameUnit _scout({String id = 'scout_1', required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    name: GameUnitType.scout.defaultNameToken,
    col: col,
    row: row,
  );
}

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}
