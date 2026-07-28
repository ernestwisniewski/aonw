import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/advance_turn_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn/phases/advance_turn_phase.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvanceTurnSnapshot', () {
    test('matches legacy turn advancement losslessly', () {
      final save = _save();
      final snapshot = SaveSnapshot.fromGameState(
        save: save,
        state: const GameState(playerGold: {'p1': 9}),
        eventLogOffset: 12,
      );
      final savedAt = DateTime.parse('2026-07-28T14:30:00+02:00');

      final legacy = const AdvanceTurnPhase().advanceSave(
        save,
        playerId: 'p1',
        savedAt: savedAt,
      );
      final canonical = const AdvanceTurnPhase().advanceSnapshot(
        snapshot,
        playerId: 'p1',
        savedAt: savedAt,
      );

      expect(canonical.save.toJson(), legacy.toJson());
      expect(canonical.eventLogOffset, 12);
      expect(canonical.rawPersistentState, snapshot.rawPersistentState);
    });

    test('preserves snapshot identity for an unknown player', () {
      final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 12);

      final advanced = const AdvanceTurnPhase().advanceSnapshot(
        snapshot,
        playerId: 'unknown',
        savedAt: DateTime.utc(2026, 7, 28),
      );

      expect(identical(advanced, snapshot), isTrue);
    });
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 4,
    playerStates: const {
      'p1': PlayerTurnState.active,
      'p2': PlayerTurnState.finished,
    },
    savedAt: DateTime.utc(2026, 7, 27),
    camera: CameraState.zero,
  );
}
