import 'dart:math' as math;

import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';

class MctsNode {
  final SimulatedState state;
  final MctsNode? parent;
  final MctsAction? action;
  final List<MctsNode> children = [];
  List<MctsAction>? _untriedActions;
  int visits = 0;
  double totalScore = 0;

  MctsNode({required this.state, this.parent, this.action});

  bool get hasCachedActions => _untriedActions != null;

  bool get hasUntriedActions => (_untriedActions?.isNotEmpty ?? false);

  double get averageScore => visits == 0 ? 0 : totalScore / visits;

  void cacheActions(Iterable<MctsAction> actions) {
    _untriedActions ??= List<MctsAction>.of(actions);
  }

  MctsAction? takeUntriedAction() {
    final actions = _untriedActions;
    if (actions == null || actions.isEmpty) return null;
    return actions.removeAt(0);
  }

  MctsNode addChild({
    required MctsAction action,
    required SimulatedState state,
  }) {
    final child = MctsNode(state: state, parent: this, action: action);
    children.add(child);
    return child;
  }

  void record(double score) {
    visits += 1;
    totalScore += score;
  }

  double ucb1({required double explorationConstant}) {
    final parentVisits = parent?.visits ?? 0;
    if (visits == 0) return double.infinity;
    if (parentVisits <= 1) return averageScore;
    return averageScore +
        explorationConstant * math.sqrt(math.log(parentVisits) / visits);
  }

  MctsNode bestChildByUcb({required double explorationConstant}) {
    if (children.isEmpty) {
      throw StateError('Cannot select a child from a leaf MCTS node.');
    }
    return children.reduce((best, child) {
      final childScore = child.ucb1(explorationConstant: explorationConstant);
      final bestScore = best.ucb1(explorationConstant: explorationConstant);
      if (childScore > bestScore) return child;
      if (childScore < bestScore) return best;
      return child.visits < best.visits ? child : best;
    });
  }

  MctsNode mostVisitedChild() {
    if (children.isEmpty) {
      throw StateError('Cannot select a child from a leaf MCTS node.');
    }
    return children.reduce((best, child) {
      if (child.visits > best.visits) return child;
      if (child.visits < best.visits) return best;
      return child.averageScore > best.averageScore ? child : best;
    });
  }
}
