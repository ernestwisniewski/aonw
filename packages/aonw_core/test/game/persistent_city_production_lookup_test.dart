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
