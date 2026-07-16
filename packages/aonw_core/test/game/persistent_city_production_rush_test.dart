part of 'persistent_city_production_resolver_test.dart';

void _registerBuildingRushProductionTests() {
  group('building rush production', () {
    test('rushes building production and emits event', () {
      final granaryCost = CityProductionRules.targetCost(
        const BuildingProductionTarget(CityBuildingType.granary),
      );
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: granaryCost - 1,
        ),
      );
      final state = PersistentGameState(
        cities: [city],
        playerGold: const {'player_1': 2},
      );

      final result = const PersistentCityProductionResolver().rushProduction(
        state: state,
        command: const RushProductionCommand('city_1'),
        actorPlayerId: 'player_1',
        mapTiles: WorldMapReadView(_worldMap()),
      );

      final updatedCity = result.state.cities.single;
      expect(result.accepted, isTrue);
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(result.state.playerGold['player_1'], 0);
      expect(result.events.single, isA<CityBuiltBuildingEvent>());
    });

    test('uses cached unrest production for rush amount and cost', () {
      final cityRuleset = CityRulesets.standard.copyWith(
        cityCenterYield: const TileYield(
          food: 2,
          production: 8,
          gold: 0,
          defense: 0,
        ),
      );
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.workshop,
          investedProduction: 0,
        ),
      );
      final state = PersistentGameState(
        cities: [city],
        playerGold: const {'player_1': 12},
        playerStabilityNet: const {'player_1': -4},
      );

      final result = const PersistentCityProductionResolver().rushProduction(
        state: state,
        command: const RushProductionCommand('city_1'),
        actorPlayerId: 'player_1',
        mapTiles: WorldMapReadView(_worldMap()),
        cityRuleset: cityRuleset,
        stabilityRuleset: StabilityRuleset.standard,
      );

      expect(result.accepted, isTrue);
      expect(result.state.playerGold['player_1'], 0);
      expect(result.state.cities.single.productionQueue?.investedProduction, 6);
      expect(result.events, isEmpty);
    });
  });
}
