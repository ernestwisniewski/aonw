import 'package:aonw_core/ai/mcts/mcts_action_generation_stats.dart';
import 'package:aonw_core/ai/mcts/mcts_node.dart';
import 'package:aonw_core/ai/mcts/mcts_search.dart';

class MctsDebugSummary {
  final int iterations;
  final Duration elapsed;
  final int plannedActions;
  final int rootChildren;
  final int exploredNodes;
  final int maxDepth;
  final MctsActionGenerationStats? actionGeneration;
  final MctsSearchTimings searchTimings;
  final MctsPhaseTimings? phaseTimings;

  const MctsDebugSummary({
    required this.iterations,
    required this.elapsed,
    required this.plannedActions,
    required this.rootChildren,
    required this.exploredNodes,
    required this.maxDepth,
    this.actionGeneration,
    this.searchTimings = const MctsSearchTimings(),
    this.phaseTimings,
  });

  factory MctsDebugSummary.fromResult(
    MctsSearchResult result, {
    MctsActionGenerationStats? actionGeneration,
    MctsPhaseTimings? phaseTimings,
  }) {
    final tree = _TreeStats.fromRoot(result.root);
    return MctsDebugSummary(
      iterations: result.iterations,
      elapsed: result.elapsed,
      plannedActions: result.bestActions.length,
      rootChildren: result.root.children.length,
      exploredNodes: tree.nodes,
      maxDepth: tree.maxDepth,
      actionGeneration: actionGeneration,
      searchTimings: result.timings,
      phaseTimings: phaseTimings,
    );
  }

  List<String> toNotes() {
    return [
      'iterations $iterations',
      'elapsed ${elapsed.inMilliseconds}ms',
      'planned $plannedActions commands',
      'root children $rootChildren',
      'explored nodes $exploredNodes',
      'max depth $maxDepth',
      'search select ${searchTimings.selectionElapsed.inMilliseconds}ms',
      'search expand ${searchTimings.expansionElapsed.inMilliseconds}ms',
      'search rollout ${searchTimings.rolloutElapsed.inMilliseconds}ms',
      'search eval ${searchTimings.evaluationElapsed.inMilliseconds}ms',
      'search backprop '
          '${searchTimings.backpropagationElapsed.inMilliseconds}ms',
      ...?actionGeneration?.toNotes(),
      ...?phaseTimings?.toNotes(),
    ];
  }

  Map<String, Object?> toMetrics() {
    return {
      'mcts.iterations': iterations,
      'mcts.elapsedMicros': elapsed.inMicroseconds,
      'mcts.plannedActions': plannedActions,
      'mcts.rootChildren': rootChildren,
      'mcts.exploredNodes': exploredNodes,
      'mcts.maxDepth': maxDepth,
      'mcts.searchSelectionElapsedMicros':
          searchTimings.selectionElapsed.inMicroseconds,
      'mcts.searchExpansionElapsedMicros':
          searchTimings.expansionElapsed.inMicroseconds,
      'mcts.searchRolloutElapsedMicros':
          searchTimings.rolloutElapsed.inMicroseconds,
      'mcts.searchEvaluationElapsedMicros':
          searchTimings.evaluationElapsed.inMicroseconds,
      'mcts.searchBackpropagationElapsedMicros':
          searchTimings.backpropagationElapsed.inMicroseconds,
      ...?actionGeneration?.toMetrics(),
      ...?phaseTimings?.toMetrics(),
    };
  }
}

class MctsPhaseTimings {
  final Duration searchElapsed;
  final Duration validationElapsed;
  final Duration baselinePlanElapsed;
  final Duration mergeElapsed;
  final Duration totalElapsed;

  const MctsPhaseTimings({
    required this.searchElapsed,
    required this.validationElapsed,
    required this.baselinePlanElapsed,
    required this.mergeElapsed,
    required this.totalElapsed,
  });

  List<String> toNotes() {
    return [
      'phase search ${searchElapsed.inMilliseconds}ms',
      'phase validation ${validationElapsed.inMilliseconds}ms',
      'phase baseline ${baselinePlanElapsed.inMilliseconds}ms',
      'phase merge ${mergeElapsed.inMilliseconds}ms',
      'phase total ${totalElapsed.inMilliseconds}ms',
    ];
  }

  Map<String, Object?> toMetrics() {
    return {
      'mcts.searchElapsedMicros': searchElapsed.inMicroseconds,
      'mcts.validationElapsedMicros': validationElapsed.inMicroseconds,
      'mcts.baselinePlanElapsedMicros': baselinePlanElapsed.inMicroseconds,
      'mcts.mergeElapsedMicros': mergeElapsed.inMicroseconds,
      'mcts.strategyElapsedMicros': totalElapsed.inMicroseconds,
    };
  }
}

class _TreeStats {
  final int nodes;
  final int maxDepth;

  const _TreeStats({required this.nodes, required this.maxDepth});

  factory _TreeStats.fromRoot(MctsNode root) {
    var nodes = 0;
    var maxDepth = 0;

    void walk(MctsNode node, int depth) {
      nodes += 1;
      if (depth > maxDepth) maxDepth = depth;
      for (final child in node.children) {
        walk(child, depth + 1);
      }
    }

    walk(root, 0);
    return _TreeStats(nodes: nodes, maxDepth: maxDepth);
  }
}
