import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _UnitAction =
    GameStateTransition Function(
      GameState state,
      MapTileLookup mapTiles,
      GameUnit unit,
    );

void main() {
  final actions = <({String name, _UnitAction apply})>[
    (
      name: 'cancel',
      apply: (state, mapTiles, unit) => MovementReducer.cancelUnitAction(
        state,
        CancelUnitActionCommand(unit.id),
        mapTiles,
      ),
    ),
    (
      name: 'skip',
      apply: (state, mapTiles, unit) => MovementReducer.skipUnitTurn(
        state,
        SkipUnitTurnCommand(unit.id),
        mapTiles,
      ),
    ),
    (
      name: 'fortify',
      apply: (state, mapTiles, unit) => MovementReducer.fortifyUnit(
        state,
        FortifyUnitCommand(unit.id),
        mapTiles,
      ),
    ),
  ];

  for (final action in actions) {
    test(
      '${action.name} refreshes selection through a canonical map lookup',
      () {
        final canonicalTile = WorldTile(
          coordinate: const HexCoord(col: 0, row: 0),
          terrains: const [TerrainType.plains],
          resources: const [ResourceType.oil, ResourceType.wheat],
          height: 0,
        );
        final mapTiles = WorldMapReadView(
          WorldMap(cols: 1, rows: 1, tiles: [canonicalTile]),
        );
        final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
        final state = GameState(
          activePlayerId: 'player_1',
          units: [unit],
          interaction: GameInteractionState(
            selection: GameSelection.unit(unit),
          ),
        );

        final result = action.apply(state, mapTiles, unit);
        final updatedUnit = result.state.units.single;

        expect(result.state.selection?.unit, same(updatedUnit));
        expect(result.state.selection?.tile?.resources, const [
          ResourceType.wheat,
        ]);
        expect(canonicalTile.resources, const [
          ResourceType.oil,
          ResourceType.wheat,
        ]);
      },
    );
  }

  test(
    'selection keeps the updated unit when its canonical tile is absent',
    () {
      final mapTiles = WorldMapReadView(
        WorldMap(cols: 1, rows: 1, tiles: const []),
      );
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final state = GameState(
        activePlayerId: 'player_1',
        units: [unit],
        interaction: GameInteractionState(selection: GameSelection.unit(unit)),
      );

      final result = MovementReducer.cancelUnitAction(
        state,
        CancelUnitActionCommand(unit.id),
        mapTiles,
      );

      expect(result.state.selection?.unit, same(result.state.units.single));
      expect(result.state.selection?.tile, isNull);
    },
  );
}
