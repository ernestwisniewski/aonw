import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects initial territory through a canonical map lookup', () {
    final mapTiles = _canonicalMapTiles();

    final selected = CityInitialTerritorySelector.select(
      center: const CityHex(col: 3, row: 3),
      mapTiles: mapTiles,
      cities: const [],
    );

    expect(selected, const [CityHex(col: 2, row: 3), CityHex(col: 2, row: 4)]);
  });

  test('completes local city founding through a canonical map lookup', () {
    final mapTiles = _canonicalMapTiles();
    final settler = GameUnit.produced(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      col: 3,
      row: 3,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [settler],
      interaction: GameInteractionState(selection: GameSelection.unit(settler)),
    );

    final started = CityFoundingReducer.startCityFounding(state, mapTiles);
    final withFirstHex = CityFoundingReducer.toggleControlledHex(
      started,
      const TileTappedCommand(3, 2),
      mapTiles,
    );
    final complete = CityFoundingReducer.toggleControlledHex(
      withFirstHex,
      const TileTappedCommand(4, 3),
      mapTiles,
    );
    final result = CityFoundingReducer.confirmCityFounding(
      complete,
      FoundCityCommand(
        settler.id,
        controlledHexes: complete.cityFoundingDraft!.controlledHexes,
      ),
      mapTiles,
    );

    expect(complete.cityFoundingDraft?.controlledHexes, const [
      CityHex(col: 3, row: 2),
      CityHex(col: 4, row: 3),
    ]);
    expect(result.events, isEmpty);
    expect(result.state.cityFoundingDraft, isNull);
    expect(result.state.units.single.cityFoundingJob, isNotNull);
    expect(result.state.selection?.unit, same(result.state.units.single));
    expect(result.state.selection?.tile?.col, 3);
    expect(result.state.selection?.tile?.row, 3);
  });
}

MapTileLookup _canonicalMapTiles() {
  return WorldMapReadView(
    WorldMap(
      cols: 7,
      rows: 7,
      tiles: [
        for (var row = 0; row < 7; row += 1)
          for (var col = 0; col < 7; col += 1)
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
