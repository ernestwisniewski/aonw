part of '../server_command_reducer_test.dart';

void _registerServerCommandReductionContractTests() {
  test('ServerCommandReduction owns movement execution inputs', () {
    final source = [
      MovementCommandExecution(
        unitId: 'unit_1',
        fromCol: 0,
        fromRow: 0,
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      ),
    ];
    final reduction = ServerCommandReduction(
      accepted: true,
      nextSnapshot: CanonicalGameSnapshot.snapshot(
        domain: DomainState.snapshot(
          turn: 1,
          matchRules: MatchRules.standard,
          participants: _domainPlayers(),
        ),
        session: MatchSessionState.snapshot(gameMode: GameMode.multiplayer),
        metadata: GameSnapshotMetadata(
          id: 'save_1',
          schemaVersion: 1,
          name: 'Server reducer contract',
          world: const WorldReference(
            name: 'test_map',
            source: MapSource.asset,
          ),
          savedAtUtc: DateTime.utc(2026, 6, 30, 11),
          camera: GameSnapshotCamera.zero,
        ),
      ),
      movementExecutions: source,
      outcome: GameOutcome.ongoing,
    );

    source.clear();

    expect(reduction.nextSnapshot, isA<CanonicalGameSnapshot>());
    expect(reduction.movementExecutions, hasLength(1));
    expect(() => reduction.movementExecutions.clear(), throwsUnsupportedError);
  });
}
