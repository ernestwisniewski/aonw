import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_economy_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('rankStrategicEconomyCommand', () {
    test('prioritizes technologies from the strategic tech path', () {
      final ranking = rankStrategicEconomyCommand(
        const SelectTechnologyCommand('player_1', TechnologyId.writing),
        _view(),
        _context(),
        _plan(
          mode: StrategicMode.techRush,
          techPath: const [TechnologyId.agriculture, TechnologyId.writing],
        ),
      );

      expect(ranking?.priority, CandidatePriority.cityRole);
      expect(ranking?.score, 624);
    });

    test('rewards worker moves that approach the assigned improvement', () {
      final ranking = rankStrategicEconomyCommand(
        const MoveUnitCommand('worker_1', 1, 0),
        _view(units: [_worker()]),
        _context(),
        _plan(
          workerAssignments: {
            'worker_1': StrategicWorkerAssignment(
              workerId: 'worker_1',
              cityId: 'city_1',
              targets: const [
                StrategicWorkerTarget(
                  cityId: 'city_1',
                  targetHex: CityHex(col: 2, row: 0),
                  improvementType: FieldImprovementType.farm,
                  score: 80,
                  buildTurns: 2,
                  existingImprovement: false,
                ),
              ],
            ),
          },
        ),
      );

      expect(ranking?.priority, CandidatePriority.cityRole);
      expect(ranking?.score, 644);
    });

    test('does not rank unrelated economic commands', () {
      final ranking = rankStrategicEconomyCommand(
        const SelectTechnologyCommand('player_1', TechnologyId.mining),
        _view(),
        _context(),
        _plan(techPath: const [TechnologyId.agriculture]),
      );

      expect(ranking, isNull);
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

StrategicPlan _plan({
  StrategicMode mode = StrategicMode.consolidate,
  List<TechnologyId> techPath = const [],
  Map<String, StrategicWorkerAssignment> workerAssignments = const {},
}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: mode,
    expectations: _expectations,
    techPath: techPath,
    workerAssignments: workerAssignments,
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
  );
}

GameUnit _worker() {
  return GameUnit(
    id: 'worker_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: GameUnitType.worker.defaultNameToken,
    col: 0,
    row: 0,
  );
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
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
