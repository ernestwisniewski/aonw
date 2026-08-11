import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/movement/unit_traversal_cost_resolver.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_source.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'unit_movement_route_search.dart';

class UnitMovementPathfinder {
  final MapTraversalView mapData;
  final List<GameUnit> units;
  final UnitTraversalCostResolver costResolver;
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
    this.costResolver = const TerrainTraversalCostResolver(),
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
    UnitMovementCapacityException? canEnterStepBeyondCapacity,
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
    final search = _UnitMovementRouteSearch(
      pathfinder: this,
      unit: unit,
      targetKey: targetKey,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    ).search();
    if (search == null) return null;
    final steps = search.steps;
    if (steps.length < 2) return null;

    return UnitMovementPlan(
      unitId: unit.id,
      targetCol: targetTile.col,
      targetRow: targetTile.row,
      totalCost: search.totalCost,
      availableMovementPoints: unit.movementPoints,
      steps: steps,
    );
  }

  UnitMovementPlan? planTowardBlockedTarget({
    required GameUnit unit,
    required MapTileView targetTile,
    UnitMovementCapacityException? canEnterStepBeyondCapacity,
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
      final candidate = plan(
        unit: unit,
        targetTile: tile,
        canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
      );
      if (candidate == null) continue;
      if (best == null ||
          _compareUnitApproachPlans(candidate, best, unit) < 0) {
        best = candidate;
      }
    }
    return best;
  }

  /// Returns bounded movement costs, including the single terrain-passable
  /// step that can exhaust a positive remainder. Its cost may exceed
  /// [maxCost], but that terminal boundary is never expanded. Per-turn
  /// capacity and the artifact-carrier exception remain authoritative.
  Map<({int col, int row}), int> movementCostsFrom({
    required GameUnit unit,
    int? maxCost,
  }) {
    final search = _search(unit: unit, maxCost: maxCost);
    return {
      for (final entry in search.bestCosts.entries)
        if (search.coords[entry.key] case final coords?)
          if (!unit.occupies(coords.col, coords.row))
            (col: coords.col, row: coords.row): entry.value,
    };
  }

  _PathSearchResult _search({required GameUnit unit, int? maxCost}) {
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
        final nextKey = _coordKey(next.col, next.row);
        final enterCost = _enterCostFor(
          unit: unit,
          next: next,
          currentCost: current.cost,
          canEnterStepBeyondCapacity: null,
        );
        if (enterCost == null) continue;

        final nextCost = current.cost + enterCost;
        if (maxCost != null && nextCost > maxCost && current.cost >= maxCost) {
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

  int? _enterCostFor({
    required GameUnit unit,
    required ({int col, int row}) next,
    required int currentCost,
    required UnitMovementCapacityException? canEnterStepBeyondCapacity,
  }) {
    if (!_isInBounds(next.col, next.row)) return null;
    final blockingUnit = _indexedUnitAt(next.col, next.row);
    if (blockingUnit != null &&
        !canEnterOccupied(unit, blockingUnit, next.col, next.row)) {
      return null;
    }
    final tile = tileAt(next.col, next.row);
    if (tile == null) return null;
    if (canEnterTile != null && !canEnterTile!(tile)) return null;
    final movementCost = costResolver.costToEnter(unit: unit, tile: tile);
    if (movementCost.blocked) return null;
    final enterCost = movementCost.value;
    final step = UnitMovementStep(
      col: next.col,
      row: next.row,
      enterCost: enterCost,
      cumulativeCost: currentCost + enterCost,
    );
    return UnitMovementFeasibility.canTraverseStep(
          unit: unit,
          step: step,
          canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
        )
        ? enterCost
        : null;
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

  int _compareNodes(_PathNode a, _PathNode b) {
    final cost = a.cost.compareTo(b.cost);
    if (cost != 0) return cost;
    final col = a.col.compareTo(b.col);
    if (col != 0) return col;
    return a.row.compareTo(b.row);
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
