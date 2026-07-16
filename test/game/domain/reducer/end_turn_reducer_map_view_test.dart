import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn/end_turn_reducer.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'advances objectives and refreshes selection from a canonical map view',
    () {
      final unit = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final state = GameState(
        activePlayerId: 'player_1',
        playerGold: const {'player_1': 10},
        units: [unit],
        interaction: GameInteractionState(selection: GameSelection.unit(unit)),
      );
      final MapReadView mapView = WorldMapReadView(_worldMap());

      final result = EndTurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapView,
      );

      expect(result.state.playerGold['player_1'], 14);
      expect(
        result.state.mapObjectiveHoldStatesByObjectiveId['pass_1']?.holdTurns,
        1,
      );
      expect(result.events.whereType<MapObjectiveSecuredEvent>(), hasLength(1));
      expect(result.state.selection?.unit, same(result.state.units.single));
      expect(result.state.selection?.tile?.col, 1);
      expect(result.state.selection?.tile?.row, 1);
      expect(result.state.selection?.tile?.terrains, const [
        TerrainType.plains,
      ]);
    },
  );
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row += 1)
        for (var col = 0; col < 3; col += 1)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
    objectives: const [
      MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 1, row: 1),
        requiredHoldTurns: 1,
        victoryPoints: 3,
        goldPerTurn: 4,
      ),
    ],
  );
}
