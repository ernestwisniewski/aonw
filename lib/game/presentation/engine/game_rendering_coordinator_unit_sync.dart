part of 'game_rendering_coordinator.dart';

extension _GameRenderingCoordinatorUnitSync on GameRenderingCoordinator {
  void _syncThreatOverlay(
    GameClientState state, {
    required bool enabled,
    required bool dimmed,
  }) {
    if (!enabled) {
      threatOverlay.clear();
      return;
    }
    threatOverlay.sync(
      parent: grid,
      state: state,
      mapData: grid.mapData,
      dimmed: dimmed,
    );
  }

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
      attackTargetUnitIds: _attackTargetUnitIds(state),
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

  Set<String> _attackTargetUnitIds(GameClientState state) {
    final attacker = _planningMarkers.selectedAttackTargetingUnit(state);
    if (attacker == null) return const {};

    return {
      for (final unit in state.unitsVisibleToActivePlayer)
        if (unit.ownerPlayerId != attacker.ownerPlayerId)
          if (grid.mapData.tileAt(unit.col, unit.row) case final tile?)
            if (_planningMarkers.canAttackTargetTile(state, attacker, tile))
              unit.id,
    };
  }

  void _syncMovePreview(
    GameClientState state,
    Component parent, {
    required bool dimmed,
  }) {
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

  bool _shouldShowThreatOverlay(GameClientState state) {
    return state.interactionMode == GameInteractionMode.attackTargeting;
  }

  bool _shouldDimThreatOverlay(GameClientState state) {
    return state.interactionMode != GameInteractionMode.attackTargeting;
  }
}
