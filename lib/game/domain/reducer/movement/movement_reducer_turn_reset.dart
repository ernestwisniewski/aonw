part of 'movement_reducer.dart';

abstract final class _MovementTurnResetProcessor {
  static GameStateTransition run(
    GameState state,
    MapTraversalView mapView, {
    required String? playerId,
    required FogOfWarService fogOfWarService,
  }) {
    state = _withoutResetPlayerTurnInteraction(state, playerId);
    final currentUnits = state.units;

    final resetUnits = [
      for (final unit in currentUnits)
        (playerId == null || unit.ownerPlayerId == playerId)
            ? UnitMovementTurnRules.resetForNewTurn(unit)
            : unit,
    ];

    var mpChanged = false;
    for (var i = 0; i < resetUnits.length; i++) {
      if (resetUnits[i].movementPoints != currentUnits[i].movementPoints) {
        mpChanged = true;
        break;
      }
    }

    final finalUnits = <GameUnit>[];
    final animationEffects = <AnimateUnitMoveEffect>[];
    var pathsInvalidated = false;

    for (var i = 0; i < resetUnits.length; i++) {
      final unit = resetUnits[i];

      if (playerId != null && unit.ownerPlayerId != playerId) {
        finalUnits.add(unit);
        continue;
      }

      // Pathfinding must account for units already moved earlier in this pass.
      final currentAllUnits = [...finalUnits, ...resetUnits.sublist(i)];

      final routed = MerchantTradeRouteRules.advanceUnit(
        unit: unit,
        units: currentAllUnits,
        cities: state.cities,
        mapData: mapView,
      );
      if (routed.routeInvalidated) pathsInvalidated = true;
      if (routed.unit.type == GameUnitType.merchant &&
          routed.unit.merchantTradeRoute != null) {
        finalUnits.add(routed.unit);
        if (routed.movedSteps.isNotEmpty) {
          animationEffects.add(
            AnimateUnitMoveEffect(
              unitId: unit.id,
              fromCol: unit.col,
              fromRow: unit.row,
              steps: routed.movedSteps,
            ),
          );
        }
        continue;
      }

      final validated = UnitMovementTurnRules.validateQueuedPath(
        unit: routed.unit,
        mapData: mapView,
        allUnits: currentAllUnits,
        cities: state.cities,
        diplomacy: state.diplomacy,
        fogOfWar: state.fogOfWar,
      );
      if (validated.queuedPath == null) {
        if (unit.queuedPath != null) pathsInvalidated = true;
        finalUnits.add(validated);
        continue;
      }

      final replan = _replanQueuedPath(
        state: state,
        unit: validated,
        allUnits: currentAllUnits,
        mapView: mapView,
      );
      final plan = replan.plan;
      if (plan == null) {
        finalUnits.add(replan.stoppedUnit!);
        continue;
      }

      if (validated.isFortified) {
        finalUnits.add(validated.copyWithQueuedPath(null));
        continue;
      }

      final reachable = plan.canMoveNow;
      final destinationStep = reachable
          ? plan.steps.last
          : plan.furthestReachableStep;

      if (destinationStep == null ||
          (destinationStep.col == validated.col &&
              destinationStep.row == validated.row)) {
        finalUnits.add(validated);
        continue;
      }

      final stepsForAnimation = reachable
          ? plan.steps.skip(1).toList()
          : plan.reachableSteps.skip(1).toList();

      final moved = validated.copyWith(
        col: destinationStep.col,
        row: destinationStep.row,
        movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      );

      final movedWithPath = reachable
          ? moved.copyWithQueuedPath(null)
          : moved.copyWithQueuedPath(validated.queuedPath);

      finalUnits.add(movedWithPath);
      if (stepsForAnimation.isNotEmpty) {
        animationEffects.add(
          AnimateUnitMoveEffect(
            unitId: validated.id,
            fromCol: validated.col,
            fromRow: validated.row,
            steps: stepsForAnimation,
          ),
        );
      }
    }

    var workingUnits = finalUnits;
    var workingFog = state.fogOfWar;
    if (mpChanged || animationEffects.isNotEmpty || pathsInvalidated) {
      workingFog = fogOfWarService.recompute(
        current: state.fogOfWar,
        mapData: mapView,
        playerIds: knownPlayerIds(state),
        units: workingUnits,
        cities: state.cities,
      );
    }

    final autoInput = withDiscoveredDiplomaticContacts(
      state.copyWith(units: workingUnits, fogOfWar: workingFog),
    );
    final autoExplore = _AutoExploreProcessor.advanceForNewTurn(
      state: autoInput,
      mapView: mapView,
      resetPlayerId: playerId,
      fogOfWarService: fogOfWarService,
    );
    workingUnits = autoExplore.units;
    workingFog = autoExplore.fogOfWar;
    _TurnProjection.apply(animationEffects, autoExplore.executions);
    final interaction = autoExplore.interaction;
    final contactsChanged = autoInput.diplomacy != state.diplomacy;
    final interactionChanged = _TurnProjection.changed(state, interaction);
    final changed =
        mpChanged ||
        animationEffects.isNotEmpty ||
        pathsInvalidated ||
        _TurnProjection.hasContinuationChanged(
          contactsChanged,
          interactionChanged,
        ) ||
        autoExplore.changed;
    if (!changed) {
      return _TurnProjection.unchangedTurn(
        state: state,
        currentUnits: currentUnits,
        mapView: mapView,
        playerId: playerId,
      );
    }
    return _TurnProjection.project(
      state: state,
      units: workingUnits,
      fogOfWar: workingFog,
      autoExplore: autoExplore,
      animationEffects: animationEffects,
      interactionChanged: interactionChanged,
      mapView: mapView,
      playerId: playerId,
    );
  }

