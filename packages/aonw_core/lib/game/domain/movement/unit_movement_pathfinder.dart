import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_source.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

class UnitMovementPathfinder {
  final MapTraversalView mapData;
  final List<GameUnit> units;
  final bool Function(MapTileView tile)? canEnterTile;
  final bool Function({
    required GameUnit movingUnit,
    required GameUnit blockingUnit,
    required int col,
    required int row,
  })?
  canEnterOccupiedTile;
  final Map<String, MapTileView> _tilesByKey;
  final bool _hasCompleteTileIndex;
  final Set<String> _missingTileKeys = {};
  final Map<String, GameUnit> _unitsByKey;
  final Map<String, Set<({int col, int row})>> _reachableMemo = {};

  UnitMovementPathfinder({
    required this.mapData,
    required Iterable<GameUnit> units,
    this.canEnterTile,
    this.canEnterOccupiedTile,
  }) : units = List.unmodifiable(units),
       _tilesByKey = _initialTileIndex(mapData),
       _hasCompleteTileIndex = mapData is MapTileSource<MapTileView>,
       _unitsByKey = _indexUnits(units);

  /// Returns whether [unit] can plan a move ending on [col]/[row] using the
  /// same blocking rules as [plan], but with an O(1) lookup after the first
  /// call for the same unit.
  bool isReachable({
    required GameUnit unit,
    required int col,
    required int row,
  }) {
    if (!_isInBounds(col, row)) return false;
    if (unit.occupies(col, row)) return false;
    final blocker = _indexedUnitAt(col, row);
    if (blocker != null && !canEnterOccupied(unit, blocker, col, row)) {
      return false;
    }
    final reachable = _reachableSetFor(unit);
    return reachable.contains((col: col, row: row));
  }

  Set<({int col, int row})> _reachableSetFor(GameUnit unit) {
    final cached = _reachableMemo[unit.id];
    if (cached != null) return cached;
    final costs = movementCostsFrom(unit: unit);
    final set = costs.keys.toSet();
    _reachableMemo[unit.id] = set;
    return set;
  }

  UnitMovementPlan? plan({
    required GameUnit unit,
    required MapTileView targetTile,
  }) {
    if (!_isInBounds(targetTile.col, targetTile.row)) return null;
    if (unit.occupies(targetTile.col, targetTile.row)) return null;

    final targetBlocker = _indexedUnitAt(targetTile.col, targetTile.row);
    if (targetBlocker != null &&
        !canEnterOccupied(
          unit,
          targetBlocker,
          targetTile.col,
          targetTile.row,
        )) {
      return null;
    }

    final targetKey = _coordKey(targetTile.col, targetTile.row);
    final search = _searchBestRoute(unit: unit, targetKey: targetKey);
    if (search == null) return null;
    final steps = _reconstructRouteSteps(search);
    if (steps.length < 2) return null;

    return UnitMovementPlan(
      unitId: unit.id,
      targetCol: targetTile.col,
      targetRow: targetTile.row,
      totalCost: search.bestScores[search.targetState]!.totalCost,
      availableMovementPoints: unit.movementPoints,
      canSpendTurnEnteringFirstStep: _canSpendTurnEnteringFirstStep(unit),
      steps: steps,
    );
  }

  UnitMovementPlan? planTowardBlockedTarget({
    required GameUnit unit,
    required MapTileView targetTile,
  }) {
    final blocker = _indexedUnitAt(targetTile.col, targetTile.row);
    if (blocker == null || blocker.id == unit.id) return null;

    UnitMovementPlan? best;
    for (final neighbor in HexGridTopology.neighbors(
      col: targetTile.col,
      row: targetTile.row,
    )) {
      final tile = tileAt(neighbor.col, neighbor.row);
      if (tile == null) continue;
      final candidate = plan(unit: unit, targetTile: tile);
      if (candidate == null) continue;
      if (best == null || _compareApproachPlans(candidate, best, unit) < 0) {
        best = candidate;
      }
    }
    return best;
  }

  Map<({int col, int row}), int> movementCostsFrom({
    required GameUnit unit,
    int? maxCost,
  }) {
    final search = _search(
      unit: unit,
      maxCost: maxCost,
      canSpendTurnEnteringFirstStep: _canSpendTurnEnteringFirstStep(unit),
    );
    return {
      for (final entry in search.bestCosts.entries)
        if (search.coords[entry.key] case final coords?)
          if (!unit.occupies(coords.col, coords.row))
            (col: coords.col, row: coords.row): entry.value,
    };
  }

