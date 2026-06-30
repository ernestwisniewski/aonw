part of 'movement_reducer.dart';

abstract final class _MovePreviewReducer {
  static GameStateTransition setPreview(
    GameState state,
    GameUnit selected,
    TileData targetTile,
    MapData mapData, {
    required GameCommandContext context,
  }) {
    final visibility = context.visibilityFor(state);
    final prePlanFeedback = _blockedFeedback(
      state: state,
      unit: selected,
      targetTile: targetTile,
      visibility: visibility,
      includeGeneric: false,
    );
    if (prePlanFeedback != null) {
      return GameStateTransition(state: state, uiEffects: [prePlanFeedback]);
    }

    final plan = UnitMovementPlanner(
      mapData: mapData,
      units: state.units,
      canEnterTile: (tile) => UnitMovementVisibilityRules.canPlanThroughTile(
        unit: selected,
        tile: tile,
        visibility: visibility,
      ),
    ).planMove(unit: selected, targetTile: targetTile);

    if (plan == null) {
      final feedback = _blockedFeedback(
        state: state,
        unit: selected,
        targetTile: targetTile,
        visibility: visibility,
        includeGeneric: true,
      );
      return GameStateTransition(
        state: state,
        uiEffects: feedback == null ? const [] : [feedback],
      );
    }
    if (!UnitMovementFeasibility.canEventuallyTraverse(
      unit: selected,
      plan: plan,
      canEnterStepBeyondCapacity: (step) =>
          MovementReducer._canCarryArtifactIntoTargetCity(
            state: state,
            unit: selected,
            targetTile: targetTile,
            step: step,
          ),
    )) {
      return GameStateTransition(
        state: state,
        uiEffects: const [
          ShowHudFeedbackEffect(
            reason: HudFeedbackReason.movementInsufficientUnitMovement,
          ),
        ],
      );
    }

    final tile = mapData.tileAt(selected.col, selected.row);
    final next = state.copyWithInteraction(
      movePreview: plan,
      selection: GameSelection.unit(selected, tile: tile),
    );
    return GameStateTransition(state: next);
  }

  static GameStateTransition confirmPreview(
    GameState state,
    MapData mapData, {
    required FogOfWarService fogOfWarService,
  }) {
    final preview = state.movePreview;
    final selected = state.selectedUnit;

    if (preview == null || selected == null || selected.id != preview.unitId) {
      return GameStateTransition(
        state: MovementReducer._clearMoveTargeting(state),
      );
    }

    final isPartialMove = preview.totalCost > preview.availableMovementPoints;
    final stepsForAnimation = isPartialMove
        ? preview.reachableSteps.skip(1).toList()
        : preview.steps.skip(1).toList();

    final workState = state.copyWithInteraction(movePreview: null);

    // The preview has already applied visibility checks; execution re-plans
    // against current blockers so queued moves cannot walk through new units.
    final targetTile = mapData.tileAt(preview.targetCol, preview.targetRow);
    if (targetTile == null) {
      return GameStateTransition(
        state: MovementReducer._clearMoveTargeting(workState),
      );
    }

    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: state.units,
    ).plan(unit: selected, targetTile: targetTile);

    if (plan == null) {
      if (isPartialMove ||
          preview.totalCost > preview.availableMovementPoints) {
        final queued = QueuedMovePath(
          targetCol: preview.targetCol,
          targetRow: preview.targetRow,
          steps: preview.steps,
        );
        final withPath = selected
            .copyWith(posture: UnitPosture.active)
            .copyWithQueuedPath(queued);
        final updatedUnits = replaceUnit(workState.units, withPath);
        var next = MovementReducer._clearMoveTargeting(
          workState,
        ).copyWith(units: updatedUnits);
        final tile = mapData.tileAt(withPath.col, withPath.row);
        next = next.copyWithInteraction(
          selection: GameSelection.unit(withPath, tile: tile),
        );
        return GameStateTransition(state: next);
      }
      return GameStateTransition(
        state: MovementReducer._clearMoveTargeting(workState),
      );
    }

    final reachable = plan.canMoveNow;
    final destinationStep = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;

