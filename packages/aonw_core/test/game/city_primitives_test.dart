import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('CityHex', () {
    test('serializes coordinates', () {
      const hex = CityHex(col: 2, row: 3);

      expect(CityHex.fromJson(hex.toJson()), hex);
      expect(hex.toJson(), {'col': 2, 'row': 3});
    });

    test('converts to and from HexCoordinate', () {
      const coordinate = HexCoordinate(col: 4, row: 5);

      final hex = CityHex.fromCoordinate(coordinate);

      expect(hex, const CityHex(col: 4, row: 5));
      expect(hex.toCoordinate(), coordinate);
    });

    test('checks tile occupation', () {
      const hex = CityHex(col: 1, row: 2);

      expect(hex.occupies(1, 2), isTrue);
      expect(hex.occupies(2, 1), isFalse);
    });
  });

  group('FieldImprovementType', () {
    test('parses names used on the wire', () {
      for (final type in FieldImprovementType.values) {
        expect(FieldImprovementType.fromString(type.name), same(type));
      }
    });

    test('exposes user-facing display names', () {
      expect(FieldImprovementType.farm.displayName, 'Farm');
      expect(FieldImprovementType.fishingBoats.displayName, 'Fishing boats');
    });

    test('rejects unknown names', () {
      expect(
        () => FieldImprovementType.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FieldImprovement', () {
    test('serializes improvement data', () {
      const improvement = FieldImprovement(
        hex: CityHex(col: 2, row: 4),
        type: FieldImprovementType.mine,
        builtByCityId: 'city_1',
      );

      expect(FieldImprovement.fromJson(improvement.toJson()), improvement);
      expect(improvement.occupies(2, 4), isTrue);
      expect(improvement.occupies(4, 2), isFalse);
    });
  });

  group('city ruleset primitives', () {
    test('exposes unlimited-paced production costs by default', () {
      expect(
        CityProductionRules.buildingProductionCost(CityBuildingType.granary),
        9,
      );
      expect(CityProductionRules.unitProductionCost(GameUnitType.worker), 19);
      expect(
        CityRulesets.standard.buildingDefinitionFor(CityBuildingType.port),
        isA<CityBuildingDefinition>(),
      );
    });

    test('applies pace balance to production and growth costs', () {
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 3,
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      );

      expect(
        CityProductionRules.buildingProductionCost(
          CityBuildingType.granary,
          paceBalance: PaceBalance.standard60,
        ),
        6,
      );
      expect(
        CityProductionRules.unitProductionCost(
          GameUnitType.worker,
          paceBalance: PaceBalance.standard60,
        ),
        12,
      );
      expect(
        CityGrowthRules.growthCost(city, paceBalance: PaceBalance.standard60),
        27,
      );
      expect(
        CityGrowthRules.growthCost(city, paceBalance: PaceBalance.unlimited),
        36,
      );
    });

    test('keeps unlimited midgame production from collapsing to one turn', () {
      const productiveMidgameCity = 20;

      final spearmanCost = CityProductionRules.unitProductionCost(
        GameUnitType.spearman,
      );
      final forgeCost = CityProductionRules.buildingProductionCost(
        CityBuildingType.forge,
      );

      expect(
        CityProductionRules.estimatedTurnsRemaining(
          productionCost: spearmanCost,
          investedProduction: 0,
          productionPerTurn: productiveMidgameCity,
        ),
        greaterThanOrEqualTo(2),
      );
      expect(
        CityProductionRules.estimatedTurnsRemaining(
          productionCost: forgeCost,
          investedProduction: 0,
          productionPerTurn: productiveMidgameCity,
        ),
        greaterThanOrEqualTo(2),
      );
    });

    test('keeps settlers and heavier units out of one-turn territory', () {
      const strongEarlyProduction = 14;

      for (final unitType in const [
        GameUnitType.settler,
        GameUnitType.spearman,
      ]) {
        final cost = CityProductionRules.unitProductionCost(
          unitType,
          paceBalance: PaceBalance.standard60,
        );
        expect(
          CityProductionRules.estimatedTurnsRemaining(
            productionCost: cost,
            investedProduction: 0,
            productionPerTurn: strongEarlyProduction,
          ),
          greaterThanOrEqualTo(2),
          reason: '${unitType.name} should not be a one-turn core build',
        );
      }
    });

    test('keeps early unit production brisk in a healthy start city', () {
      const healthyEarlyProduction = 6;

      final expectedMaxTurns = {
        GameUnitType.worker: 2,
        GameUnitType.scout: 2,
        GameUnitType.warrior: 2,
        GameUnitType.archer: 3,
        GameUnitType.settler: 3,
        GameUnitType.spearman: 3,
      };

      for (final entry in expectedMaxTurns.entries) {
        final cost = CityProductionRules.unitProductionCost(
          entry.key,
          paceBalance: PaceBalance.standard60,
        );
        expect(
          CityProductionRules.estimatedTurnsRemaining(
            productionCost: cost,
            investedProduction: 0,
            productionPerTurn: healthyEarlyProduction,
          ),
          lessThanOrEqualTo(entry.value),
          reason: '${entry.key.name} should feel viable in the early game',
        );
      }
    });

    test('serializes production targets and queues', () {
      final queue = CityProductionQueue.unit(
        unitType: GameUnitType.archer,
        investedProduction: 4,
      );

      expect(CityProductionQueue.fromJson(queue.toJson()), queue);
      expect(
        CityProductionTarget.fromJson({
          'kind': 'building',
          'buildingType': CityBuildingType.workshop.name,
        }),
        const BuildingProductionTarget(CityBuildingType.workshop),
      );
      expect(
        CityProductionTarget.fromJson({
          'kind': 'project',
          'projectType': CityProjectType.research.name,
        }),
        const ProjectProductionTarget(CityProjectType.research),
      );
    });

    test('calculates city progression values', () {
      expect(
        CityProgressionCatalog.standard.growthCost(
          population: 3,
          territoryHexCount: 4,
        ),
        34,
      );
      expect(CityProgressionCatalog.standard.workedHexLimitForPopulation(3), 3);
    });

    test('checks field improvement requirements against core tile data', () {
      const riverGrassland = TileData(
        col: 1,
        row: 2,
        terrains: [TerrainType.grassland, TerrainType.river],
        resources: [],
        height: 0,
      );

      final definition =
          FieldImprovementCatalog.standard[FieldImprovementType.riverFarm]!;

      expect(definition.canImprove(riverGrassland), isTrue);
      expect(definition.failureFor(riverGrassland), isNull);
    });
  });

  group('GameCity', () {
    test('round-trips persistent city state', () {
      final city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'City 1',
        population: 4,
        storedFood: 5,
        center: const CityHex(col: 0, row: 0),
        controlledHexes: const [CityHex(col: 1, row: 0)],
        workedHexes: const [CityHex(col: 0, row: 0)],
        preferredExpansionHex: const CityHex(col: 0, row: 1),
        buildings: const {CityBuildingType.granary},
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 3,
        ),
        productionOverflow: 2,
        specialization: CitySpecializationType.industry,
        hitPoints: 11,
      );

      expect(GameCity.fromJson(city.toJson()), city);
      expect(city.capitalOwnerPlayerId, 'player_1');
      expect(city.territoryHexCount, 2);
      expect(city.controlsTile(1, 0), isTrue);
    });

    test('preserves founding owner when city owner changes', () {
      const city = GameCity(
        id: 'city_player_2_0_0',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 0, row: 0),
      );

      final captured = city.copyWith(ownerPlayerId: 'player_1');

      expect(captured.ownerPlayerId, 'player_1');
      expect(captured.foundingOwnerPlayerId, 'player_2');
      expect(captured.capitalOwnerPlayerId, 'player_2');
    });

    test('defaults missing collection metadata from JSON', () {
      final json =
          const GameCity(
              id: 'city_player_1_0_0',
              ownerPlayerId: 'player_1',
              name: 'City 1',
              center: CityHex(col: 0, row: 0),
            ).toJson()
            ..remove('controlledHexes')
            ..remove('workedHexes')
            ..remove('buildings');

      final decoded = GameCity.fromJson(json);

      expect(decoded.controlledHexes, isEmpty);
      expect(decoded.workedHexes, isEmpty);
      expect(decoded.buildings, isEmpty);
      expect(decoded.productionOverflow, 0);
      expect(decoded.preferredExpansionHex, isNull);
      expect(decoded.foundingOwnerPlayerId, isNull);
      expect(decoded.capitalOwnerPlayerId, 'player_1');
    });

    test('copyWith can preserve and clear nullable production queue', () {
      final city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.worker,
          investedProduction: 1,
        ),
      );

      expect(city.copyWith().productionQueue, city.productionQueue);
      expect(city.copyWith(productionQueue: null).productionQueue, isNull);
    });

    test(
      'copyWith can preserve and clear nullable preferred expansion hex',
      () {
        const city = GameCity(
          id: 'city_player_1_0_0',
          ownerPlayerId: 'player_1',
          name: 'City 1',
          center: CityHex(col: 0, row: 0),
          preferredExpansionHex: CityHex(col: 0, row: 1),
        );

        expect(
          city.copyWith().preferredExpansionHex,
          city.preferredExpansionHex,
        );
        expect(
          city.copyWith(preferredExpansionHex: null).preferredExpansionHex,
          isNull,
        );
      },
    );

    test('copyWith can set and clear specialization', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 0),
        specialization: CitySpecializationType.commerce,
      );

      expect(
        city
            .copyWith(specialization: CitySpecializationType.science)
            .specialization,
        CitySpecializationType.science,
      );
      expect(city.copyWith(specialization: null).specialization, isNull);
    });
  });

  group('CitySpecializationRules', () {
    test('maps specializations to economy bonuses', () {
      expect(
        CitySpecializationRules.yieldFor(CitySpecializationType.growth).food,
        2,
      );
      expect(
        CitySpecializationRules.yieldFor(
          CitySpecializationType.industry,
        ).production,
        2,
      );
      expect(
        CitySpecializationRules.yieldFor(CitySpecializationType.commerce).gold,
        3,
      );
      expect(
        CitySpecializationRules.scienceFor(CitySpecializationType.science),
        2,
      );
    });

    test('requires an anchor building for each specialization', () {
      expect(
        CitySpecializationRules.requiredBuildingFor(
          CitySpecializationType.growth,
        ),
        CityBuildingType.granary,
      );
      expect(
        CitySpecializationRules.requiredBuildingFor(
          CitySpecializationType.industry,
        ),
        CityBuildingType.workshop,
      );
      expect(
        CitySpecializationRules.requiredBuildingFor(
          CitySpecializationType.commerce,
        ),
        CityBuildingType.merchantHall,
      );
      expect(
        CitySpecializationRules.requiredBuildingFor(
          CitySpecializationType.science,
        ),
        CityBuildingType.archive,
      );
      expect(
        CitySpecializationRules.requiredBuildingFor(
          CitySpecializationType.military,
        ),
        CityBuildingType.barracks,
      );
      expect(
        CitySpecializationRules.hasRequiredBuilding({
          CityBuildingType.archive,
        }, CitySpecializationType.science),
        isTrue,
      );
      expect(
        CitySpecializationRules.hasRequiredBuilding({
          CityBuildingType.granary,
        }, CitySpecializationType.science),
        isFalse,
      );
    });

    test('specialization boosts only matching production targets', () {
      expect(
        CitySpecializationRules.productionPerTurnForTarget(
          productionPerTurn: 4,
          target: const UnitProductionTarget(GameUnitType.warrior),
          specialization: CitySpecializationType.military,
        ),
        5,
      );
      expect(
        CitySpecializationRules.productionPerTurnForTarget(
          productionPerTurn: 4,
          target: const UnitProductionTarget(GameUnitType.worker),
          specialization: CitySpecializationType.growth,
        ),
        5,
      );
      expect(
        CitySpecializationRules.productionPerTurnForTarget(
          productionPerTurn: 4,
          target: const BuildingProductionTarget(CityBuildingType.granary),
          specialization: CitySpecializationType.industry,
        ),
        5,
      );
      expect(
        CitySpecializationRules.productionPerTurnForTarget(
          productionPerTurn: 4,
          target: const ProjectProductionTarget(CityProjectType.wealth),
          specialization: CitySpecializationType.commerce,
        ),
        5,
      );
      expect(
        CitySpecializationRules.productionPerTurnForTarget(
          productionPerTurn: 4,
          target: const ProjectProductionTarget(CityProjectType.research),
          specialization: CitySpecializationType.science,
        ),
        5,
      );
      expect(
        CitySpecializationRules.productionPerTurnForTarget(
          productionPerTurn: 4,
          target: const ProjectProductionTarget(CityProjectType.wealth),
          specialization: CitySpecializationType.science,
        ),
        4,
      );
    });
  });

  group('CityTerritoryRules', () {
    test('accepts territory connected through the city center', () {
      expect(
        CityTerritoryRules.isConnected(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 4, row: 2),
          ],
        ),
        isTrue,
      );
    });

    test('rejects disconnected controlled hexes', () {
      expect(
        CityTerritoryRules.isConnected(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 4, row: 2),
            CityHex(col: 0, row: 2),
          ],
        ),
        isFalse,
      );
    });

    test('allows first-ring expansion without previous-ring support', () {
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [],
          target: const CityHex(col: 3, row: 2),
          maxDistance: 2,
        ),
        isTrue,
      );
    });

    test('requires two adjacent previous-ring hexes for outer expansion', () {
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [CityHex(col: 3, row: 2)],
          target: const CityHex(col: 4, row: 2),
          maxDistance: 2,
        ),
        isFalse,
      );
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 3, row: 1),
          ],
          target: const CityHex(col: 4, row: 2),
          maxDistance: 2,
        ),
        isTrue,
      );
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [CityHex(col: 4, row: 2)],
          target: const CityHex(col: 5, row: 2),
          maxDistance: 3,
        ),
        isFalse,
      );
      expect(
        CityTerritoryRules.hasExpansionSupport(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 4, row: 2),
            CityHex(col: 4, row: 3),
          ],
          target: const CityHex(col: 5, row: 2),
          maxDistance: 3,
        ),
        isTrue,
      );
    });
  });

  group('CityTerritoryBoundary', () {
    test('single city hex has all six outer edges', () {
      final edges = CityTerritoryBoundary.edgesFor(const [
        CityHex(col: 2, row: 2),
      ]);

      expect(edges, hasLength(6));
      expect(
        edges.map((edge) => edge.side).toSet(),
        CityHexEdge.values.toSet(),
      );
    });
  });

  group('CityFoundingDraft', () {
    test('round-trips through JSON and checks confirmability', () {
      final draft = CityFoundingDraft(
        unitId: 'commander_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [
          CityHex(col: 3, row: 2),
          CityHex(col: 4, row: 2),
        ],
      );

      expect(CityFoundingDraft.fromJson(draft.toJson()), draft);
      expect(draft.hasRequiredControlledHexes, isTrue);
      expect(draft.hasConnectedTerritory, isTrue);
      expect(draft.canConfirm, isTrue);
    });
  });
}
