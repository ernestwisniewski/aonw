import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class UnitMovementPathfinder {
  final MapData mapData;
  final List<GameUnit> units;
  final bool Function(TileData tile)? canEnterTile;
  final bool Function({
    required GameUnit movingUnit,
    required GameUnit blockingUnit,
    required int col,
    required int row,
  })?
  canEnterOccupiedTile;
  final Map<String, TileData> _tilesByKey;
  final Map<String, GameUnit> _unitsByKey;
  final Map<String, Set<({int col, int row})>> _reachableMemo = {};

  UnitMovementPathfinder({
    required this.mapData,
    required Iterable<GameUnit> units,
    this.canEnterTile,
    this.canEnterOccupiedTile,
  }) : units = List.unmodifiable(units),
       _tilesByKey = _indexTiles(mapData.tiles),
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
    final blocker = _unitAt(col, row);
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
    required TileData targetTile,
  }) {
    if (!_isInBounds(targetTile.col, targetTile.row)) return null;
    if (unit.occupies(targetTile.col, targetTile.row)) return null;

    final targetBlocker = _unitAt(targetTile.col, targetTile.row);
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
    final search = _search(unit: unit, stopAtKey: targetKey);
    if (!search.parents.containsKey(targetKey)) return null;

    final steps = _reconstructSteps(
      targetKey: targetKey,
      parents: search.parents,
      enterCosts: search.enterCosts,
      coords: search.coords,
      cumulativeCosts: search.bestCosts,
    );
    if (steps.length < 2) return null;

    return UnitMovementPlan(
      unitId: unit.id,
      targetCol: targetTile.col,
      targetRow: targetTile.row,
      totalCost: search.bestCosts[targetKey] ?? 0,
      availableMovementPoints: unit.movementPoints,
      canSpendTurnEnteringFirstStep: _canSpendTurnEnteringFirstStep(unit),
      steps: steps,
    );
  }

  UnitMovementPlan? planTowardBlockedTarget({
    required GameUnit unit,
    required TileData targetTile,
  }) {
    final blocker = _unitAt(targetTile.col, targetTile.row);
    if (blocker == null || blocker.id == unit.id) return null;

    UnitMovementPlan? best;
    for (final neighbor in HexGridTopology.neighbors(
      col: targetTile.col,
      row: targetTile.row,
    )) {
      final tile = mapData.tileAt(neighbor.col, neighbor.row);
      if (tile == null) continue;
      final candidate = plan(unit: unit, targetTile: tile);
      if (candidate == null) continue;
      if (best == null || _compareApproachPlans(candidate, best) < 0) {
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
    String? stopAtKey,
    int? maxCost,
    bool canSpendTurnEnteringFirstStep = false,
  }) {
    final frontier = <_PathNode>[
      _PathNode(col: unit.col, row: unit.row, cost: 0),
    ];
    final startKey = _coordKey(unit.col, unit.row);
    final bestCosts = <String, int>{startKey: 0};
    final parents = <String, String?>{startKey: null};
    final enterCosts = <String, int>{startKey: 0};
    final coords = <String, ({int col, int row})>{
      startKey: (col: unit.col, row: unit.row),
    };
    while (frontier.isNotEmpty) {
      frontier.sort(_compareNodes);
      final current = frontier.removeAt(0);
      final currentKey = _coordKey(current.col, current.row);
      if (currentKey == stopAtKey) break;
      if (current.cost != bestCosts[currentKey]) continue;
      if (maxCost != null && current.cost > maxCost) continue;

      for (final next in HexGridTopology.neighbors(
        col: current.col,
        row: current.row,
      )) {
        if (!_isInBounds(next.col, next.row)) continue;
        final nextKey = _coordKey(next.col, next.row);
        final blockingUnit = _unitAt(next.col, next.row);
        if (blockingUnit != null &&
            !canEnterOccupied(unit, blockingUnit, next.col, next.row)) {
          continue;
        }

        final tile = _tilesByKey[nextKey];
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
        parents[nextKey] = currentKey;
        enterCosts[nextKey] = enterCost.value;
        coords[nextKey] = next;
        frontier.add(_PathNode(col: next.col, row: next.row, cost: nextCost));
      }
    }

    return _PathSearchResult(
      bestCosts: bestCosts,
      parents: parents,
      enterCosts: enterCosts,
      coords: coords,
    );
  }

  List<UnitMovementStep> _reconstructSteps({
    required String targetKey,
    required Map<String, String?> parents,
    required Map<String, int> enterCosts,
    required Map<String, ({int col, int row})> coords,
    required Map<String, int> cumulativeCosts,
  }) {
    final reversedKeys = <String>[];
    String? cursor = targetKey;
    while (cursor != null) {
      reversedKeys.add(cursor);
      cursor = parents[cursor];
    }

    return [
      for (final key in reversedKeys.reversed)
        UnitMovementStep(
          col: coords[key]!.col,
          row: coords[key]!.row,
          enterCost: enterCosts[key] ?? 0,
          cumulativeCost: cumulativeCosts[key] ?? 0,
        ),
    ];
  }

  GameUnit? _unitAt(int col, int row) {
    return _unitsByKey[_coordKey(col, row)];
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

  static Map<String, TileData> _indexTiles(Iterable<TileData> tiles) {
    final byKey = <String, TileData>{};
    for (final tile in tiles) {
      byKey.putIfAbsent(_coordKey(tile.col, tile.row), () => tile);
    }
    return byKey;
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

  int _compareApproachPlans(UnitMovementPlan a, UnitMovementPlan b) {
    final cost = a.totalCost.compareTo(b.totalCost);
    if (cost != 0) return cost;
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
  final Map<String, String?> parents;
  final Map<String, int> enterCosts;
  final Map<String, ({int col, int row})> coords;

  const _PathSearchResult({
    required this.bestCosts,
    required this.parents,
    required this.enterCosts,
    required this.coords,
  });
}
