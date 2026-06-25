part of 'strategy_aware_economy_ranker.dart';

final class _EconomyWorkerCommandRanker {
  const _EconomyWorkerCommandRanker();

  CommandRanking? rankMove(
    MoveUnitCommand command,
    GameView view,
    StrategicPlan plan,
  ) {
    final target = plan.workerAssignments[command.unitId]?.primaryTarget;
    if (target == null) return null;

    final worker = ownUnitById(view, command.unitId);
    if (worker == null || !worker.isWorker) return null;

    final improvement = distanceImprovement(
      fromCol: worker.col,
      fromRow: worker.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: target.targetHex.toCoordinate(),
    );
    if (improvement <= 0) return null;

    return CommandRanking(
      CandidatePriority.cityRole,
      620 + target.score / 10 + improvement * 16,
    );
  }

  CommandRanking? rankAssignment(
    AssignWorkerToHexCommand command,
    GameView view,
    StrategicPlan plan,
  ) {
    final target = plan.workerAssignments[command.unitId]?.primaryTarget;
    final worker = ownUnitById(view, command.unitId);
    if (target == null || worker == null || !target.existingImprovement) {
      return null;
    }
    if (!_workerIsOnTarget(worker, target)) return null;

    return CommandRanking(CandidatePriority.cityRole, 680 + target.score / 10);
  }

  CommandRanking? rankImprovement(
    SelectWorkerImprovementCommand command,
    GameView view,
    StrategicPlan plan,
  ) {
    final target = plan.workerAssignments[command.unitId]?.primaryTarget;
    final worker = ownUnitById(view, command.unitId);
    if (target == null || worker == null) return null;
    if (target.improvementType != command.improvementType) return null;

    final onTarget = _workerIsOnTarget(worker, target);
    return CommandRanking(
      CandidatePriority.cityRole,
      650 + target.score / 10 + (onTarget ? 32 : 0),
    );
  }

  bool _workerIsOnTarget(GameUnit worker, StrategicWorkerTarget target) {
    return worker.col == target.targetHex.col &&
        worker.row == target.targetHex.row;
  }
}

final class _EconomyTechnologyRanker {
  const _EconomyTechnologyRanker();

  CommandRanking? rank(SelectTechnologyCommand command, StrategicPlan plan) {
    final index = plan.techPath.indexOf(command.technologyId);
    if (index < 0) return null;

    return CommandRanking(CandidatePriority.cityRole, 640 - index * 16);
  }
}
