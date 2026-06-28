part of 'game_renderer.dart';

void _handleRendererUnitMarkerTapped(GameRenderer renderer, String unitId) {
  if (renderer._shouldSuppressTapAfterLongPress()) return;
  final unit = renderer._renderState.unitById(unitId);
  if (unit == null) {
    renderer._artifactTapCycle.clear();
    return;
  }

  renderer._artifactTapCycle.clear();
  unawaited(renderer.onCommand(TileTappedCommand(unit.col, unit.row)));
}

void _handleRendererArtifactMarkerTapped(
  GameRenderer renderer,
  WorldArtifact artifact,
) {
  if (renderer._shouldSuppressTapAfterLongPress()) return;
  final tile = _tileForArtifactLocation(renderer, artifact.location);
  if (tile == null) return;
  if (renderer._markerTapTargetsHex()) {
    renderer._artifactTapCycle.clear();
    unawaited(renderer.onCommand(TileTappedCommand(tile.col, tile.row)));
    return;
  }
  if (_handleStackedMapObjectTap(
    renderer,
    tile.col,
    tile.row,
    preferredArtifact: artifact,
    useTileTappedForHexTarget: true,
  )) {
    return;
  }
  final target = renderer._artifactTapCycle.nextTarget(artifact.id);
  if (target == ArtifactMarkerTapTarget.artifact &&
      renderer.onArtifactInspected != null) {
    renderer.onArtifactInspected?.call(
      artifact,
      renderer._inspectionAnchorForTile(tile),
    );
    return;
  }
  unawaited(renderer.onCommand(TileTappedCommand(tile.col, tile.row)));
}

void _handleRendererMapObjectiveMarkerTapped(
  GameRenderer renderer,
  MapObjectiveProgress progress,
) {
  if (renderer._shouldSuppressTapAfterLongPress()) return;
  final definition = progress.definition;
  final tile = renderer.mapData.tileAt(definition.hex.col, definition.hex.row);
  if (tile == null) return;
  if (renderer._markerTapTargetsHex()) {
    renderer._artifactTapCycle.clear();
    unawaited(renderer.onCommand(TileTappedCommand(tile.col, tile.row)));
    return;
  }

  if (_handleStackedMapObjectTap(
    renderer,
    tile.col,
    tile.row,
    preferredObjective: progress,
  )) {
    return;
  }

  final target = renderer._artifactTapCycle.nextTarget(
    _objectiveCycleId(definition.id),
  );
  if (target == ArtifactMarkerTapTarget.artifact &&
      renderer.onObjectiveInspected != null) {
    renderer.onObjectiveInspected?.call(
      progress,
      renderer._inspectionAnchorForTile(tile),
    );
    return;
  }
  unawaited(renderer.onCommand(SelectTileCommand(tile.col, tile.row)));
}

bool _handleStackedMapObjectTap(
  GameRenderer renderer,
  int col,
  int row, {
  String? preferredUnitId,
  WorldArtifact? preferredArtifact,
  MapObjectiveProgress? preferredObjective,
  bool includeTileInspection = false,
  bool preferOccupiedHexCycle = false,
  bool preferCityUnitTerrainCycle = false,
  bool useTileTappedForHexTarget = false,
}) {
  final tile = renderer.mapData.tileAt(col, row);
  if (tile == null) return false;

  final unit = preferredUnitId == null
      ? renderer._renderState.unitAt(col, row)
      : renderer._renderState.unitById(preferredUnitId);
  final artifact = preferredArtifact ?? _mapArtifactAt(renderer, col, row);
  final objective = preferredObjective ?? _mapObjectiveAt(renderer, col, row);
  final occupiedHexTapCycle =
      preferOccupiedHexCycle && unit != null && preferredUnitId == null;
  final cityUnitTerrainCycle =
      preferCityUnitTerrainCycle &&
      unit != null &&
      preferredUnitId == null &&
      renderer._renderState.selection?.type == GameSelectionType.unit &&
      renderer._renderState.selection?.unit?.id == unit.id;
  final hasInspectableObject =
      (artifact != null && renderer.onArtifactInspected != null) ||
      (objective != null && renderer.onObjectiveInspected != null);
  final canInspectTile =
      includeTileInspection &&
      renderer.onTileInspected != null &&
      (cityUnitTerrainCycle ||
          occupiedHexTapCycle ||
          hasInspectableObject ||
          renderer._renderState.selection?.type == GameSelectionType.tile);
  if (!cityUnitTerrainCycle &&
      !occupiedHexTapCycle &&
      !hasInspectableObject &&
      !canInspectTile) {
    return false;
  }

  final targets = cityUnitTerrainCycle
      ? <ArtifactMarkerTapTarget>[
          if (canInspectTile) ArtifactMarkerTapTarget.tileInspection,
          ArtifactMarkerTapTarget.hex,
        ]
      : occupiedHexTapCycle
      ? <ArtifactMarkerTapTarget>[
          ArtifactMarkerTapTarget.unit,
          ArtifactMarkerTapTarget.hex,
          if (canInspectTile) ArtifactMarkerTapTarget.tileInspection,
        ]
      : <ArtifactMarkerTapTarget>[
          if (unit != null) ArtifactMarkerTapTarget.unit,
          if (artifact != null && renderer.onArtifactInspected != null)
            ArtifactMarkerTapTarget.artifact,
          if (objective != null && renderer.onObjectiveInspected != null)
            ArtifactMarkerTapTarget.objective,
          if (canInspectTile) ArtifactMarkerTapTarget.tileInspection,
          ArtifactMarkerTapTarget.hex,
        ];
  final preferredFirstTarget = _preferredStackTarget(
    renderer,
    col,
    row,
    unit: unit,
    artifact: artifact,
    objective: objective,
    preferredArtifact: preferredArtifact,
    preferredObjective: preferredObjective,
    preferCityUnitTerrainCycle: cityUnitTerrainCycle,
    preferOccupiedHexCycle: occupiedHexTapCycle,
  );
  final target = renderer._artifactTapCycle.nextStackTarget(
    _mapStackCycleId(
      col,
      row,
      unitId: unit?.id,
      artifactId: artifact?.id,
      objectiveId: objective?.definition.id,
    ),
    targets: targets,
    preferredFirstTarget: preferredFirstTarget,
  );

  switch (target) {
    case ArtifactMarkerTapTarget.unit:
      if (unit == null) return false;
      if (renderer._isReady) renderer._focusUnit(unit);
      renderer._lastFocusedSelectionKey = 'unit:${unit.id}';
      unawaited(renderer.onCommand(SelectUnitCommand(unit.id)));
    case ArtifactMarkerTapTarget.artifact:
      if (artifact == null) return false;
      renderer.onArtifactInspected?.call(
        artifact,
        renderer._inspectionAnchorForTile(tile),
      );
    case ArtifactMarkerTapTarget.objective:
      if (objective == null) return false;
      renderer.onObjectiveInspected?.call(
        objective,
        renderer._inspectionAnchorForTile(tile),
      );
    case ArtifactMarkerTapTarget.tileInspection:
      renderer._handleTileInspected(tile);
    case ArtifactMarkerTapTarget.hex:
      unawaited(
        renderer.onCommand(
          useTileTappedForHexTarget
              ? TileTappedCommand(col, row)
              : SelectTileCommand(col, row),
        ),
      );
  }
  return true;
}

