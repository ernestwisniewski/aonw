import 'package:aonw_core/ai/mcts/mcts_config.dart';

class MctsBudget {
  final Duration wallClock;
  final int? iterationBudget;
  final int minIterations;

  const MctsBudget({
    required this.wallClock,
    this.iterationBudget,
    this.minIterations = 0,
  });

  factory MctsBudget.fromConfig({
    required MctsConfig config,
    DateTime? deadline,
    DateTime Function() now = DateTime.now,
  }) {
    var wallClock = config.wallClockBudget;
    if (deadline != null) {
      final remaining =
          deadline.toUtc().difference(now().toUtc()) -
          config.deadlineSafetyMargin;
      if (remaining < wallClock) {
        wallClock = remaining > Duration.zero ? remaining : Duration.zero;
      }
    }
    return MctsBudget(
      wallClock: wallClock,
      iterationBudget: config.iterationBudget,
      minIterations: config.minIterations,
    );
  }

  bool exhausted(int iterations, Duration elapsed) {
    if (iterations < minIterations) return false;
    if (wallClock <= Duration.zero || elapsed >= wallClock) return true;
    final iterationBudget = this.iterationBudget;
    if (iterationBudget != null) return iterations >= iterationBudget;
    return false;
  }
}
