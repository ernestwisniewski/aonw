import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyWarGoalWakeUpPlanner', () {
    test('wakes fortified military assigned to offensive war goals only', () {
      final mapData = _map();
      final fortified = GameUnit.produced(
        id: 'fortified_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWithPosture(UnitPosture.fortified);
      final active = GameUnit.produced(
        id: 'active_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final defended = GameUnit.produced(
        id: 'defended_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 0,
      ).copyWithPosture(UnitPosture.fortified);
      final view = _view(
        mapData: mapData,
        units: [fortified, active, defended],
      );

      final commands = const BasicStrategyWarGoalWakeUpPlanner().plan(
        view,
        StrategicPlan(
          computedAtTurn: view.turn,
          mode: StrategicMode.military,
          expectations: _expectations,
          warGoals: [
            WarGoal(
              targetPlayerId: 'player_2',
              kind: WarGoalKind.captureCity,
              targetHex: const HexCoordinate(col: 3, row: 0),
              turnsBudget: 4,
              assignedUnitIds: const ['active_1', 'fortified_1'],
              priority: 5,
            ),
            WarGoal(
              targetPlayerId: 'player_2',
              kind: WarGoalKind.defend,
              targetHex: const HexCoordinate(col: 0, row: 0),
              turnsBudget: 4,
              assignedUnitIds: const ['defended_1'],
              priority: 10,
            ),
          ],
        ),
      );

      expect(commands, [const CancelUnitActionCommand('fortified_1')]);
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

GameView _view({required MapData mapData, required List<GameUnit> units}) {
  return GameView.fromPersistentState(
    PersistentGameState(units: units),
    forPlayerId: 'player_1',
    turn: 2,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
