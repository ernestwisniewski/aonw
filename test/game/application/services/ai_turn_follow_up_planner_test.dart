import 'package:aonw/game/application/services/ai_turn_follow_up_planner.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnFollowUpPlanner', () {
    test('does nothing when local AI runtime is disabled', () {
      final action = AiTurnFollowUpPlanner.plan(
        updatedSave: _save(gameMode: GameMode.multiplayer),
        previousTurn: 1,
        aiPlayerId: 'ai_1',
        controlPlayerId: 'human',
        localAiRuntimeEnabled: false,
      );

      expect(action, isA<AiTurnFollowUpNone>());
    });

    test('schedules the next hot-seat AI player', () {
      final action = AiTurnFollowUpPlanner.plan(
        updatedSave: _save(
          gameMode: GameMode.hotSeat,
          playerStates: const {
            'human': PlayerTurnState.finished,
            'ai_1': PlayerTurnState.finished,
            'ai_2': PlayerTurnState.active,
          },
        ),
        previousTurn: 1,
        aiPlayerId: 'ai_1',
        controlPlayerId: 'ai_1',
        localAiRuntimeEnabled: true,
      );

      expect(
        action,
        isA<AiTurnFollowUpScheduleAi>().having(
          (action) => action.playerId,
          'playerId',
          'ai_2',
        ),
      );
    });

    test('creates hot-seat human handoff with fresh turn state', () {
      final action = AiTurnFollowUpPlanner.plan(
        updatedSave: _save(
          gameMode: GameMode.hotSeat,
          turn: 2,
          playerStates: const {
            'human': PlayerTurnState.active,
            'ai_1': PlayerTurnState.finished,
            'ai_2': PlayerTurnState.finished,
          },
        ),
        previousTurn: 1,
        aiPlayerId: 'ai_1',
        controlPlayerId: 'ai_1',
        localAiRuntimeEnabled: true,
      );

      expect(
        action,
        isA<AiTurnFollowUpHotSeatHandoff>()
            .having((action) => action.player.id, 'player.id', 'human')
            .having((action) => action.turnNumber, 'turnNumber', 2)
            .having((action) => action.freshTurn, 'freshTurn', isTrue),
      );
    });

    test(
      'schedules the next active multiplayer AI before returning to human',
      () {
        final action = AiTurnFollowUpPlanner.plan(
          updatedSave: _save(
            gameMode: GameMode.multiplayer,
            playerStates: const {
              'human': PlayerTurnState.active,
              'ai_1': PlayerTurnState.finished,
              'ai_2': PlayerTurnState.active,
            },
          ),
          previousTurn: 1,
          aiPlayerId: 'ai_1',
          controlPlayerId: 'human',
          localAiRuntimeEnabled: true,
        );

        expect(
          action,
          isA<AiTurnFollowUpScheduleAi>().having(
            (action) => action.playerId,
            'playerId',
            'ai_2',
          ),
        );
      },
    );

    test('confirms the local human when multiplayer AI chain is complete', () {
      final action = AiTurnFollowUpPlanner.plan(
        updatedSave: _save(
          gameMode: GameMode.multiplayer,
          playerStates: const {
            'human': PlayerTurnState.active,
            'ai_1': PlayerTurnState.finished,
            'ai_2': PlayerTurnState.finished,
          },
        ),
        previousTurn: 1,
        aiPlayerId: 'ai_1',
        controlPlayerId: 'ai_1',
        localAiRuntimeEnabled: true,
      );

      expect(
        action,
        isA<AiTurnFollowUpConfirmHumanTurn>()
            .having((action) => action.playerId, 'playerId', 'human')
            .having(
              (action) => action.playTurnAdvanceEffects,
              'playTurnAdvanceEffects',
              isFalse,
            ),
      );
    });

    test('confirms human with turn-advance effects after a fresh turn', () {
      final action = AiTurnFollowUpPlanner.plan(
        updatedSave: _save(
          gameMode: GameMode.multiplayer,
          turn: 2,
          playerStates: const {
            'human': PlayerTurnState.active,
            'ai_1': PlayerTurnState.finished,
            'ai_2': PlayerTurnState.finished,
          },
        ),
        previousTurn: 1,
        aiPlayerId: 'ai_1',
        controlPlayerId: 'human',
        localAiRuntimeEnabled: true,
      );

      expect(
        action,
        isA<AiTurnFollowUpConfirmHumanTurn>()
            .having((action) => action.playerId, 'playerId', 'human')
            .having(
              (action) => action.playTurnAdvanceEffects,
              'playTurnAdvanceEffects',
              isTrue,
            ),
      );
    });

    test('does nothing when the local human cannot act after turn advance', () {
      final action = AiTurnFollowUpPlanner.plan(
        updatedSave: _save(
          gameMode: GameMode.multiplayer,
          turn: 2,
          playerStates: const {
            'human': PlayerTurnState.finished,
            'ai_1': PlayerTurnState.finished,
            'ai_2': PlayerTurnState.finished,
          },
        ),
        previousTurn: 1,
        aiPlayerId: 'ai_1',
        controlPlayerId: 'human',
        localAiRuntimeEnabled: true,
      );

      expect(action, isA<AiTurnFollowUpNone>());
    });
  });
}

GameSave _save({
  required GameMode gameMode,
  int turn = 1,
  Map<String, PlayerTurnState> playerStates = const {
    'human': PlayerTurnState.active,
    'ai_1': PlayerTurnState.finished,
    'ai_2': PlayerTurnState.finished,
  },
}) {
  return GameSave(
    id: 'save_1',
    name: 'AI follow-up planner test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
    players: const [_humanPlayer, _aiPlayer1, _aiPlayer2],
    gameMode: gameMode,
  );
}

const _humanPlayer = Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB);

const _aiPlayer1 = Player(
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
);

const _aiPlayer2 = Player(
  id: 'ai_2',
  name: 'AI 2',
  colorValue: 0xFF16A34A,
  kind: PlayerKind.ai,
  ai: AiPlayer(
    strategyId: AiStrategyId.mcts,
    difficulty: AiDifficulty.normal,
    persona: AiPersona.expansive,
    seed: 2002,
  ),
);
