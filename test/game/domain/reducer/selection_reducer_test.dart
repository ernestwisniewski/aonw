import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile(int col, int row) => TileData(
  col: col,
  row: row,
  terrains: const [TerrainType.grassland],
  resources: const [],
  height: 0,
);

MapData _mapWith(List<TileData> tiles) =>
    MapData(cols: 10, rows: 10, tiles: tiles);

GameUnit _unit({
  String id = 'u1',
  String ownerPlayerId = 'p1',
  GameUnitType type = GameUnitType.commander,
  int col = 0,
  int row = 0,
}) => GameUnit(
  id: id,
  ownerPlayerId: ownerPlayerId,
  type: type,
  name: type.defaultNameToken,
  col: col,
  row: row,
);

GameCity _city({
  String id = 'c1',
  String ownerPlayerId = 'p1',
  int col = 2,
  int row = 2,
}) => GameCity(
  id: id,
  ownerPlayerId: ownerPlayerId,
  name: 'City',
  center: CityHex(col: col, row: row),
);

FieldImprovement _improvement({
  int col = 3,
  int row = 3,
  FieldImprovementType type = FieldImprovementType.farm,
}) => FieldImprovement(
  hex: CityHex(col: col, row: row),
  type: type,
);

/// Creates fog where all listed tiles are visible for the player.
FogOfWarState _fogVisible(String playerId, List<TileData> tiles) {
  final hexes = {
    for (final tile in tiles) HexCoordinate(col: tile.col, row: tile.row),
  };
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: hexes),
    },
  );
}

/// Creates fog where all tiles are hidden for the player.
FogOfWarState _fogHidden(String playerId) {
  return FogOfWarState(players: {playerId: PlayerFogOfWar(playerId: playerId)});
}

