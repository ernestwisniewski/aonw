part of 'local_command_transport_test.dart';

void _registerWorkerReplayTests() {
  for (final scenario in _acceptedWorkerReplayScenarios()) {
    test('replays accepted worker command once: ${scenario.name}', () async {
      final harness = _WorkerReplayHarness.create(scenario.initialState);
      final initialState = harness.state;
      final initialAuthoritative = _authoritativeProjection(initialState);

      expect(initialState.pendingAction, isNull);

      await harness.dispatch(scenario.command);

      expect(harness.lastDispatchOffset, 1);
      expect(harness.repository.snapshot.eventLogOffset, 1);
      expect(harness.eventLog.commands, hasLength(1));
      final logged = harness.eventLog.commands.single;
      expect(logged.offset, 1);
      expect(logged.actorPlayerId, 'player_1');
      _expectExactWorkerCommand(logged.command, scenario.command);
      _expectAcceptedWorkerEffect(
        scenario.effect,
        before: initialState,
        after: harness.state,
      );
      expect(
        _authoritativeProjection(harness.state),
        isNot(equals(initialAuthoritative)),
      );
      expect(
        harness.repository.snapshot.domain.copyWith(
          actions: DomainActionState.empty,
        ),
        _authoritativeProjection(harness.state),
      );

      final timeline = await harness.replayTimeline();

      expect(
        _authoritativeProjection(timeline.initialState),
        initialAuthoritative,
      );
      expect(timeline.steps, hasLength(1));
      final step = timeline.steps.single;
      expect(step.index, 1);
      expect(step.offset, 1);
      _expectExactWorkerCommand(step.loggedCommand.command, scenario.command);
      expect(
        _authoritativeProjection(step.previousState),
        initialAuthoritative,
      );
      _expectAcceptedWorkerEffect(
        scenario.effect,
        before: step.previousState,
        after: step.state,
      );
      _expectSameAuthoritativeState(step.state, harness.state);
    });
  }

  test(
    'keeps worker previews out of replay and logs one complete confirmation',
    () async {
      final harness = _WorkerReplayHarness.create(_workerReplayState());

      await harness.dispatchIntent(
        const StartWorkerActionSelectionCommand('worker_1'),
      );
      await harness.dispatchIntent(
        const ChooseWorkerImprovementIntent(
          'worker_1',
          FieldImprovementType.mine,
        ),
      );
      await harness.dispatchIntent(
        const ChooseWorkerImprovementIntent(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );
      await harness.dispatchIntent(
        const CancelWorkerActionSelectionCommand('worker_1'),
      );

      expect(harness.eventLog.commands, isEmpty);
      expect(harness.repository.snapshot.eventLogOffset, 0);
      expect(harness.state.pendingAction, isNull);
      expect(harness.state.units.single.workerJob, isNull);

      await harness.dispatchIntent(
        const StartWorkerActionSelectionCommand('worker_1'),
      );
      await harness.dispatchIntent(
        const ChooseWorkerImprovementIntent(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );
      await harness.dispatchIntent(
        const ConfirmWorkerImprovementIntent('worker_1'),
      );

      expect(harness.eventLog.commands, hasLength(1));
      expect(harness.repository.snapshot.eventLogOffset, 1);
      expect(
        harness.eventLog.commands.single.command,
        const ConfirmWorkerImprovementCommand(
          'worker_1',
          improvementType: FieldImprovementType.farm,
        ),
      );
      final liveJob = harness.state.units.single.workerJob;
      expect(liveJob?.improvementType, FieldImprovementType.farm);
      expect(liveJob?.remainingTurns, liveJob?.totalTurns);

      final replayedStates = await harness.replayedStates();

      expect(replayedStates, hasLength(1));
      final replayed = replayedStates.single;
      _expectSameAuthoritativeState(replayed, harness.state);
      expect(
        replayed.units.single.workerJob?.remainingTurns,
        liveJob?.totalTurns,
      );
      expect(replayed.fieldImprovements, isEmpty);
    },
  );

  test('replays confirmation without a selection as a domain no-op', () async {
    final harness = _WorkerReplayHarness.create(_workerReplayState());

    await harness.dispatch(const ConfirmWorkerImprovementCommand('worker_1'));

    expect(harness.eventLog.commands, hasLength(1));
    expect(harness.repository.snapshot.eventLogOffset, 1);
    expect(harness.state.units.single.workerJob, isNull);
    final replayedStates = await harness.replayedStates();
    expect(replayedStates, hasLength(1));
    expect(replayedStates.single.units.single.workerJob, isNull);
    _expectSameAuthoritativeState(replayedStates.single, harness.state);
  });

  test(
    'replays a rejected confirmation without creating worker domain work',
    () async {
      final harness = _WorkerReplayHarness.create(
        _workerReplayState(workerCol: 2, workerRow: 2),
      );

      await harness.dispatchIntent(
        const StartWorkerActionSelectionCommand('worker_1'),
      );
      await harness.dispatchIntent(
        const ChooseWorkerImprovementIntent(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );
      await harness.dispatchIntent(
        const ConfirmWorkerImprovementIntent('worker_1'),
      );

      expect(harness.eventLog.commands, hasLength(1));
      expect(harness.state.pendingAction, isA<PendingWorkerActionSelection>());
      expect(harness.state.units.single.workerJob, isNull);
      final replayedStates = await harness.replayedStates();
      expect(replayedStates, hasLength(1));
      expect(replayedStates.single.pendingAction, isNull);
      expect(replayedStates.single.units.single.workerJob, isNull);
      _expectSameAuthoritativeState(replayedStates.single, harness.state);
    },
  );

  test(
    'does not replay a client-only city draft as authoritative state',
    () async {
      final harness = _WorkerReplayHarness.create(
        _workerReplayState(
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'settler_1',
            ownerPlayerId: 'player_1',
            center: const CityHex(col: 2, row: 2),
            controlledHexes: const [CityHex(col: 2, row: 2)],
          ),
        ),
      );

      await harness.dispatchIntent(
        const StartWorkerActionSelectionCommand('worker_1'),
      );
      await harness.dispatchIntent(
        const ChooseWorkerImprovementIntent(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );
      await harness.dispatchIntent(
        const ConfirmWorkerImprovementIntent('worker_1'),
      );

      expect(harness.state.cityFoundingDraft, isNull);
      expect(harness.state.units.single.workerJob, isNotNull);
      final replayedStates = await harness.replayedStates();
      expect(replayedStates, hasLength(1));
      expect(replayedStates.single.cityFoundingDraft, isNull);
      expect(replayedStates.single.units.single.workerJob, isNotNull);
      _expectSameAuthoritativeState(replayedStates.single, harness.state);
    },
  );
}

void _expectSameAuthoritativeState(
  GameClientState replayed,
  GameClientState live,
) {
  expect(_authoritativeProjection(replayed), _authoritativeProjection(live));
}

Object _authoritativeProjection(GameClientState state) =>
    state.domain.copyWith(actions: DomainActionState.empty);

void _expectExactWorkerCommand(DomainCommand? actual, DomainCommand expected) {
  expect(actual, isNotNull);
  expect(actual.runtimeType, expected.runtimeType);
  expect(actual, expected);
  expect(
    DomainCommandCodec.toJson(actual!),
    DomainCommandCodec.toJson(expected),
  );
}

void _expectAcceptedWorkerEffect(
  _AcceptedWorkerEffect effect, {
  required GameClientState before,
  required GameClientState after,
}) {
  final workerBefore = before.units.single;
  final workerAfter = after.units.single;
  expect(workerAfter.id, workerBefore.id);
  expect(workerAfter.col, workerBefore.col);
  expect(workerAfter.row, workerBefore.row);
  expect(after.cities, before.cities);
  expect(after.fieldImprovements, before.fieldImprovements);
  expect(after.research, before.research);

  switch (effect) {
    case _AcceptedWorkerEffect.startsFarmJob:
      expect(workerBefore.workerJob, isNull);
      expect(
        workerAfter.workerJob?.targetHex,
        CityHex(col: workerBefore.col, row: workerBefore.row),
      );
      expect(workerAfter.workerJob?.improvementType, FieldImprovementType.farm);
      expect(
        workerAfter.workerJob?.remainingTurns,
        workerAfter.workerJob?.totalTurns,
      );
      expect(workerAfter.workerAssignment, workerBefore.workerAssignment);
    case _AcceptedWorkerEffect.cancelsJob:
      expect(workerBefore.workerJob, isNotNull);
      expect(workerAfter.workerJob, isNull);
      expect(workerAfter.workerAssignment, workerBefore.workerAssignment);
    case _AcceptedWorkerEffect.assignsHex:
      expect(workerBefore.workerAssignment, isNull);
      expect(
        workerAfter.workerAssignment,
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 1)),
      );
      expect(workerAfter.workerJob, workerBefore.workerJob);
      expect(workerAfter.movementPoints, 0);
    case _AcceptedWorkerEffect.cancelsAssignment:
      expect(workerBefore.workerAssignment, isNotNull);
      expect(workerAfter.workerAssignment, isNull);
      expect(workerAfter.workerJob, workerBefore.workerJob);
  }
}

List<_AcceptedWorkerReplayScenario> _acceptedWorkerReplayScenarios() => [
  _AcceptedWorkerReplayScenario(
    name: 'select improvement without preview',
    initialState: _workerReplayState(),
    command: const SelectWorkerImprovementCommand(
      'worker_1',
      FieldImprovementType.farm,
    ),
    effect: _AcceptedWorkerEffect.startsFarmJob,
  ),
  _AcceptedWorkerReplayScenario(
    name: 'confirm improvement with complete payload',
    initialState: _workerReplayState(),
    command: const ConfirmWorkerImprovementCommand(
      'worker_1',
      improvementType: FieldImprovementType.farm,
    ),
    effect: _AcceptedWorkerEffect.startsFarmJob,
  ),
  _AcceptedWorkerReplayScenario(
    name: 'cancel active job',
    initialState: _workerReplayState(
      workerJob: const WorkerJob(
        targetHex: CityHex(col: 1, row: 1),
        improvementType: FieldImprovementType.farm,
        remainingTurns: 2,
        totalTurns: 3,
      ),
    ),
    command: const CancelWorkerJobCommand('worker_1'),
    effect: _AcceptedWorkerEffect.cancelsJob,
  ),
  _AcceptedWorkerReplayScenario(
    name: 'assign to improved city hex',
    initialState: _workerReplayState(
      fieldImprovements: const [
        FieldImprovement(
          hex: CityHex(col: 1, row: 1),
          type: FieldImprovementType.farm,
          builtByCityId: 'city_1',
        ),
      ],
    ),
    command: const AssignWorkerToHexCommand('worker_1'),
    effect: _AcceptedWorkerEffect.assignsHex,
  ),
  _AcceptedWorkerReplayScenario(
    name: 'cancel active assignment',
    initialState: _workerReplayState(
      workerAssignment: const WorkerAssignment(
        targetHex: CityHex(col: 1, row: 1),
      ),
    ),
    command: const CancelWorkerAssignmentCommand('worker_1'),
    effect: _AcceptedWorkerEffect.cancelsAssignment,
  ),
];

enum _AcceptedWorkerEffect {
  startsFarmJob,
  cancelsJob,
  assignsHex,
  cancelsAssignment,
}

final class _AcceptedWorkerReplayScenario {
  const _AcceptedWorkerReplayScenario({
    required this.name,
    required this.initialState,
    required this.command,
    required this.effect,
  });

  final String name;
  final GameClientState initialState;
  final DomainCommand command;
  final _AcceptedWorkerEffect effect;
}

GameClientState _workerReplayState({
  int workerCol = 1,
  int workerRow = 1,
  CityFoundingDraft? cityFoundingDraft,
  WorkerJob? workerJob,
  WorkerAssignment? workerAssignment,
  List<FieldImprovement> fieldImprovements = const [],
}) {
  final worker = GameUnit(
    id: 'worker_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: GameUnitType.worker.defaultNameToken,
    col: workerCol,
    row: workerRow,
    workerJob: workerJob,
    workerAssignment: workerAssignment,
  );
  return GameClientState(
    units: [worker],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 1)],
      ),
    ],
    fieldImprovements: fieldImprovements,
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
        ),
      },
    ),
    activePlayerId: 'player_1',
    activePlayerCanAct: true,
    interaction: InteractionState(cityFoundingDraft: cityFoundingDraft),
  );
}

