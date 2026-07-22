part of 'movement_reducer.dart';

abstract final class _MovePreviewReducer {
  static GameStateTransition setPreview(
    GameState state,
    GameUnit selected,
    MapTileView targetTile,
    MapTraversalView mapView, {
    required GameCommandContext context,
  }) {
    final planning = _previewVisibility(state, selected, context);
    final prePlanFeedback = _blockedFeedback(
      state: state,
      unit: selected,
      targetTile: targetTile,
      visibility: planning.visibility,
      includeGeneric: false,
    );
    if (prePlanFeedback != null) {
      return GameStateTransition(state: state, uiEffects: [prePlanFeedback]);
    }

    final plan = _planPreview(
      state: state,
      selected: selected,
      targetTile: targetTile,
      mapView: mapView,
      actorPlayerId: planning.actorPlayerId,
      visibility: planning.visibility,
    );

    if (plan == null) {
      return _noPlanTransition(
        state: state,
        selected: selected,
        targetTile: targetTile,
        visibility: planning.visibility,
      );
    }
    if (!_canPreviewEventuallyTraverse(
      state: state,
      selected: selected,
      plan: plan,
      targetTile: targetTile,
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

    final next = state.copyWithInteraction(
      movePreview: plan,
      selection: _MoveSelection.forUnit(state, selected, mapView),
    );
    return GameStateTransition(state: next);
  }

  static ({String actorPlayerId, FogVisibilityQuery visibility})
  _previewVisibility(
    GameState state,
    GameUnit selected,
    GameCommandContext context,
  ) {
    final actorPlayerId = context.hasActor
        ? context.actorPlayerId!
        : state.activePlayerId.isNotEmpty
        ? state.activePlayerId
        : selected.ownerPlayerId;
    return (
      actorPlayerId: actorPlayerId,
      visibility: UnitMovementVisibilityRules.visibilityForActor(
        fogOfWar: state.fogOfWar,
        actorPlayerId: actorPlayerId,
        ignoreDynamicFog: context.ignoreFogOfWar,
      ),
    );
  }

  static GameStateTransition _noPlanTransition({
    required GameState state,
    required GameUnit selected,
    required MapTileView targetTile,
    required FogVisibilityQuery visibility,
  }) {
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

  static bool _canPreviewEventuallyTraverse({
    required GameState state,
    required GameUnit selected,
    required UnitMovementPlan plan,
    required MapTileView targetTile,
  }) {
    return UnitMovementFeasibility.canEventuallyTraverse(
      unit: selected,
      plan: plan,
      canEnterStepBeyondCapacity: (step) =>
          MovementReducer._canCarryArtifactIntoTargetCity(
            state: state,
            unit: selected,
            targetTile: targetTile,
            step: step,
          ),
    );
  }

  static UnitMovementPlan? _planPreview({
    required GameState state,
    required GameUnit selected,
    required MapTileView targetTile,
    required MapTraversalView mapView,
    required String actorPlayerId,
    required FogVisibilityQuery visibility,
  }) {
    return UnitMovementPlanner(
      mapData: mapView,
      units: UnitMovementVisibilityRules.planningUnitsForActor(
        units: state.units,
        movingUnit: selected,
        actorPlayerId: actorPlayerId,
        visibility: visibility,
      ),
      canEnterTile: (tile) =>
          UnitMovementVisibilityRules.canPlanThroughTile(
            unit: selected,
            tile: tile,
            visibility: visibility,
          ) &&
          MovementHiddenObstacleRules.canPlanThroughCity(
            cities: state.cities,
            diplomacy: state.diplomacy,
            unit: selected,
            tile: tile,
            visibility: visibility,
          ),
    ).planMove(unit: selected, targetTile: targetTile);
  }

  static GameStateTransition confirmPreview(
    GameState state,
    MapTraversalView mapView, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
  }) {
    final preview = state.movePreview;
    final selected = state.selectedUnit;

    if (preview == null || selected == null || selected.id != preview.unitId) {
      return GameStateTransition(
        state: MovementReducer._clearMoveTargeting(state),
      );
    }

    final workState = state.copyWithInteraction(movePreview: null);
    final transition = MovementReducer.moveUnit(
      workState,
      MoveUnitCommand(selected.id, preview.targetCol, preview.targetRow),
      mapView,
      context: context,
      fogOfWarService: fogOfWarService,
    );
    final updatedUnit = transition.state.unitById(selected.id);
    final completedNow = updatedUnit != null && updatedUnit.queuedPath == null;
    final next = identical(transition.state, workState)
        ? MovementReducer._clearMoveTargeting(transition.state)
        : transition.state.copyWithInteraction(
            moveCommandActive: completedNow,
            movePreview: null,
          );

    return GameStateTransition(
      state: next,
      events: transition.events,
      uiEffects: transition.uiEffects,
    );
  }

  static ShowHudFeedbackEffect? _blockedFeedback({
    required GameState state,
    required GameUnit unit,
    required MapTileView targetTile,
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

    if (targetDynamicVisible &&
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
