import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _grassMap() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

MapData _coastalMap() {
  final map = _grassMap();
  final coastIndex = map.tiles.indexWhere(
    (tile) => tile.col == 2 && tile.row == 1,
  );
  map.tiles[coastIndex] = map.tiles[coastIndex].copyWith(
    terrains: const [TerrainType.coast],
  );
  final oceanIndex = map.tiles.indexWhere(
    (tile) => tile.col == 3 && tile.row == 1,
  );
  map.tiles[oceanIndex] = map.tiles[oceanIndex].copyWith(
    terrains: const [TerrainType.ocean],
  );
  return map;
}

GameCity _city({
  CityProductionQueue? productionQueue,
  CitySpecializationType? specialization,
}) {
  return GameCity(
    id: 'city',
    ownerPlayerId: 'player_1',
    name: 'City',
    population: 3,
    storedFood: 0,
    center: const CityHex(col: 1, row: 1),
    controlledHexes: const [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)],
    buildings: const {},
    specialization: specialization,
    productionQueue: productionQueue,
  );
}

void main() {
  group('CityTurnProcessor production queue', () {
    final fastGranaryRuleset = CityRulesets.standard.copyWith(
      buildings: {
        CityBuildingType.granary: const CityBuildingDefinition(
          type: CityBuildingType.granary,
          productionCost: 1,
        ),
      },
    );
    final fastWarriorRuleset = CityRulesets.standard.copyWith(
      units: {
        ...CityRulesets.standard.units,
        GameUnitType.warrior: const UnitProductionDefinition(
          type: GameUnitType.warrior,
          productionCost: 1,
        ),
      },
    );
    final fastScoutShipRuleset = CityRulesets.standard.copyWith(
      units: {
        ...CityRulesets.standard.units,
        GameUnitType.scoutShip: const UnitProductionDefinition(
          type: GameUnitType.scoutShip,
          productionCost: 1,
        ),
      },
    );

    test('adds city production yield to invested production each turn', () {
      final city = _city(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      final updatedCity = result.cities.single;
      expect(updatedCity.productionQueue?.investedProduction, 1);
      expect(
        updatedCity.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
      expect(updatedCity.buildings, isEmpty);
    });

    test(
      'completes building and clears queue when invested production reaches cost',
      () {
        final city = _city(
          productionQueue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 9,
          ),
        );

        final result = CityTurnProcessor.advanceForPlayer(
          playerId: 'player_1',
          cities: [city],
          fieldImprovements: const [],
          mapData: _grassMap(),
          paceBalance: PaceBalance.long120,
        );

        final updatedCity = result.cities.single;
        expect(updatedCity.buildings, contains(CityBuildingType.granary));
        expect(updatedCity.productionQueue, isNull);
        expect(
          result.events.map((e) => e.type),
          contains(CityTurnEventType.builtBuilding),
        );
      },
    );

    test('uses injected city ruleset when completing production', () {
      final city = _city(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _grassMap(),
        ruleset: fastGranaryRuleset,
        paceBalance: PaceBalance.long120,
      );

      final updatedCity = result.cities.single;
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
    });

    test('industry specialization boosts building production', () {
      final twoProductionGranaryRuleset = CityRulesets.standard.copyWith(
        buildings: {
          CityBuildingType.granary: const CityBuildingDefinition(
            type: CityBuildingType.granary,
            productionCost: 2,
          ),
        },
      );
      final city = _city(
        specialization: CitySpecializationType.industry,
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _grassMap(),
        ruleset: twoProductionGranaryRuleset,
      );

      final updatedCity = result.cities.single;
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
    });

    test('uses city production yield as build investment', () {
      final productionMap = MapData(
        cols: 4,
        rows: 4,
        tiles: [
          for (var row = 0; row < 4; row++)
            for (var col = 0; col < 4; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 2 && row == 1
                    ? const [TerrainType.hills]
                    : const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
        ],
      );
      final city = _city(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.housing,
          investedProduction: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: productionMap,
      );

      expect(result.cities.single.productionQueue?.investedProduction, 3);
    });

    test('stores production overflow when completing a building', () {
      final productionMap = MapData(
        cols: 4,
        rows: 4,
        tiles: [
          for (var row = 0; row < 4; row++)
            for (var col = 0; col < 4; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 2 && row == 1
                    ? const [TerrainType.hills]
                    : const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
        ],
      );
      final city = _city(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: productionMap,
        ruleset: fastGranaryRuleset,
        paceBalance: PaceBalance.long120,
      );

      final updatedCity = result.cities.single;
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(updatedCity.productionOverflow, 2);
    });

    test('adds strategic resource production from unlocked technologies', () {
      final coalMap = MapData(
        cols: 4,
        rows: 4,
        tiles: [
          for (var row = 0; row < 4; row++)
            for (var col = 0; col < 4; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.grassland],
                resources: col == 2 && row == 1
                    ? const [ResourceType.coal]
                    : const [],
                height: 0,
              ),
        ],
      );
      final city = _city(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.coalMining},
          ),
        },
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: coalMap,
        research: research,
      );

      expect(result.cities.single.productionQueue?.investedProduction, 2);
    });

    test('applies army production bonus only to unit queues', () {
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.logistics},
          ),
        },
      );

      final unitResult = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [
          _city(
            productionQueue: CityProductionQueue.unit(
              unitType: GameUnitType.warrior,
              investedProduction: 0,
            ),
          ),
        ],
        fieldImprovements: const [],
        mapData: _grassMap(),
        research: research,
        ruleset: fastWarriorRuleset.copyWith(
          units: {
            ...fastWarriorRuleset.units,
            GameUnitType.warrior: const UnitProductionDefinition(
              type: GameUnitType.warrior,
              productionCost: 2,
            ),
          },
        ),
        paceBalance: PaceBalance.long120,
      );

      final buildingResult = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [
          _city(
            productionQueue: CityProductionQueue.building(
              buildingType: CityBuildingType.granary,
              investedProduction: 0,
            ),
          ),
        ],
        fieldImprovements: const [],
        mapData: _grassMap(),
        research: research,
        ruleset: CityRulesets.standard.copyWith(
          buildings: {
            ...CityRulesets.standard.buildings,
            CityBuildingType.granary: const CityBuildingDefinition(
              type: CityBuildingType.granary,
              productionCost: 2,
            ),
          },
        ),
        paceBalance: PaceBalance.long120,
      );

      expect(unitResult.cities.single.productionQueue, isNull);
      expect(unitResult.units.single.type, GameUnitType.warrior);
      expect(
        buildingResult.cities.single.productionQueue?.investedProduction,
        1,
      );
      expect(buildingResult.cities.single.buildings, isEmpty);
    });

    test('does nothing when productionQueue is null', () {
      final city = _city(productionQueue: null);

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      final updatedCity = result.cities.single;
      expect(updatedCity.buildings, isEmpty);
      expect(updatedCity.productionQueue, isNull);
      expect(
        result.events.map((e) => e.type),
        isNot(contains(CityTurnEventType.builtBuilding)),
      );
    });

    test('wealth project converts city production into gold each turn', () {
      final city = _city(
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      expect(result.goldGained, 1);
      expect(result.scienceGained, ScienceYieldBreakdown.empty);
      expect(
        result.cities.single.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.wealth),
      );
    });

    test('research project converts city production into bonus science', () {
      final city = _city(
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      expect(result.goldGained, 0);
      expect(result.scienceGained.total, 1);
      expect(result.scienceGained.byCityId, {'city': 1});
      expect(result.scienceGained.sources.single.cityId, 'city');
      expect(
        result.cities.single.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.research),
      );
    });

    test('science specialization boosts research project output', () {
      final productionMap = _grassMap();
      final hillIndex = productionMap.tiles.indexWhere(
        (tile) => tile.col == 2 && tile.row == 1,
      );
      productionMap.tiles[hillIndex] = productionMap.tiles[hillIndex].copyWith(
        terrains: const [TerrainType.hills],
      );
      final city = _city(
        specialization: CitySpecializationType.science,
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );
      final highProductionRuleset = CityRulesets.standard.copyWith(
        cityCenterYield: const TileYield(
          food: 2,
          production: 12,
          gold: 0,
          defense: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: productionMap,
        ruleset: highProductionRuleset,
      );

      expect(result.scienceGained.total, 2);
      expect(result.scienceGained.byCityId, {'city': 2});
    });

    test(
      'produces unit and clears queue when invested production reaches cost',
      () {
        final city = _city(
          productionQueue: CityProductionQueue.unit(
            unitType: GameUnitType.warrior,
            investedProduction: 0,
          ),
        );

        final result = CityTurnProcessor.advanceForPlayer(
          playerId: 'player_1',
          cities: [city],
          fieldImprovements: const [],
          mapData: _grassMap(),
          ruleset: fastWarriorRuleset,
          paceBalance: PaceBalance.long120,
        );

        final updatedCity = result.cities.single;
        final producedUnit = result.units.single;
        expect(updatedCity.productionQueue, isNull);
        expect(producedUnit.type, GameUnitType.warrior);
        expect(producedUnit.col, city.center.col);
        expect(producedUnit.row, city.center.row);
        expect(
          result.events.map((event) => event.type),
          contains(CityTurnEventType.producedUnit),
        );
      },
    );

    test('produces naval unit on city coast hex', () {
      final city = _city(
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.scoutShip,
          investedProduction: 0,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _coastalMap(),
        ruleset: fastScoutShipRuleset,
        paceBalance: PaceBalance.long120,
      );

      final producedUnit = result.units.single;
      expect(result.cities.single.productionQueue, isNull);
      expect(producedUnit.type, GameUnitType.scoutShip);
      expect(producedUnit.col, 2);
      expect(producedUnit.row, 1);
      expect(
        result.events.map((event) => event.type),
        contains(CityTurnEventType.producedUnit),
      );
    });

    test('keeps completed unit queue when no spawn hex is available', () {
      final city = _city(
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 0,
        ),
      );
      final occupiedUnits = [
        GameUnit.produced(
          id: 'u_center',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        ),
        GameUnit.produced(
          id: 'u_21',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
        GameUnit.produced(
          id: 'u_22',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 2,
        ),
        GameUnit.produced(
          id: 'u_12',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 2,
        ),
        GameUnit.produced(
          id: 'u_02',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 0,
          row: 2,
        ),
        GameUnit.produced(
          id: 'u_01',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 0,
          row: 1,
        ),
        GameUnit.produced(
          id: 'u_10',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
      ];

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        units: occupiedUnits,
        mapData: _grassMap(),
        ruleset: fastWarriorRuleset,
        paceBalance: PaceBalance.long120,
      );

      expect(
        result.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 1,
        ),
      );
      expect(result.units, occupiedUnits);
      expect(
        result.events.map((event) => event.type),
        isNot(contains(CityTurnEventType.producedUnit)),
      );
    });
  });
}
