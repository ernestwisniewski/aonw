part of 'movement_reducer.dart';

abstract final class _DirectMoveProcessor {
  static GameStateTransition run(
    GameState state,
    MoveUnitCommand command,
    MapData mapData, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
    required bool Function(TileData tile)? canEnterTile,
  }) {
    final validation = UnitCommandValidator.movableUnit(
      state,
      unitId: command.unitId,
      context: context,
    );
    if (validation is! ValidUnit) return GameStateTransition(state: state);

    final unit = validation.unit;
    final targetTile = _validTargetTile(state, unit, command, mapData);
    if (targetTile == null) return GameStateTransition(state: state);

    final plan = _DirectMovePlanFinder(
      state: state,
      unit: unit,
      targetTile: targetTile,
      mapData: mapData,
      context: context,
      canEnterTileOverride: canEnterTile,
    ).plan();
    if (plan == null) return GameStateTransition(state: state);

    if (!_canTraverseEventually(state, unit, targetTile, plan)) {
      return _insufficientMovement(state);
    }

    final execution = _DirectMoveExecution.from(plan);
    if (execution.keepsUnitAtOrigin(unit)) {
      return MovementReducer._queueMovePath(state, unit, plan, mapData);
    }

    return _applyExecutedMove(
      state: state,
      unit: unit,
      movedUnit: execution.movedUnit(unit),
      animationSteps: execution.animationSteps,
      mapData: mapData,
      fogOfWarService: fogOfWarService,
    );
  }

  static TileData? _validTargetTile(
    GameState state,
    GameUnit unit,
    MoveUnitCommand command,
    MapData mapData,
  ) {
    final targetTile = mapData.tileAt(command.targetCol, command.targetRow);
    if (targetTile == null) return null;
    if (unit.occupies(targetTile.col, targetTile.row)) return null;
    if (MovementReducer._blocksForeignCityCenter(
      state,
      unit,
      targetTile.col,
      targetTile.row,
    )) {
      return null;
    }
    return targetTile;
  }

  static bool _canTraverseEventually(
    GameState state,
    GameUnit unit,
    TileData targetTile,
    UnitMovementPlan plan,
  ) {
    return UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
      canEnterStepBeyondCapacity: (step) =>
          MovementReducer._canCarryArtifactIntoTargetCity(
            state: state,
            unit: unit,
            targetTile: targetTile,
            step: step,
          ),
    );
  }

  static GameStateTransition _insufficientMovement(GameState state) {
    return GameStateTransition(
      state: state,
      uiEffects: const [
        ShowHudFeedbackEffect(
          reason: HudFeedbackReason.movementInsufficientUnitMovement,
        ),
      ],
    );
  }

  static GameStateTransition _applyExecutedMove({
    required GameState state,
    required GameUnit unit,
    required GameUnit movedUnit,
    required List<UnitMovementStep> animationSteps,
    required MapData mapData,
    required FogOfWarService fogOfWarService,
  }) {
    final updatedUnits = replaceUnit(state.units, movedUnit);
    final newFog = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: knownPlayerIds(state),
      units: updatedUnits,
      cities: state.cities,
    );

    var next = withDiscoveredDiplomaticContacts(
      state.copyWith(units: updatedUnits, fogOfWar: newFog),
    ).copyWithInteraction(movePreview: null);

    if (state.selectedUnitId == unit.id) {
      next = next.copyWithInteraction(
        selection: GameSelection.unit(
          movedUnit,
          tile: mapData.tileAt(movedUnit.col, movedUnit.row),
        ),
      );
    }

    return GameStateTransition(
      state: next,
      uiEffects: [
        if (animationSteps.isNotEmpty)
          AnimateUnitMoveEffect(
            unitId: unit.id,
            fromCol: unit.col,
            fromRow: unit.row,
            steps: animationSteps,
          ),
      ],
      events: [
        UnitMovedEvent(
          unitId: unit.id,
          fromCol: unit.col,
          fromRow: unit.row,
          toCol: movedUnit.col,
          toRow: movedUnit.row,
        ),
      ],
    );
  }
}

final class _DirectMovePlanFinder {
  _DirectMovePlanFinder({
    required this.state,
    required this.unit,
    required this.targetTile,
    required this.mapData,
    required this.context,
    required this.canEnterTileOverride,
  });

  final GameState state;
  final GameUnit unit;
  final TileData targetTile;
  final MapData mapData;
  final GameCommandContext context;
  final bool Function(TileData tile)? canEnterTileOverride;

  UnitMovementPlan? plan() {
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: state.units,
      canEnterTile: _canEnterTile,
    );

    return pathfinder.plan(unit: unit, targetTile: targetTile) ??
        _approachBlockedTarget(pathfinder);
  }

  bool _canEnterTile(TileData tile) {
    final override = canEnterTileOverride;
    if (override != null) return override(tile);
    return UnitMovementVisibilityRules.canPlanThroughTile(
      unit: unit,
      tile: tile,
      visibility: context.visibilityFor(state),
    );
  }

  UnitMovementPlan? _approachBlockedTarget(UnitMovementPathfinder pathfinder) {
    final blocker = state.units.unitAt(targetTile.col, targetTile.row);
    if (blocker == null || blocker.id == unit.id) return null;

    final approach = pathfinder.planTowardBlockedTarget(
      unit: unit,
      targetTile: targetTile,
    );
    if (approach == null) return null;

    return _shouldUseApproach(blocker, approach) ? approach : null;
  }

  bool _shouldUseApproach(GameUnit blocker, UnitMovementPlan approach) {
    return _targetIsHidden ||
        _targetIsBlockedByOpponent(blocker) ||
        _approachCostsMoreThanCurrentTurn(approach);
  }

  bool get _targetIsHidden {
    return !context
        .visibilityFor(state)
        .canSeeDynamicAt(targetTile.col, targetTile.row);
  }

  bool _targetIsBlockedByOpponent(GameUnit blocker) {
    return blocker.ownerPlayerId != unit.ownerPlayerId;
  }

  bool _approachCostsMoreThanCurrentTurn(UnitMovementPlan approach) {
    return approach.totalCost > unit.movementPoints;
  }
}

final class _DirectMoveExecution {
  _DirectMoveExecution({
    required this.plan,
    required this.destinationStep,
    required this.animationSteps,
  });

  factory _DirectMoveExecution.from(UnitMovementPlan plan) {
    final reachesTarget = plan.canMoveNow;
    return _DirectMoveExecution(
      plan: plan,
      destinationStep: reachesTarget
          ? plan.steps.last
          : plan.furthestReachableStep,
      animationSteps: reachesTarget
          ? plan.steps.skip(1).toList()
          : plan.reachableSteps.skip(1).toList(),
    );
  }

  final UnitMovementPlan plan;
  final UnitMovementStep? destinationStep;
  final List<UnitMovementStep> animationSteps;

  bool keepsUnitAtOrigin(GameUnit unit) {
    final step = destinationStep;
    return step == null || unit.occupies(step.col, step.row);
  }

  GameUnit movedUnit(GameUnit unit) {
    final step = destinationStep!;
    final moved = unit.copyWith(
      col: step.col,
      row: step.row,
      movementPoints: plan.remainingMovementPointsAfterStep(step),
      posture: UnitPosture.active,
    );
    return plan.canMoveNow
        ? moved.copyWithQueuedPath(null)
        : moved.copyWithQueuedPath(MovementReducer._queuedPathFor(plan));
  }
}
