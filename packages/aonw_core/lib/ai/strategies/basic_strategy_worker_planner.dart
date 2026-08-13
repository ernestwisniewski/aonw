import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'basic_strategy_worker_movement.dart';
part 'basic_strategy_worker_improvements.dart';
part 'basic_strategy_worker_targets.dart';

final class BasicStrategyWorkerPlanner {
  const BasicStrategyWorkerPlanner();

  List<DomainCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (view.ownCities.isEmpty) return const [];

    final workers = [
      for (final unit in view.ownUnits)
        if (unit.isWorker) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (workers.isEmpty) return const [];

    final commands = <DomainCommand>[];
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      costResolver: view.traversalCostResolver,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );

    for (final worker in workers) {
      final action = _workerAction(
        worker: worker,
        view: view,
        assignment: context.strategicPlan?.workerAssignments[worker.id],
        pathfinder: pathfinder,
        occupied: occupied,
        usedUnitIds: usedUnitIds,
      );

      if (action == null) continue;
      commands.add(action);
      usedUnitIds.add(worker.id);
      _reserveWorkerDestination(worker, action, occupied);
    }

    for (final worker in workers) {
      final assignment = _idleWorkerAssignment(worker, view, usedUnitIds);
      if (assignment == null) continue;

      commands.add(assignment);
      usedUnitIds.add(worker.id);
    }

    return List.unmodifiable(commands);
  }

  DomainCommand? _workerAction({
    required GameUnit worker,
    required GameView view,
    required StrategicWorkerAssignment? assignment,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
    required Set<String> usedUnitIds,
  }) {
    if (_cannotUseWorker(worker, usedUnitIds)) return null;

    return _strategicWorkerAction(
          worker: worker,
          assignment: assignment,
          view: view,
          pathfinder: pathfinder,
          occupied: occupied,
        ) ??
        _currentWorkerImprovement(worker: worker, view: view) ??
        _moveWorkerTowardImprovement(
          worker: worker,
          view: view,
          pathfinder: pathfinder,
          occupied: occupied,
        );
  }

  DomainCommand? _idleWorkerAssignment(
    GameUnit worker,
    GameView view,
    Set<String> usedUnitIds,
  ) {
    if (_cannotUseWorker(worker, usedUnitIds) ||
        !_canAssignWorker(worker, view)) {
      return null;
    }
    return AssignWorkerToHexCommand(worker.id);
  }

  bool _cannotUseWorker(GameUnit worker, Set<String> usedUnitIds) {
    return usedUnitIds.contains(worker.id) ||
        worker.isWorking ||
        !worker.hasMovementRemaining ||
        worker.queuedPath != null;
  }

  void _reserveWorkerDestination(
    GameUnit worker,
    DomainCommand command,
    Set<String> occupied,
  ) {
    if (command case MoveUnitCommand(:final targetCol, :final targetRow)) {
      occupied
        ..remove(_key(worker.col, worker.row))
        ..add(_key(targetCol, targetRow));
    }
  }

  String _key(int col, int row) => '$col:$row';
}
