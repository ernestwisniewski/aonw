import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameAiTurnAutoPilotRules', () {
    test('runs the active AI player when local control matches state', () {
      final save = _save(
        gameMode: GameMode.hotSeat,
        playerStates: const {
          'human': PlayerTurnState.finished,
          'ai_1': PlayerTurnState.active,
          'ai_2': PlayerTurnState.active,
        },
      );
      const control = PlayerControlState(activePlayerId: 'ai_1');
      const gameState = GameState(
        activePlayerId: 'ai_1',
        activePlayerCanAct: true,
      );

      final player = GameAiTurnAutoPilotRules.aiPlayerToRun(
        save: save,
        control: control,
        gameState: gameState,
      );

      expect(player?.id, 'ai_1');
    });

    test('finds the next active AI after a multiplayer human handoff', () {
      final save = _save(
        gameMode: GameMode.multiplayer,
        playerStates: const {
          'human': PlayerTurnState.active,
          'ai_1': PlayerTurnState.active,
          'ai_2': PlayerTurnState.active,
        },
      );
      const control = PlayerControlState(activePlayerId: 'human');
      const gameState = GameState(
        activePlayerId: 'human',
        activePlayerCanAct: true,
      );

      final player = GameAiTurnAutoPilotRules.aiPlayerToRun(
        save: save,
        control: control,
        gameState: gameState,
      );

      expect(player?.id, 'ai_1');
    });

    test('advances from a finished human to the next active AI', () {
      final save = _save(
        gameMode: GameMode.hotSeat,
        playerStates: const {
          'human': PlayerTurnState.finished,
          'ai_1': PlayerTurnState.active,
          'ai_2': PlayerTurnState.active,
        },
      );
      const control = PlayerControlState(
        activePlayerId: 'human',
        canAct: false,
      );
      const gameState = GameState(
        activePlayerId: 'human',
        activePlayerCanAct: false,
      );

      final player = GameAiTurnAutoPilotRules.aiPlayerToRun(
        save: save,
        control: control,
        gameState: gameState,
      );

      expect(player?.id, 'ai_1');
    });

    test('accepts only the still-active scheduled AI turn', () {
      final save = _save(
        gameMode: GameMode.hotSeat,
        playerStates: const {
          'human': PlayerTurnState.finished,
          'ai_1': PlayerTurnState.active,
          'ai_2': PlayerTurnState.finished,
        },
      );

      expect(
        GameAiTurnAutoPilotRules.canRunScheduledAiTurn(
          save: save,
          scheduledTurn: 1,
          playerId: 'ai_1',
        ),
        isTrue,
      );
      expect(
        GameAiTurnAutoPilotRules.canRunScheduledAiTurn(
          save: save.copyWith(turn: 2),
          scheduledTurn: 1,
          playerId: 'ai_1',
        ),
        isFalse,
      );
      expect(
        GameAiTurnAutoPilotRules.canRunScheduledAiTurn(
          save: save,
          scheduledTurn: 1,
          playerId: 'ai_2',
        ),
        isFalse,
      );
      expect(
        GameAiTurnAutoPilotRules.canRunScheduledAiTurn(
          save: save,
          scheduledTurn: 1,
          playerId: 'human',
        ),
        isFalse,
      );
    });
  });
}

GameSave _save({
  required GameMode gameMode,
  required Map<String, PlayerTurnState> playerStates,
}) {
  return GameSave(
    id: 'save_1',
    name: 'AI autopilot rules test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
    players: const [
      Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB),
      Player(
        id: 'ai_1',
        name: 'AI 1',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.basic,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 1001,
        ),
      ),
      Player(
        id: 'ai_2',
        name: 'AI 2',
        colorValue: 0xFF16A34A,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.basic,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 1002,
        ),
      ),
    ],
    gameMode: gameMode,
  );
}
