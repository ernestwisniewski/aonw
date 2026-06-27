import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: switch ((col, row)) {
            (2, 1) => const [TerrainType.hills],
            _ => const [TerrainType.grassland],
          },
          resources: const [],
          height: 0,
        ),
  ],
);

GameCity _city() => const GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 1, row: 1), CityHex(col: 2, row: 1)],
);

GameUnit _worker({int col = 1, int row = 1}) => GameUnit(
  id: 'worker_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.worker,
  name: GameUnitType.worker.defaultNameToken,
  col: col,
  row: row,
);

ResearchState _research(Set<TechnologyId> unlocked) {
  return ResearchState(
    players: {'player_1': PlayerResearchState(unlockedTechnologyIds: unlocked)},
  );
}

void main() {
  group('WorkerReducer via GameStateReducer', () {
    test(
      'select worker improvement sets pending preview without starting a job',
      () {
        final worker = _worker();
        final state = GameState(
          units: [worker],
          cities: [_city()],
          research: _research({TechnologyId.agriculture}),
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          interaction: GameInteractionState(
            selection: GameSelection.unit(worker),
          ),
        );
        final reducer = GameStateReducer(mapData: _map());

        final afterStart = reducer
            .reduce(state, const StartWorkerActionSelectionCommand('worker_1'))
            .state;

        final afterSelect = reducer
            .reduce(
              afterStart,
              const SelectWorkerImprovementCommand(
                'worker_1',
                FieldImprovementType.farm,
              ),
            )
            .state;

        final pending = afterSelect.pendingAction;
        expect(pending, isA<PendingWorkerActionSelection>());
        expect(
          (pending as PendingWorkerActionSelection).improvementType,
          FieldImprovementType.farm,
        );
        final updatedWorker = afterSelect.units.firstWhere(
          (u) => u.id == worker.id,
        );
        expect(updatedWorker.workerJob, isNull);
        expect(updatedWorker.movementPoints, worker.movementPoints);
      },
    );

    test(
      'confirm worker improvement creates a job from the previewed type',
      () {
        final worker = _worker();
        final state = GameState(
          units: [worker],
          cities: [_city()],
          research: _research({TechnologyId.agriculture}),
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          interaction: GameInteractionState(
            selection: GameSelection.unit(worker),
          ),
        );
        final reducer = GameStateReducer(mapData: _map());

        final afterStart = reducer
            .reduce(state, const StartWorkerActionSelectionCommand('worker_1'))
            .state;
        final afterSelect = reducer
            .reduce(
              afterStart,
              const SelectWorkerImprovementCommand(
                'worker_1',
                FieldImprovementType.farm,
              ),
            )
            .state;

        final afterConfirm = reducer
            .reduce(
              afterSelect,
              const ConfirmWorkerImprovementCommand('worker_1'),
            )
            .state;

        final updatedWorker = afterConfirm.units.firstWhere(
          (u) => u.id == worker.id,
        );
        expect(updatedWorker.workerJob, isNotNull);
        expect(
          updatedWorker.workerJob!.improvementType,
          FieldImprovementType.farm,
        );
        expect(updatedWorker.movementPoints, 0);
        expect(afterConfirm.pendingAction, isNull);
      },
    );

    test('direct select worker improvement starts a job', () {
      final worker = _worker();
      final state = GameState(
        units: [worker],
        cities: [_city()],
        research: _research({TechnologyId.agriculture}),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker),
        ),
      );
      final reducer = GameStateReducer(mapData: _map());

      final result = reducer.reduce(
        state,
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.farm,
        ),
      );

      final updatedWorker = result.state.units.firstWhere(
        (u) => u.id == worker.id,
      );
      expect(updatedWorker.workerJob, isNotNull);
      expect(updatedWorker.workerJob!.targetHex, const CityHex(col: 1, row: 1));
      expect(
        updatedWorker.workerJob!.improvementType,
        FieldImprovementType.farm,
      );
      expect(updatedWorker.movementPoints, 0);
      expect(result.state.pendingAction, isNull);
    });

    test('does not start an improvement outside city borders', () {
      final worker = _worker(col: 1, row: 0);
      final state = GameState(
        units: [worker],
        cities: [_city()],
        research: _research({TechnologyId.agriculture}),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker),
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );
      final reducer = GameStateReducer(mapData: _map());

      final result = reducer.reduce(
        state,
        const ConfirmWorkerImprovementCommand('worker_1'),
      );

      final updatedWorker = result.state.units.single;
      expect(updatedWorker.workerJob, isNull);
      expect(result.state.pendingAction, state.pendingAction);
    });

    test('cancel worker job clears active job from the unit', () {
      final worker = _worker().copyWithWorkerJob(
        const WorkerJob(
          targetHex: CityHex(col: 1, row: 1),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 2,
        ),
      );
      final state = GameState(
        units: [worker],
        cities: [_city()],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker),
        ),
      );
      final reducer = GameStateReducer(mapData: _map());

      final result = reducer.reduce(
        state,
        const CancelWorkerJobCommand('worker_1'),
      );

      expect(result.state.units.single.workerJob, isNull);
    });

    test('assign worker to improved city hex consumes action', () {
      final worker = _worker();
      final state = GameState(
        units: [worker],
        cities: [_city()],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker),
        ),
      );
      final reducer = GameStateReducer(mapData: _map());

      final result = reducer.reduce(
        state,
        const AssignWorkerToHexCommand('worker_1'),
      );

      final updatedWorker = result.state.units.single;
      expect(
        updatedWorker.workerAssignment?.targetHex,
        const CityHex(col: 1, row: 1),
      );
      expect(updatedWorker.movementPoints, 0);
      expect(result.state.pendingAction, isNull);
    });

    test('cancel worker assignment detaches worker from field bonus', () {
      final worker = _worker().copyWithWorkerAssignment(
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 1)),
      );
      final state = GameState(
        units: [worker],
        cities: [_city()],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker),
        ),
      );
      final reducer = GameStateReducer(mapData: _map());

      final result = reducer.reduce(
        state,
        const CancelWorkerAssignmentCommand('worker_1'),
      );

      expect(result.state.units.single.workerAssignment, isNull);
    });
  });
}
