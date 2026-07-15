import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCityProductionResolver bounded map lookup', () {
    test('rejects a terrain-gated wonder without the required neighbor', () {
      final result = _startHangingGardens(_worldMap());

      expect(result.accepted, isFalse);
      expect(result.reason, 'wonder_not_available');
    });

    test('starts a terrain-gated wonder through WorldMap lookup', () {
      final result = _startHangingGardens(_worldMap(withAdjacentRiver: true));

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.productionQueue?.target,
        const WonderProductionTarget(WonderType.hangingGardens),
      );
    });

    test('rushes a unit and resolves its spawn through WorldMap lookup', () {
      const target = UnitProductionTarget(GameUnitType.warrior);
      final targetCost = CityProductionRules.targetCost(target);
      final city =
          const GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'City',
            center: CityHex(col: 1, row: 1),
          ).copyWith(
            productionQueue: CityProductionQueue.unit(
              unitType: GameUnitType.warrior,
              investedProduction: targetCost - 1,
            ),
          );
      final state = PersistentGameState(
        cities: [city],
        playerGold: const {'player_1': 100},
      );

      final result = const PersistentCityProductionResolver().rushProduction(
        state: state,
        command: const RushProductionCommand('city_1'),
        actorPlayerId: 'player_1',
        worldMap: _worldMap(),
      );

      expect(result.accepted, isTrue);
      expect(result.state.cities.single.productionQueue, isNull);
      expect(result.state.units.single.type, GameUnitType.warrior);
      expect(
        result.state.units.single.coordinate,
        const HexCoordinate(col: 1, row: 1),
      );
      expect(result.state.playerGold['player_1'], lessThan(100));
      expect(result.events.single, isA<CityProducedUnitEvent>());
    });
  });
}

PersistentCityProductionResult _startHangingGardens(WorldMap worldMap) {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 1, row: 1),
  );
  final state = PersistentGameState(
    cities: [city],
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.waterEngineering},
        ),
      },
    ),
  );

  return const PersistentCityProductionResolver().startWonder(
    state: state,
    command: const StartWonderCommand('city_1', WonderType.hangingGardens),
    actorPlayerId: 'player_1',
    worldMap: worldMap,
  );
}

WorldMap _worldMap({bool withAdjacentRiver = false}) {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: col == 2 && row == 1 && withAdjacentRiver
                ? const [TerrainType.grassland, TerrainType.river]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