  _PathSearchResult _search({
    required GameUnit unit,
    int? maxCost,
    bool canSpendTurnEnteringFirstStep = false,
  }) {
    final frontier = <_PathNode>[
      _PathNode(col: unit.col, row: unit.row, cost: 0),
    ];
    final startKey = _coordKey(unit.col, unit.row);
    final bestCosts = <String, int>{startKey: 0};
    final coords = <String, ({int col, int row})>{
      startKey: (col: unit.col, row: unit.row),
    };
    while (frontier.isNotEmpty) {
      frontier.sort(_compareNodes);
      final current = frontier.removeAt(0);
      final currentKey = _coordKey(current.col, current.row);
      if (current.cost != bestCosts[currentKey]) continue;
      if (maxCost != null && current.cost > maxCost) continue;

      for (final next in HexGridTopology.neighbors(
        col: current.col,
        row: current.row,
      )) {
        if (!_isInBounds(next.col, next.row)) continue;
        final nextKey = _coordKey(next.col, next.row);
        final blockingUnit = _indexedUnitAt(next.col, next.row);
        if (blockingUnit != null &&
            !canEnterOccupied(unit, blockingUnit, next.col, next.row)) {
          continue;
        }

        final tile = tileAt(next.col, next.row);
        if (tile == null) continue;
        if (canEnterTile != null && !canEnterTile!(tile)) continue;
        final enterCost = UnitMovementCostRules.costToEnterTile(
          tile,
          unitType: unit.type,
        );
        if (enterCost.blocked) continue;

        final nextCost = current.cost + enterCost.value;
        if (maxCost != null &&
            nextCost > maxCost &&
            !(canSpendTurnEnteringFirstStep &&
                _isFirstStepFromStart(
                  currentKey: currentKey,
                  startKey: startKey,
                  maxCost: maxCost,
                ))) {
          continue;
        }
        final knownCost = bestCosts[nextKey];
        if (knownCost != null && knownCost <= nextCost) continue;

        bestCosts[nextKey] = nextCost;
        coords[nextKey] = next;
        frontier.add(_PathNode(col: next.col, row: next.row, cost: nextCost));
      }
    }

    return _PathSearchResult(bestCosts: bestCosts, coords: coords);
  }

  _RouteSearchResult? _searchBestRoute({
    required GameUnit unit,
    required String targetKey,
  }) {
    final maxMovement = UnitMovementBalance.maxMovementPointsFor(
      type: unit.type,
      carriedArtifactId: unit.carriedArtifactId,
    );
    final start = _RouteState(
      col: unit.col,
      row: unit.row,
      remaining: unit.movementPoints,
      started: false,
    );
    const startScore = _RouteScore(turns: 0, totalCost: 0, stepCount: 0);
    final frontier = <_RouteNode>[_RouteNode(state: start, score: startScore)];
    final bestScores = <_RouteState, _RouteScore>{start: startScore};
    final parents = <_RouteState, _RouteState?>{start: null};
    final enterCosts = <_RouteState, int>{start: 0};

    while (frontier.isNotEmpty) {
      frontier.sort(_compareRouteNodes);
      final current = frontier.removeAt(0);
      final knownScore = bestScores[current.state];
      if (knownScore == null ||
          _compareRouteScores(current.score, knownScore) != 0) {
        continue;
      }
      if (_coordKey(current.state.col, current.state.row) == targetKey) {
        return _RouteSearchResult(
          targetState: current.state,
          bestScores: bestScores,
          parents: parents,
          enterCosts: enterCosts,
        );
      }

      for (final next in HexGridTopology.neighbors(
        col: current.state.col,
        row: current.state.row,
      )) {
        if (!_isInBounds(next.col, next.row)) continue;
        final blockingUnit = _indexedUnitAt(next.col, next.row);
        if (blockingUnit != null &&
            !canEnterOccupied(unit, blockingUnit, next.col, next.row)) {
          continue;
        }

        final tile = tileAt(next.col, next.row);
        if (tile == null) continue;
        if (canEnterTile != null && !canEnterTile!(tile)) continue;
        final enterCost = UnitMovementCostRules.costToEnterTile(
          tile,
          unitType: unit.type,
        );
        if (enterCost.blocked) continue;

        final transition = _advanceRoute(
          current: current,
          enterCost: enterCost.value,
          maxMovement: maxMovement,
        );
        final nextState = _RouteState(
          col: next.col,
          row: next.row,
          remaining: transition.remaining,
          started: true,
        );
        final nextScore = _RouteScore(
          turns: transition.turns,
          totalCost: current.score.totalCost + enterCost.value,
          stepCount: current.score.stepCount + 1,
        );
        final previous = bestScores[nextState];
        if (previous != null && _compareRouteScores(previous, nextScore) <= 0) {
          continue;
        }

        bestScores[nextState] = nextScore;
        parents[nextState] = current.state;
        enterCosts[nextState] = enterCost.value;
        frontier.add(_RouteNode(state: nextState, score: nextScore));
      }
    }
    return null;
  }

  ({int turns, int remaining}) _advanceRoute({
    required _RouteNode current,
    required int enterCost,
    required int maxMovement,
  }) {
    var turns = current.score.turns;
    var remaining = current.state.remaining;
    if (!current.state.started) {
      turns = 1;
      if (enterCost <= remaining) {
        remaining -= enterCost;
      } else if (remaining > 0) {
        // The manual movement rules allow the first step to consume the
        // remainder of a partially spent turn.
        remaining = 0;
      } else {
        turns += 1;
        remaining = _remainingAfterNewTurn(enterCost, maxMovement);
      }
    } else if (enterCost <= remaining) {
      remaining -= enterCost;
    } else {
      turns += 1;
      remaining = _remainingAfterNewTurn(enterCost, maxMovement);
    }
    return (turns: turns, remaining: remaining);
  }

