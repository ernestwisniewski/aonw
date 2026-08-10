part of 'basic_strategy_worker_planner.dart';

extension _BasicStrategyWorkerTargets on BasicStrategyWorkerPlanner {
  DomainCommand? _strategicWorkerAction({
    required GameUnit worker,
    required StrategicWorkerAssignment? assignment,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
  }) {
    if (assignment == null) return null;

    for (final target in _workerTargetsByActionPriority(assignment.targets)) {
      final action = _strategicTargetAction(
        worker: worker,
        target: target,
        view: view,
        pathfinder: pathfinder,
        occupied: occupied,
      );
      if (action != null) return action;
    }

    return null;
  }

  Iterable<StrategicWorkerTarget> _workerTargetsByActionPriority(
    Iterable<StrategicWorkerTarget> targets,
  ) {
    return [
      ...targets.where((target) => !target.existingImprovement),
      ...targets.where((target) => target.existingImprovement),
    ];
  }

  DomainCommand? _strategicTargetAction({
    required GameUnit worker,
    required StrategicWorkerTarget target,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
  }) {
    if (!_isStrategicWorkerTargetUsable(
      worker: worker,
      target: target,
      view: view,
    )) {
      return null;
    }

    return switch (_workerAtTarget(worker, target)) {
      true => _strategicTargetActionAtCurrentHex(
        worker: worker,
        target: target,
        view: view,
      ),
      false => _moveWorkerTowardStrategicTarget(
        worker: worker,
        target: target,
        view: view,
        pathfinder: pathfinder,
        occupied: occupied,
      ),
    };
  }

  bool _workerAtTarget(GameUnit worker, StrategicWorkerTarget target) {
    return worker.occupies(target.targetHex.col, target.targetHex.row);
  }

  DomainCommand? _strategicTargetActionAtCurrentHex({
    required GameUnit worker,
    required StrategicWorkerTarget target,
    required GameView view,
  }) {
    return switch (target.existingImprovement) {
      true => _strategicAssignmentCommand(worker, target, view),
      false => _strategicImprovementCommand(worker, target, view),
    };
  }

  DomainCommand? _strategicAssignmentCommand(
    GameUnit worker,
    StrategicWorkerTarget target,
    GameView view,
  ) {
    return _canAssignWorkerAt(worker, view, target.targetHex)
        ? AssignWorkerToHexCommand(worker.id)
        : null;
  }

  DomainCommand? _strategicImprovementCommand(
    GameUnit worker,
    StrategicWorkerTarget target,
    GameView view,
  ) {
    return _canBuildWorkerImprovementAt(
          worker: worker,
          view: view,
          improvementType: target.improvementType,
          targetHex: target.targetHex,
        )
        ? SelectWorkerImprovementCommand(worker.id, target.improvementType)
        : null;
  }

  bool _isStrategicWorkerTargetUsable({
    required GameUnit worker,
    required StrategicWorkerTarget target,
    required GameView view,
  }) {
    final tile = view.mapData.tileAt(
      target.targetHex.col,
      target.targetHex.row,
    );
    if (tile == null || !view.visibility.canInspectTile(tile)) return false;

    if (target.existingImprovement) {
      return _hasAssignableStrategicImprovement(
        worker: worker,
        target: target,
        view: view,
      );
    }

    return _canBuildWorkerImprovementAt(
      worker: worker,
      view: view,
      improvementType: target.improvementType,
      targetHex: target.targetHex,
      requireReadyWorker: false,
    );
  }

  bool _hasAssignableStrategicImprovement({
    required GameUnit worker,
    required StrategicWorkerTarget target,
    required GameView view,
  }) {
    final improvement = CityTileYieldRules.improvementAt(
      target.targetHex,
      view.ownImprovements,
    );
    return improvement?.type == target.improvementType &&
        _canAssignWorkerAt(
          worker,
          view,
          target.targetHex,
          requireReadyWorker: false,
        );
  }
}
