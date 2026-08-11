part of 'unit_movement_pathfinder.dart';

final class _UnitMovementRouteSearch {
  _UnitMovementRouteSearch({
    required this.pathfinder,
    required this.unit,
    required this.targetKey,
    required this.canEnterStepBeyondCapacity,
  }) : maxMovement = UnitMovementBalance.maxMovementPointsFor(
         type: unit.type,
         carriedArtifactId: unit.carriedArtifactId,
       ) {
    final start = _RouteState(
      col: unit.col,
      row: unit.row,
      remaining: unit.movementPoints,
      started: false,
    );
    const score = _RouteScore(turns: 0, totalCost: 0, stepCount: 0);
    frontier.add(_RouteNode(state: start, score: score));
    bestScores[start] = score;
    parents[start] = null;
    enterCosts[start] = 0;
  }

  final UnitMovementPathfinder pathfinder;
  final GameUnit unit;
  final String targetKey;
  final UnitMovementCapacityException? canEnterStepBeyondCapacity;
  final int maxMovement;
  late final MinBinaryHeap<_RouteNode> frontier = MinBinaryHeap<_RouteNode>(
    _compareRouteNodes,
  );
  final bestScores = <_RouteState, _RouteScore>{};
  final parents = <_RouteState, _RouteState?>{};
  final enterCosts = <_RouteState, int>{};

  _RouteSearchResult? search() {
    while (frontier.isNotEmpty) {
      final current = _takeCurrent();
      if (current == null) continue;
      if (_isTarget(current.state)) return _result(current.state);
      for (final next in HexGridTopology.neighbors(
        col: current.state.col,
        row: current.state.row,
      )) {
        _visit(current, next);
      }
    }
    return null;
  }

  _RouteNode? _takeCurrent() {
    final current = frontier.removeFirst();
    final knownScore = bestScores[current.state];
    if (knownScore == null ||
        _compareRouteScores(current.score, knownScore) != 0) {
      return null;
    }
    return current;
  }

  bool _isTarget(_RouteState state) =>
      UnitMovementPathfinder._coordKey(state.col, state.row) == targetKey;

  _RouteSearchResult _result(_RouteState targetState) => _RouteSearchResult(
    targetState: targetState,
    bestScores: bestScores,
    parents: parents,
    enterCosts: enterCosts,
  );

  void _visit(_RouteNode current, ({int col, int row}) next) {
    final enterCost = pathfinder._enterCostFor(
      unit: unit,
      next: next,
      currentCost: current.score.totalCost,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
    if (enterCost == null) return;
    final transition = _advanceRoute(current, enterCost);
    final nextState = _RouteState(
      col: next.col,
      row: next.row,
      remaining: transition.remaining,
      started: true,
    );
    final nextScore = _RouteScore(
      turns: transition.turns,
      totalCost: current.score.totalCost + enterCost,
      stepCount: current.score.stepCount + 1,
    );
    final previous = bestScores[nextState];
    if (previous != null && _compareRouteScores(previous, nextScore) <= 0) {
      return;
    }
    bestScores[nextState] = nextScore;
    parents[nextState] = current.state;
    enterCosts[nextState] = enterCost;
    frontier.add(_RouteNode(state: nextState, score: nextScore));
  }

  ({int turns, int remaining}) _advanceRoute(
    _RouteNode current,
    int enterCost,
  ) {
    var turns = current.score.turns;
    var remaining = current.state.remaining;
    if (!current.state.started) turns = 1;
    if (enterCost <= remaining) {
      remaining -= enterCost;
    } else if (remaining > 0) {
      remaining = 0;
    } else {
      turns += 1;
      remaining = _remainingAfterNewTurn(enterCost, maxMovement);
    }
    return (turns: turns, remaining: remaining);
  }
}

int _remainingAfterNewTurn(int enterCost, int maxMovement) =>
    enterCost >= maxMovement ? 0 : maxMovement - enterCost;

int _compareRouteNodes(_RouteNode a, _RouteNode b) {
  final score = _compareRouteScores(a.score, b.score);
  if (score != 0) return score;
  final col = a.state.col.compareTo(b.state.col);
  if (col != 0) return col;
  final row = a.state.row.compareTo(b.state.row);
  if (row != 0) return row;
  return b.state.remaining.compareTo(a.state.remaining);
}

int _compareRouteScores(_RouteScore a, _RouteScore b) {
  final turns = a.turns.compareTo(b.turns);
  if (turns != 0) return turns;
  final cost = a.totalCost.compareTo(b.totalCost);
  if (cost != 0) return cost;
  return a.stepCount.compareTo(b.stepCount);
}

int _compareUnitApproachPlans(
  UnitMovementPlan a,
  UnitMovementPlan b,
  GameUnit unit,
) {
  final maxMovement = UnitMovementBalance.maxMovementPointsFor(
    type: unit.type,
    carriedArtifactId: unit.carriedArtifactId,
  );
  final turns = a
      .estimatedTurns(maxMovement)
      .compareTo(b.estimatedTurns(maxMovement));
  if (turns != 0) return turns;
  final cost = a.totalCost.compareTo(b.totalCost);
  if (cost != 0) return cost;
  final steps = a.steps.length.compareTo(b.steps.length);
  if (steps != 0) return steps;
  final col = a.targetCol.compareTo(b.targetCol);
  return col != 0 ? col : a.targetRow.compareTo(b.targetRow);
}

final class _RouteState {
  const _RouteState({
    required this.col,
    required this.row,
    required this.remaining,
    required this.started,
  });

  final int col;
  final int row;
  final int remaining;
  final bool started;

  @override
  bool operator ==(Object other) =>
      other is _RouteState &&
      other.col == col &&
      other.row == row &&
      other.remaining == remaining &&
      other.started == started;

  @override
  int get hashCode => Object.hash(col, row, remaining, started);
}

final class _RouteScore {
  const _RouteScore({
    required this.turns,
    required this.totalCost,
    required this.stepCount,
  });

  final int turns;
  final int totalCost;
  final int stepCount;
}

final class _RouteNode {
  const _RouteNode({required this.state, required this.score});

  final _RouteState state;
  final _RouteScore score;
}

final class _RouteSearchResult {
  const _RouteSearchResult({
    required this.targetState,
    required this.bestScores,
    required this.parents,
    required this.enterCosts,
  });

  final _RouteState targetState;
  final Map<_RouteState, _RouteScore> bestScores;
  final Map<_RouteState, _RouteState?> parents;
  final Map<_RouteState, int> enterCosts;

  int get totalCost => bestScores[targetState]!.totalCost;

  List<UnitMovementStep> get steps {
    final reversed = <_RouteState>[];
    _RouteState? cursor = targetState;
    while (cursor != null) {
      reversed.add(cursor);
      cursor = parents[cursor];
    }
    return [
      for (final state in reversed.reversed)
        UnitMovementStep(
          col: state.col,
          row: state.row,
          enterCost: enterCosts[state] ?? 0,
          cumulativeCost: bestScores[state]?.totalCost ?? 0,
        ),
    ];
  }
}
