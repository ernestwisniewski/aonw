part of '../network_command_transport_test.dart';

void _registerTransientSnapshotCases() {
  test('applies client-only commands locally without HTTP', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
    );
    final server = _FakeCommandServer(save: _save(), state: state);
    final transport = _transport(server);

    final result = await transport.dispatch(
      saveId: 'save_1',
      currentState: state,
      command: const SetActivePlayerCommand('player_2', canAct: false),
    );

    expect(server.sentCommands, isEmpty);
    expect(result.snapshot, isNull);
    expect(result.state.activePlayerId, 'player_2');
    expect(result.state.activePlayerCanAct, isFalse);
    expect(result.uiEffects, isEmpty);
    expect(result.events, isEmpty);
    expect(result.offset, -1);
    expect(result.storedSnapshot, isFalse);
  });

  test('does not send server-managed movement resets', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
    );
    final server = _FakeCommandServer(save: _save(), state: state);

    final result = await _transport(server).dispatch(
      saveId: 'save_1',
      currentState: state,
      command: const ResetUnitMovementCommand(playerId: 'player_1'),
    );

    expect(server.sentCommands, isEmpty);
    expect(result.snapshot, isNull);
    expect(result.state, same(state));
    expect(result.uiEffects, isEmpty);
    expect(result.events, isEmpty);
    expect(result.offset, -1);
    expect(result.storedSnapshot, isFalse);
  });
}
