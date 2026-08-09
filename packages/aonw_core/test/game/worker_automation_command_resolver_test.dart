import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DomainWorkerAutomationCommandResolver', () {
    test('starts the shared recommended improvement on the current hex', () {
      final worker = _worker(col: 1, movementPoints: 2);
      final state = _state(
        units: [worker],
        cities: [
          _city(centerCol: 0, controlledCols: const [1]),
        ],
      );

      final result = _resolve(state);

      expect(result.accepted, isTrue);
      expect(result.execution, isNull);
      final updated = result.state.units.single;
      expect(updated.posture, UnitPosture.active);
      expect(updated.movementPoints, 0);
      expect(updated.workerJob, isNotNull);
      final recommendation = WorkerImprovementRecommendation.bestForHex(
        unit: worker,
        targetHex: const CityHex(col: 1, row: 0),
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        mapTiles: _map(),
        research: state.research,
      );
      expect(updated.workerJob?.improvementType, recommendation?.type);
    });

    test('uses path cost and keeps automation with a queued route', () {
      final worker = _worker(col: 4, movementPoints: 1);
      final state = _state(
        units: [worker],
        cities: [
          _city(centerCol: 0, controlledCols: const [1]),
        ],
      );

      final result = _resolve(state);

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      final updated = result.state.units.single;
      expect(updated.col, 3);
      expect(updated.queuedPath?.targetCol, 1);
      expect(updated.posture, UnitPosture.autoWorking);
      expect(updated.workerJob, isNull);
    });

    test('prefers any reachable build task over a nearer assignment', () {
      final worker = _worker(col: 3, movementPoints: 1);
      final state = _state(
        units: [worker],
        cities: [
          _city(centerCol: 4, controlledCols: const [0, 2]),
        ],
        improvements: const [
          FieldImprovement(
            hex: CityHex(col: 2, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
      );

      final result = _resolve(state);

      expect(result.accepted, isTrue);
      final updated = result.state.units.single;
      expect(updated.queuedPath?.targetCol, 0);
      expect(updated.workerAssignment, isNull);
      expect(updated.posture, UnitPosture.autoWorking);
    });

    test('falls back to working a free completed improvement', () {
      final worker = _worker(col: 1, movementPoints: 2);
      final state = _state(
        units: [worker],
        cities: [
          _city(centerCol: 0, controlledCols: const [1]),
        ],
        improvements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
      );

      final result = _resolve(state);

      expect(result.accepted, isTrue);
      final updated = result.state.units.single;
      expect(updated.workerJob, isNull);
      expect(
        updated.workerAssignment,
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 0)),
      );
      expect(updated.posture, UnitPosture.active);
      expect(updated.movementPoints, 0);
    });

    test('rejects a direct request when no legal task exists', () {
      final state = _state(units: [_worker(col: 4, movementPoints: 2)]);

      final result = _resolve(state);

      expect(result.accepted, isFalse);
      expect(result.reason, 'worker_automation_no_target');
      expect(identical(result.state, state), isTrue);
    });

    test('continuation replans and begins work after reaching its target', () {
      final queued = QueuedMovePath(
        targetCol: 1,
        targetRow: 0,
        steps: const [
          UnitMovementStep(col: 2, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final worker = _worker(
        col: 2,
        movementPoints: 2,
      ).copyWithPosture(UnitPosture.autoWorking).copyWithQueuedPath(queued);
      final state = _state(
        units: [worker],
        cities: [
          _city(centerCol: 0, controlledCols: const [1]),
        ],
      );

      final result = _resolve(
        state,
        phase: WorkerAutomationCommandPhase.continuation,
      );

      expect(result.accepted, isTrue);
      expect(result.execution?.destination.col, 1);
      final updated = result.state.units.single;
      expect(updated.col, 1);
      expect(updated.workerJob, isNotNull);
      expect(updated.posture, UnitPosture.active);
    });

    test('another automatic worker reserves its target hex', () {
      final reservedPath = QueuedMovePath(
        targetCol: 1,
        targetRow: 0,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final first = _worker(id: 'worker_1', col: 0, movementPoints: 1)
          .copyWithPosture(UnitPosture.autoWorking)
          .copyWithQueuedPath(reservedPath);
      final second = _worker(id: 'worker_2', col: 4, movementPoints: 1);
      final state = _state(
        units: [first, second],
        cities: [
          _city(centerCol: 0, controlledCols: const [1, 2]),
        ],
      );

      final result = _resolve(state, unitId: second.id);

      expect(result.accepted, isTrue);
      expect(result.state.units.last.queuedPath?.targetCol, 2);
    });
  });

  test(
    'turn movement continues automatic travel and starts work on arrival',
    () {
      final initialPath = QueuedMovePath(
        targetCol: 1,
        targetRow: 0,
        steps: const [
          UnitMovementStep(col: 4, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 3),
        ],
      );
      final worker = _worker(col: 4, movementPoints: 0)
          .copyWithPosture(UnitPosture.autoWorking)
          .copyWithQueuedPath(initialPath);
      final state = _state(
        units: [worker],
        cities: [
          _city(centerCol: 0, controlledCols: const [1]),
        ],
      );

      final first = DomainTurnMovementProcessor.resetForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: _map(),
      );
      final travelling = first.state.units.single;

      expect(first.executions, hasLength(1));
      expect(travelling.col, 1);
      expect(travelling.posture, UnitPosture.autoWorking);
      expect(travelling.queuedPath, isNull);
      expect(travelling.movementPoints, 0);
      expect(travelling.workerJob, isNull);

      final second = DomainTurnMovementProcessor.resetForPlayers(
        state: first.state,
        playerIds: const ['player_1'],
        mapData: _map(),
      );
      final working = second.state.units.single;

      expect(working.col, 1);
      expect(working.workerJob, isNotNull);
      expect(working.posture, UnitPosture.active);
      expect(working.queuedPath, isNull);
    },
  );
}

DomainWorkerAutomationCommandResult _resolve(
  DomainState state, {
  String unitId = 'worker_1',
  WorkerAutomationCommandPhase phase = WorkerAutomationCommandPhase.direct,
}) {
  return const DomainWorkerAutomationCommandResolver().resolve(
    state: state,
    interaction: state.actions,
    command: AutomateWorkerCommand(unitId),
    actorPlayerId: 'player_1',
    mapData: _map(),
    phase: phase,
  );
}

DomainState _state({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  List<FieldImprovement> improvements = const [],
}) {
  return DomainState.snapshot(
    units: units,
    cities: cities,
    fieldImprovements: improvements,
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: const {
            TechnologyId.agriculture,
            TechnologyId.mining,
          },
        ),
      },
    ),
  );
}

GameUnit _worker({
  String id = 'worker_1',
  required int col,
  required int movementPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: 'Worker',
    col: col,
    row: 0,
    movementPoints: movementPoints,
  );
}

GameCity _city({required int centerCol, required List<int> controlledCols}) {
  return GameCity.snapshot(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: centerCol, row: 0),
    controlledHexes: [
      for (final col in controlledCols) CityHex(col: col, row: 0),
    ],
  );
}

WorldMap _map() {
  return WorldMap(
    cols: 5,
    rows: 1,
    tiles: [
      for (var col = 0; col < 5; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
