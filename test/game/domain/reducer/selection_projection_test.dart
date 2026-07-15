import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw/game/domain/turn/phases/selection_refresh_phase.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapData = _map();

  test('city production projects the current city selection', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    const state = GameState(
      cities: [city],
      activePlayerId: 'player_1',
      playerColors: {'player_1': 0xFF123456},
    );

    final selection = CityProductionReducer.citySelection(state, city, mapData);

    expect(selection.type, GameSelectionType.city);
    expect(selection.city, same(city));
    expect(selection.cityPlayerColor, 0xFF123456);
    expect(selection.cityYield, isNotNull);
  });

  test('tile tap leaves stale move mode before standard selection', () {
    const state = GameState(
      interaction: GameInteractionState(moveCommandActive: true),
    );

    final transition = SelectionReducer.handleTileTapped(
      state,
      const TileTappedCommand(1, 1),
      mapData,
    );

    expect(transition.state.selection?.type, GameSelectionType.tile);
    expect(transition.state.moveCommandActive, isFalse);
    expect(transition.state.movePreview, isNull);
  });

  group('SelectionRefreshPhase', () {
    test('selects a city founded by the previously selected unit', () {
      final founder = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      const foundedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Founded city',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      final state = GameState(
        cities: const [foundedCity],
        activePlayerId: 'player_1',
        interaction: GameInteractionState(
          selection: GameSelection.unit(founder),
        ),
      );

      final refreshed = const SelectionRefreshPhase().apply(
        _context(state, mapData),
      );

      expect(refreshed.state.selection?.type, GameSelectionType.city);
      expect(refreshed.state.selection?.city, same(foundedCity));
      expect(refreshed.state.selection?.cityYield, isNotNull);
    });

    test('reprojects an updated selected city', () {
      const selectedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Before turn',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      const updatedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'After turn',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
        population: 2,
      );
      final state = GameState(
        cities: const [updatedCity],
        activePlayerId: 'player_1',
        interaction: GameInteractionState(
          selection: GameSelection.city(
            selectedCity,
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
        ),
      );

      final refreshed = const SelectionRefreshPhase().apply(
        _context(state, mapData),
      );

      expect(refreshed.state.selection?.city, same(updatedCity));
      expect(refreshed.state.selection?.city?.population, 2);
      expect(refreshed.state.selection?.cityYield, isNotNull);
    });
  });
}

TurnContext _context(GameState state, MapData mapData) => TurnContext(
  state: state,
  mapData: mapData,
  ruleset: GameRuleset.standard(),
  playerId: 'player_1',
);

MapData _map() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row += 1)
      for (var col = 0; col < 3; col += 1)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