void main() {
  // SelectTileCommand

  group('selectTile', () {
    test('selects tile and clears move/founding state', () {
      final tile = _tile(3, 4);
      final mapData = _mapWith([tile]);
      final draft = CityFoundingDraft(
        unitId: 'u1',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 0, row: 0),
      );
      final state = const GameState(
        activePlayerId: 'p1',
        moveCommandActive: true,
      ).copyWith(cityFoundingDraft: draft);

      final result = SelectionReducer.selectTile(
        state,
        const SelectTileCommand(3, 4),
        mapData,
      );

      expect(result.selection, isNotNull);
      expect(result.selection!.type, GameSelectionType.tile);
      expect(result.selection!.tile!.col, 3);
      expect(result.selection!.tile!.row, 4);
      expect(result.moveCommandActive, isFalse);
      expect(result.movePreview, isNull);
      expect(result.cityFoundingDraft, isNull);
    });

    test('returns unchanged state when tile not found in mapData', () {
      final mapData = _mapWith([]);
      const state = GameState(activePlayerId: 'p1');

      final result = SelectionReducer.selectTile(
        state,
        const SelectTileCommand(99, 99),
        mapData,
      );

      expect(result, same(state));
    });
  });
  // SelectUnitCommand

  group('selectUnit', () {
    test(
      'selects unit and auto-starts move targeting for controllable units',
      () {
        final unit = _unit(col: 1, row: 2);
        final tile = _tile(1, 2);
        final mapData = _mapWith([tile]);
        final state = GameState(activePlayerId: 'p1', units: [unit]);

        final result = SelectionReducer.selectUnit(
          state,
          const SelectUnitCommand('u1'),
          mapData,
        );

        expect(result.selection, isNotNull);
        expect(result.selection!.type, GameSelectionType.unit);
        expect(result.selection!.unit!.id, 'u1');
        expect(result.moveCommandActive, isTrue);
      },
    );

    test('selects enemy unit without starting move targeting', () {
      final unit = _unit(ownerPlayerId: 'p2', col: 1, row: 2);
      final tile = _tile(1, 2);
      final mapData = _mapWith([tile]);
      final state = GameState(activePlayerId: 'p1', units: [unit]);

      final result = SelectionReducer.selectUnit(
        state,
        const SelectUnitCommand('u1'),
        mapData,
      );

      expect(result.selection, isNotNull);
      expect(result.selection!.type, GameSelectionType.unit);
      expect(result.moveCommandActive, isFalse);
    });

    test('selects merchant without starting ordinary move targeting', () {
      final merchant = _unit(type: GameUnitType.merchant, col: 1, row: 2);
      final tile = _tile(1, 2);
      final mapData = _mapWith([tile]);
      final state = GameState(activePlayerId: 'p1', units: [merchant]);

      final result = SelectionReducer.selectUnit(
        state,
        const SelectUnitCommand('u1'),
        mapData,
      );

      expect(result.selection?.unit?.type, GameUnitType.merchant);
      expect(result.moveCommandActive, isFalse);
    });

    test('returns unchanged state when unit not found', () {
      final mapData = _mapWith([]);
      const state = GameState(activePlayerId: 'p1');

      final result = SelectionReducer.selectUnit(
        state,
        const SelectUnitCommand('nonexistent'),
        mapData,
      );

      expect(result, same(state));
    });
  });
  // SelectCityCommand

  group('selectCity', () {
    test('selects city with yield and economy', () {
      final city = _city(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
        playerColors: const {'p1': 0xFF0000FF},
      );

      final result = SelectionReducer.selectCity(
        state,
        const SelectCityCommand('c1'),
        mapData,
      );

      expect(result.selection, isNotNull);
      expect(result.selection!.type, GameSelectionType.city);
      expect(result.selection!.city!.id, 'c1');
      expect(result.selection!.cityYield, isNotNull);
      expect(result.selection!.cityEconomy, isNotNull);
      expect(result.selection!.cityPlayerColor, 0xFF0000FF);
      expect(result.moveCommandActive, isFalse);
    });

    test('uses fallback player color when not in playerColors', () {
      final city = _city(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final state = GameState(activePlayerId: 'p1', cities: [city]);

      final result = SelectionReducer.selectCity(
        state,
        const SelectCityCommand('c1'),
        mapData,
      );

      expect(result.selection!.cityPlayerColor, isNotNull);
    });

    test('returns unchanged state when city not found', () {
      final mapData = _mapWith([]);
      const state = GameState(activePlayerId: 'p1');

      final result = SelectionReducer.selectCity(
        state,
        const SelectCityCommand('nonexistent'),
        mapData,
      );

      expect(result, same(state));
    });
  });
  // handleTileTapped

  group('handleTileTapped', () {
    test('tapping hidden tile clears selection', () {
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogHidden('p1');
      final selection = GameSelection.tile(_tile(0, 0));
      final state = GameState(
        activePlayerId: 'p1',
        fogOfWar: fog,
      ).copyWith(selection: selection);

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );

      expect(result.state.selection, isNull);
      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.cityFoundingDraft, isNull);
    });

    test(
      'tapping hidden tile during move mode with controllable unit returns unchanged',
      () {
        final unit = _unit(col: 1, row: 1);
        final tile11 = _tile(1, 1);
        final tile33 = _tile(3, 3);
        final mapData = _mapWith([tile11, tile33]);
        // Only (1,1) visible; (3,3) is hidden
        final fog = _fogVisible('p1', [tile11]);
        final state = GameState(
          activePlayerId: 'p1',
          units: [unit],
          moveCommandActive: true,
          fogOfWar: fog,
        ).copyWith(selection: GameSelection.unit(unit, tile: tile11));

        final result = SelectionReducer.handleTileTapped(
          state,
          const TileTappedCommand(3, 3),
          mapData,
        );

        // Movement reducer would handle this -- state unchanged
        expect(result.state, same(state));
      },
    );

    test('tapping during city founding is ignored', () {
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);
      final draft = CityFoundingDraft(
        unitId: 'u1',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 0, row: 0),
      );
      final state = GameState(
        activePlayerId: 'p1',
        fogOfWar: fog,
      ).copyWith(cityFoundingDraft: draft);

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );

      expect(result.state.cityFoundingDraft, isNotNull);
    });

    test('tapping commander tile cycles: unit+move -> tile -> unit+move', () {
      final unit = _unit(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      // Step 1: Start with unit selected + move active
      final state = GameState(
        activePlayerId: 'p1',
        units: [unit],
        moveCommandActive: true,
        fogOfWar: fog,
      ).copyWith(selection: GameSelection.unit(unit, tile: tile));

      // Step 2: Tap the unit's own tile -> selects the hex.
      var result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(2, 2),
        mapData,
      );
      expect(result.state.selection!.type, GameSelectionType.tile);
      expect(result.state.moveCommandActive, isFalse);

      // Step 3: Tap again -> unit selected with move targeting.
      result = SelectionReducer.handleTileTapped(
        result.state,
        const TileTappedCommand(2, 2),
        mapData,
      );
      expect(result.state.selection!.type, GameSelectionType.unit);
      expect(result.state.moveCommandActive, isTrue);
    });

    test(
      'tapping different controllable unit in move mode switches to that unit',
      () {
        final unit1 = _unit(id: 'u1', col: 1, row: 1);
        final unit2 = _unit(id: 'u2', col: 3, row: 3);
        final tile11 = _tile(1, 1);
        final tile33 = _tile(3, 3);
        final mapData = _mapWith([tile11, tile33]);
        final fog = _fogVisible('p1', [tile11, tile33]);

        final state = GameState(
          activePlayerId: 'p1',
          units: [unit1, unit2],
          moveCommandActive: true,
          fogOfWar: fog,
        ).copyWith(selection: GameSelection.unit(unit1, tile: tile11));

        final result = SelectionReducer.handleTileTapped(
          state,
          const TileTappedCommand(3, 3),
          mapData,
        );

        expect(result.state.selection!.type, GameSelectionType.unit);
        expect(result.state.selection!.unit!.id, 'u2');
        expect(result.state.moveCommandActive, isTrue);
      },
    );

    test('tapping tile with enemy unit selects enemy unit preview', () {
      final enemyUnit = _unit(ownerPlayerId: 'p2', col: 3, row: 3);
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(
        activePlayerId: 'p1',
        units: [enemyUnit],
        fogOfWar: fog,
      );

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );

      expect(result.state.selection!.type, GameSelectionType.unit);
      expect(result.state.selection!.unit!.id, enemyUnit.id);
      expect(result.state.selection!.tile!.col, 3);
      expect(result.state.selection!.tile!.row, 3);
      expect(result.state.moveCommandActive, isFalse);
    });

    test('tapping selected enemy unit again cycles back to tile', () {
      final enemyUnit = _unit(ownerPlayerId: 'p2', col: 3, row: 3);
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(
        activePlayerId: 'p1',
        units: [enemyUnit],
        fogOfWar: fog,
      ).copyWith(selection: GameSelection.unit(enemyUnit, tile: tile));

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );

      expect(result.state.selection!.type, GameSelectionType.tile);
      expect(result.state.selection!.tile!.col, 3);
      expect(result.state.selection!.tile!.row, 3);
      expect(result.state.moveCommandActive, isFalse);
    });

    test(
      'tapping improvement with unit cycles improvement, unit, then tile',
      () {
        final unit = _unit(col: 3, row: 3);
        final improvement = _improvement(col: 3, row: 3);
        final tile = _tile(3, 3);
        final mapData = _mapWith([tile]);
        final fog = _fogVisible('p1', [tile]);
        var state = GameState(
          activePlayerId: 'p1',
          units: [unit],
          fieldImprovements: [improvement],
          fogOfWar: fog,
        );

        var result = SelectionReducer.handleTileTapped(
          state,
          const TileTappedCommand(3, 3),
          mapData,
        );
        expect(
          result.state.selection!.type,
          GameSelectionType.fieldImprovement,
        );
        expect(result.state.moveCommandActive, isFalse);

        state = result.state;
        result = SelectionReducer.handleTileTapped(
          state,
          const TileTappedCommand(3, 3),
          mapData,
        );
        expect(result.state.selection!.type, GameSelectionType.unit);
        expect(result.state.moveCommandActive, isTrue);

        result = SelectionReducer.handleTileTapped(
          result.state,
          const TileTappedCommand(3, 3),
          mapData,
        );
        expect(result.state.selection!.type, GameSelectionType.tile);
        expect(result.state.moveCommandActive, isFalse);
      },
    );

    test('tapping improvement without unit cycles improvement then tile', () {
      final improvement = _improvement(col: 3, row: 3);
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);
      var state = GameState(
        activePlayerId: 'p1',
        fieldImprovements: [improvement],
        fogOfWar: fog,
      );

      var result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );
      expect(result.state.selection!.type, GameSelectionType.fieldImprovement);
      expect(result.state.moveCommandActive, isFalse);

      state = result.state;
      result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );
      expect(result.state.selection!.type, GameSelectionType.tile);
      expect(result.state.moveCommandActive, isFalse);
    });

    test('tapping enemy unit in move mode selects enemy preview', () {
      final ownUnit = _unit(id: 'u1', col: 1, row: 1);
      final enemyUnit = _unit(id: 'u2', ownerPlayerId: 'p2', col: 3, row: 3);
      final tile11 = _tile(1, 1);
      final tile33 = _tile(3, 3);
      final mapData = _mapWith([tile11, tile33]);
      final fog = _fogVisible('p1', [tile11, tile33]);

      final state = GameState(
        activePlayerId: 'p1',
        units: [ownUnit, enemyUnit],
        moveCommandActive: true,
        fogOfWar: fog,
      ).copyWith(selection: GameSelection.unit(ownUnit, tile: tile11));

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );

      expect(result.state.selection!.type, GameSelectionType.unit);
      expect(result.state.selection!.unit!.id, enemyUnit.id);
      expect(result.state.selection!.tile!.col, 3);
      expect(result.state.selection!.tile!.row, 3);
      expect(result.state.moveCommandActive, isFalse);
    });

    test('tapping empty tile selects tile', () {
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(activePlayerId: 'p1', fogOfWar: fog);

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(3, 3),
        mapData,
      );

      expect(result.state.selection!.type, GameSelectionType.tile);
      expect(result.state.selection!.tile!.col, 3);
      expect(result.state.selection!.tile!.row, 3);
    });

    test('returns unchanged when tile not in mapData', () {
      final mapData = _mapWith([]);
      const state = GameState(activePlayerId: 'p1');

      final result = SelectionReducer.handleTileTapped(
        state,
        const TileTappedCommand(99, 99),
        mapData,
      );

      expect(result.state, same(state));
    });
  });
  // handleCityTapped -- own city with unit

  group('handleCityTapped -- own city with unit', () {
    test('cycles city -> unit -> tile -> city', () {
      final city = _city(col: 2, row: 2);
      final unit = _unit(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      // Start: no selection
      final state = GameState(
        activePlayerId: 'p1',
        units: [unit],
        cities: [city],
        playerColors: const {'p1': 0xFF0000FF},
        fogOfWar: fog,
      );

      // First tap -> city (no prior selection)
      var result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);

      // Tap city again -> unit
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.unit);

      // Tap city again -> tile
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.tile);

      // Tap city again -> city
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);
    });
  });
  // handleCityTapped -- own city without unit

  group('handleCityTapped -- own city without unit', () {
    test('cycles city -> tile -> city', () {
      final city = _city(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
        playerColors: const {'p1': 0xFF0000FF},
        fogOfWar: fog,
      );

      // First tap -> city
      var result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);

      // Second tap -> tile
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.tile);

      // Third tap -> city
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);
    });

    test('can select own city while waiting for another player', () {
      final city = _city(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(
        activePlayerId: 'p1',
        activePlayerCanAct: false,
        cities: [city],
        playerColors: const {'p1': 0xFF0000FF},
        fogOfWar: fog,
      );

      final result = SelectionReducer.handleCityTapped(state, city, mapData);

      expect(result.selection!.type, GameSelectionType.city);
      expect(result.moveCommandActive, isFalse);
    });
  });
  // handleCityTapped -- enemy city

  group('handleCityTapped -- enemy city', () {
    test('with unit: first tap selects tile, second tap selects unit', () {
      final city = _city(ownerPlayerId: 'p2', col: 2, row: 2);
      final unit = _unit(ownerPlayerId: 'p2', col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(
        activePlayerId: 'p1',
        units: [unit],
        cities: [city],
        fogOfWar: fog,
      );

      // First tap -> tile (not on this tile yet)
      var result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result.selection!.type, GameSelectionType.tile);

      // Second tap (on this tile) -> unit
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.unit);
    });

    test('without unit: selects tile', () {
      final city = _city(ownerPlayerId: 'p2', col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
        fogOfWar: fog,
      );

      final result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result.selection!.type, GameSelectionType.tile);
    });

    test('during founding returns unchanged', () {
      final city = _city(ownerPlayerId: 'p2', col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final draft = CityFoundingDraft(
        unitId: 'u1',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 0, row: 0),
      );

      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
      ).copyWith(cityFoundingDraft: draft);

      final result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result, same(state));
    });
  });
  // Integration: GameStateReducer wiring

  group('GameStateReducer wiring', () {
    test('SelectTileCommand dispatches to SelectionReducer', () {
      final tile = _tile(1, 1);
      final mapData = _mapWith([tile]);
      final reducer = GameStateReducer(mapData: mapData);
      const state = GameState(activePlayerId: 'p1');

      final result = reducer.reduce(state, const SelectTileCommand(1, 1));

      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, GameSelectionType.tile);
    });

    test('SelectUnitCommand dispatches to SelectionReducer', () {
      final unit = _unit(col: 1, row: 1);
      final tile = _tile(1, 1);
      final mapData = _mapWith([tile]);
      final reducer = GameStateReducer(mapData: mapData);
      final state = GameState(activePlayerId: 'p1', units: [unit]);

      final result = reducer.reduce(state, const SelectUnitCommand('u1'));

      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, GameSelectionType.unit);
      expect(result.state.moveCommandActive, isTrue);
    });

    test('SelectCityCommand dispatches to SelectionReducer', () {
      final city = _city(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final reducer = GameStateReducer(mapData: mapData);
      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
        playerColors: const {'p1': 0xFF0000FF},
      );

      final result = reducer.reduce(state, const SelectCityCommand('c1'));

      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, GameSelectionType.city);
    });

    test('TileTappedCommand dispatches to SelectionReducer', () {
      final tile = _tile(5, 5);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);
      final reducer = GameStateReducer(mapData: mapData);
      final state = GameState(activePlayerId: 'p1', fogOfWar: fog);

      final result = reducer.reduce(state, const TileTappedCommand(5, 5));

      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, GameSelectionType.tile);
    });

    test('CityTappedCommand dispatches to SelectionReducer', () {
      final city = _city(col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);
      final reducer = GameStateReducer(mapData: mapData);
      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
        playerColors: const {'p1': 0xFF0000FF},
        fogOfWar: fog,
      );

      final result = reducer.reduce(state, const CityTappedCommand('c1'));

      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, GameSelectionType.city);
    });
  });
}
