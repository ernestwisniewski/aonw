import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
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
  controlledHexes: [CityHex(col: 1, row: 1)],
);

GameUnit _workerWithJob(
  int remainingTurns, {
  int col = 1,
  int row = 1,
  FieldImprovementType improvementType = FieldImprovementType.farm,
}) =>
    GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: col,
      row: row,
      movementPoints: 0,
    ).copyWithWorkerJob(
      WorkerJob(
        targetHex: CityHex(col: col, row: row),
        improvementType: improvementType,
        remainingTurns: remainingTurns,
        totalTurns: 2,
      ),
    );

void main() {
  group('WorkerTurnProcessor', () {
    test('decrements active worker jobs between turns', () {
      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [_workerWithJob(2)],
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
      );

      expect(result.changed, isTrue);
      expect(result.units.single.workerJob?.remainingTurns, 1);
      expect(result.fieldImprovements, isEmpty);
    });

    test('completes worker job and creates a field improvement', () {
      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [_workerWithJob(1)],
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
      );

      expect(result.units, isEmpty);
      expect(result.fieldImprovements, hasLength(1));
      expect(result.fieldImprovements.single.type, FieldImprovementType.farm);
      expect(result.fieldImprovements.single.builtByCityId, 'city_1');
    });

    test('cancels a completed job outside city borders', () {
      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [_workerWithJob(1, col: 1, row: 0)],
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
      );

      expect(
        result.cities.single.controlledHexes,
        isNot(contains(const CityHex(col: 1, row: 0))),
      );
      expect(result.fieldImprovements, isEmpty);
      expect(result.units.single.workerJob, isNull);
    });

    test('completing fishing boats works on controlled coastal fish', () {
      final coastalMap = MapData(
        cols: 3,
        rows: 3,
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 1 && row == 0
                    ? const [TerrainType.coast]
                    : const [TerrainType.grassland],
                resources: col == 1 && row == 0
                    ? const [ResourceType.fish]
                    : const [],
                height: 0,
              ),
        ],
      );

      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [
          _workerWithJob(
            1,
            col: 1,
            row: 0,
            improvementType: FieldImprovementType.fishingBoats,
          ),
        ],
        cities: [
          _city().copyWith(
            controlledHexes: [
              ..._city().controlledHexes,
              const CityHex(col: 1, row: 0),
            ],
          ),
        ],
        fieldImprovements: const [],
        mapData: coastalMap,
      );

      expect(
        result.cities.single.controlledHexes,
        contains(const CityHex(col: 1, row: 0)),
      );
      expect(
        result.fieldImprovements.single.type,
        FieldImprovementType.fishingBoats,
      );
    });

    test('completing pearl divers works on controlled coastal pearls', () {
      final coastalMap = MapData(
        cols: 3,
        rows: 3,
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 1 && row == 0
                    ? const [TerrainType.coast]
                    : const [TerrainType.grassland],
                resources: col == 1 && row == 0
                    ? const [ResourceType.pearls]
                    : const [],
                height: 0,
              ),
        ],
      );

      final result = WorkerTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        units: [
          _workerWithJob(
            1,
            col: 1,
            row: 0,
            improvementType: FieldImprovementType.pearlDivers,
          ),
        ],
        cities: [
          _city().copyWith(
            controlledHexes: [
              ..._city().controlledHexes,
              const CityHex(col: 1, row: 0),
            ],
          ),
        ],
        fieldImprovements: const [],
        mapData: coastalMap,
      );

      expect(
        result.cities.single.controlledHexes,
        contains(const CityHex(col: 1, row: 0)),
      );
      expect(
        result.fieldImprovements.single.type,
        FieldImprovementType.pearlDivers,
      );
    });
  });
}
