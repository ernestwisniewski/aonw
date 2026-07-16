part of 'city_reducer_test.dart';

void _registerCityRushProductionTests(MapData Function() mapDataProvider) {
  group('rushProduction', () {
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
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        playerGold: const {'player_1': 12},
        playerStabilityNet: const {'player_1': -4},
      );

      final result = CityProductionReducer.rushProduction(
        state,
        const RushProductionCommand('city_1'),
        mapDataProvider(),
        ruleset: GameRuleset.defaults.copyWith(city: cityRuleset),
      );

      expect(result.state.playerGold['player_1'], 0);
      expect(result.state.cities.single.productionQueue?.investedProduction, 6);
      expect(result.events, isEmpty);
    });

    test('spends gold to finish an active building queue', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 5,
        ),
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        playerGold: const {'player_1': 2},
      );

      final result = CityProductionReducer.rushProduction(
        state,
        const RushProductionCommand('city_1'),
        mapDataProvider(),
        context: const GameCommandContext(paceBalance: PaceBalance.long120),
      );

      final updatedCity = result.state.cities.single;
      expect(updatedCity.buildings, contains(CityBuildingType.granary));
      expect(updatedCity.productionQueue, isNull);
      expect(result.state.playerGold['player_1'], 0);
      expect(result.events.single, isA<CityBuiltBuildingEvent>());
    });

    test('keeps state unchanged when treasury cannot pay rush cost', () {
      final city = _city().copyWith(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 7,
        ),
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        playerGold: const {'player_1': 1},
      );

      final result = CityProductionReducer.rushProduction(
        state,
        const RushProductionCommand('city_1'),
        mapDataProvider(),
      );

      expect(result.state, same(state));
      expect(result.events, isEmpty);
    });
  });
}
