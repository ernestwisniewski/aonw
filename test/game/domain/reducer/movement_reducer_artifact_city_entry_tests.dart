part of 'movement_reducer_test.dart';

void _registerArtifactCarrierDirectMoveTest() {
  test('moveUnit lets artifact carriers enter own rough city center', () {
    final roughMap = _artifactCarrierRoughCityMap();
    final carrier = _artifactCarrier();
    final city = _city(id: 'city_1', col: 1);
    final state = GameState(
      units: [carrier],
      cities: [city],
      activePlayerId: 'player_1',
    );

    final result = resolveMovementCommandForTest(
      state,
      const MoveUnitCommand('carrier_1', 1, 0),
      roughMap,
    );

    final moved = result.state.units.single;
    expect(moved.col, 1);
    expect(moved.row, 0);
    expect(moved.movementPoints, 0);
    expect(result.events.single, isA<UnitMovedEvent>());
    expect(result.uiEffects.whereType<ShowHudFeedbackEffect>(), isEmpty);
  });
}

void _registerArtifactCarrierPreviewTests() {
  test('previews artifact carrier movement into own rough city center', () {
    final roughMap = _artifactCarrierRoughCityMap();
    final carrier = _artifactCarrier();
    final state = _artifactCarrierSelectedState(carrier);

    final result = MovementReducer.handleMoveTargetTile(
      state,
      roughMap.tileAt(1, 0)!,
      roughMap,
    );

    expect(result.state.movePreview?.targetCol, 1);
    expect(result.state.movePreview?.targetRow, 0);
    expect(result.uiEffects.whereType<ShowHudFeedbackEffect>(), isEmpty);
  });

  test('engine completes spend-turn entry into own rough city center', () {
    final roughMap = _artifactCarrierRoughCityMap();
    final carrier = _artifactCarrier();
    final state = _artifactCarrierSelectedState(carrier);
    final targetTile = roughMap.tileAt(1, 0)!;

    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      targetTile,
      roughMap,
    );
    final confirmed = resolveMovementCommandForTest(
      previewed.state,
      MoveUnitCommand(carrier.id, targetTile.col, targetTile.row),
      roughMap,
    );
    final moved = confirmed.state.units.single;

    expect(previewed.state.movePreview?.canMoveNow, isTrue);
    expect((moved.col, moved.row), (1, 0));
    expect(moved.movementPoints, 0);
    expect(moved.queuedPath, isNull);
    expect(confirmed.state.moveCommandActive, isTrue);
    expect(
      confirmed.uiEffects.whereType<AnimateUnitMoveEffect>().single.steps,
      hasLength(1),
    );
  });
}

MapData _artifactCarrierRoughCityMap() => _map(
  2,
  1,
  terrainOverrides: {
    (col: 1, row: 0): const [
      TerrainType.grassland,
      TerrainType.forest,
      TerrainType.hills,
    ],
  },
);

GameUnit _artifactCarrier() => GameUnit.produced(
  id: 'carrier_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.scout,
  col: 0,
  row: 0,
).copyWith(movementPoints: 2).copyWithCarriedArtifact('artifact_1');

GameState _artifactCarrierSelectedState(GameUnit carrier) => GameState(
  units: [carrier],
  cities: [_city(id: 'city_1', col: 1)],
  activePlayerId: 'player_1',
  interaction: GameInteractionState(
    selection: GameSelection.unit(carrier),
    moveCommandActive: true,
  ),
);
