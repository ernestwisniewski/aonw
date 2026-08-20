import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

WorldTile _tile(int col, int row) => WorldTile(
  col: col,
  row: row,
  terrains: const [TerrainType.grassland],
  resources: const [],
  height: 0,
);

WorldMap _mapWith(List<WorldTile> tiles) =>
    WorldMap(cols: 10, rows: 10, tiles: tiles);

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
FogOfWarState _fogVisible(String playerId, List<WorldTile> tiles) {
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
      final state = GameClientState(
        activePlayerId: 'p1',
        interaction: const InteractionState(moveCommandActive: true),
      ).copyWithInteraction(cityFoundingDraft: draft);

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
      final state = GameClientState(activePlayerId: 'p1');

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
        final state = GameClientState(activePlayerId: 'p1', units: [unit]);

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
      final state = GameClientState(activePlayerId: 'p1', units: [unit]);

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
      final state = GameClientState(activePlayerId: 'p1', units: [merchant]);

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
      final state = GameClientState(activePlayerId: 'p1');

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
      final state = GameClientState(
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
      final state = GameClientState(activePlayerId: 'p1', cities: [city]);

      final result = SelectionReducer.selectCity(
        state,
        const SelectCityCommand('c1'),
        mapData,
      );

      expect(result.selection!.cityPlayerColor, isNotNull);
    });

    test('returns unchanged state when city not found', () {
      final mapData = _mapWith([]);
      final state = GameClientState(activePlayerId: 'p1');

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
      final state = GameClientState(
        activePlayerId: 'p1',
        fogOfWar: fog,
      ).copyWithInteraction(selection: selection);

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
        final state =
            GameClientState(
              activePlayerId: 'p1',
              units: [unit],
              fogOfWar: fog,
              interaction: const InteractionState(moveCommandActive: true),
            ).copyWithInteraction(
              selection: GameSelection.unit(unit, tile: tile11),
            );

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
      final state = GameClientState(
        activePlayerId: 'p1',
        fogOfWar: fog,
      ).copyWithInteraction(cityFoundingDraft: draft);

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
      final state = GameClientState(
        activePlayerId: 'p1',
        units: [unit],
        fogOfWar: fog,
        interaction: const InteractionState(moveCommandActive: true),
      ).copyWithInteraction(selection: GameSelection.unit(unit, tile: tile));

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

        final state =
            GameClientState(
              activePlayerId: 'p1',
              units: [unit1, unit2],
              fogOfWar: fog,
              interaction: const InteractionState(moveCommandActive: true),
            ).copyWithInteraction(
              selection: GameSelection.unit(unit1, tile: tile11),
            );

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

      final state = GameClientState(
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

      final state =
          GameClientState(
            activePlayerId: 'p1',
            units: [enemyUnit],
            fogOfWar: fog,
          ).copyWithInteraction(
            selection: GameSelection.unit(enemyUnit, tile: tile),
          );

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
        var state = GameClientState(
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
      var state = GameClientState(
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

      final state =
          GameClientState(
            activePlayerId: 'p1',
            units: [ownUnit, enemyUnit],
            fogOfWar: fog,
            interaction: const InteractionState(moveCommandActive: true),
          ).copyWithInteraction(
            selection: GameSelection.unit(ownUnit, tile: tile11),
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

    test('tapping empty tile selects tile', () {
      final tile = _tile(3, 3);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameClientState(activePlayerId: 'p1', fogOfWar: fog);

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
      final state = GameClientState(activePlayerId: 'p1');

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
      final state = GameClientState(
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

      final state = GameClientState(
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

      final state = GameClientState(
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
    test('with unit follows the same city, unit, tile cycle', () {
      final city = _city(ownerPlayerId: 'p2', col: 2, row: 2);
      final unit = _unit(ownerPlayerId: 'p2', col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameClientState(
        activePlayerId: 'p1',
        units: [unit],
        cities: [city],
        fogOfWar: fog,
      );

      // First tap -> city.
      var result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);

      // Second tap -> unit.
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.unit);

      // Third tap -> tile.
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.tile);

      // Fourth tap -> city again.
      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);
    });

    test('without unit follows the same city, tile cycle', () {
      final city = _city(ownerPlayerId: 'p2', col: 2, row: 2);
      final tile = _tile(2, 2);
      final mapData = _mapWith([tile]);
      final fog = _fogVisible('p1', [tile]);

      final state = GameClientState(
        activePlayerId: 'p1',
        cities: [city],
        fogOfWar: fog,
      );

      var result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);

      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.tile);

      result = SelectionReducer.handleCityTapped(result, city, mapData);
      expect(result.selection!.type, GameSelectionType.city);
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

      final state = GameClientState(
        activePlayerId: 'p1',
        cities: [city],
      ).copyWithInteraction(cityFoundingDraft: draft);

      final result = SelectionReducer.handleCityTapped(state, city, mapData);
      expect(result, same(state));
    });
  });
}
