import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentWorkerCommandResolver', () {
    test('starts a worker improvement for a controlled worker', () {
      final state = _state(
        research: _researchWith(TechnologyId.agriculture),
        runtimeState: const GameRuntimeState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );

      final result = const PersistentWorkerCommandResolver()
          .selectWorkerImprovement(
            state: state,
            command: const SelectWorkerImprovementCommand(
              'worker_1',
              FieldImprovementType.farm,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      final worker = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(worker.movementPoints, 0);
      expect(worker.workerAssignment, isNull);
      expect(worker.workerJob?.targetHex, const CityHex(col: 1, row: 0));
      expect(worker.workerJob?.improvementType, FieldImprovementType.farm);
      expect(worker.workerJob?.remainingTurns, 3);
      expect(result.state.runtimeState.pendingAction, isNull);
    });

    test('uses the selected pace for worker improvement duration', () {
      final state = _state(research: _researchWith(TechnologyId.agriculture));

      final result = const PersistentWorkerCommandResolver()
          .selectWorkerImprovement(
            state: state,
            command: const SelectWorkerImprovementCommand(
              'worker_1',
              FieldImprovementType.farm,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
            paceBalance: PaceBalance.standard60,
          );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.workerJob?.remainingTurns, 2);
      expect(result.state.units.single.workerJob?.totalTurns, 2);
    });

    test('confirms a pending worker improvement', () {
      final state = _state(
        research: _researchWith(TechnologyId.agriculture),
        runtimeState: const GameRuntimeState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );

      final result = const PersistentWorkerCommandResolver()
          .confirmWorkerImprovement(
            state: state,
            command: const ConfirmWorkerImprovementCommand('worker_1'),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isTrue);
      expect(
        result.state.units.single.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
      expect(result.state.runtimeState.pendingAction, isNull);
    });

    test('rejects a locked worker improvement', () {
      final state = _state();

      final result = const PersistentWorkerCommandResolver()
          .selectWorkerImprovement(
            state: state,
            command: const SelectWorkerImprovementCommand(
              'worker_1',
              FieldImprovementType.farm,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'worker_improvement_unavailable');
      expect(result.state, state);
    });

    test('rejects worker commands for another player unit', () {
      final state = _state(workerOwnerPlayerId: 'player_2');

      final result = const PersistentWorkerCommandResolver()
          .selectWorkerImprovement(
            state: state,
            command: const SelectWorkerImprovementCommand(
              'worker_1',
              FieldImprovementType.farm,
            ),
            actorPlayerId: 'player_1',
            mapDefinition: _mapDefinition(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'worker_not_controlled');
      expect(result.state, state);
    });

    test('cancels an active worker job', () {
      final worker = _worker().copyWithWorkerJob(
        const WorkerJob(
          targetHex: CityHex(col: 1, row: 0),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 2,
        ),
      );
      final state = PersistentGameState(units: [worker]);

      final result = const PersistentWorkerCommandResolver().cancelWorkerJob(
        state: state,
        command: const CancelWorkerJobCommand('worker_1'),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.workerJob, isNull);
    });

    test('assigns a worker to an existing improvement', () {
      final state = _state(
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
      );

      final result = const PersistentWorkerCommandResolver().assignWorkerToHex(
        state: state,
        command: const AssignWorkerToHexCommand('worker_1'),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      final worker = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(
        worker.workerAssignment,
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 0)),
      );
      expect(worker.movementPoints, 0);
    });

    test('cancels an active worker assignment', () {
      final worker = _worker().copyWithWorkerAssignment(
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 0)),
      );
      final state = PersistentGameState(units: [worker]);

      final result = const PersistentWorkerCommandResolver()
          .cancelWorkerAssignment(
            state: state,
            command: const CancelWorkerAssignmentCommand('worker_1'),
            actorPlayerId: 'player_1',
          );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.workerAssignment, isNull);
    });
  });
}

PersistentGameState _state({
  String workerOwnerPlayerId = 'player_1',
  ResearchState research = ResearchState.empty,
  GameRuntimeState runtimeState = GameRuntimeState.empty,
  List<FieldImprovement> fieldImprovements = const [],
}) {
  return PersistentGameState(
    units: [_worker(ownerPlayerId: workerOwnerPlayerId)],
    cities: [_city()],
    fieldImprovements: fieldImprovements,
    research: research,
    runtimeState: runtimeState,
  );
}

GameUnit _worker({String ownerPlayerId = 'player_1'}) {
  return GameUnit(
    id: 'worker_1',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.worker,
    name: 'Worker',
    col: 1,
    row: 0,
  );
}

GameCity _city() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 0, row: 0),
    controlledHexes: [CityHex(col: 1, row: 0)],
  );
}

ResearchState _researchWith(TechnologyId technologyId) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: {technologyId}),
    },
  );
}

MapDefinition _mapDefinition() {
  return MapDefinition(
    cols: 4,
    rows: 4,
    mapName: 'duel',
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
