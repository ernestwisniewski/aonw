import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Worker turn rules', () {
    test('blocks locked improvements with required technology', () {
      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(col: 1, row: 0),
        improvementType: FieldImprovementType.mine,
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
        research: ResearchState.empty,
      );

      expect(legality.allowed, isFalse);
      expect(legality.blocker, WorkerImprovementBlocker.technologyLocked);
      expect(legality.requiredTechnology?.id, TechnologyId.mining);
    });

    test('completes worker job and consumes the default worker', () {
      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [_workerWithJob()],
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
      );
      final updatedCity = result.cities.single;
      final improvement = result.fieldImprovements.single;

      expect(result.changed, isTrue);
      expect(result.units, isEmpty);
      expect(
        updatedCity.controlledHexes.where(
          (hex) => hex == const CityHex(col: 1, row: 0),
        ),
        hasLength(1),
      );
      expect(improvement.type, FieldImprovementType.farm);
      expect(improvement.builtByCityId, 'city_1');
    });

    test('keeps a worker with remaining improvement charges', () {
      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [_workerWithJob().copyWithWorkerBuildCharges(2)],
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
      );
      final updatedWorker = result.units.single;

      expect(updatedWorker.workerJob, isNull);
      expect(updatedWorker.workerBuildCharges, 1);
      expect(result.fieldImprovements.single.type, FieldImprovementType.farm);
    });
  });
}

GameCity _city() => const GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 0, row: 1), CityHex(col: 1, row: 0)],
);

GameUnit _worker({required int col, required int row}) => GameUnit(
  id: 'worker_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.worker,
  name: GameUnitType.worker.defaultNameToken,
  col: col,
  row: row,
);

GameUnit _workerWithJob() {
  return _worker(col: 1, row: 0).copyWithWorkerJob(
    const WorkerJob(
      targetHex: CityHex(col: 1, row: 0),
      improvementType: FieldImprovementType.farm,
      remainingTurns: 1,
      totalTurns: 1,
    ),
  );
}

MapData _map() {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 2; col++)
          TileData(
            col: col,
            row: row,
            terrains: col == 1 && row == 0
                ? const [TerrainType.hills]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
