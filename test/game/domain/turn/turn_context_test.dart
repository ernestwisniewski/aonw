import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnContext', () {
    test('copyWith can clear nullable save metadata', () {
      final savedAt = DateTime.utc(2026, 7, 9, 12);
      const mapTiles = _EmptyMapTiles();
      final context = TurnContext(
        state: GameClientState(),
        save: GameSave(
          id: 'save_1',
          name: 'Game',
          mapName: 'verdantia',
          turn: 1,
          playerStates: const {},
          savedAt: savedAt,
          camera: CameraState.zero,
        ),
        mapTiles: mapTiles,
        ruleset: GameRuleset.defaults,
        playerId: 'player_1',
        savedAt: savedAt,
      );

      final cleared = context.copyWith(save: null, savedAt: null);

      expect(cleared.save, isNull);
      expect(cleared.savedAt, isNull);
      expect(cleared.mapTiles, same(mapTiles));
    });
  });
}

final class _EmptyMapTiles implements MapTileLookup {
  const _EmptyMapTiles();

  @override
  MapTileView? tileAt(int col, int row) => null;
}