final class _WorkerReplayHarness {
  _WorkerReplayHarness._({
    required this.state,
    required this.repository,
    required this.eventLog,
    required this.replayStore,
    required this.reducer,
    required this.transport,
  });

  factory _WorkerReplayHarness.create(GameClientState initialState) {
    final save = _save(players: const [_player1]);
    final initialSnapshot = GameSnapshotFactory.fromClientState(
      save: save,
      state: initialState,
    );
    final repository = _MemoryGameRepository(initialSnapshot);
    final eventLog = _MemoryEventLog();
    final replayStore = _MemoryReplayStore(initialSnapshot);
    final reducer = GameStateReducer(mapData: _map());
    final transport = LocalCommandTransport(
      reducer: reducer,
      gameRepository: repository,
      eventLog: eventLog,
      snapshotStore: _MemorySnapshotStore(),
      clock: _FixedClock(DateTime.utc(2026, 7, 18, 12)),
    );
    return _WorkerReplayHarness._(
      state: initialSnapshot.toClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      ),
      repository: repository,
      eventLog: eventLog,
      replayStore: replayStore,
      reducer: reducer,
      transport: transport,
    );
  }

  GameClientState state;
  final _MemoryGameRepository repository;
  final _MemoryEventLog eventLog;
  final _MemoryReplayStore replayStore;
  final GameStateReducer reducer;
  final LocalCommandTransport transport;
  int? lastDispatchOffset;

  Future<void> dispatch(DomainCommand command) async {
    final result = await transport.dispatch(
      saveId: repository.snapshot.save.id,
      currentState: state,
      command: command,
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );
    state = result.state;
    lastDispatchOffset = result.offset;
  }

  Future<void> dispatchIntent(GameIntent intent) async {
    final resolution = GameIntentResolver(
      reducer: reducer,
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    ).resolve(state.interaction, intent, state);
    final command = resolution.domainCommand;
    if (command != null) {
      await dispatch(command);
      return;
    }
    state = resolution.interaction == state.interaction
        ? state
        : state.copyWith(interaction: resolution.interaction);
    lastDispatchOffset = null;
  }

  Future<ReplayTimeline> replayTimeline() {
    return ReplayService(
      replayStore: replayStore,
      eventLog: eventLog,
      commandResolver: LocalCommandResolver(reducer: reducer),
    ).buildTimeline(repository.snapshot.save.id);
  }

  Future<List<GameClientState>> replayedStates() async {
    final timeline = await replayTimeline();
    return [for (final step in timeline.steps) step.state];
  }
}
