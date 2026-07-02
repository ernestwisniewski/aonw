import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('City turn rules', () {
    test('calculates worked tile yield and economy breakdown', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      final tileYield = CityYieldCalculator.totalFor(city, _map());
      final economy = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: _map(),
      );

      expect(
        tileYield,
        const TileYield(food: 3, production: 4, gold: 0, defense: 0),
      );
      expect(economy.populationUpkeep, 3);
      expect(economy.netFood, 0);
      expect(economy.netYield.production, 4);
    });

    test('specialization contributes city economy and science', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        specialization: CitySpecializationType.commerce,
      );
      final cityYield = CityYieldCalculator.totalFor(city, _map());
      final economy = CityEconomyBreakdown.from(
        city: city,
        tileYield: cityYield,
        mapData: _map(),
      );

      expect(economy.specializationYield.gold, 3);
      expect(economy.netYield.gold, 3);

      final science = ScienceYieldCalculator.totalForPlayer(
        playerId: 'player_1',
        cities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_1',
            name: 'Academy',
            center: CityHex(col: 0, row: 0),
            specialization: CitySpecializationType.science,
          ),
        ],
        research: ResearchState.empty,
        ruleset: TechnologyRulesets.standard,
      );

      expect(science.byCityId['city_2'], 4);
    });

    test('stability modifiers gate growth and scale city yields', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      const tileYield = TileYield(food: 6, production: 5, gold: 5, defense: 0);

      final stable = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: _map(),
      );
      final content = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: _map(),
        stabilityModifier: StabilityPolicy.modifierFor(StabilityBand.content),
      );
      final strained = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: _map(),
        stabilityModifier: StabilityPolicy.modifierFor(StabilityBand.strained),
      );
      final unrest = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: _map(),
        stabilityModifier: StabilityPolicy.modifierFor(StabilityBand.unrest),
      );

      expect(content.foodDeposit, stable.foodDeposit + 1);
      expect(content.netYield, stable.netYield);
      expect(strained.foodDeposit, 0);
      expect(strained.netYield.production, stable.netYield.production);
      expect(strained.netYield.gold, 4);
      expect(unrest.foodDeposit, 0);
      expect(unrest.netYield.production, 3);
      expect(unrest.netYield.gold, 3);
    });

    test('military specialization accelerates unit production only', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: const CityHex(col: 0, row: 0),
        specialization: CitySpecializationType.military,
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction:
              CityProductionRules.unitProductionCost(GameUnitType.warrior) - 1,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _map(),
      );

      expect(result.cities.single.productionQueue, isNull);
      expect(result.units.single.type, GameUnitType.warrior);
      expect(result.events.single.type, CityTurnEventType.producedUnit);
    });

    test('advances production queues and emits city events', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction:
              CityProductionRules.buildingProductionCost(
                CityBuildingType.granary,
              ) -
              1,
        ),
      );

      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        mapData: _map(),
      );
      final updatedCity = result.cities.single;

      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(result.events.single.type, CityTurnEventType.builtBuilding);
      expect(result.hasStateChanges, isTrue);
    });
  });
}

MapData _map() {
  return MapData(
    cols: 2,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [ResourceType.iron],
        height: 0,
      ),
    ],
  );
}
