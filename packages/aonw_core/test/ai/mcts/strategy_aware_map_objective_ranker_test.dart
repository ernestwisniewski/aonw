import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_map_objective_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware map objective ranker', () {
    test('rewards combat unit moves toward valuable map objectives', () {
      final ranking = rankMapObjectiveCommand(
        const MoveUnitCommand('warrior_1', 1, 0),
        _view(units: [_unit('warrior_1')]),
        _context(),
      );

      expect(ranking?.priority, CandidatePriority.defense);
      expect(ranking?.score, 735);
    });

    test('strongly rewards stepping directly onto a map objective', () {
      final ranking = rankMapObjectiveCommand(
        const MoveUnitCommand('warrior_1', 2, 0),
        _view(units: [_unit('warrior_1', col: 1)]),
        _context(),
      );

      expect(ranking?.priority, CandidatePriority.defense);
      expect(ranking?.score, 870);
    });

    test('does not pull workers or settlers toward map objectives', () {
      final workerRanking = rankMapObjectiveCommand(
        const MoveUnitCommand('worker_1', 1, 0),
        _view(units: [_unit('worker_1', type: GameUnitType.worker)]),
        _context(),
      );
      final settlerRanking = rankMapObjectiveCommand(
        const MoveUnitCommand('settler_1', 1, 0),
        _view(units: [_unit('settler_1', type: GameUnitType.settler)]),
        _context(),
      );

      expect(workerRanking, isNull);
      expect(settlerRanking, isNull);
    });

    test('ignores objectives already completed by the player', () {
      final ranking = rankMapObjectiveCommand(
        const MoveUnitCommand('warrior_1', 1, 0),
        _view(
          units: [_unit('warrior_1')],
          runtimeState: const GameRuntimeState(
            mapObjectiveHoldStatesByObjectiveId: {
              'pass_1': MapObjectiveHoldState(
                objectiveId: 'pass_1',
                playerId: 'player_1',
                holdTurns: 2,
              ),
            },
          ),
        ),
        _context(),
      );

      expect(ranking, isNull);
    });
  });
}

AiContext _context() {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData(),
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view({
  List<GameUnit> units = const [],
  GameRuntimeState runtimeState = GameRuntimeState.empty,
}) {
  return GameView.fromPersistentState(
    PersistentGameState(units: units, runtimeState: runtimeState),
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
  GameUnitType type = GameUnitType.warrior,
  int col = 0,
  int row = 0,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
  );
}

MapData _mapData() {
  return MapData(
    cols: 4,
    rows: 1,
    objectives: const [
      MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 2, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 3,
        goldPerTurn: 2,
      ),
    ],
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
