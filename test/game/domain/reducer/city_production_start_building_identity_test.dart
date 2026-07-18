import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'same target takes the accepted local no-op path with new identities',
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
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.craftsmanship},
            ),
          },
        ),
      );

      final result = CityProductionReducer.startBuilding(
        state,
        const StartBuildingCommand('city_1', CityBuildingType.workshop),
        WorldMapReadView(_worldMap()),
      );

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
