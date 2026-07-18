import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepted unit action no-op preserves full state identity', () {
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 0,
      row: 0,
    );
    final state = GameState(units: [commander], activePlayerId: 'player_1');

    final result = MovementReducer.cancelUnitAction(
      state,
      CancelUnitActionCommand(commander.id),
      const _EmptyMapTileLookup(),
    );

    expect(result.state, same(state));
  });
}

final class _EmptyMapTileLookup implements MapTileLookup {
  const _EmptyMapTileLookup();

  @override
  MapTileView? tileAt(int col, int row) => null;
}
