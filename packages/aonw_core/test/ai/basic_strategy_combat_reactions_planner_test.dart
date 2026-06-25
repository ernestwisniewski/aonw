import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyCombatReactionsPlanner', () {
    test('prioritizes an assigned offensive war goal target', () {
      final mapData = _map(cols: 4, rows: 4);
      final view = _view(
        mapData: mapData,
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
          _unit(
            id: 'generic_enemy',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 2,
            row: 1,
            hitPoints: 1,
          ),
          _unit(
            id: 'goal_enemy',
            ownerPlayerId: 'player_3',
            type: GameUnitType.warrior,
            col: 1,
            row: 2,
            hitPoints: 1,
          ),
        ],
      );

      final commands = const BasicStrategyCombatReactionsPlanner().plan(
        view,
        _context(
          view,
          strategicPlan: StrategicPlan(
            computedAtTurn: view.turn,
            mode: StrategicMode.military,
            expectations: _expectations,
            warGoals: [
              WarGoal(
                targetPlayerId: 'player_3',
                kind: WarGoalKind.eliminateUnits,
                targetHex: const HexCoordinate(col: 1, row: 2),
                turnsBudget: 4,
                assignedUnitIds: const ['warrior_1'],
                priority: 5,
              ),
            ],
          ),
        ),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, [const AttackHexCommand('warrior_1', 1, 2)]);
    });

    test('retreats low-health military before considering attacks', () {
      final mapData = _map(cols: 5, rows: 5);
      final view = _view(
        mapData: mapData,
        units: [
          _unit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
            hitPoints: 3,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 2,
            row: 1,
          ),
        ],
      );

      final commands = const BasicStrategyCombatReactionsPlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands.whereType<AttackHexCommand>(), isEmpty);
      final retreat = commands.whereType<MoveUnitCommand>().single;
      expect(retreat.unitId, 'warrior_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: retreat.targetCol, row: retreat.targetRow),
          const HexCoordinate(col: 2, row: 1),
        ),
        greaterThan(1),
      );
    });
  });
}

const _expectations = EconomyExpectations(
  expectedCityCount: 1,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 1,
  goldReserveTarget: 10,
  minimumSciencePerTurn: 3,
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

AiContext _context(GameView view, {StrategicPlan? strategicPlan}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
    strategicPlan: strategicPlan,
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
