import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnContext', () {
    test('copyWith can clear nullable save metadata', () {
      final savedAt = DateTime.utc(2026, 7, 9, 12);
      final context = TurnContext(
        state: const GameState(),
        save: GameSave(
          id: 'save_1',
          name: 'Game',
          mapName: 'verdantia',
          turn: 1,
          playerStates: const {},
          savedAt: savedAt,
          camera: CameraState.zero,
        ),
        mapData: MapData(cols: 0, rows: 0, tiles: const []),
        ruleset: GameRuleset.defaults,
        playerId: 'player_1',
        savedAt: savedAt,
      );

      final cleared = context.copyWith(save: null, savedAt: null);

      expect(cleared.save, isNull);
      expect(cleared.savedAt, isNull);
    });
  });
}
