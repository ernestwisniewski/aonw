import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final customRuleset = CityRulesets.standard.copyWith(
    buildings: {
      CityBuildingType.granary: const CityBuildingDefinition(
        type: CityBuildingType.granary,
        productionCost: 2,
      ),
    },
  );

  MapData grassMap() => MapData(
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

  group('CityProductionRules.buildingProductionCost', () {
    final unlimitedBuildingCosts = {
      CityBuildingType.granary: 9,
      CityBuildingType.waterMill: 22,
      CityBuildingType.workshop: 22,
      CityBuildingType.storehouse: 18,
      CityBuildingType.housing: 27,
      CityBuildingType.merchantHall: 18,
      CityBuildingType.stonemason: 22,
      CityBuildingType.barracks: 24,
      CityBuildingType.marketplace: 29,
      CityBuildingType.port: 27,
      CityBuildingType.aqueduct: 29,
      CityBuildingType.forge: 32,
      CityBuildingType.stable: 27,
      CityBuildingType.bank: 32,
      CityBuildingType.buildersGuild: 31,
      CityBuildingType.factory: 44,
      CityBuildingType.lighthouse: 29,
      CityBuildingType.trainingGrounds: 32,
      CityBuildingType.townHall: 35,
      CityBuildingType.monument: 22,
    };

    for (final entry in unlimitedBuildingCosts.entries) {
      test(
        '${entry.key.name} costs ${entry.value} production in unlimited',
        () {
          expect(
            CityProductionRules.buildingProductionCost(entry.key),
            entry.value,
          );
        },
      );
    }

    test('reads production cost from an injected ruleset', () {
      expect(
        CityProductionRules.buildingProductionCost(
          CityBuildingType.granary,
          ruleset: customRuleset,
        ),
        3,
      );
    });

    test('reads target cost from a building production target', () {
      expect(
        CityProductionRules.targetCost(
          const BuildingProductionTarget(CityBuildingType.granary),
        ),
        9,
      );
    });

    test('reads target cost from a unit production target', () {
      expect(
        CityProductionRules.targetCost(
          const UnitProductionTarget(GameUnitType.warrior),
        ),
        20,
      );
    });

    test('reads unit production cost from ruleset', () {
      expect(CityProductionRules.unitProductionCost(GameUnitType.archer), 21);
    });
  });

  group('CityProductionRules.canBuild', () {
    test('returns false if building already built', () {
      expect(
        CityProductionRules.canBuild({
          CityBuildingType.granary,
        }, CityBuildingType.granary),
        isFalse,
      );
    });

    test('returns true if building not yet built', () {
      expect(
        CityProductionRules.canBuild({
          CityBuildingType.granary,
        }, CityBuildingType.workshop),
        isTrue,
      );
    });

    test('returns false if technology is locked', () {
      expect(
        CityProductionRules.canBuild(
          {CityBuildingType.granary},
          CityBuildingType.workshop,
          technologyUnlocked: false,
        ),
        isFalse,
      );
    });

    test('returns false if building requirements are not met', () {
      expect(
        CityProductionRules.canBuild(
          {},
          CityBuildingType.port,
          requirementsMet: false,
        ),
        isFalse,
      );
    });
  });

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
        mapData: grassMap(),
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
        mapData: grassMap(),
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
          mapData: grassMap(),
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
      final mapData = grassMap();

      final supply = CityUnitSupplyRules.forPlayer(
        playerId: 'player_1',
        cities: cities,
        units: const [],
        fieldImprovements: const [],
        mapData: mapData,
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
          mapData: mapData,
        ),
        isFalse,
      );
    });
  });

  group('CityProductionQueue', () {
    test('building constructor creates a building production target', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      );

      expect(
        q.target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
    });

    test('unit constructor creates a unit production target', () {
      final q = CityProductionQueue.unit(
        unitType: GameUnitType.archer,
        investedProduction: 1,
      );

      expect(q.target, const UnitProductionTarget(GameUnitType.archer));
    });

    test('project constructor creates a project production target', () {
      final q = CityProductionQueue.project(
        projectType: CityProjectType.research,
      );

      expect(q.target, const ProjectProductionTarget(CityProjectType.research));
      expect(q.investedProduction, 0);
    });

    test('isComplete when invested production >= production cost', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 9,
      );
      expect(q.isComplete, isTrue);
    });

    test('not complete when invested production < production cost', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 8,
      );
      expect(q.isComplete, isFalse);
    });

    test('isCompleteFor uses the injected ruleset', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 3,
      );

      expect(q.isCompleteFor(customRuleset), isTrue);
    });

    test('project queues are continuous and never complete', () {
      final q = CityProductionQueue.project(
        projectType: CityProjectType.wealth,
        investedProduction: 99,
      );

      expect(q.isComplete, isFalse);
      expect(q.isCompleteFor(customRuleset), isFalse);
      expect(CityProductionRules.targetCost(q.target), 0);
      expect(CityProductionRules.canRush(q.target), isFalse);
    });

    test('advancedBy increments invested production by production amount', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 1,
      );
      expect(q.advancedBy(3).investedProduction, 4);
      expect(
        q.advancedBy(3).target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
    });

    test('advancedBy ignores non-positive production', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 1,
      );

      expect(q.advancedBy(0), q);
      expect(q.advancedBy(-1), q);
    });

    test('completionOverflow returns only production above target cost', () {
      expect(
        CityProductionRules.completionOverflow(
          productionCost: 8,
          investedProduction: 11,
        ),
        3,
      );
      expect(
        CityProductionRules.completionOverflow(
          productionCost: 8,
          investedProduction: 8,
        ),
        0,
      );
    });

    test(
      'rolloverInvestment caps stored overflow at half next target cost',
      () {
        expect(
          CityProductionRules.rolloverInvestment(
            storedOverflow: 6,
            productionCost: 8,
          ),
          4,
        );
        expect(
          CityProductionRules.rolloverInvestment(
            storedOverflow: 2,
            productionCost: 8,
          ),
          2,
        );
      },
    );

    test('estimatedTurnsRemaining uses production per turn', () {
      expect(
        CityProductionRules.estimatedTurnsRemaining(
          productionCost: 7,
          investedProduction: 1,
          productionPerTurn: 2,
        ),
        3,
      );
    });

    test('estimatedTurnsRemaining is null without production', () {
      expect(
        CityProductionRules.estimatedTurnsRemaining(
          productionCost: 7,
          investedProduction: 1,
          productionPerTurn: 0,
        ),
        isNull,
      );
    });

    test(
      'toJson writes target and invested production for building queues',
      () {
        final q = CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 2,
        );

        expect(q.toJson(), {
          'target': {'kind': 'building', 'buildingType': 'workshop'},
          'investedProduction': 2,
        });
      },
    );

    test('toJson writes target and invested production for unit queues', () {
      final q = CityProductionQueue.unit(
        unitType: GameUnitType.settler,
        investedProduction: 2,
      );

      expect(q.toJson(), {
        'target': {'kind': 'unit', 'unitType': 'settler'},
        'investedProduction': 2,
      });
    });

    test('toJson writes target and invested production for project queues', () {
      final q = CityProductionQueue.project(
        projectType: CityProjectType.research,
        investedProduction: 0,
      );

      expect(q.toJson(), {
        'target': {'kind': 'project', 'projectType': 'research'},
        'investedProduction': 0,
      });
    });

    test('fromJson reads new target JSON', () {
      final q = CityProductionQueue.fromJson({
        'target': {'kind': 'building', 'buildingType': 'workshop'},
        'investedProduction': 2,
      });

      expect(
        q,
        CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 2,
        ),
      );
    });

    test('toJson / fromJson roundtrip', () {
      final q = CityProductionQueue.building(
        buildingType: CityBuildingType.workshop,
        investedProduction: 2,
      );
      expect(CityProductionQueue.fromJson(q.toJson()), equals(q));
    });

    test('unit queue toJson / fromJson roundtrip', () {
      final q = CityProductionQueue.unit(
        unitType: GameUnitType.archer,
        investedProduction: 3,
      );
      expect(CityProductionQueue.fromJson(q.toJson()), equals(q));
    });

    test('project queue toJson / fromJson roundtrip', () {
      final q = CityProductionQueue.project(
        projectType: CityProjectType.wealth,
      );
      expect(CityProductionQueue.fromJson(q.toJson()), equals(q));
    });
  });
}
