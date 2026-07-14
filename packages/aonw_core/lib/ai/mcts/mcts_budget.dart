import 'package:aonw_core/ai/mcts/mcts_config.dart';

class MctsBudget {
  final Duration wallClock;
  final int? iterationBudget;
  final int minIterations;
  final bool isIterationOnly;

  const MctsBudget({
    required this.wallClock,
    this.iterationBudget,
    this.minIterations = 0,
  }) : isIterationOnly = false;

  factory MctsBudget.iterations(int iterations) {
    if (iterations <= 0) {
      throw ArgumentError.value(
        iterations,
        'iterations',
        'Must be greater than zero.',
      );
    }
    return MctsBudget._iterationOnly(iterations);
  }

  const MctsBudget._iterationOnly(int iterations)
    : wallClock = Duration.zero,
      iterationBudget = iterations,
      minIterations = iterations,
      isIterationOnly = true;

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
    if (isIterationOnly) return iterations >= this.iterationBudget!;
    if (iterations < minIterations) return false;
    if (wallClock <= Duration.zero || elapsed >= wallClock) return true;
    final iterationBudget = this.iterationBudget;
    if (iterationBudget != null) return iterations >= iterationBudget;
    return false;
  }
}