    if (destinationStep == null ||
        (destinationStep.col == selected.col &&
            destinationStep.row == selected.row)) {
      final queued = QueuedMovePath(
        targetCol: preview.targetCol,
        targetRow: preview.targetRow,
        steps: preview.steps,
      );
      final withPath = selected
          .copyWith(posture: UnitPosture.active)
          .copyWithQueuedPath(queued);
      final updatedUnits = replaceUnit(workState.units, withPath);
      var next = MovementReducer._clearMoveTargeting(
        workState,
      ).copyWith(units: updatedUnits);
      final tile = mapData.tileAt(withPath.col, withPath.row);
      next = next.copyWithInteraction(
        selection: GameSelection.unit(withPath, tile: tile),
      );
      return GameStateTransition(state: next);
    }

    final moved = selected.copyWith(
      col: destinationStep.col,
      row: destinationStep.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      posture: UnitPosture.active,
    );

    final movedWithPath = isPartialMove
        ? moved.copyWithQueuedPath(
            QueuedMovePath(
              targetCol: preview.targetCol,
              targetRow: preview.targetRow,
              steps: preview.steps,
            ),
          )
        : moved.copyWithQueuedPath(null);

    final updatedUnits = replaceUnit(workState.units, movedWithPath);

    final newFog = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: knownPlayerIds(state),
      units: updatedUnits,
      cities: state.cities,
    );

    final destTile = mapData.tileAt(movedWithPath.col, movedWithPath.row);
    final keepMoveTargetingActive = !isPartialMove;
    var next = withDiscoveredDiplomaticContacts(
      workState
          .copyWith(units: updatedUnits, fogOfWar: newFog)
          .copyWithInteraction(moveCommandActive: keepMoveTargetingActive),
    );
    next = next.copyWithInteraction(
      selection: GameSelection.unit(movedWithPath, tile: destTile),
    );

    return GameStateTransition(
      state: next,
      uiEffects: [
        if (stepsForAnimation.isNotEmpty)
          AnimateUnitMoveEffect(
            unitId: selected.id,
            fromCol: selected.col,
            fromRow: selected.row,
            steps: stepsForAnimation,
          ),
      ],
    );
  }

  static ShowHudFeedbackEffect? _blockedFeedback({
    required GameState state,
    required GameUnit unit,
    required TileData targetTile,
    required FogVisibilityQuery visibility,
    required bool includeGeneric,
  }) {
    final fogTracksPlayer =
        visibility.isEnabled &&
        visibility.state.playerIds.contains(visibility.playerId);
    final tileVisibility = visibility.visibilityForTile(targetTile);
    final targetIsKnown = !fogTracksPlayer || tileVisibility.isKnown;
    final targetDynamicVisible = !fogTracksPlayer || tileVisibility.isVisible;

    final targetBlocker = state.units.unitAt(targetTile.col, targetTile.row);
    if (targetBlocker != null && targetBlocker.id != unit.id) {
      if (targetBlocker.ownerPlayerId != unit.ownerPlayerId &&
          !targetDynamicVisible) {
        // Enemy units are dynamic information and must not be revealed by
        // movement feedback while their tile is under fog.
      } else {
        final city = state.cityAt(targetTile.col, targetTile.row);
        if (city != null) {
          return const ShowHudFeedbackEffect(
            reason: HudFeedbackReason.movementCityOccupied,
          );
        }
        if (targetBlocker.ownerPlayerId != unit.ownerPlayerId) {
          return const ShowHudFeedbackEffect(
            reason: HudFeedbackReason.movementEnemyOccupied,
          );
        }
        return null;
      }
    }

    if (targetIsKnown &&
        MovementReducer._blocksForeignCityCenter(
          state,
          unit,
          targetTile.col,
          targetTile.row,
        )) {
      return const ShowHudFeedbackEffect(
        reason: HudFeedbackReason.movementForeignCity,
      );
    }

    if (fogTracksPlayer && !tileVisibility.isKnown) {
      final distance = HexDistance.between(
        HexCoordinate(col: unit.col, row: unit.row),
        HexCoordinate.fromTile(targetTile),
      );
      if (distance > UnitMovementVisibilityRules.hiddenPathingRange) {
        return const ShowHudFeedbackEffect(
          reason: HudFeedbackReason.movementHiddenRouteTooFar,
        );
      }
    }

    if (targetIsKnown &&
        UnitMovementCostRules.costToEnterTile(
          targetTile,
          unitType: unit.type,
        ).blocked) {
      return const ShowHudFeedbackEffect(
        reason: HudFeedbackReason.movementBlockedTerrain,
      );
    }

    if (!includeGeneric) return null;

    return const ShowHudFeedbackEffect(
      reason: HudFeedbackReason.movementNoRoute,
    );
  }
}
