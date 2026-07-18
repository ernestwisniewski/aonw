part of 'movement_reducer.dart';

PersistedInteractionState _persistedUnitActionInteraction(GameState state) {
  return PersistedInteractionState(
    cityFoundingDraft: state.cityFoundingDraft,
    pendingAction: state.pendingAction,
  );
}

GameState _applyUnitActionResult(
  GameState state,
  UnitActionCommandResult result,
) {
  final unitsChanged = !identical(result.units, state.units);
  final artifactsChanged = !identical(result.artifacts, state.artifacts);
  var next = switch ((unitsChanged, artifactsChanged)) {
    (true, true) => state.copyWith(
      units: result.units,
      artifacts: result.artifacts,
    ),
    (true, false) => state.copyWith(units: result.units),
    (false, true) => state.copyWith(artifacts: result.artifacts),
    (false, false) => state,
  };
  if (state.cityFoundingDraft == result.interaction.cityFoundingDraft &&
      state.pendingAction == result.interaction.pendingAction) {
    return next;
  }
  next = next.copyWithInteraction(
    cityFoundingDraft: result.interaction.cityFoundingDraft,
    pendingAction: result.interaction.pendingAction,
  );
  return next;
}

final class _UnitActionStateCleanup {
  _UnitActionStateCleanup(
    this.state,
    this.previousUnit,
    this.updatedUnit,
    this.mapTiles,
  );

  GameState state;
  final GameUnit previousUnit;
  final GameUnit updatedUnit;
  final MapTileLookup mapTiles;

  void clearMoveTargetingOwnedByUnit() {
    if (MovementReducer._moveStateBelongsToUnit(state, previousUnit.id)) {
      state = MovementReducer._clearMoveTargeting(state);
    }
  }

  void refreshSelection() {
    if (state.selectedUnitId == previousUnit.id) {
      final currentUnit = state.unitById(updatedUnit.id) ?? updatedUnit;
      state = MovementReducer._selectUpdatedUnit(state, currentUnit, mapTiles);
    }
  }

  void activateMoveTargetingWhenReady(bool shouldActivate) {
    if (!shouldActivate) return;
    if (state.selectedUnitId == previousUnit.id &&
        MovementReducer._canAutoActivateMoveTargeting(state, updatedUnit)) {
      state = state.copyWithInteraction(moveCommandActive: true);
    }
  }
}
