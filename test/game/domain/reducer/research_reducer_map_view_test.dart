import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/research/research_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies a controlled-resource boost through canonical map lookup', () {
    final MapTileLookup mapTiles = WorldMapReadView(
      WorldMap(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            coordinate: const HexCoord(col: 0, row: 0),
            terrains: const [TerrainType.hills],
            resources: const [ResourceType.iron],
            height: 0,
          ),
        ],
      ),
    );
    final state = GameState(
      activePlayerId: 'player_1',
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      research: ResearchState(
        players: {'player_1': PlayerResearchState(scienceOverflow: 10)},
      ),
    );

    final result = ResearchReducer.selectTechnology(
      state,
      const SelectTechnologyCommand('player_1', TechnologyId.mining),
      mapTiles: mapTiles,
    );

    final research = result.state.research.forPlayer('player_1');
    expect(research.activeTechnologyId, TechnologyId.mining);
    expect(research.progressFor(TechnologyId.mining), 2);
    expect(research.scienceOverflow, 0);
  });
}
