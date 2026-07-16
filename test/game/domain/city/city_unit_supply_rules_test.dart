import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityUnitSupplyRules', () {
    test('uses population plus net food as unit supply capacity', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      );

      final supply = CityUnitSupplyRules.forPlayer(
        playerId: 'player_1',
        cities: [city],
        units: const [],
        fieldImprovements: const [],
        artifacts: const [],
        mapView: _grassMap(),
      );

      expect(supply.capacity, 6);
      expect(supply.used, 0);
      expect(supply.available, 6);
    });

    test('counts existing units and queued units against supply', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        center: const CityHex(col: 1, row: 1),
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.settler,
          investedProduction: 0,
        ),
      );
      final units = [
        GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 1,
        ),
      ];

      final supply = CityUnitSupplyRules.forPlayer(
        playerId: 'player_1',
        cities: [city],
        units: units,
        fieldImprovements: const [],
        artifacts: const [],
        mapView: _grassMap(),
      );

      expect(supply.capacity, 3);
      expect(supply.unitSupplyUsed, 2);
      expect(supply.queuedSupplyUsed, 1);
      expect(supply.used, 3);
      expect(supply.available, 0);
    });

    test('blocks new unit queue when supply is full', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        center: CityHex(col: 1, row: 1),
      );
      final units = [
        for (var i = 0; i < 3; i++)
          GameUnit.produced(
            id: 'worker_$i',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: i,
            row: 0,
          ),
      ];

      expect(
        CityUnitSupplyRules.canQueueUnit(
          playerId: 'player_1',
          unitType: GameUnitType.warrior,
          cities: [city],
          units: units,
          fieldImprovements: const [],
          artifacts: const [],
          mapView: _grassMap(),
        ),
        isFalse,
      );
    });

    test('caps high food empires to the map-scaled unit ceiling', () {
      final cities = [
        for (var i = 0; i < 5; i++)
          GameCity(
            id: 'city_$i',
            ownerPlayerId: 'player_1',
            name: 'City $i',
            population: 3,
            center: const CityHex(col: 1, row: 1),
            controlledHexes: const [
              CityHex(col: 1, row: 0),
              CityHex(col: 0, row: 1),
            ],
          ),
      ];
      final mapData = _grassMap();

      final supply = CityUnitSupplyRules.forPlayer(
        playerId: 'player_1',
        cities: cities,
        units: const [],
        fieldImprovements: const [],
        artifacts: const [],
        mapView: mapData,
      );

      expect(supply.rawCapacity, 30);
      expect(supply.mapCapacity, CityUnitSupplyRules.minimumMapCapacity);
      expect(supply.capacity, CityUnitSupplyRules.minimumMapCapacity);
      expect(
        CityUnitSupplyRules.canQueueUnit(
          playerId: 'player_1',
          unitType: GameUnitType.warrior,
          cities: cities,
          units: [
            for (var i = 0; i < CityUnitSupplyRules.minimumMapCapacity; i++)
              GameUnit.produced(
                id: 'worker_$i',
                ownerPlayerId: 'player_1',
                type: GameUnitType.worker,
                col: i % 3,
                row: i ~/ 3,
              ),
          ],
          fieldImprovements: const [],
          artifacts: const [],
          mapView: mapData,
        ),
        isFalse,
      );
    });
  });
}

MapData _grassMap() => MapData(
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
