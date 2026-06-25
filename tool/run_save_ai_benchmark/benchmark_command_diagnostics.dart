part of '../run_save_ai_benchmark.dart';

GameCommand _terminalFor(GameMode gameMode, String playerId) {
  return switch (gameMode) {
    GameMode.hotSeat => EndTurnCommand(playerId),
    GameMode.multiplayer => SubmitTurnCommand(playerId),
  };
}

bool _isTerminal(GameCommand command) {
  return command is EndTurnCommand || command is SubmitTurnCommand;
}

bool _isUnitAlreadyAtTarget(MoveUnitCommand command, GameState state) {
  for (final unit in state.units) {
    if (unit.id != command.unitId) continue;
    return unit.col == command.targetCol && unit.row == command.targetRow;
  }
  return false;
}

_StaleMoveDiagnostic? _staleMoveDiagnostic(
  MoveUnitCommand command,
  GameState state, {
  GameView? planningView,
  Player? player,
  Iterable<Player> players = const [],
  Set<String> humanPlayerIds = const {},
  int commandIndex = -1,
}) {
  GameUnit? movingUnit;
  GameUnit? blocker;
  for (final unit in state.units) {
    if (unit.id == command.unitId) {
      movingUnit = unit;
    } else if (unit.col == command.targetCol && unit.row == command.targetRow) {
      blocker ??= unit;
    }
  }

  if (blocker != null) {
    final actorId = player?.id ?? '';
    final ownerId = blocker.ownerPlayerId;
    final planTargetOccupant = planningView == null
        ? null
        : _planningTargetOccupantId(
            planningView,
            command.targetCol,
            command.targetRow,
          );
    return _StaleMoveDiagnostic(
      commandIndex: commandIndex,
      command: _describeCommand(command),
      reason: 'targetOccupied',
      unitId: command.unitId,
      unitCol: movingUnit?.col,
      unitRow: movingUnit?.row,
      targetCol: command.targetCol,
      targetRow: command.targetRow,
      blockerUnitId: blocker.id,
      blockerOwnerPlayerId: ownerId,
      blockerOwnerKind: _ownerKind(
        ownerId,
        actorPlayerId: actorId,
        players: players,
        humanPlayerIds: humanPlayerIds,
      ),
      blockerRelation: actorId.isEmpty || actorId == ownerId
          ? 'self'
          : state.runtimeState.diplomacy.statusBetween(actorId, ownerId).name,
      blockerPlanVisibility: planningView == null
          ? null
          : _planningVisibilityForUnit(planningView, blocker),
      planTargetOccupantId: planTargetOccupant,
    );
  }

  if (movingUnit == null) return null;
  if (movingUnit.col == command.targetCol &&
      movingUnit.row == command.targetRow) {
    return _StaleMoveDiagnostic(
      commandIndex: commandIndex,
      command: _describeCommand(command),
      reason: 'unitAlreadyAtTarget',
      unitId: command.unitId,
      unitCol: movingUnit.col,
      unitRow: movingUnit.row,
      targetCol: command.targetCol,
      targetRow: command.targetRow,
    );
  }
  return null;
}

String _ownerKind(
  String ownerPlayerId, {
  required String actorPlayerId,
  required Iterable<Player> players,
  required Set<String> humanPlayerIds,
}) {
  if (ownerPlayerId == actorPlayerId) return 'own';
  if (humanPlayerIds.contains(ownerPlayerId)) return 'human';
  for (final player in players) {
    if (player.id == ownerPlayerId) return player.kind.name;
  }
  return 'unknown';
}

String _planningVisibilityForUnit(GameView view, GameUnit unit) {
  if (view.ownUnits.any((own) => own.id == unit.id)) return 'own';
  if (view.visibleEnemyUnits.any((enemy) => enemy.id == unit.id)) {
    return 'visibleEnemy';
  }
  if (_planningTargetOccupantId(view, unit.col, unit.row) != null) {
    return 'occupiedByDifferentKnownUnit';
  }
  return 'hiddenOrMovedAfterPlan';
}

String? _planningTargetOccupantId(GameView view, int col, int row) {
  for (final unit in [...view.ownUnits, ...view.visibleEnemyUnits]) {
    if (unit.col == col && unit.row == row) return unit.id;
  }
  return null;
}

List<String> _rejectionReasons(GameStateTransition transition) {
  return [
    for (final event in transition.events)
      if (event case CommandRejectedEvent(:final reason)) reason,
  ];
}

