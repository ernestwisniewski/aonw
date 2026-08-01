part of 'movement_reducer_test.dart';

void _registerFortifiedMovementPreviewTest(WorldMap Function() currentMap) {
  test('fortified unit previews with the movement restored by its move', () {
    final mapData = currentMap();
    final fortified = _commander(
      movementPoints: 0,
    ).copyWithPosture(UnitPosture.fortified);
    final state = GameClientState(
      units: [fortified],
      activePlayerId: 'player_1',
      interaction: InteractionState(
        selection: GameSelection.unit(fortified),
        moveCommandActive: true,
      ),
    );
    final target = mapData.tileAt(1, 0)!;

    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      target,
      mapData,
    );

    expect(previewed.state.movePreview, isNotNull);
    expect(
      previewed.state.movePreview?.availableMovementPoints,
      UnitMovementBalance.maxMovementPointsForType(fortified.type),
    );
    expect(previewed.state.units.single.posture, UnitPosture.fortified);

    final confirmed = resolveMovementCommandForTest(
      previewed.state,
      MoveUnitCommand(fortified.id, target.col, target.row),
      mapData,
    );

    final moved = confirmed.state.units.single;
    expect((moved.col, moved.row), (1, 0));
    expect(moved.posture, UnitPosture.active);
    expect(
      moved.movementPoints,
      UnitMovementBalance.maxMovementPointsForType(moved.type) - 1,
    );
    expect(confirmed.state.movePreview, isNull);
    expect(
      confirmed.uiEffects.whereType<AnimateUnitMoveEffect>(),
      hasLength(1),
    );
  });
}