  static _QueuedPathReplan _replanQueuedPath({
    required GameState state,
    required GameUnit unit,
    required List<GameUnit> allUnits,
    required MapTraversalView mapView,
  }) {
    final path = unit.queuedPath!;
    final targetTile = mapView.tileAt(path.targetCol, path.targetRow);
    if (targetTile == null) {
      return _QueuedPathReplan.stopped(unit.copyWithQueuedPath(null));
    }

    final visibility = UnitMovementVisibilityRules.visibilityForActor(
      fogOfWar: state.fogOfWar,
      actorPlayerId: unit.ownerPlayerId,
    );
    final plan = _planQueuedPath(
      state: state,
      unit: unit,
      allUnits: allUnits,
      mapView: mapView,
      targetTile: targetTile,
      visibility: visibility,
    );
    if (plan == null) {
      return _QueuedPathReplan.stopped(unit.copyWithQueuedPath(null));
    }
    if (MovementHiddenObstacleRules.reachablePathHitsHiddenBlocker(
      plan: plan,
      movingUnit: unit,
      allUnits: allUnits,
      cities: state.cities,
      diplomacy: state.diplomacy,
      visibility: visibility,
    )) {
      return _QueuedPathReplan.stopped(unit);
    }
    return _QueuedPathReplan.ready(plan);
  }

  static UnitMovementPlan? _planQueuedPath({
    required GameState state,
    required GameUnit unit,
    required List<GameUnit> allUnits,
    required MapTraversalView mapView,
    required MapTileView targetTile,
    required FogVisibilityQuery visibility,
  }) {
    return UnitMovementPathfinder(
      mapData: mapView,
      units: UnitMovementVisibilityRules.planningUnitsForActor(
        units: allUnits,
        movingUnit: unit,
        actorPlayerId: unit.ownerPlayerId,
        visibility: visibility,
      ),
      canEnterTile: (tile) => MovementHiddenObstacleRules.canPlanThroughCity(
        cities: state.cities,
        diplomacy: state.diplomacy,
        unit: unit,
        tile: tile,
        visibility: visibility,
      ),
      canEnterOccupiedTile:
          ({
            required movingUnit,
            required blockingUnit,
            required col,
            required row,
          }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
            movingUnit: movingUnit,
            col: col,
            row: row,
            cities: state.cities,
          ),
    ).plan(unit: unit, targetTile: targetTile);
  }

