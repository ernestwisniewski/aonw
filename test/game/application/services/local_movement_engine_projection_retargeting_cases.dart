part of 'local_movement_engine_projection_test.dart';

void _registerLocalMovementRetargetingTests() {
  test('accepted preview move consuming the last MP ends targeting', () {
    final result = _resolveAcceptedPreviewMove(
      movementPoints: 3,
      targetTerrains: const [TerrainType.snow],
      expectedCost: 3,
    );

    expect(result.state.units.single.col, 1);
    expect(result.state.units.single.movementPoints, 0);
    expect(result.state.selection?.unit, same(result.state.units.single));
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('accepted preview move retaining MP keeps targeting active', () {
    final result = _resolveAcceptedPreviewMove(
      movementPoints: 3,
      targetTerrains: const [TerrainType.grassland],
      expectedCost: 1,
    );

    expect(result.state.units.single.col, 1);
    expect(result.state.units.single.movementPoints, 2);
    expect(result.state.selection?.unit, same(result.state.units.single));
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isTrue);
  });

  test('accepted identity preview confirmation clears stale targeting', () {
    const steps = [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
    ];
    final unit = _unit(id: 'mover', movementPoints: 0).copyWithQueuedPath(
      QueuedMovePath(targetCol: 2, targetRow: 0, steps: steps),
    );
    final state = GameClientState(
      activePlayerId: _playerId,
      units: [unit],
      interaction: InteractionState(
        selection: GameSelection.unit(unit),
        moveCommandActive: true,
        movePreview: UnitMovementPlan(
          unitId: unit.id,
          targetCol: 2,
          targetRow: 0,
          totalCost: 2,
          availableMovementPoints: 0,
          steps: steps,
        ),
      ),
    );
    final snapshot = _snapshot(state);

    final result = _resolver(_map(cols: 3)).resolve(
      baseSnapshot: snapshot,
      currentState: state,
      command: const MoveUnitCommand('mover', 2, 0),
      savedAt: DateTime.utc(2026, 7, 29, 19, 30),
      context: const GameCommandContext(actorPlayerId: _playerId),
      movementPresentationOrigin:
          LocalMovementPresentationOrigin.previewConfirmation,
    );

    expect(result.snapshot.domain, same(snapshot.domain));
    expect(result.state.units, state.units);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('hidden-blocker identity keeps valid retargeting active', () {
    final unit = _unit(id: 'mover');
    final blocker = GameUnit(
      id: 'hidden_blocker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 1,
      row: 0,
      movementPoints: 3,
    );
    final preview = UnitMovementPlan(
      unitId: unit.id,
      targetCol: 1,
      targetRow: 0,
      totalCost: 1,
      availableMovementPoints: unit.movementPoints,
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
    );
    final state = GameClientState(
      activePlayerId: _playerId,
      units: [unit, blocker],
      fogOfWar: _fog(visibleCols: 1),
      interaction: InteractionState(
        selection: GameSelection.unit(unit),
        moveCommandActive: true,
        movePreview: preview,
      ),
    );

    final result = _resolver(_map(cols: 2)).resolve(
      baseSnapshot: _snapshot(state),
      currentState: state,
      command: const MoveUnitCommand('mover', 1, 0),
      savedAt: DateTime.utc(2026, 7, 29, 19, 45),
      context: const GameCommandContext(actorPlayerId: _playerId),
      movementPresentationOrigin:
          LocalMovementPresentationOrigin.previewConfirmation,
    );

    expect(result.state.units, state.units);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isTrue);
    expect(result.events, isEmpty);
    expect(result.movementExecutions, isEmpty);
  });
}

LocalCommandResolution _resolveAcceptedPreviewMove({
  required int movementPoints,
  required List<TerrainType> targetTerrains,
  required int expectedCost,
}) {
  final unit = _unit(id: 'mover', movementPoints: movementPoints);
  final preview = UnitMovementPlan(
    unitId: unit.id,
    targetCol: 1,
    targetRow: 0,
    totalCost: expectedCost,
    availableMovementPoints: movementPoints,
    canSpendTurnEnteringFirstStep: true,
    steps: [
      const UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(
        col: 1,
        row: 0,
        enterCost: expectedCost,
        cumulativeCost: expectedCost,
      ),
    ],
  );
  final state = GameClientState(
    activePlayerId: _playerId,
    activePlayerCanAct: true,
    units: [unit],
    interaction: InteractionState(
      selection: GameSelection.unit(unit),
      moveCommandActive: true,
      movePreview: preview,
    ),
  );

  return _resolver(
    _map(cols: 2, terrainOverrides: {1: targetTerrains}),
  ).resolve(
    baseSnapshot: _snapshot(state),
    currentState: state,
    command: const MoveUnitCommand('mover', 1, 0),
    savedAt: DateTime.utc(2026, 7, 31, 10),
    context: const GameCommandContext(actorPlayerId: _playerId),
    movementPresentationOrigin:
        LocalMovementPresentationOrigin.previewConfirmation,
  );
}
