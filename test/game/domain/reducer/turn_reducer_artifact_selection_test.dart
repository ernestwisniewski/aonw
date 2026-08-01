import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending city selection includes stored artifact yield', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    const artifact = WorldArtifact(
      id: 'artifact.merchantsSeal',
      type: WorldArtifactType.merchantsSeal,
      location: WorldArtifactLocation.stored(cityId: 'city_1'),
    );
    final state = GameClientState(
      cities: [city],
      artifacts: [artifact],
      activePlayerId: 'player_1',
    );
    final mapData = _map();

    final result = TurnReducer.focusNextPendingAction(
      state,
      'player_1',
      mapData,
    );

    final baseYield = CityYieldCalculator.totalFor(city, mapData);
    expect(result.state.selection?.city?.id, city.id);
    expect(
      result.state.selection?.cityYield?.gold,
      baseYield.gold + artifact.type.cityYield.gold,
    );
    expect(
      result.state.selection?.cityEconomy?.netYield.gold,
      baseYield.gold + artifact.type.cityYield.gold,
    );
  });
}

WorldMap _map() {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
