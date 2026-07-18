import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'same building target is an accepted value no-op with new identities',
    () {
      final queue = CityProductionQueue.building(
        buildingType: CityBuildingType.workshop,
        investedProduction: 5,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 0, row: 0),
        productionQueue: queue,
        productionOverflow: 6,
      );
      final state = PersistentGameState(
        cities: [city],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.craftsmanship},
            ),
          },
        ),
      );

      final result = const PersistentCityProductionResolver().startBuilding(
        state: state,
        command: const StartBuildingCommand(
          'city_1',
          CityBuildingType.workshop,
        ),
        actorPlayerId: 'player_1',
        mapTiles: WorldMapReadView(_worldMap()),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.events, isEmpty);
      expect(result.state, state);
      expect(result.state, isNot(same(state)));
      expect(result.state.cities, isNot(same(state.cities)));
      expect(result.state.cities.single, isNot(same(city)));
      expect(result.state.cities.single.productionQueue, queue);
      expect(result.state.cities.single.productionQueue, isNot(same(queue)));
    },
  );
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 1,
    rows: 1,
    tiles: [
      WorldTile(
        coordinate: const HexCoord(col: 0, row: 0),
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
    ],
  );
}
