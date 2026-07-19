import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsStrategy bypass telemetry', () {
    test('falls back when deadline is below minimum budget', () {
      const fallbackCommand = SelectTechnologyCommand(
        'player_1',
        TechnologyId.agriculture,
      );
      const strategy = MctsStrategy(
        config: MctsConfig(minimumBudget: Duration(seconds: 1)),
        fallback: _StaticStrategy(commands: [fallbackCommand]),
      );

      final plan = strategy.plan(
        _view(),
        _context(deadline: DateTime.now().subtract(const Duration(seconds: 1))),
      );

      expect(plan.commands, const [fallbackCommand]);
      expect(plan.debug?.strategyId, 'mcts');
      expect(
        plan.debug?.notes,
        contains('bypassed search: deadline below minimum budget'),
      );
      expect(plan.debug?.metrics['mcts.searchBypassed'], true);
      expect(
        plan.debug?.metrics['mcts.bypassReason'],
        'deadline below minimum budget',
      );
      expect(plan.debug?.metrics['mcts.iterations'], 0);
      expect(plan.debug?.metrics['mcts.mergeElapsedMicros'], isA<int>());
    });
  });
}

class _StaticStrategy implements AiStrategy {
  final List<GameCommand> commands;

  const _StaticStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(
      commands: commands,
      debug: AiDebugInfo(strategyId: 'static'),
    );
  }
}

AiContext _context({DateTime? deadline}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
    deadline: deadline,
  );
}

GameView _view() {
  return GameView.fromPersistentState(
    const PersistentGameState(),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
  );
}

final _mapData = MapData(cols: 1, rows: 1, tiles: const []);
