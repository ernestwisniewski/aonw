import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_frontier_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware frontier ranker', () {
    test('rewards assigned clearing moves toward the target blocker', () {
      final ranking = rankFrontierClearingCommand(
        const MoveUnitCommand('warrior_clearer', 2, 0),
        _view(units: [_unit('warrior_clearer', col: 1)]),
        _context(),
        _plan(
          frontierClearingAssignments: const {
            'warrior_clearer': StrategicFrontierClearingAssignment(
              unitId: 'warrior_clearer',
              founderId: 'settler_1',
              targetPlayerId: 'enemy',
              targetHex: HexCoordinate(col: 3, row: 0),
              founderDistance: 1,
              priority: 4,
            ),
          },
        ),
      );

      expect(ranking?.priority, CandidatePriority.opening);
      expect(ranking?.score, 1261);
    });

    test('ignores moves for units without a frontier clearing assignment', () {
      final ranking = rankFrontierClearingCommand(
        const MoveUnitCommand('warrior_clearer', 2, 0),
        _view(units: [_unit('warrior_clearer', col: 1)]),
        _context(),
        _plan(),
      );

      expect(ranking, isNull);
    });
  });
}

const _expectations = EconomyExpectations(
  expectedCityCount: 2,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 2,
  goldReserveTarget: 8,
  minimumSciencePerTurn: 2,
);

StrategicPlan _plan({
  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments =
      const {},
}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: StrategicMode.expand,
    expectations: _expectations,
    frontierClearingAssignments: frontierClearingAssignments,
  );
}

AiContext _context() {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData(),
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view({List<GameUnit> units = const []}) {
  return GameView.fromPersistentState(
    PersistentGameState(units: units),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData(),
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: true,
    ignoreDynamicFogOfWar: true,
  );
}

GameUnit _unit(String id, {int col = 0, int row = 0}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
  );
}

MapData _mapData() {
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
