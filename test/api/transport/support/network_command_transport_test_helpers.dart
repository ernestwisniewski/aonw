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

GameSave _multiplayerSave() => _save().copyWith(
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    Player(id: 'player_2', name: 'Bob', colorValue: 0xFFd05b47),
  ],
);

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

void _registerEngineFamilyRoutingTests() {
  for (final fixture in [
    (
      name: 'movement',
      command: const MoveUnitCommand('attacker', 1, 0) as DomainCommand,
    ),
    (
      name: 'combat',
      command: const AttackHexCommand('attacker', 1, 0) as DomainCommand,
    ),
  ]) {
    test('routes accepted ${fixture.name} through its engine family without '
        'the legacy reducer', () async {
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
      final before = GameClientState(
        units: [attacker, defender],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: const InteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'attacker',
            defenderCol: 1,
            defenderRow: 0,
          ),
        ),
      );
      final after = before.copyWith(
        units: fixture.name == 'movement'
            ? [attacker.copyWith(col: 1, row: 0), defender]
            : [attacker],
        interaction: const InteractionState(),
      );
      final snapshot = GameSnapshotFactory.fromClientState(
        save: _save(),
        state: after,
        eventLogOffset: 1,
      );
      const snapshotCodec = SnapshotCodec();
      final dispatcher = _ScriptedCommandDispatcher(
        (sentCommand) => WireCommandAck(
          matchId: sentCommand.saveId,
          clientMessageId: sentCommand.clientMessageId,
          accepted: true,
          offset: 1,
          snapshot: snapshotCodec.toWire(
            matchId: sentCommand.saveId,
            snapshot: snapshot,
          ),
          events: fixture.name == 'combat'
              ? _projectedCombatEventPayloads()
              : const [],
          movementExecutions: WireMovementExecutionList(const []),
        ),
      );
      final reducer = GameStateReducer(mapData: _map());
      final transport = NetworkCommandTransport(
        commandDispatcher: dispatcher,
        token: AuthToken('jwt-token'),
        actorPlayerId: 'player_1',
        tickGenerator: ClientTickGenerator(),
        localReducer: reducer,
        gameRepository: _SnapshotRepository(
          GameSnapshotFactory.fromClientState(
            save: _save(),
            state: before,
            eventLogOffset: 0,
          ),
        ),
      );

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: before,
        command: fixture.command,
      );

      expect(result.snapshot?.eventLogOffset, snapshot.eventLogOffset);
      if (fixture.name == 'combat') {
        expect(result.state.pendingAction, isNull);
        expect(result.combatAnimations, const [
          CombatAnimationFact(
            eventIndex: 0,
            attackerUnitId: 'attacker',
            defenderId: 'defender',
            attackerFromCol: 0,
            attackerFromRow: 0,
            attackerToCol: 1,
            attackerToRow: 0,
          ),
        ]);
      }
    });
  }

  test('routes accepted research through its engine family without '
      'the legacy reducer', () async {
    final before = GameClientState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: const InteractionState(
        pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
      ),
    );
    final after = before.copyWith(
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      interaction: const InteractionState(),
    );
    final snapshot = GameSnapshotFactory.fromClientState(
      save: _save(),
      state: after,
      eventLogOffset: 1,
    );
    const snapshotCodec = SnapshotCodec();
    final dispatcher = _ScriptedCommandDispatcher(
      (sentCommand) => WireCommandAck(
        matchId: sentCommand.saveId,
        clientMessageId: sentCommand.clientMessageId,
        accepted: true,
        offset: 1,
        snapshot: snapshotCodec.toWire(
          matchId: sentCommand.saveId,
          snapshot: snapshot,
        ),
        movementExecutions: WireMovementExecutionList(const []),
      ),
    );
    final reducer = GameStateReducer(mapData: _map());
    final transport = NetworkCommandTransport(
      commandDispatcher: dispatcher,
      token: AuthToken('jwt-token'),
      actorPlayerId: 'player_1',
      tickGenerator: ClientTickGenerator(),
      localReducer: reducer,
      gameRepository: _SnapshotRepository(
        GameSnapshotFactory.fromClientState(save: _save(), state: before),
      ),
    );

    final result = await transport.dispatch(
      saveId: 'save_1',
      currentState: before,
      command: const SelectTechnologyCommand(
        'player_1',
        TechnologyId.agriculture,
      ),
    );

    expect(
      result.state.research.forPlayer('player_1').activeTechnologyId,
      TechnologyId.agriculture,
    );
    expect(result.state.pendingAction, isNull);
  });

  test('routes accepted diplomacy through its engine family without '
      'the legacy reducer', () async {
    final before = GameClientState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: const InteractionState(
        pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
      ),
    );
    final after = before.copyWith(
      diplomacy: DiplomacyState.empty
          .addContact('player_1', 'player_2')
          .addProposal(
            const DiplomaticProposal(
              id: 'proposal_1',
              fromPlayerId: 'player_1',
              toPlayerId: 'player_2',
              kind: DiplomaticProposalKind.friendship,
              createdTurn: 1,
              expiresOnTurn: 6,
            ),
          ),
    );
    final snapshot = GameSnapshotFactory.fromClientState(
      save: _save(),
      state: after,
      eventLogOffset: 1,
    );
    const snapshotCodec = SnapshotCodec();
    final dispatcher = _ScriptedCommandDispatcher(
      (sentCommand) => WireCommandAck(
        matchId: sentCommand.saveId,
        clientMessageId: sentCommand.clientMessageId,
        accepted: true,
        offset: 1,
        snapshot: snapshotCodec.toWire(
          matchId: sentCommand.saveId,
          snapshot: snapshot,
        ),
        movementExecutions: WireMovementExecutionList(const []),
      ),
    );
    final reducer = GameStateReducer(mapData: _map());
    final transport = NetworkCommandTransport(
      commandDispatcher: dispatcher,
      token: AuthToken('jwt-token'),
      actorPlayerId: 'player_1',
      tickGenerator: ClientTickGenerator(),
      localReducer: reducer,
      gameRepository: _SnapshotRepository(
        GameSnapshotFactory.fromClientState(save: _save(), state: before),
      ),
    );

    final result = await transport.dispatch(
      saveId: 'save_1',
      currentState: before,
      command: const SendDiplomaticProposalCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        kind: DiplomaticProposalKind.friendship,
        proposalId: 'proposal_1',
      ),
    );

    expect(result.state.diplomacy.pendingProposals.keys, ['proposal_1']);
    expect(
      result.state.pendingAction,
      const PendingResearchSelection(ownerPlayerId: 'player_1'),
    );
  });
}

