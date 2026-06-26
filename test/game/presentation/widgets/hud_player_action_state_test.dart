import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/hud_player_action_state.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudPlayerActionState', () {
    test('allows active player HUD actions while the turn is open', () {
      final state = HudPlayerActionState.from(
        gameState: const GameState(),
        gameSave: _save(),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );

      expect(state.actionsLocked, isFalse);
      expect(state.canShowGlobalActions, isTrue);
      expect(state.showTopResources, isTrue);
    });

    test('locks actions after player submitted the turn', () {
      final state = HudPlayerActionState.from(
        gameState: const GameState(submittedPlayerIds: {'player_1'}),
        gameSave: _save(),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );

      expect(state.actionsLocked, isTrue);
      expect(state.canShowGlobalActions, isFalse);
      expect(state.showTopResources, isTrue);
    });

    test('locks actions when player control is inactive', () {
      final state = HudPlayerActionState.from(
        gameState: const GameState(),
        gameSave: _save(),
        activePlayerId: 'player_1',
        activePlayerCanAct: false,
      );

      expect(state.actionsLocked, isTrue);
      expect(state.canShowGlobalActions, isTrue);
      expect(state.showTopResources, isTrue);
    });

    test('hides player HUD chrome without an active player', () {
      final state = HudPlayerActionState.from(
        gameState: const GameState(),
        gameSave: _save(),
        activePlayerId: '',
        activePlayerCanAct: true,
      );

      expect(state.actionsLocked, isFalse);
      expect(state.canShowGlobalActions, isFalse);
      expect(state.showTopResources, isFalse);
    });
  });
}

GameSave _save({
  Map<String, PlayerTurnState> playerStates = const {
    'player_1': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    turn: 1,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 4, 30),
    camera: CameraState.zero,
  );
}
