import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection reads and freezes a canonical world-map tile', () {
    final world = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [
        WorldTile.at(
          coordinate: const HexCoord(col: 0, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [ResourceType.oil, ResourceType.wheat],
          height: 0,
        ),
      ],
    );
    final canonicalTile = world.tileAtHex(const HexCoord(col: 0, row: 0))!;
    final MapTileLookup mapTiles = world;
    final fog = FogOfWarState(
      players: {
        'p1': PlayerFogOfWar(
          playerId: 'p1',
          visibleHexes: {const HexCoordinate(col: 0, row: 0)},
        ),
      },
    );

    final hiddenResult = SelectionReducer.handleTileTapped(
      GameClientState(activePlayerId: 'p1', fogOfWar: fog),
      const TileTappedCommand(0, 0),
      mapTiles,
    );
    final hiddenSnapshot = hiddenResult.state.selection!.tile!;

    expect(hiddenResult.state.selection!.type, GameSelectionType.tile);
    expect(hiddenSnapshot.resources, [ResourceType.wheat]);
    expect(hiddenSnapshot, isNot(same(canonicalTile)));
    expect(canonicalTile.resources, [ResourceType.oil, ResourceType.wheat]);
    expect(
      () => hiddenSnapshot.terrains.add(TerrainType.desert),
      throwsUnsupportedError,
    );
    expect(
      () => hiddenSnapshot.resources.add(ResourceType.iron),
      throwsUnsupportedError,
    );

    final visibleResult = SelectionReducer.handleTileTapped(
      GameClientState(
        activePlayerId: 'p1',
        fogOfWar: fog,
        research: ResearchState(
          players: {
            'p1': PlayerResearchState(
              unlockedTechnologyIds: const {TechnologyId.combustion},
            ),
          },
        ),
      ),
      const TileTappedCommand(0, 0),
      mapTiles,
    );

    expect(visibleResult.state.selection!.tile!.resources, [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
    expect(canonicalTile.resources, [ResourceType.oil, ResourceType.wheat]);
  });
}
