part of '../network_command_transport_test.dart';

NetworkCommandTransport _transport(
  _FakeCommandServer server, {
  int startTickAt = 1,
  CommandAuthTokenReader? tokenReader,
}) {
  return NetworkCommandTransport(
    commandDispatcher: server,
    token: AuthToken('jwt-token'),
    tokenReader: tokenReader,
    actorPlayerId: 'player_1',
    tickGenerator: ClientTickGenerator(startAt: startTickAt),
    localReducer: server.reducer,
    gameRepository: _SnapshotRepository(server.snapshot),
  );
}

NetworkCommandConflictException _commandConflict(
  String errorCode, {
  int? nextTick,
}) {
  return NetworkCommandConflictException(code: errorCode, nextTick: nextTick);
}

WireMovementExecutionList _twoStepMovementExecutions(String unitId) {
  return WireMovementExecutionList([
    WireMovementExecution(
      unitId: unitId,
      fromCol: 0,
      fromRow: 0,
      steps: const [
        WireMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        WireMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
      ],
    ),
  ]);
}
