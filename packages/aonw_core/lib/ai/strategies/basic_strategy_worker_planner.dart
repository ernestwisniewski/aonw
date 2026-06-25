import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

part 'basic_strategy_worker_movement.dart';

final class BasicStrategyWorkerPlanner {
  const BasicStrategyWorkerPlanner();

  List<GameCommand> plan(
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

    final commands = <GameCommand>[];
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
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

  GameCommand? _workerAction({
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

  GameCommand? _idleWorkerAssignment(
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
        worker.movementPoints <= 0 ||
        worker.queuedPath != null;
  }

  void _reserveWorkerDestination(
    GameUnit worker,
    GameCommand command,
    Set<String> occupied,
  ) {
    if (command case MoveUnitCommand(:final targetCol, :final targetRow)) {
      occupied
        ..remove(_key(worker.col, worker.row))
        ..add(_key(targetCol, targetRow));
    }
  }

  GameCommand? _strategicWorkerAction({
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

  GameCommand? _strategicTargetAction({
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

  GameCommand? _strategicTargetActionAtCurrentHex({
    required GameUnit worker,
    required StrategicWorkerTarget target,
    required GameView view,
  }) {
    return switch (target.existingImprovement) {
      true => _strategicAssignmentCommand(worker, target, view),
      false => _strategicImprovementCommand(worker, target, view),
    };
  }

  GameCommand? _strategicAssignmentCommand(
    GameUnit worker,
    StrategicWorkerTarget target,
    GameView view,
  ) {
    return _canAssignWorkerAt(worker, view, target.targetHex)
        ? AssignWorkerToHexCommand(worker.id)
        : null;
  }

  GameCommand? _strategicImprovementCommand(
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

  bool _canBuildWorkerImprovementAt({
    required GameUnit worker,
    required GameView view,
    required FieldImprovementType improvementType,
    required CityHex targetHex,
    bool requireReadyWorker = true,
    ResearchState? research,
  }) {
    return WorkerImprovementRules.evaluate(
      unit: worker,
      improvementType: improvementType,
      cities: view.ownCities,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
      research: research ?? _researchFor(view),
      targetHex: targetHex,
      requireReadyWorker: requireReadyWorker,
      cityRuleset: view.ruleset.city,
      technologyRuleset: view.ruleset.technology,
    ).allowed;
  }

  bool _canAssignWorker(GameUnit worker, GameView view) {
    return _canAssignWorkerAt(
      worker,
      view,
      CityHex(col: worker.col, row: worker.row),
    );
  }

  bool _canAssignWorkerAt(
    GameUnit worker,
    GameView view,
    CityHex targetHex, {
    bool requireReadyWorker = true,
  }) {
    return WorkerAssignmentRules.evaluate(
      unit: worker,
      cities: view.ownCities,
      fieldImprovements: view.ownImprovements,
      units: view.ownUnits,
      mapData: view.mapData,
      targetHex: targetHex,
      requireReadyWorker: requireReadyWorker,
    ).allowed;
  }

  GameCommand? _currentWorkerImprovement({
    required GameUnit worker,
    required GameView view,
  }) {
    final improvement = _bestImprovementFor(
      worker: worker,
      hex: CityHex(col: worker.col, row: worker.row),
      view: view,
    );
    return improvement == null
        ? null
        : SelectWorkerImprovementCommand(worker.id, improvement.type);
  }

  _WorkerImprovementOption? _bestImprovementFor({
    required GameUnit worker,
    required CityHex hex,
    required GameView view,
  }) {
    final tile = view.mapData.tileAt(hex.col, hex.row);
    if (tile == null) return null;

    final research = _researchFor(view);
    final options =
        view.ruleset.city.improvements.keys
            .map(
              (type) => _improvementOptionFor(
                worker: worker,
                view: view,
                tile: tile,
                hex: hex,
                type: type,
                research: research,
              ),
            )
            .whereType<_WorkerImprovementOption>()
            .toList()
          ..sort(_compareWorkerImprovementOptions);

    return options.isEmpty ? null : options.first;
  }

  _WorkerImprovementOption? _improvementOptionFor({
    required GameUnit worker,
    required GameView view,
    required TileData tile,
    required CityHex hex,
    required FieldImprovementType type,
    required ResearchState research,
  }) {
    if (!_canBuildWorkerImprovementAt(
      worker: worker,
      view: view,
      improvementType: type,
      targetHex: hex,
      research: research,
    )) {
      return null;
    }

    return _WorkerImprovementOption(
      type: type,
      score: WorkerImprovementScoring.scoreFor(
        type: type,
        tile: tile,
        ruleset: view.ruleset.city,
      ).toDouble(),
      buildTurns: FieldImprovementRules.buildTurnsFor(
        type,
        ruleset: view.ruleset.city,
        paceBalance: view.ruleset.paceBalance,
      ),
    );
  }

  int _compareWorkerImprovementOptions(
    _WorkerImprovementOption a,
    _WorkerImprovementOption b,
  ) {
    return _firstNonZero([
      b.score.compareTo(a.score),
      a.buildTurns.compareTo(b.buildTurns),
      a.type.name.compareTo(b.type.name),
    ]);
  }

  int _firstNonZero(Iterable<int> comparisons) {
    for (final comparison in comparisons) {
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  ResearchState _researchFor(GameView view) {
    return ResearchState(players: {view.forPlayerId: view.ownResearch});
  }

  String _key(int col, int row) => '$col:$row';
}

final class _WorkerImprovementOption {
  const _WorkerImprovementOption({
    required this.type,
    required this.score,
    required this.buildTurns,
  });

  final FieldImprovementType type;
  final double score;
  final int buildTurns;
}
