import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerAssignmentRules', () {
    test('limits active worker assignments by city population', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 2, row: 0)],
      );
      final assignedWorker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
        workerAssignment: const WorkerAssignment(
          targetHex: CityHex(col: 1, row: 0),
        ),
      );
      final nextWorker = GameUnit(
        id: 'worker_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 2,
        row: 0,
        movementPoints: 1,
      );

      final legality = WorkerAssignmentRules.evaluate(
        unit: nextWorker,
        cities: [city],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
          FieldImprovement(
            hex: CityHex(col: 2, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
        ],
        units: [assignedWorker, nextWorker],
        mapData: _map(),
      );

      expect(WorkerAssignmentRules.maxAssignmentsForCity(city), 1);
      expect(legality.allowed, isFalse);
      expect(
        legality.blocker,
        WorkerAssignmentBlocker.cityAssignmentLimitReached,
      );
    });
  });
}

MapData _map() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
