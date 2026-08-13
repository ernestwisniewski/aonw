import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'matches WorldMap with reversed WorldMap tiles and a reserved high ground route',
    () {
      final mapData = _explorationMap();
      final worldView = _reversedWorldMap(mapData);
      final scout = _scout(id: 'explorer', col: 1, row: 1);
      final reservingScout = _reservingScout();
      final fog = _knownWesternFog();
      const planner = ScoutAutoExplorePlanner();

      final legacyUnreserved = planner.commandFor(
        unit: scout,
        mapData: mapData,
        units: [scout],
        fogOfWar: fog,
        costResolver: const TerrainTraversalCostResolver(),
      );
      final canonicalUnreserved = planner.commandFor(
        unit: scout,
        mapData: worldView,
        units: [scout],
        fogOfWar: fog,
        costResolver: const TerrainTraversalCostResolver(),
      );
      final legacyReserved = planner.commandFor(
        unit: scout,
        mapData: mapData,
        units: [reservingScout, scout],
        fogOfWar: fog,
        costResolver: const TerrainTraversalCostResolver(),
      );
      final canonicalReserved = planner.commandFor(
        unit: scout,
        mapData: worldView,
        units: [reservingScout, scout],
        fogOfWar: fog,
        costResolver: const TerrainTraversalCostResolver(),
      );

      expect(_commandSnapshot(canonicalUnreserved), 'explorer:4,0');
      expect(
        _commandSnapshot(canonicalUnreserved),
        _commandSnapshot(legacyUnreserved),
      );
      expect(_commandSnapshot(canonicalReserved), 'explorer:4,2');
      expect(
        _commandSnapshot(canonicalReserved),
        _commandSnapshot(legacyReserved),
      );
      expect(
        _reservedCoordinates(reservingScout),
        isNot(
          contains(
            HexCoordinate(
              col: canonicalReserved!.targetCol,
              row: canonicalReserved.targetRow,
            ),
          ),
        ),
      );
    },
  );
}

WorldMap _explorationMap() {
  return WorldMap(
    cols: 6,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 6; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: _terrainsAt(col, row),
            resources: const [],
            height: _heightAt(col, row),
          ),
    ],
  );
}

List<TerrainType> _terrainsAt(int col, int row) {
  if (col == 3 && row == 1) return const [TerrainType.mountain];
  if (col == 1 && row == 2) {
    return const [TerrainType.plains, TerrainType.forest];
  }
  return const [TerrainType.grassland];
}

int _heightAt(int col, int row) {
  if (col != 4) return 0;
  if (row == 0) return 4;
  return row == 2 ? 2 : 0;
}

WorldMap _reversedWorldMap(WorldMap mapData) {
  return WorldMap(
    cols: mapData.cols,
    rows: mapData.rows,
    tiles: mapData.tiles.reversed.map(
      (tile) => WorldTile.at(
        coordinate: HexCoord(col: tile.col, row: tile.row),
        terrains: tile.terrains,
        resources: tile.resources,
        height: tile.height,
      ),
    ),
  );
}

GameUnit _scout({required String id, required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    name: id,
    col: col,
    row: row,
  );
}

GameUnit _reservingScout() {
  return _scout(id: 'reserved_route', col: 2, row: 0)
      .copyWithPosture(UnitPosture.autoExploring)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 5,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 2, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 4, row: 0, enterCost: 1, cumulativeCost: 2),
            UnitMovementStep(col: 5, row: 0, enterCost: 1, cumulativeCost: 3),
          ],
        ),
      );
}

FogOfWarState _knownWesternFog() {
  final known = {
    for (var row = 0; row < 3; row++)
      for (var col = 0; col <= 2; col++) HexCoordinate(col: col, row: row),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: known,
        visibleHexes: known,
      ),
    },
  );
}

Set<HexCoordinate> _reservedCoordinates(GameUnit unit) {
  return {
    for (final step in unit.queuedPath!.steps.skip(1))
      HexCoordinate(col: step.col, row: step.row),
  };
}

String? _commandSnapshot(MoveUnitCommand? command) {
  if (command == null) return null;
  return '${command.unitId}:${command.targetCol},${command.targetRow}';
}
