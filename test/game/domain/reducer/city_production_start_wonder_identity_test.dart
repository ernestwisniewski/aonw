import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

const _playerId = 'player_1';

void main() {
  test('rejected active wonder keeps the full local state and selection', () {
    final targetCity = _city(
      productionQueue: CityProductionQueue.wonder(
        wonderType: WonderType.hangingGardens,
        investedProduction: 13,
      ),
      productionOverflow: 7,
    );
    final selection = _citySelection(targetCity);
    final state = _stableCitiesState(
      cities: [targetCity],
      selection: selection,
      research: _writingResearch(),
    );
    final cities = state.cities;
    final city = cities.single;
    final queue = city.productionQueue;

    final result = _startWonder(state);

    expect(result.events, isEmpty);
    expect(result.state, same(state));
    expect(result.state.cities, same(cities));
    expect(result.state.cities.single, same(city));
    expect(result.state.cities.single.productionQueue, same(queue));
    expect(result.state.selection, same(selection));
  });

  test(
    'accepted replacement creates fresh identities and refreshes matching city',
    () {
      final targetCity = _city(
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 17,
        ),
        productionOverflow: 9,
      );
      final unrelatedCity = _city(
        id: 'unrelated_city',
        center: const CityHex(col: 2, row: 2),
      );
      final selection = _citySelection(targetCity);
      final state = _stableCitiesState(
        cities: [targetCity, unrelatedCity],
        selection: selection,
        research: _writingResearch(),
      );
      final cities = state.cities;
      final city = cities.first;
      final queue = city.productionQueue;
      final unrelated = cities.last;

      final result = _startWonder(state);

      final updatedCity = result.state.cities.first;
      final updatedQueue = updatedCity.productionQueue;
      expect(result.events, isEmpty);
      expect(result.state, isNot(same(state)));
      expect(result.state.cities, isNot(same(cities)));
      expect(updatedCity, isNot(same(city)));
      expect(updatedQueue, isNot(same(queue)));
      expect(result.state.cities.last, same(unrelated));
      expect(
        updatedQueue?.target,
        const WonderProductionTarget(WonderType.greatLibrary),
      );
      expect(updatedQueue?.investedProduction, 17);
      expect(updatedCity.productionOverflow, 9);
      expect(result.state.selection, isNot(same(selection)));
      expect(result.state.selection?.city, same(updatedCity));
    },
  );

  test('accepted replacement does not refresh a different city selection', () {
    final targetCity = _city(
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 17,
      ),
      productionOverflow: 9,
    );
    final selectedCity = _city(
      id: 'selected_city',
      center: const CityHex(col: 2, row: 2),
    );
    final selection = _citySelection(selectedCity);
    final state = _stableCitiesState(
      cities: [targetCity, selectedCity],
      selection: selection,
      research: _writingResearch(),
    );
    final selectedCityInState = state.cities.last;

    final result = _startWonder(state);

    expect(result.state, isNot(same(state)));
    expect(result.state.selection, same(selection));
    expect(result.state.selection?.city, same(selectedCity));
    expect(result.state.cities.last, same(selectedCityInState));
    expect(
      result.state.cities.first.productionQueue?.target,
      const WonderProductionTarget(WonderType.greatLibrary),
    );
  });
}

GameStateTransition _startWonder(GameState state) {
  return CityProductionReducer.startWonder(
    state,
    const StartWonderCommand('city_1', WonderType.greatLibrary),
    _mapTiles(),
  );
}

GameState _stableCitiesState({
  required List<GameCity> cities,
  required GameSelection selection,
  required ResearchState research,
}) {
  final state = GameState(
    cities: cities,
    activePlayerId: _playerId,
    playerColors: const {_playerId: 0xFF123456},
    playerGold: const {_playerId: 41},
    research: research,
    interaction: GameInteractionState(selection: selection),
  );
  return state.copyWith(cities: state.cities);
}

GameSelection _citySelection(GameCity city) {
  return GameSelection.city(
    city,
    cityYield: TileYield.zero,
    playerColor: 0xFF123456,
  );
}

GameCity _city({
  String id = 'city_1',
  CityHex center = const CityHex(col: 1, row: 1),
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: _playerId,
    name: id,
    center: center,
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
  );
}

ResearchState _writingResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.writing},
      ),
    },
  );
}

MapTileLookup _mapTiles() {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 3,
      tiles: [
        for (var row = 0; row < 3; row++)
          for (var col = 0; col < 3; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
