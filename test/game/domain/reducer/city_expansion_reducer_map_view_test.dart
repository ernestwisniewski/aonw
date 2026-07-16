import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_expansion_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects and reprojects expansion through canonical map lookup', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 2, row: 1)],
    );
    const pending = PendingCityExpansionSelection(
      ownerPlayerId: 'player_1',
      cityId: 'city_1',
    );
    final state = GameState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      cities: const [city],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.urbanization},
          ),
        },
      ),
      interaction: GameInteractionState(
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0,
        ),
        pendingAction: pending,
      ),
    );
    final MapTileLookup mapTiles = WorldMapReadView(_worldMap());

    final result = CityExpansionReducer.selectExpansionHex(
      state,
      const SelectCityExpansionHexCommand('city_1', 1, 2),
      mapTiles,
    );

    final updatedCity = result.state.cities.single;
    expect(updatedCity.preferredExpansionHex, const CityHex(col: 1, row: 2));
    expect(result.state.selection?.city, same(updatedCity));
    expect(
      result
          .state
          .selection
          ?.cityEconomy
          ?.technologyEffects
          .maxControlledHexesBonus,
      1,
    );
    expect(result.state.selection?.cityTileYieldBreakdown, isNotNull);
    expect(result.state.pendingAction, pending);
    expect(result.events, isEmpty);
  });
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row += 1)
        for (var col = 0; col < 4; col += 1)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
