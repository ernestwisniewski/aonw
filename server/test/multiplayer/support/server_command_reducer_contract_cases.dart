part of '../server_command_reducer_test.dart';

void _registerServerCommandReductionContractTests() {
  test('ServerCommandReduction owns movement execution inputs', () {
    final state = _diplomacyState();
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
      snapshot: _snapshot(state),
      movementExecutions: source,
      turn: 1,
      previousState: state,
      state: state,
      outcome: GameOutcome.ongoing,
    );

    source.clear();

    expect(reduction.movementExecutions, hasLength(1));
    expect(() => reduction.movementExecutions.clear(), throwsUnsupportedError);
  });
}
