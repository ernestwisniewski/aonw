part of 'mcts_strategy_test.dart';

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

class _StaticActionGenerator implements MctsActionGenerator {
  final List<MctsAction> actions;

  const _StaticActionGenerator({required this.actions});

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    return actions;
  }
}