List<Map<String, dynamic>> _projectedCombatEventPayloads() {
  return [
    {
      'type': 'CombatResolved',
      'attackerUnitId': 'attacker',
      'defenderUnitId': 'defender',
      'outcome': {
        'attackerUnitId': 'attacker',
        'defenderUnitId': 'defender',
        'attackerHpAfter': 10,
        'defenderHpAfter': 0,
        'attackerKilled': false,
        'defenderKilled': true,
        'defenderRetreated': false,
        'steps': [
          {'type': 'Attack', 'damage': 1, 'active': <String>[]},
        ],
      },
      CombatAnimationFactCodec.eventPayloadKey: CombatAnimationFactCodec.toJson(
        const CombatAnimationFact(
          eventIndex: 0,
          attackerUnitId: 'attacker',
          defenderId: 'defender',
          attackerFromCol: 0,
          attackerFromRow: 0,
          attackerToCol: 1,
          attackerToRow: 0,
        ),
      ),
    },
  ];
}

class _FakeCommandServer implements WireCommandDispatcher {
  final GameStateReducer reducer = GameStateReducer(mapData: _map());
  final CommandCodec commandCodec = const CommandCodec();
  final EventCodec eventCodec = const EventCodec();
  final SnapshotCodec snapshotCodec = const SnapshotCodec();
  final List<_SentCommand> sentCommands = [];
  GameSave save;
  GameClientState state;
  CanonicalGameSnapshot? nextAcceptedSnapshot;
  WireMovementExecutionList nextMovementExecutions;
  WireCommandAck? lastAck;
  Object? nextError;
  int offset = 0;

  _FakeCommandServer({
    required this.save,
    required this.state,
    this.nextAcceptedSnapshot,
    WireMovementExecutionList? nextMovementExecutions,
    this.nextError,
  }) : nextMovementExecutions =
           nextMovementExecutions ?? WireMovementExecutionList(const []);

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    sentCommands.add(
      _SentCommand(
        saveId: saveId,
        token: token,
        afterOffset: afterOffset,
        wire: wire,
        clientMessageId: clientMessageId,
      ),
    );
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    offset += 1;

    final command = commandCodec.fromWire(wire);
    final context = commandCodec.contextFromWire(wire);
    final timestamp = DateTime.utc(2026, 4, 26, 12, 0, offset);
    final resolution = LocalCommandResolver(reducer: reducer).resolve(
      baseSnapshot: snapshot,
      currentState: state,
      command: command,
      savedAt: timestamp,
      context: context,
    );
    final transition = GameStateTransition(
      state: resolution.state,
      events: resolution.events,
      uiEffects: resolution.uiEffects,
    );
    final movementExecutions = nextMovementExecutions;
    nextMovementExecutions = WireMovementExecutionList(const []);
    state = transition.state;
    final nextSnapshot =
        nextAcceptedSnapshot ??
        resolution.snapshot.copyWith(eventLogOffset: offset);
    nextAcceptedSnapshot = null;
    save = nextSnapshot.save;
    state = nextSnapshot.toClientState(
      activePlayerId: state.activePlayerId,
      activePlayerCanAct: state.activePlayerCanAct,
    );
    return lastAck = WireCommandAck(
      matchId: wire.matchId,
      clientMessageId: clientMessageId,
      accepted: true,
      offset: offset,
      tick: wire.tick,
      timestamp: timestamp,
      snapshot: snapshotCodec.toWire(
        matchId: wire.matchId,
        snapshot: nextSnapshot,
      ),
      events: eventCodec.eventsToJsonList(transition.events),
      movementExecutions: movementExecutions,
    );
  }

  CanonicalGameSnapshot get snapshot => GameSnapshotFactory.fromClientState(
    save: save,
    state: state,
    eventLogOffset: offset,
  );
}