String _describeCommand(GameCommand command) {
  return switch (command) {
    MoveUnitCommand() =>
      'move ${command.unitId} to (${command.targetCol},${command.targetRow})',
    AttackHexCommand() =>
      'attack (${command.defenderCol},${command.defenderRow}) '
          'with ${command.attackerUnitId}',
    FoundCityCommand() => 'found city with ${command.founderId}',
    SelectTechnologyCommand() => 'research ${command.technologyId.name}',
    StartUnitProductionCommand() =>
      'start ${command.unitType.name} in ${command.cityId}',
    StartBuildingCommand() =>
      'start ${command.buildingType.name} in ${command.cityId}',
    StartCityProjectCommand() =>
      'start ${command.projectType.name} in ${command.cityId}',
    SetCitySpecializationCommand() =>
      'specialize ${command.cityId} as ${command.specialization.name}',
    SelectWorkerImprovementCommand() =>
      'select ${command.improvementType.name} for ${command.unitId}',
    ConfirmWorkerImprovementCommand() =>
      'confirm worker improvement for ${command.unitId}',
    AssignWorkerToHexCommand() => 'assign worker ${command.unitId}',
    CancelWorkerAssignmentCommand() =>
      'cancel worker assignment ${command.unitId}',
    CancelWorkerJobCommand() => 'cancel worker job ${command.unitId}',
    CancelUnitActionCommand() => 'cancel unit action ${command.unitId}',
    SkipUnitTurnCommand() => 'skip ${command.unitId}',
    FortifyUnitCommand() => 'fortify ${command.unitId}',
    AutoExploreUnitCommand() => 'auto explore ${command.unitId}',
    ResetUnitMovementCommand() =>
      'reset movement for ${command.playerId ?? 'all'}',
    EndTurnCommand() => 'end turn for ${command.playerId}',
    SubmitTurnCommand() => 'submit turn for ${command.playerId}',
    RushProductionCommand() => 'rush production in ${command.cityId}',
    _ => command.runtimeType.toString(),
  };
}

String _describeRejectedCommand(
  GameCommand command,
  GameState state,
  MapData mapData,
  GameCommandContext context,
) {
  final description = _describeCommand(command);
  if (command is! MoveUnitCommand) return description;

  final unit = _unitByIdOrNull(state.units, command.unitId);
  if (unit == null) return '$description [unitMissing]';

  final details = <String>[
    'unitAt=(${unit.col},${unit.row})',
    'mp=${unit.movementPoints}',
    'posture=${unit.posture.name}',
  ];
  if (!context.canControlUnit(state, unit)) {
    details.add('notControllable owner=${unit.ownerPlayerId}');
  }
  if (unit.isWorking) details.add('working');
  if (unit.isFortified) details.add('fortified');
  if (unit.occupies(command.targetCol, command.targetRow)) {
    details.add('alreadyAtTarget');
  }

  final targetTile = mapData.tileAt(command.targetCol, command.targetRow);
  if (targetTile == null) {
    details.add('targetOutOfBounds');
    return '$description [${details.join('; ')}]';
  }
  details.add('targetTerrain=${targetTile.primaryTerrain.name}');

  final blocker = _unitAtOrNull(
    state.units,
    command.targetCol,
    command.targetRow,
  );
  if (blocker != null && blocker.id != unit.id) {
    details.add('targetBlockedBy=${blocker.id}/${blocker.ownerPlayerId}');
  }

  final visibility = context.visibilityFor(state);
  final pathfinder = UnitMovementPathfinder(
    mapData: mapData,
    units: state.units,
    canEnterTile: (tile) => UnitMovementVisibilityRules.canPlanThroughTile(
      unit: unit,
      tile: tile,
      visibility: visibility,
    ),
  );
  final plan = pathfinder.plan(unit: unit, targetTile: targetTile);
  if (plan == null) {
    final approach = blocker == null
        ? null
        : pathfinder.planTowardBlockedTarget(
            unit: unit,
            targetTile: targetTile,
          );
    if (approach == null) {
      details.add('path=null');
    } else {
      details.add(
        'path=null approachCost=${approach.totalCost}'
        ' approachDest=(${approach.targetCol},${approach.targetRow})',
      );
    }
  } else {
    final destination = plan.totalCost <= unit.movementPoints
        ? plan.steps.last
        : plan.furthestReachableStep;
    details.add(
      'pathCost=${plan.totalCost}'
      ' reachable=${plan.totalCost <= unit.movementPoints}',
    );
    if (destination != null) {
      details.add('destination=(${destination.col},${destination.row})');
    }
  }

  return '$description [${details.join('; ')}]';
}
