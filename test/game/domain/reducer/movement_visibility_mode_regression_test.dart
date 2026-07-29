import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/movement_engine_test_driver.dart';

void main() {
  test(
    'explicit pathing-only visibility survives legacy ignore-fog context',
    () {
      final mover = _unit(id: 'mover', ownerPlayerId: 'player_1', col: 0);
      final blocker = _unit(
        id: 'hidden_blocker',
        ownerPlayerId: 'player_2',
        col: 1,
      );
      final state = GameState(
        playerColors: const {'player_1': 0xff112233, 'player_2': 0xff445566},
        activePlayerId: 'player_1',
        units: [mover, blocker],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );

      final result = resolveMovementCommandForTest(
        state,
        const MoveUnitCommand('mover', 2, 0),
        _map(),
        context: const GameCommandContext(
          actorPlayerId: 'player_1',
          ignoreFogOfWar: true,
        ),
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
      );

      expect(result.state, same(state));
      expect(result.events, isEmpty);
      expect(result.uiEffects, isEmpty);
    },
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required int col,
}) => GameUnit(
  id: id,
  ownerPlayerId: ownerPlayerId,
  type: GameUnitType.commander,
  name: id,
  col: col,
  row: 0,
  movementPoints: 5,
);

MapTraversalView _map() => WorldMapReadView(
  WorldMap(
    cols: 3,
    rows: 2,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 2; row++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  ),
);
