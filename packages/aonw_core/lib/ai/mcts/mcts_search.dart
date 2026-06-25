import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_action_generator.dart';
import 'package:aonw_core/ai/mcts/mcts_budget.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluator.dart';
import 'package:aonw_core/ai/mcts/mcts_node.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulator.dart';

class MctsSearchResult {
  final int iterations;
  final Duration elapsed;
  final MctsNode root;
  final List<MctsAction> bestActions;
  final MctsSearchTimings timings;

  const MctsSearchResult({
    required this.iterations,
    required this.elapsed,
    required this.root,
    required this.bestActions,
    this.timings = const MctsSearchTimings(),
  });
}

class MctsSearchTimings {
  final Duration selectionElapsed;
  final Duration expansionElapsed;
  final Duration rolloutElapsed;
  final Duration evaluationElapsed;
  final Duration backpropagationElapsed;

  const MctsSearchTimings({
    this.selectionElapsed = Duration.zero,
    this.expansionElapsed = Duration.zero,
    this.rolloutElapsed = Duration.zero,
    this.evaluationElapsed = Duration.zero,
    this.backpropagationElapsed = Duration.zero,
  });
}

class MctsSearch {
  final MctsActionGenerator actionGenerator;
  final MctsSimulator simulator;
  final MctsEvaluator evaluator;
  final double explorationConstant;

  const MctsSearch({
    required this.actionGenerator,
    required this.simulator,
    required this.evaluator,
    required this.explorationConstant,
  });

  MctsSearchResult search({
    required SimulatedState rootState,
    required AiContext context,
    required MctsBudget budget,
    MctsNode? existingRoot,
  }) {
    final root = existingRoot ?? MctsNode(state: rootState);
    final stopwatch = Stopwatch()..start();
    var iterations = 0;
    var selectionElapsed = Duration.zero;
    var expansionElapsed = Duration.zero;
    var rolloutElapsed = Duration.zero;
    var evaluationElapsed = Duration.zero;
    var backpropagationElapsed = Duration.zero;

    while (!budget.exhausted(iterations, stopwatch.elapsed)) {
      final selectionStopwatch = Stopwatch()..start();
      var node = _select(root, context);
      selectionStopwatch.stop();
      selectionElapsed += selectionStopwatch.elapsed;

      final expansionStopwatch = Stopwatch()..start();
      node = _expand(node, context);
      expansionStopwatch.stop();
      expansionElapsed += expansionStopwatch.elapsed;

      final rolloutStopwatch = Stopwatch()..start();
      final rolloutState = simulator.advanceTurn(node.state);
      rolloutStopwatch.stop();
      rolloutElapsed += rolloutStopwatch.elapsed;

      final evaluationStopwatch = Stopwatch()..start();
      final score = evaluator.score(
        rolloutState,
        rootState.view.forPlayerId,
        context: context,
      );
      evaluationStopwatch.stop();
      evaluationElapsed += evaluationStopwatch.elapsed;

      final backpropagationStopwatch = Stopwatch()..start();
      _backpropagate(node, score);
      backpropagationStopwatch.stop();
      backpropagationElapsed += backpropagationStopwatch.elapsed;
      iterations += 1;
    }
    stopwatch.stop();

    return MctsSearchResult(
      iterations: iterations,
      elapsed: stopwatch.elapsed,
      root: root,
      bestActions: _bestActionSequence(root),
      timings: MctsSearchTimings(
        selectionElapsed: selectionElapsed,
        expansionElapsed: expansionElapsed,
        rolloutElapsed: rolloutElapsed,
        evaluationElapsed: evaluationElapsed,
        backpropagationElapsed: backpropagationElapsed,
      ),
    );
  }

  MctsNode _select(MctsNode root, AiContext context) {
    var node = root;
    while (!node.state.isTerminal) {
      _cacheActions(node, context);
      if (node.hasUntriedActions || node.children.isEmpty) return node;
      node = node.bestChildByUcb(explorationConstant: explorationConstant);
    }
    return node;
  }

  MctsNode _expand(MctsNode node, AiContext context) {
    _cacheActions(node, context);
    final action = node.takeUntriedAction();
    if (action == null) return node;
    return node.addChild(
      action: action,
      state: simulator.applyAction(node.state, action),
    );
  }

  void _cacheActions(MctsNode node, AiContext context) {
    if (node.hasCachedActions) return;
    node.cacheActions(actionGenerator.candidatesFor(node.state, context));
  }

  void _backpropagate(MctsNode node, double score) {
    MctsNode? current = node;
    while (current != null) {
      current.record(score);
      current = current.parent;
    }
  }

  List<MctsAction> _bestActionSequence(MctsNode root) {
    final actions = <MctsAction>[];
    var current = root;
    while (current.children.isNotEmpty) {
      final child = current.mostVisitedChild();
      final action = child.action;
      if (action == null || action.endsPlanning) break;
      actions.add(action);
      current = child;
    }
    return List.unmodifiable(actions);
  }
}
