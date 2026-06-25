import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_war_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware war ranker', () {
    test('rewards assigned movement toward a war goal target', () {
      final ranking = rankWarCommand(
        const MoveUnitCommand('warrior_1', 1, 0),
        _view(units: [_unit('warrior_1')]),
        _context(),
        _plan(
          warGoals: [
            WarGoal(
              targetPlayerId: 'enemy_a',
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 3, row: 0),
              turnsBudget: 4,
              assignedUnitIds: const ['warrior_1'],
              priority: 2,
            ),
          ],
        ),
      );

      expect(ranking?.priority, CandidatePriority.war);
      expect(ranking?.score, 1120);
    });

    test('blocks assigned attackers from chasing unrelated targets', () {
      final ranking = rankAssignedWarFocusGuard(
        const AttackHexCommand('warrior_1', 1, 0),
        _view(
          units: [
            _unit('warrior_1'),
            _unit('enemy_b_warrior', ownerPlayerId: 'enemy_b', col: 1),
          ],
        ),
        _context(),
        _plan(
          warGoals: [
            WarGoal(
              targetPlayerId: 'enemy_a',
              kind: WarGoalKind.eliminateUnits,
              targetHex: const HexCoordinate(col: 7, row: 7),
              turnsBudget: 4,
              assignedUnitIds: const ['warrior_1'],
              priority: 2,
            ),
          ],
        ),
      );

      expect(ranking?.priority, CandidatePriority.fallback);
      expect(ranking?.score, -975);
    });
  });
}

const _expectations = EconomyExpectations(
  expectedCityCount: 1,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 1,
  goldReserveTarget: 8,
  minimumSciencePerTurn: 2,
);

StrategicPlan _plan({List<WarGoal> warGoals = const []}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: StrategicMode.military,
    expectations: _expectations,
    warGoals: warGoals,
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

GameUnit _unit(
  String id, {
  String ownerPlayerId = 'player_1',
  int col = 0,
  int row = 0,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
  );
}

MapData _mapData() {
  return MapData(
    cols: 8,
    rows: 8,
    tiles: [
      for (var col = 0; col < 8; col++)
        for (var row = 0; row < 8; row++)
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