  static int _remainingAfterNewTurn(int enterCost, int maxMovement) {
    return enterCost >= maxMovement ? 0 : maxMovement - enterCost;
  }

  List<UnitMovementStep> _reconstructRouteSteps(_RouteSearchResult search) {
    final reversed = <_RouteState>[];
    _RouteState? cursor = search.targetState;
    while (cursor != null) {
      reversed.add(cursor);
      cursor = search.parents[cursor];
    }
    return [
      for (final state in reversed.reversed)
        UnitMovementStep(
          col: state.col,
          row: state.row,
          enterCost: search.enterCosts[state] ?? 0,
          cumulativeCost: search.bestScores[state]?.totalCost ?? 0,
        ),
    ];
  }

  GameUnit? _indexedUnitAt(int col, int row) {
    return _unitsByKey[_coordKey(col, row)];
  }

  /// Returns a tile through the pathfinder's request-scoped spatial index.
  ///
  /// Complete sources keep an eager O(1) index. Narrow traversal views cache
  /// only borrowed tile references reached by the search.
  MapTileView? tileAt(int col, int row) {
    final key = _coordKey(col, row);
    final indexed = _tilesByKey[key];
    if (indexed != null) return indexed;
    if (_hasCompleteTileIndex || _missingTileKeys.contains(key)) return null;

    final tile = mapData.tileAt(col, row);
    if (tile == null) {
      _missingTileKeys.add(key);
      return null;
    }
    return _tilesByKey[key] = tile;
  }

  bool canEnterOccupied(
    GameUnit movingUnit,
    GameUnit blockingUnit,
    int col,
    int row,
  ) {
    if (blockingUnit.id == movingUnit.id) return true;
    return canEnterOccupiedTile?.call(
          movingUnit: movingUnit,
          blockingUnit: blockingUnit,
          col: col,
          row: row,
        ) ??
        false;
  }

  bool _isInBounds(int col, int row) {
    return col >= 0 && row >= 0 && col < mapData.cols && row < mapData.rows;
  }

  static String _coordKey(int col, int row) => '$col:$row';

  static Map<String, MapTileView> _indexTiles(Iterable<MapTileView> tiles) {
    final byKey = <String, MapTileView>{};
    for (final tile in tiles) {
      byKey.putIfAbsent(_coordKey(tile.col, tile.row), () => tile);
    }
    return byKey;
  }

  static Map<String, MapTileView> _initialTileIndex(MapTraversalView mapData) {
    return mapData is MapTileSource<MapTileView>
        ? _indexTiles(mapData.tiles)
        : <String, MapTileView>{};
  }

  static Map<String, GameUnit> _indexUnits(Iterable<GameUnit> units) {
    final byKey = <String, GameUnit>{};
    for (final unit in units) {
      byKey.putIfAbsent(_coordKey(unit.col, unit.row), () => unit);
    }
    return byKey;
  }

  static bool _isFirstStepFromStart({
    required String currentKey,
    required String startKey,
    required int maxCost,
  }) {
    return currentKey == startKey && maxCost > 0;
  }

  static bool _canSpendTurnEnteringFirstStep(GameUnit unit) {
    return unit.movementPoints > 0;
  }

  int _compareNodes(_PathNode a, _PathNode b) {
    final cost = a.cost.compareTo(b.cost);
    if (cost != 0) return cost;
    final col = a.col.compareTo(b.col);
    if (col != 0) return col;
    return a.row.compareTo(b.row);
  }

  int _compareRouteNodes(_RouteNode a, _RouteNode b) {
    final score = _compareRouteScores(a.score, b.score);
    if (score != 0) return score;
    final col = a.state.col.compareTo(b.state.col);
    if (col != 0) return col;
    final row = a.state.row.compareTo(b.state.row);
    if (row != 0) return row;
    return b.state.remaining.compareTo(a.state.remaining);
  }

  static int _compareRouteScores(_RouteScore a, _RouteScore b) {
    final turns = a.turns.compareTo(b.turns);
    if (turns != 0) return turns;
    final cost = a.totalCost.compareTo(b.totalCost);
    if (cost != 0) return cost;
    return a.stepCount.compareTo(b.stepCount);
  }

  int _compareApproachPlans(
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
    if (col != 0) return col;
    return a.targetRow.compareTo(b.targetRow);
  }
}

class _PathNode {
  final int col;
  final int row;
  final int cost;

  const _PathNode({required this.col, required this.row, required this.cost});
}

class _PathSearchResult {
  final Map<String, int> bestCosts;
  final Map<String, ({int col, int row})> coords;

  const _PathSearchResult({required this.bestCosts, required this.coords});
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
}
