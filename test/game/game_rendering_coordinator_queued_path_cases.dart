part of 'game_rendering_coordinator_test.dart';

WorldMap _mapWithObjectives(List<MapObjectiveDefinition> objectives) =>
    WorldMap(
      cols: 4,
      rows: 1,
      objectives: objectives,
      tiles: [
        for (var col = 0; col < 4; col++)
          WorldTile(
            col: col,
            row: 0,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
      ],
    );

void _registerQueuedPathRenderingTests() {
  test('rebases a queued path after the unit has already travelled', () {
    final map = _map();
    final warrior =
        GameUnit(
          id: 'warrior',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 1,
          row: 0,
          movementPoints: 3,
        ).copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 3,
            targetRow: 0,
            steps: const [
              UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
              UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
              UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 3),
              UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 4),
            ],
          ),
        );
    final movePreview = _RecordingMovePreviewLayer();

    _coordinator(map: map, movePreview: movePreview).syncAll(
      state: GameClientState(
        activePlayerId: 'player_1',
        units: [warrior],
        interaction: InteractionState(
          selection: GameSelection.unit(warrior, tile: _tile(map, 1)),
        ),
      ),
      parent: Component(),
      viewModelNotifier: ValueNotifier(RenderState.empty),
    );

    expect(movePreview.lastPreview?.path, const [
      (col: 1, row: 0),
      (col: 2, row: 0),
      (col: 3, row: 0),
    ]);
    expect(movePreview.lastPreview?.totalCost, 3);
    expect(movePreview.lastPreview?.canMoveNow, isTrue);
    expect(movePreview.lastPreview?.estimatedTurns(3), 1);
    expect(movePreview.lastDisplaySteps, hasLength(4));
    expect(movePreview.lastTravelledUpToIndex, 1);
    expect(movePreview.lastMaxMovementPointsPerTurn, 6);
  });
}

class _RecordingMovePreviewLayer extends UnitMovePreviewLayer {
  UnitMovementPlan? lastPreview;
  List<UnitMovementPlan> lastPreviews = const [];
  List<UnitMovementStep>? lastDisplaySteps;
  int? lastTravelledUpToIndex;
  GameUnitType? lastUnitType;
  int? lastMaxMovementPointsPerTurn;
  bool? lastDimmed;
  bool? lastSubdued;
  bool? lastShowCostLabel;
  bool? lastShowTargetOutline;
  Set<int>? lastRoadSegmentIndices;

  @override
  void sync({
    required Component parent,
    required UnitMovementPlan? preview,
    int travelledUpToIndex = 0,
    GameUnitType? unitType,
    bool dimmed = false,
    bool showTargetOutline = false,
  }) => syncMany(
    parent: parent,
    previews: preview == null
        ? const []
        : [
            UnitMovePreviewLayerEntry(
              id: preview.unitId,
              preview: preview,
              travelledUpToIndex: travelledUpToIndex,
              unitType: unitType,
              dimmed: dimmed,
              showTargetOutline: showTargetOutline,
            ),
          ],
  );

  @override
  void syncMany({
    required Component parent,
    required Iterable<UnitMovePreviewLayerEntry> previews,
  }) {
    final entries = previews.toList(growable: false);
    lastPreviews = [for (final entry in entries) entry.preview];
    final last = entries.lastOrNull;
    lastPreview = last?.preview;
    lastDisplaySteps = last?.displaySteps;
    lastTravelledUpToIndex = last?.travelledUpToIndex;
    lastUnitType = last?.unitType;
    lastMaxMovementPointsPerTurn = last?.maxMovementPointsPerTurn;
    lastDimmed = last?.dimmed;
    lastSubdued = last?.subdued;
    lastShowCostLabel = last?.showCostLabel;
    lastShowTargetOutline = last?.showTargetOutline;
    lastRoadSegmentIndices = last?.roadSegmentIndices;
  }

  @override
  void clear() {
    lastPreview = null;
    lastPreviews = const [];
    lastDisplaySteps = null;
    lastTravelledUpToIndex = null;
    lastUnitType = null;
    lastMaxMovementPointsPerTurn = null;
    lastDimmed = null;
    lastSubdued = null;
    lastShowCostLabel = null;
    lastShowTargetOutline = null;
    lastRoadSegmentIndices = null;
  }
}
