part of '../network_command_transport_test.dart';

void _registerTransientSnapshotCases() {
  test('applies client-only commands locally without HTTP', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: GameInteractionState(
        selection: GameSelection.unit(commander),
      ),
    );
    final server = _FakeCommandServer(save: _save(), state: state);
    final transport = _transport(server);

    final result = await transport.dispatchAcrossBoundary(
      saveId: 'save_1',
      currentState: state,
      command: const ToggleMoveTargetingCommand(),
    );

    expect(server.sentCommands, isEmpty);
    expect(result.snapshot, isNull);
    expect(result.state.activePlayerId, 'player_1');
    expect(result.state.moveCommandActive, isTrue);
    expect(result.uiEffects, isEmpty);
    expect(result.events, isEmpty);
    expect(result.offset, -1);
    expect(result.storedSnapshot, isFalse);
  });

  test('does not send another presentation-only interaction', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
    );
    final server = _FakeCommandServer(save: _save(), state: state);

    final result = await _transport(server).dispatchAcrossBoundary(
      saveId: 'save_1',
      currentState: state,
      command: const CancelCityFoundingCommand(),
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
