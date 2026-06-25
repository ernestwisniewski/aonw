part of 'basic_strategy_worker_planner.dart';

extension _BasicStrategyWorkerMovement on BasicStrategyWorkerPlanner {
  MoveUnitCommand? _moveWorkerTowardStrategicTarget({
    required GameUnit worker,
    required StrategicWorkerTarget target,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
  }) {
    final targetTile = view.mapData.tileAt(
      target.targetHex.col,
      target.targetHex.row,
    );
    if (targetTile == null) return null;

    return _moveCommandTowardHex(
      unit: worker,
      target: target.targetHex.toCoordinate(),
      view: view,
      pathfinder: pathfinder,
      occupied: occupied,
    );
  }

  MoveUnitCommand? _moveCommandTowardHex({
    required GameUnit unit,
    required HexCoordinate target,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
    Map<({int col, int row}), int>? movementCosts,
  }) {
    final destination = _reachableMoveTowardHex(
      unit: unit,
      target: target,
      view: view,
      pathfinder: pathfinder,
      occupied: occupied,
      movementCosts: movementCosts,
    );
    if (destination == null) return null;
    return MoveUnitCommand(unit.id, destination.col, destination.row);
  }

  MoveUnitCommand? _moveWorkerTowardImprovement({
    required GameUnit worker,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
  }) {
    final movementCosts = pathfinder.movementCostsFrom(
      unit: worker,
      maxCost: worker.movementPoints,
    );
    final candidates =
        view.mapData.tiles
            .where((tile) => _canConsiderImprovementTile(worker, view, tile))
            .map(
              (tile) => _workerMoveCandidateFor(
                worker: worker,
                tile: tile,
                view: view,
                pathfinder: pathfinder,
                occupied: occupied,
                movementCosts: movementCosts,
              ),
            )
            .whereType<_WorkerMoveCandidate>()
            .toList()
          ..sort(_compareWorkerMoveCandidates);

    if (candidates.isEmpty) return null;
    final target = candidates.first;
    return MoveUnitCommand(
      worker.id,
      target.destinationCol,
      target.destinationRow,
    );
  }

  bool _canConsiderImprovementTile(
    GameUnit worker,
    GameView view,
    TileData tile,
  ) {
    return !worker.occupies(tile.col, tile.row) &&
        view.visibility.canInspectTile(tile);
  }

  _WorkerMoveCandidate? _workerMoveCandidateFor({
    required GameUnit worker,
    required TileData tile,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
    required Map<({int col, int row}), int> movementCosts,
  }) {
    final improvement = _bestImprovementFor(
      worker: worker,
      hex: CityHex(col: tile.col, row: tile.row),
      view: view,
    );
    if (improvement == null) return null;

    final destination = _reachableMoveTowardHex(
      unit: worker,
      target: HexCoordinate.fromTile(tile),
      view: view,
      pathfinder: pathfinder,
      occupied: occupied,
      movementCosts: movementCosts,
    );
    if (destination == null) return null;

    return _WorkerMoveCandidate(
      targetTile: tile,
      destinationCol: destination.col,
      destinationRow: destination.row,
      improvement: improvement,
      movementCost: destination.movementCost,
    );
  }

  _ReachableMoveDestination? _reachableMoveTowardHex({
    required GameUnit unit,
    required HexCoordinate target,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
    Map<({int col, int row}), int>? movementCosts,
  }) {
    final current = HexCoordinate(col: unit.col, row: unit.row);
    final currentDistance = HexDistance.between(current, target);
    final costs =
        movementCosts ??
        pathfinder.movementCostsFrom(unit: unit, maxCost: unit.movementPoints);
    final candidates =
        costs.entries
            .map(
              (entry) => _reachableMoveDestinationFor(
                entry: entry,
                unit: unit,
                target: target,
                currentDistance: currentDistance,
                view: view,
                occupied: occupied,
              ),
            )
            .whereType<_ReachableMoveDestination>()
            .toList()
          ..sort(_compareReachableMove);

    return candidates.isEmpty ? null : candidates.first;
  }

  _ReachableMoveDestination? _reachableMoveDestinationFor({
    required MapEntry<({int col, int row}), int> entry,
    required GameUnit unit,
    required HexCoordinate target,
    required int currentDistance,
    required GameView view,
    required Set<String> occupied,
  }) {
    final hex = entry.key;
    if (!_canUseMoveDestination(unit, view, occupied, hex)) return null;

    final distance = HexDistance.between(
      HexCoordinate(col: hex.col, row: hex.row),
      target,
    );
    if (distance >= currentDistance) return null;

    return _ReachableMoveDestination(
      col: hex.col,
      row: hex.row,
      distanceToTarget: distance,
      movementCost: entry.value,
    );
  }

  bool _canUseMoveDestination(
    GameUnit unit,
    GameView view,
    Set<String> occupied,
    ({int col, int row}) hex,
  ) {
    final tile = view.mapData.tileAt(hex.col, hex.row);
    return !unit.occupies(hex.col, hex.row) &&
        !occupied.contains(_key(hex.col, hex.row)) &&
        tile != null &&
        view.visibility.canSeeDynamicAt(hex.col, hex.row);
  }

  int _compareReachableMove(
    _ReachableMoveDestination a,
    _ReachableMoveDestination b,
  ) {
    return _firstNonZero([
      a.distanceToTarget.compareTo(b.distanceToTarget),
      b.movementCost.compareTo(a.movementCost),
      a.col.compareTo(b.col),
      a.row.compareTo(b.row),
    ]);
  }

  int _compareWorkerMoveCandidates(
    _WorkerMoveCandidate a,
    _WorkerMoveCandidate b,
  ) {
    return _firstNonZero([
      b.improvement.score.compareTo(a.improvement.score),
      a.movementCost.compareTo(b.movementCost),
      a.targetTile.col.compareTo(b.targetTile.col),
      a.targetTile.row.compareTo(b.targetTile.row),
    ]);
  }
}

final class _WorkerMoveCandidate {
  const _WorkerMoveCandidate({
    required this.targetTile,
    required this.destinationCol,
    required this.destinationRow,
    required this.improvement,
    required this.movementCost,
  });

  final TileData targetTile;
  final int destinationCol;
  final int destinationRow;
  final _WorkerImprovementOption improvement;
  final int movementCost;
}

final class _ReachableMoveDestination {
  const _ReachableMoveDestination({
    required this.col,
    required this.row,
    required this.distanceToTarget,
    required this.movementCost,
  });

  final int col;
  final int row;
  final int distanceToTarget;
  final int movementCost;
}
