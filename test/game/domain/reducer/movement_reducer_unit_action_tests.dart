part of 'movement_reducer_test.dart';

void _registerCanonicalSkipCancelTest(WorldMap Function() mapData) {
  test('cancelUnitAction restores movement after skipping turn', () {
    final commander = _commander(movementPoints: 2);
    const pendingSkip = PendingUnitTurnSkip(
      ownerPlayerId: 'player_1',
      unitId: 'commander_player_1',
      restoreMovementPoints: 2,
    );
    final skippedState = GameClientState(
      units: [commander.copyWith(movementPoints: 0)],
      activePlayerId: 'player_1',
      domainActions: DomainActionState(pendingAction: pendingSkip),
      interaction: InteractionState(
        selection: GameSelection.unit(commander.copyWith(movementPoints: 0)),
        pendingAction: pendingSkip,
      ),
    );

    final result = resolveMovementCommandForTest(
      skippedState,
      const CancelUnitActionCommand('commander_player_1'),
      mapData(),
    );

    expect(result.state.units.single.movementPoints, 2);
    expect(result.state.pendingAction, isNull);
    expect(result.state.selection?.unit?.movementPoints, 2);
  });
}