ArtifactMarkerTapTarget _preferredStackTarget(
  GameRenderer renderer,
  int col,
  int row, {
  required GameUnit? unit,
  required WorldArtifact? artifact,
  required MapObjectiveProgress? objective,
  required WorldArtifact? preferredArtifact,
  required MapObjectiveProgress? preferredObjective,
  required bool preferCityUnitTerrainCycle,
  required bool preferOccupiedHexCycle,
}) {
  if (preferCityUnitTerrainCycle) {
    return renderer._renderState.selection?.type == GameSelectionType.tile &&
            renderer._selectionMatchesTileCoordinates(col, row)
        ? ArtifactMarkerTapTarget.hex
        : ArtifactMarkerTapTarget.tileInspection;
  }
  if (preferOccupiedHexCycle) {
    if (unit != null && renderer._renderState.selectedUnitId != unit.id) {
      return ArtifactMarkerTapTarget.unit;
    }
    if (renderer._renderState.selection?.type == GameSelectionType.tile &&
        renderer._selectionMatchesTileCoordinates(col, row)) {
      return ArtifactMarkerTapTarget.tileInspection;
    }
    return ArtifactMarkerTapTarget.hex;
  }
  if (preferredArtifact != null) return ArtifactMarkerTapTarget.artifact;
  if (preferredObjective != null) return ArtifactMarkerTapTarget.objective;
  if (unit != null && renderer._renderState.selectedUnitId != unit.id) {
    return ArtifactMarkerTapTarget.unit;
  }
  if (renderer._selectionMatchesTileCoordinates(col, row)) {
    if (artifact != null) return ArtifactMarkerTapTarget.artifact;
    if (objective != null) return ArtifactMarkerTapTarget.objective;
    return ArtifactMarkerTapTarget.tileInspection;
  }
  return ArtifactMarkerTapTarget.unit;
}

WorldArtifact? _mapArtifactAt(GameRenderer renderer, int col, int row) {
  for (final artifact in renderer._renderState.artifacts) {
    final location = artifact.location;
    if ((location.kind == WorldArtifactLocationKind.map ||
            location.kind == WorldArtifactLocationKind.excavation) &&
        location.col == col &&
        location.row == row) {
      return artifact;
    }
  }
  return null;
}

MapObjectiveProgress? _mapObjectiveAt(GameRenderer renderer, int col, int row) {
  MapObjectiveDefinition? objective;
  for (final definition in renderer.mapData.objectives) {
    final hex = definition.hex;
    if (hex.col == col && hex.row == row) {
      objective = definition;
      break;
    }
  }
  if (objective == null) return null;
  return MapObjectiveRules.snapshot(
    objectives: [objective],
    cities: renderer._renderState.citiesKnownToActivePlayer,
    units: renderer._renderState.unitsVisibleToActivePlayer,
    holdStatesByObjectiveId:
        renderer._renderState.mapObjectiveHoldStatesByObjectiveId,
  ).entryFor(objective.id);
}

String _objectiveCycleId(String objectiveId) => 'objective:$objectiveId';

String _mapStackCycleId(
  int col,
  int row, {
  required String? unitId,
  required String? artifactId,
  required String? objectiveId,
}) {
  return 'stack:$col:$row:${unitId ?? '-'}:${artifactId ?? '-'}:${objectiveId ?? '-'}';
}

TileData? _tileForArtifactLocation(
  GameRenderer renderer,
  WorldArtifactLocation location,
) {
  return switch (location.kind) {
    WorldArtifactLocationKind.map || WorldArtifactLocationKind.excavation =>
      switch ((location.col, location.row)) {
        (final int col, final int row) => renderer.mapData.tileAt(col, row),
        _ => null,
      },
    WorldArtifactLocationKind.carried ||
    WorldArtifactLocationKind.stored => null,
  };
}
