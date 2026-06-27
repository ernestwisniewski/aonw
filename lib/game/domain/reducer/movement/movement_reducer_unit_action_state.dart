part of 'movement_reducer.dart';

final class _UnitActionStateCleanup {
  _UnitActionStateCleanup(
    this.state,
    this.previousUnit,
    this.updatedUnit,
    this.mapData,
  );

  GameState state;
  final GameUnit previousUnit;
  final GameUnit updatedUnit;
  final MapData mapData;

  void replaceUpdatedUnitIfChanged() {
    if (updatedUnit != previousUnit) {
      state = state.copyWith(units: replaceUnit(state.units, updatedUnit));
    }
  }

  void cancelArtifactExcavation() {
    final artifactId = previousUnit.excavatingArtifactId;
    if (artifactId == null) return;

    state = state.copyWith(
      artifacts: [
        for (final artifact in state.artifacts)
          if (artifact.id == artifactId && artifact.location.isBeingExcavated)
            artifact.copyWith(
              location: WorldArtifactLocation.map(
                col: artifact.location.col ?? previousUnit.col,
                row: artifact.location.row ?? previousUnit.row,
              ),
            )
          else
            artifact,
      ],
    );
  }

  void clearMoveTargetingOwnedByUnit() {
    if (MovementReducer._moveStateBelongsToUnit(state, previousUnit.id)) {
      state = MovementReducer._clearMoveTargeting(state);
    }
  }

  void clearPendingActionOwnedByUnit() {
    if (state.pendingAction?.ownsUnit(previousUnit.id) ?? false) {
      state = state.copyWithInteraction(pendingAction: null);
    }
  }

  void clearCityFoundingDraftOwnedByUnit() {
    if (state.cityFoundingDraft?.unitId == previousUnit.id) {
      state = state.copyWithInteraction(cityFoundingDraft: null);
    }
  }

  void refreshSelection() {
    if (state.selectedUnitId == previousUnit.id) {
      state = MovementReducer._selectUpdatedUnit(state, updatedUnit, mapData);
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
