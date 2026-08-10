part of '../run_save_ai_benchmark.dart';

class _CommandStats {
  _CommandStats({
    required this.total,
    required this.attacks,
    required this.attackHumans,
    required this.attackPressureTargets,
    required this.attackNonHumans,
    required this.attackUnknownTargets,
    required Map<String, int> attackTargetOwners,
    required Map<String, int> nonHumanAttackReasons,
    required this.moves,
    required this.movesTowardHumans,
    required this.movesAwayFromHumans,
    required this.movesTowardWarGoals,
    required this.movesAwayFromWarGoals,
    required this.movesTowardPressureTargets,
    required this.movesAwayFromPressureTargets,
    required this.production,
    required this.workerActions,
    required this.estimatedVisibleDelayCommands,
  }) : attackTargetOwners = Map.unmodifiable(attackTargetOwners),
       nonHumanAttackReasons = Map.unmodifiable(nonHumanAttackReasons);

  final int total;
  final int attacks;
  final int attackHumans;
  final int attackPressureTargets;
  final int attackNonHumans;
  final int attackUnknownTargets;
  final Map<String, int> attackTargetOwners;
  final Map<String, int> nonHumanAttackReasons;
  final int moves;
  final int movesTowardHumans;
  final int movesAwayFromHumans;
  final int movesTowardWarGoals;
  final int movesAwayFromWarGoals;
  final int movesTowardPressureTargets;
  final int movesAwayFromPressureTargets;
  final int production;
  final int workerActions;
  final int estimatedVisibleDelayCommands;

  int get distractingNonHumanAttacks {
    return nonHumanAttackReasons[_nonHumanAttackReasonDistracting] ?? 0;
  }

  factory _CommandStats.fromPlan(
    AiTurnPlan plan, {
    required GameView view,
    required Set<String> humanPlayerIds,
    StrategicPlan? strategicPlan,
  }) {
    return _CommandStats.fromCommands(
      plan.commands,
      view: view,
      humanPlayerIds: humanPlayerIds,
      strategicPlan: strategicPlan,
    );
  }

