import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsSearch', () {
    test('selects the most visited high scoring action', () {
      final search = MctsSearch(
        actionGenerator: _FixedGenerator(),
        simulator: const TracingMctsSimulator(),
        evaluator: const CommandSequenceEvaluator(),
        explorationConstant: 1.4,
      );

      final result = search.search(
        rootState: SimulatedState.fromView(_view(), maxPlanningDepth: 1),
        context: _context(),
        budget: const MctsBudget(wallClock: Duration.zero, minIterations: 12),
      );

      expect(result.iterations, 12);
      expect(result.elapsed, greaterThanOrEqualTo(Duration.zero));
      expect(result.bestActions.single, _FixedGenerator.researchAction);
    });
  });
}

class _FixedGenerator implements MctsActionGenerator {
  static const moveAction = CommandMctsAction(MoveUnitCommand('unit_1', 1, 0));
  static const researchAction = CommandMctsAction(
    SelectTechnologyCommand('player_1', TechnologyId.agriculture),
  );

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    if (state.isTerminal) return const [];
    return const [moveAction, researchAction, EndPlanningAction()];
  }
}

AiContext _context() {
  final mapData = MapData(cols: 1, rows: 1, tiles: const []);
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view() {
  final mapData = MapData(cols: 1, rows: 1, tiles: const []);
  return GameView.fromPersistentState(
    const PersistentGameState(),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}
