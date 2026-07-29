part of 'local_command_transport_test.dart';

void _registerCombatTransportTests() {
  test('seeds combat resolution from the loaded save turn', () async {
    final attacker = GameUnit.produced(
      id: 'attacker',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final defender = GameUnit.produced(
      id: 'defender',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 1,
      row: 0,
    );
    final save = _save(players: const [_player1, _player2], turn: 7);
    final repository = _MemoryGameRepository(
      SaveSnapshot(
        save: save,
        units: [attacker, defender],
        fogOfWar: _visible('player_1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      ),
    );
    final eventLog = _MemoryEventLog();
    final transport = LocalCommandTransport(
      reducer: GameStateReducer(mapData: _map()),
      gameRepository: repository,
      eventLog: eventLog,
      snapshotStore: _MemorySnapshotStore(),
      clock: _FixedClock(DateTime.utc(2026, 4, 24, 12)),
    );

    final result = await transport.dispatch(
      saveId: save.id,
      currentState: GameState(
        units: [attacker, defender],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        fogOfWar: _visible('player_1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      ),
      command: const AttackHexCommand('attacker', 1, 0),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    final outcome = result.events
        .whereType<CombatResolvedEvent>()
        .single
        .outcome;
    expect(result.combatAnimations, hasLength(1));
    expect(result.combatAnimations.single.attackerFromCol, 0);
    expect(result.combatAnimations.single.attackerToCol, 1);
    final seed = outcome.steps.whereType<RollStep>().first.seed;
    expect(
      seed,
      CombatRng.fromTurn(
        turn: 7,
        attackerId: 'attacker',
        defenderId: 'defender',
      ).seed,
    );
    expect(
      eventLog.commands.single.activity
          .where((entry) => entry.event is CombatResolvedEvent)
          .map((entry) => entry.playerId),
      ['player_1', 'player_2'],
    );
  });
}
