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

  _registerCanonicalReducerGuardTests();
}

void _registerCanonicalReducerGuardTests() {
  group('ServerCommandReducer canonical rejection guards', () {
    test(
      'rejects a crafted presentation intent before loading a map',
      () async {
        final snapshot = _reducerGuardSnapshot();
        final reduction = await ServerCommandReducer().reduce(
          match: _runningMatch(),
          snapshot: snapshot,
          wireCommand: const WireCommand(
            matchId: 'match_1',
            tick: 1,
            turn: 1,
            actorPlayerId: 'player_1',
            command: {'type': 'SelectUnit', 'unitId': 'unit_1'},
          ),
          actorPlayerId: 'player_1',
          now: DateTime.utc(2026, 6, 30, 12),
        );

        expect(reduction.accepted, isFalse);
        expect(reduction.reason, 'invalid_command_payload');
        expect(reduction.nextSnapshot, isNull);
      },
    );

    for (final scenario in _commandGuardScenarios) {
      test('rejects ${scenario.name} before loading a map', () async {
        final reduction = await ServerCommandReducer().reduce(
          match: scenario.match,
          snapshot: scenario.snapshot,
          wireCommand: scenario.command,
          actorPlayerId: scenario.actorPlayerId,
          now: DateTime.utc(2026, 6, 30, 12),
        );

        expect(reduction.reason, scenario.reason);
      });
    }
    for (final scenario in _timeoutGuardScenarios) {
      test('rejects timeout ${scenario.name} before loading a map', () async {
        final reduction = await ServerCommandReducer().reduceTimedOutTurn(
          match: scenario.match,
          snapshot: scenario.snapshot,
          actorPlayerId: scenario.actorPlayerId,
          now: DateTime.utc(2026, 6, 30, 12),
        );

        expect(reduction.reason, scenario.reason);
      });
    }
  });
}

typedef _CommandGuardScenario = ({
  String name,
  WireMatch match,
  CanonicalGameSnapshot snapshot,
  WireCommand command,
  String actorPlayerId,
  String reason,
});

final List<_CommandGuardScenario> _commandGuardScenarios = [
  (
    name: 'a non-running match',
    match: _runningMatch().copyWith(state: 'finished'),
    snapshot: _reducerGuardSnapshot(),
    command: _wireCommand(const EndTurnCommand('player_1')),
    actorPlayerId: 'player_1',
    reason: 'match_not_running',
  ),
  (
    name: 'a stale turn',
    match: _runningMatch(),
    snapshot: _reducerGuardSnapshot(),
    command: _wireCommand(const EndTurnCommand('player_1')).copyWith(turn: 2),
    actorPlayerId: 'player_1',
    reason: 'stale_turn',
  ),
  (
    name: 'an eliminated player',
    match: _runningMatch(),
    snapshot: _reducerGuardSnapshot(kickedPlayerIds: const {'player_1'}),
    command: _wireCommand(const EndTurnCommand('player_1')),
    actorPlayerId: 'player_1',
    reason: 'player_eliminated',
  ),
  (
    name: 'an already submitted player',
    match: _runningMatch(),
    snapshot: _reducerGuardSnapshot(submittedPlayerIds: const {'player_1'}),
    command: _wireCommand(
      const SendGoldGiftCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        amount: 1,
      ),
    ),
    actorPlayerId: 'player_1',
    reason: 'player_already_submitted',
  ),
];

typedef _TimeoutGuardScenario = ({
  String name,
  WireMatch match,
  CanonicalGameSnapshot snapshot,
  String actorPlayerId,
  String reason,
});

final List<_TimeoutGuardScenario> _timeoutGuardScenarios = [
  (
    name: 'for a non-running match',
    match: _runningMatch().copyWith(state: 'finished'),
    snapshot: _reducerGuardSnapshot(
      turnStartedAt: DateTime.utc(2026, 6, 30, 11),
    ),
    actorPlayerId: 'player_1',
    reason: 'match_not_running',
  ),
  (
    name: 'inside the active window',
    match: _runningMatch(),
    snapshot: _reducerGuardSnapshot(
      turnStartedAt: DateTime.utc(2026, 6, 30, 12),
    ),
    actorPlayerId: 'player_1',
    reason: 'turn_not_timed_out',
  ),
  (
    name: 'for an eliminated actor',
    match: _runningMatch(),
    snapshot: _reducerGuardSnapshot(
      kickedPlayerIds: const {'player_1'},
      turnStartedAt: DateTime.utc(2026, 6, 30, 11),
    ),
    actorPlayerId: 'player_1',
    reason: 'player_eliminated',
  ),
  (
    name: 'for an actor outside the active roster',
    match: _runningMatch(),
    snapshot: _reducerGuardSnapshot(
      turnStartedAt: DateTime.utc(2026, 6, 30, 11),
    ),
    actorPlayerId: 'not-active',
    reason: 'turn_player_not_active',
  ),
];

CanonicalGameSnapshot _reducerGuardSnapshot({
  Set<String> submittedPlayerIds = const {},
  Set<String> kickedPlayerIds = const {},
  DateTime? turnStartedAt,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: _domainPlayers(),
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      submittedPlayerIds: submittedPlayerIds,
      kickedPlayerIds: kickedPlayerIds,
      turnStartedAt: turnStartedAt,
    ),
    metadata: GameSnapshotMetadata(
      id: 'save_1',
      schemaVersion: 1,
      name: 'Reducer guard snapshot',
      world: const WorldReference(name: 'test_map', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 6, 30, 11),
      camera: GameSnapshotCamera.zero,
    ),
  );
}