  factory _CommandStats.fromCommands(
    Iterable<DomainCommand> commands, {
    required GameView view,
    required Set<String> humanPlayerIds,
    StrategicPlan? strategicPlan,
  }) {
    var attacks = 0;
    var attackHumans = 0;
    var attackPressureTargets = 0;
    var attackNonHumans = 0;
    var attackUnknownTargets = 0;
    var moves = 0;
    var movesTowardHumans = 0;
    var movesAwayFromHumans = 0;
    var movesTowardWarGoals = 0;
    var movesAwayFromWarGoals = 0;
    var movesTowardPressureTargets = 0;
    var movesAwayFromPressureTargets = 0;
    var production = 0;
    var workerActions = 0;
    var estimatedVisibleDelayCommands = 0;
    final attackTargetOwners = <String, int>{};
    final nonHumanAttackReasons = <String, int>{};
    final unitsById = {for (final unit in view.ownUnits) unit.id: unit};
    final humanAnchors = _humanTargetAnchors(view, humanPlayerIds);
    final humanPressureTargetIds = {
      for (final playerId in view.pressureTargetPlayerIds)
        if (humanPlayerIds.contains(playerId)) playerId,
    };
    final humanPressureAnchors = _targetAnchorsForOwners(
      view,
      humanPressureTargetIds,
    );
    final pressureAnchors = _targetAnchorsForOwners(
      view,
      view.pressureTargetPlayerIds,
    );
    final warGoalAnchors = _warGoalTargetAnchors(
      strategicPlan,
      view,
      humanPlayerIds,
    );
    final warGoalAnchorsByUnitId = _warGoalTargetAnchorsByUnitId(
      strategicPlan,
      view,
      humanPlayerIds,
    );
    final hasHumanPressureContact = _hasPressureContact(
      view,
      humanPressureAnchors,
    );

    var total = 0;
    for (final command in commands) {
      total += 1;
      switch (command) {
        case AttackHexCommand():
          estimatedVisibleDelayCommands += 1;
          attacks += 1;
          final targetOwner = _ownerAt(
            view,
            command.defenderCol,
            command.defenderRow,
          );
          if (targetOwner == null) {
            attackUnknownTargets += 1;
          } else {
            attackTargetOwners.update(
              targetOwner,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
            if (humanPlayerIds.contains(targetOwner)) {
              attackHumans += 1;
            } else {
              attackNonHumans += 1;
              final reason = _nonHumanAttackReason(
                command,
                view: view,
                targetOwner: targetOwner,
                humanPressureAnchors: humanPressureAnchors,
                hasHumanPressureContact: hasHumanPressureContact,
              );
              nonHumanAttackReasons.update(
                reason,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
            }
            if (view.pressureTargetPlayerIds.contains(targetOwner)) {
              attackPressureTargets += 1;
            }
          }
        case MoveUnitCommand():
          estimatedVisibleDelayCommands += 1;
          moves += 1;
          final unit = unitsById[command.unitId];
          if (unit != null && humanAnchors.isNotEmpty) {
            final before = _nearestDistance(
              HexCoordinate(col: unit.col, row: unit.row),
              humanAnchors,
            );
            final after = _nearestDistance(
              HexCoordinate(col: command.targetCol, row: command.targetRow),
              humanAnchors,
            );
            if (after < before) movesTowardHumans += 1;
            if (after > before) movesAwayFromHumans += 1;
          }
          if (unit != null && pressureAnchors.isNotEmpty) {
            final before = _nearestDistance(
              HexCoordinate(col: unit.col, row: unit.row),
              pressureAnchors,
            );
            final after = _nearestDistance(
              HexCoordinate(col: command.targetCol, row: command.targetRow),
              pressureAnchors,
            );
            if (after < before) movesTowardPressureTargets += 1;
            if (after > before) movesAwayFromPressureTargets += 1;
          }
          if (unit != null) {
            final anchors = warGoalAnchorsByUnitId[unit.id] ?? warGoalAnchors;
            if (anchors.isNotEmpty) {
              final before = _nearestDistance(
                HexCoordinate(col: unit.col, row: unit.row),
                anchors,
              );
              final after = _nearestDistance(
                HexCoordinate(col: command.targetCol, row: command.targetRow),
                anchors,
              );
              if (after < before) movesTowardWarGoals += 1;
              if (after > before) movesAwayFromWarGoals += 1;
            }
          }
        case FoundCityCommand():
          estimatedVisibleDelayCommands += 1;
        case StartBuildingCommand() ||
            StartUnitProductionCommand() ||
            StartCityProjectCommand() ||
            RushProductionCommand():
          production += 1;
        case SelectWorkerImprovementCommand() ||
            ConfirmWorkerImprovementCommand() ||
            AssignWorkerToHexCommand() ||
            CancelWorkerAssignmentCommand() ||
            CancelWorkerJobCommand():
          estimatedVisibleDelayCommands += 1;
          workerActions += 1;
        default:
          break;
      }
    }

    return _CommandStats(
      total: total,
      attacks: attacks,
      attackHumans: attackHumans,
      attackPressureTargets: attackPressureTargets,
      attackNonHumans: attackNonHumans,
      attackUnknownTargets: attackUnknownTargets,
      attackTargetOwners: _sortedIntMap(attackTargetOwners),
      nonHumanAttackReasons: _sortedIntMap(nonHumanAttackReasons),
      moves: moves,
      movesTowardHumans: movesTowardHumans,
      movesAwayFromHumans: movesAwayFromHumans,
      movesTowardWarGoals: movesTowardWarGoals,
      movesAwayFromWarGoals: movesAwayFromWarGoals,
      movesTowardPressureTargets: movesTowardPressureTargets,
      movesAwayFromPressureTargets: movesAwayFromPressureTargets,
      production: production,
      workerActions: workerActions,
      estimatedVisibleDelayCommands: estimatedVisibleDelayCommands,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'total': total,
      'attacks': attacks,
      'attackHumans': attackHumans,
      'attackPressureTargets': attackPressureTargets,
      'attackNonHumans': attackNonHumans,
      'attackUnknownTargets': attackUnknownTargets,
      'attackTargetOwners': attackTargetOwners,
      'nonHumanAttackReasons': nonHumanAttackReasons,
      'distractingNonHumanAttacks': distractingNonHumanAttacks,
      'moves': moves,
      'movesTowardHumans': movesTowardHumans,
      'movesAwayFromHumans': movesAwayFromHumans,
      'movesTowardWarGoals': movesTowardWarGoals,
      'movesAwayFromWarGoals': movesAwayFromWarGoals,
      'movesTowardPressureTargets': movesTowardPressureTargets,
      'movesAwayFromPressureTargets': movesAwayFromPressureTargets,
      'production': production,
      'workerActions': workerActions,
      'estimatedVisibleDelayCommands': estimatedVisibleDelayCommands,
    };
  }
}
