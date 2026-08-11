part of 'game_rendering_coordinator.dart';

extension _GameRenderingCoordinatorUnitSync on GameRenderingCoordinator {
  void _syncUnitMarkers(GameClientState state, Component world) {
    final cityTiles = {
      for (final city in state.citiesKnownToActivePlayer)
        (col: city.center.col, row: city.center.row),
    };
    unitMarkers.sync(
      parent: world,
      units: state.unitsVisibleToActivePlayer,
      selectedUnitId: state.selectedUnitId,
      pendingAction: state.pendingAction,
      attackTargetUnitIds: const {},
      cityTiles: cityTiles,
      artifactExcavationTurnsByUnitId: _artifactExcavationTurnsByUnitId(state),
    );
  }

  Map<String, int> _artifactExcavationTurnsByUnitId(GameClientState state) {
    return {
      for (final artifact in state.artifacts)
        if (artifact.location.isBeingExcavated &&
            artifact.location.unitId != null)
          artifact.location.unitId!: artifact.location.remainingTurns,
    };
  }

  void _syncMovePreview(
    GameClientState state,
    Component parent, {
    required bool dimmed,
  }) {
    if (state.interactionMode == GameInteractionMode.attackTargeting) {
      movePreview.clear();
      return;
    }
    final entries = <UnitMovePreviewLayerEntry>[];
    for (final unit in state.units) {
      final entry = UnitMovePreviewEntryBuilder.queuedPath(
        state: state,
        unit: unit,
        dimmed: dimmed,
      );
      if (entry != null) entries.add(entry);
    }

    final activePreview = state.movePreview;
    if (activePreview != null &&
        _canShowPathForUnit(state, activePreview.unitId)) {
      final selected = state.selectedUnitId == activePreview.unitId;
      final unit = state.unitById(activePreview.unitId);
      entries
        ..removeWhere((entry) => entry.preview.unitId == activePreview.unitId)
        ..add(
          UnitMovePreviewLayerEntry(
            id: 'active:${activePreview.unitId}',
            preview: activePreview,
            unitType: unit?.type,
            maxMovementPointsPerTurn: unit == null
                ? null
                : UnitMovePreviewEntryBuilder.maxMovementPoints(unit),
            dimmed: dimmed,
            subdued: !selected,
            showCostLabel: false,
            showConfirmationHint: selected,
            showTargetPulse: selected,
            showTargetArrow: false,
          ),
        );
    }

    movePreview.syncMany(parent: parent, previews: entries);
  }

  bool _canShowPathForUnit(GameClientState state, String unitId) {
    final unit = state.unitById(unitId);
    return unit != null && state.canControlUnit(unit);
  }
}
