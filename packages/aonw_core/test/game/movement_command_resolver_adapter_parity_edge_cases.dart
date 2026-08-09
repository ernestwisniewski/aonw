part of 'movement_command_resolver_adapter_parity_test.dart';

void _registerMovementCommandResolverAdapterParityEdgeCases() {
  _registerArtifactCarrierBoundaryCase();
  _registerCapacityAwareRouteCase();

  test('only unrestricted mode reveals a hidden dynamic blocker', () {
    final blocker = movementUnit(
      id: 'hidden_blocker',
      ownerPlayerId: movementOpponentId,
      col: 1,
    );
    final states = movementStates(
      mover: movementUnit(),
      additionalUnits: [blocker],
      fogOfWar: movementFog(visibleCols: 1),
    );
    const command = MoveUnitCommand(movementUnitId, 1, 0);
    final map = movementMap(cols: 2);

    final pathingResults = resolveMovement(
      states,
      command,
      map,
      visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
    );
    final unrestrictedResults = resolveMovement(
      states,
      command,
      map,
      visibilityMode: MovementCommandVisibilityMode.unrestricted,
    );

    expect(pathingResults.kernel.accepted, isTrue);
    expect(pathingResults.kernel.units, same(states.kernel.units));
    expect(pathingResults.kernel.events, isEmpty);
    expect(pathingResults.kernel.execution, isNull);
    expectRejectedMovementIdentity(
      states,
      unrestrictedResults,
      reason: 'move_target_occupied',
    );
  });
}

void _registerCapacityAwareRouteCase() {
  test('uses a feasible detour instead of rejecting a cheaper shortcut', () {
    final states = movementStates(
      mover: movementUnit(type: GameUnitType.warrior, movementPoints: 3),
    );

    final results = resolveMovement(
      states,
      const MoveUnitCommand(movementUnitId, 2, 0),
      _capacityDetourMap(),
    );

    expectAcceptedMovementParity(states, results);
    final moved = results.kernel.units.first;
    expect((moved.col, moved.row, moved.movementPoints), (1, 2, 0));
    expect((moved.queuedPath?.targetCol, moved.queuedPath?.targetRow), (2, 0));
    expect(stepCoordinates(moved.queuedPath!.steps), const [
      (0, 0),
      (0, 1),
      (0, 2),
      (1, 2),
      (2, 2),
      (2, 1),
      (2, 0),
    ]);
    expect(stepCoordinates(results.kernel.execution!.steps), const [
      (0, 1),
      (0, 2),
      (1, 2),
    ]);
  });
}

void _registerArtifactCarrierBoundaryCase() {
  test('artifact carrier exhausts a route prefix on costly terrain', () {
    final carrier = movementUnit(
      type: GameUnitType.warrior,
      movementPoints: 2,
    ).copyWithCarriedArtifact('artifact_1');
    final states = movementStates(mover: carrier);
    final map = movementMap(
      cols: 4,
      terrainOverrides: const {
        (col: 2, row: 0): [
          TerrainType.grassland,
          TerrainType.forest,
          TerrainType.hills,
        ],
      },
    );

    final results = resolveMovement(
      states,
      const MoveUnitCommand(movementUnitId, 3, 0),
      map,
    );

    expectAcceptedMovementParity(states, results);
    final moved = results.kernel.units.first;
    expect((moved.col, moved.row, moved.movementPoints), (2, 0, 0));
    expect(moved.queuedPath?.targetCol, 3);
    expect(stepCoordinates(results.kernel.execution!.steps), const [
      (1, 0),
      (2, 0),
    ]);
    expectMoveEvent(results.kernel.events, fromCol: 0, toCol: 2);
  });
}

WorldMap _capacityDetourMap() {
  const passable = <({int col, int row}), List<TerrainType>>{
    (col: 0, row: 0): [TerrainType.grassland],
    (col: 1, row: 0): [
      TerrainType.grassland,
      TerrainType.forest,
      TerrainType.jungle,
      TerrainType.hills,
    ],
    (col: 2, row: 0): [TerrainType.grassland],
    (col: 0, row: 1): [TerrainType.grassland],
    (col: 0, row: 2): [TerrainType.grassland],
    (col: 1, row: 2): [TerrainType.grassland],
    (col: 2, row: 2): [TerrainType.grassland],
    (col: 2, row: 1): [TerrainType.grassland],
  };
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains:
                passable[(col: col, row: row)] ??
                const [TerrainType.grassland, TerrainType.mountain],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
