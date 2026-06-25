import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyFrontierClearingPlanner', () {
    test('attacks an assigned frontier blocker in range', () {
      final mapData = _map(cols: 4, rows: 3);
      const targetHex = HexCoordinate(col: 2, row: 1);
      final view = _view(
        mapData: mapData,
        units: [
          _unit(
            id: 'tank_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.tank,
            col: 1,
            row: 1,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: targetHex.col,
            row: targetHex.row,
          ),
        ],
      );

      final commands = const BasicStrategyFrontierClearingPlanner().plan(
        view,
        _context(view, assignments: [_assignment(unitId: 'tank_1')]),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, [const AttackHexCommand('tank_1', 2, 1)]);
    });

    test('moves an assigned unit closer to a blocker outside attack range', () {
      final mapData = _map(cols: 5, rows: 3);
      const targetHex = HexCoordinate(col: 4, row: 1);
      final view = _view(
        mapData: mapData,
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: targetHex.col,
            row: targetHex.row,
          ),
        ],
      );
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyFrontierClearingPlanner().plan(
        view,
        _context(
          view,
          assignments: [_assignment(unitId: 'warrior_1', targetHex: targetHex)],
        ),
        <String>{},
        reservedHexes,
      );

      final move = commands.whereType<MoveUnitCommand>().single;
      expect(move.unitId, 'warrior_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          targetHex,
        ),
        lessThan(
          HexDistance.between(const HexCoordinate(col: 0, row: 1), targetHex),
        ),
      );
      expect(reservedHexes, isEmpty);
    });
  });
}

StrategicFrontierClearingAssignment _assignment({
  required String unitId,
  HexCoordinate targetHex = const HexCoordinate(col: 2, row: 1),
}) {
  return StrategicFrontierClearingAssignment(
    unitId: unitId,
    founderId: 'settler_1',
    targetPlayerId: 'player_2',
    targetHex: targetHex,
    founderDistance: 2,
    priority: 4,
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int col,
  required int row,
}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    col: col,
    row: row,
  );
}

GameView _view({required MapData mapData, required List<GameUnit> units}) {
  return GameView.fromPersistentState(
    PersistentGameState(
      units: units,
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 2,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context(
  GameView view, {
  required List<StrategicFrontierClearingAssignment> assignments,
}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
    strategicPlan: StrategicPlan(
      computedAtTurn: view.turn,
      mode: StrategicMode.expand,
      expectations: const EconomyExpectations(
        expectedCityCount: 3,
        expectedWorkerCount: 2,
        expectedMilitaryCount: 2,
        goldReserveTarget: 10,
        minimumSciencePerTurn: 3,
      ),
      frontierClearingAssignments: {
        for (final assignment in assignments) assignment.unitId: assignment,
      },
    ),
  );
}

MapData _map({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

Set<HexCoordinate> _allHexesIn(MapData mapData) {
  return {
    for (var col = 0; col < mapData.cols; col++)
      for (var row = 0; row < mapData.rows; row++)
        HexCoordinate(col: col, row: row),
  };
}