  static GameState _refreshSelectedUnit(
    GameState state,
    List<GameUnit> units,
    MapTileLookup mapTiles, {
    String? resetPlayerId,
  }) {
    var next = state;
    final selectedId = state.selectedUnitId;
    if (selectedId != null) {
      for (final unit in units) {
        if (unit.id == selectedId) {
          next = MovementReducer._selectUpdatedUnit(next, unit, mapTiles);
          final unitWasReset =
              resetPlayerId == null || unit.ownerPlayerId == resetPlayerId;
          if (unitWasReset &&
              MovementReducer._canAutoActivateMoveTargeting(next, unit)) {
            next = next.copyWithInteraction(
              movePreview: null,
              moveCommandActive: true,
            );
          }
          break;
        }
      }
    }

    return next;
  }

  static GameState _withoutResetPlayerTurnInteraction(
    GameState state,
    String? resetPlayerId,
  ) {
    final pendingAction = state.pendingAction;
    final clearTurnSkip =
        pendingAction is PendingUnitTurnSkip &&
        (resetPlayerId == null || pendingAction.ownerPlayerId == resetPlayerId);

    final movePreview = state.movePreview;
    final previewUnit = movePreview == null
        ? null
        : state.unitById(movePreview.unitId);
    final clearMovePreview =
        movePreview != null &&
        (previewUnit == null ||
            state.selectedUnitId != movePreview.unitId ||
            resetPlayerId == null ||
            previewUnit.ownerPlayerId == resetPlayerId);

    final selectedUnit = state.selectedUnit;
    final deactivateMoveCommand =
        state.moveCommandActive &&
        (selectedUnit == null ||
            resetPlayerId == null ||
            clearMovePreview ||
            selectedUnit.ownerPlayerId == resetPlayerId);

    if (!clearTurnSkip && !clearMovePreview && !deactivateMoveCommand) {
      return state;
    }
    return state.copyWithInteraction(
      movePreview: clearMovePreview ? null : movePreview,
      pendingAction: clearTurnSkip ? null : pendingAction,
      moveCommandActive: deactivateMoveCommand ? false : null,
    );
  }
}

abstract final class _TurnProjection {
  static void apply(
    List<AnimateUnitMoveEffect> effects,
    List<MovementCommandExecution> executions,
  ) {
    effects.addAll(animationEffectsFor(executions));
  }

  static List<AnimateUnitMoveEffect> animationEffectsFor(
    List<MovementCommandExecution> executions,
  ) {
    return [
      for (final execution in executions)
        AnimateUnitMoveEffect(
          unitId: execution.unitId,
          fromCol: execution.fromCol,
          fromRow: execution.fromRow,
          steps: execution.steps,
        ),
    ];
  }

  static bool changed(GameState state, PersistedInteractionState interaction) {
    return interaction.cityFoundingDraft != state.cityFoundingDraft ||
        interaction.pendingAction != state.pendingAction;
  }

  static bool hasContinuationChanged(
    bool contactsChanged,
    bool interactionChanged,
  ) => contactsChanged || interactionChanged;

  static GameStateTransition unchangedTurn({
    required GameState state,
    required List<GameUnit> currentUnits,
    required MapTraversalView mapView,
    required String? playerId,
  }) {
    return GameStateTransition(
      state: _MovementTurnResetProcessor._refreshSelectedUnit(
        state,
        currentUnits,
        mapView,
        resetPlayerId: playerId,
      ),
    );
  }

  static GameStateTransition project({
    required GameState state,
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required TurnAutoExploreAdvance autoExplore,
    required List<AnimateUnitMoveEffect> animationEffects,
    required bool interactionChanged,
    required MapTraversalView mapView,
    required String? playerId,
  }) {
    var projected = state.copyWith(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: autoExplore.diplomacy,
    );
    if (interactionChanged) {
      projected = projected.copyWithInteraction(
        cityFoundingDraft: autoExplore.interaction.cityFoundingDraft,
        pendingAction: autoExplore.interaction.pendingAction,
      );
    }
    final next = _MovementTurnResetProcessor._refreshSelectedUnit(
      projected,
      units,
      mapView,
      resetPlayerId: playerId,
    );
    return GameStateTransition(
      state: next,
      events: autoExplore.events,
      uiEffects: animationEffects,
    );
  }
}

final class _QueuedPathReplan {
  const _QueuedPathReplan.ready(UnitMovementPlan this.plan)
    : stoppedUnit = null;

  const _QueuedPathReplan.stopped(GameUnit this.stoppedUnit) : plan = null;

  final UnitMovementPlan? plan;
  final GameUnit? stoppedUnit;
}
