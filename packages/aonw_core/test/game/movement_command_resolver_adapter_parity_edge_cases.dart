part of 'movement_command_resolver_adapter_parity_test.dart';

void _registerMovementCommandResolverAdapterParityEdgeCases() {
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
