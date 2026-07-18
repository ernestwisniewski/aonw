part of 'local_command_transport_test.dart';

void _registerWorkerReplayTests() {
  test(
    'keeps worker previews out of replay and logs one complete confirmation',
    () async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 1,
      );
      final initialState = GameState(
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
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
            ),
          },
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final save = _save(players: const [_player1]);
      final initialSnapshot = SaveSnapshot.fromGameState(
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
      var state = initialSnapshot.toGameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );

      Future<void> dispatch(GameCommand command) async {
        final result = await transport.dispatch(
          saveId: save.id,
          currentState: state,
          command: command,
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );
        state = result.state;
      }

      await dispatch(const StartWorkerActionSelectionCommand('worker_1'));
      await dispatch(
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.mine,
        ),
      );
      await dispatch(
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );
      await dispatch(const CancelWorkerActionSelectionCommand('worker_1'));

      expect(eventLog.commands, isEmpty);
      expect(repository.snapshot.eventLogOffset, 0);
      expect(state.pendingAction, isNull);
      expect(state.units.single.workerJob, isNull);

      await dispatch(const StartWorkerActionSelectionCommand('worker_1'));
      await dispatch(
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );
      await dispatch(const ConfirmWorkerImprovementCommand('worker_1'));

      expect(eventLog.commands, hasLength(1));
      expect(repository.snapshot.eventLogOffset, 1);
      expect(
        eventLog.commands.single.command,
        const ConfirmWorkerImprovementCommand(
          'worker_1',
          improvementType: FieldImprovementType.farm,
        ),
      );
      final liveJob = state.units.single.workerJob;
      expect(liveJob?.improvementType, FieldImprovementType.farm);
      expect(liveJob?.remainingTurns, liveJob?.totalTurns);

      final timeline = await ReplayService(
        replayStore: replayStore,
        eventLog: eventLog,
        commandResolver: LocalCommandResolver(reducer: reducer),
      ).buildTimeline(save.id);

      expect(timeline.steps, hasLength(1));
      final replayed = timeline.steps.single.state;
      expect(
        replayed.toPersistentState().withoutClientInteractionState(),
        state.toPersistentState().withoutClientInteractionState(),
      );
      expect(
        replayed.units.single.workerJob?.remainingTurns,
        liveJob?.totalTurns,
      );
      expect(replayed.fieldImprovements, isEmpty);
    },
  );
}

final class _MemoryReplayStore implements ReplayStore {
  _MemoryReplayStore(this.snapshot);

  SaveSnapshot? snapshot;

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async => snapshot;

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {
    snapshot = null;
  }
}
