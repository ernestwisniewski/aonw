import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_runner.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnFollowUpRunner', () {
    test('clears handoff and schedules next multiplayer AI', () async {
      final calls = <String>[];
      final logger = _RecordingGameLogger();
      final runner = _runner(calls, logger: logger);

      final nextAi = await runner.advanceAfterAiTurn(
        updatedSave: _save(
          gameMode: GameMode.multiplayer,
          playerStates: const {
            'human': PlayerTurnState.active,
            'ai_1': PlayerTurnState.finished,
            'ai_2': PlayerTurnState.active,
          },
        ),
        previousTurn: 1,
        playerId: 'ai_1',
        terminalUiEffects: const [],
      );

      expect(nextAi, 'ai_2');
      expect(calls, const ['clear']);
      expect(logger.infoMessages, isEmpty);
    });

    test(
      'confirms human turn with turn-advance playback and logging',
      () async {
        final calls = <String>[];
        final logger = _RecordingGameLogger();
        final runner = _runner(calls, logger: logger);

        final nextAi = await runner.advanceAfterAiTurn(
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
          playerId: 'ai_1',
          terminalUiEffects: const [JumpCameraEffect(col: 2, row: 3)],
        );

        expect(nextAi, isNull);
        expect(calls, const [
          'clear',
          'effects:save_1:1',
          'confirm:human',
          'focus:human',
        ]);
        expect(
          logger.infoMessages.single,
          startsWith('AI Runtime: hidden turn-advance effects duration='),
        );
        expect(logger.infoMessages.single, contains('effects=1'));
      },
    );

    test('sets formatted hot-seat handoff for human player', () async {
      final calls = <String>[];
      final handoffs = <HandoffData>[];
      final runner = _runner(calls, handoffs: handoffs);

      final nextAi = await runner.advanceAfterAiTurn(
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
        playerId: 'ai_1',
        terminalUiEffects: const [],
      );

      expect(nextAi, isNull);
      expect(calls, const ['handoff:human']);
      expect(handoffs.single.playerId, 'human');
      expect(handoffs.single.playerName, 'formatted Human');
      expect(handoffs.single.turnNumber, 2);
      expect(handoffs.single.freshTurn, isTrue);
    });

    test('does nothing when local AI runtime is disabled', () async {
      final calls = <String>[];
      final runner = _runner(calls, localAiRuntimeEnabled: false);

      final nextAi = await runner.advanceAfterAiTurn(
        updatedSave: _save(gameMode: GameMode.multiplayer),
        previousTurn: 1,
        playerId: 'ai_1',
        terminalUiEffects: const [JumpCameraEffect(col: 2, row: 3)],
      );

      expect(nextAi, isNull);
      expect(calls, isEmpty);
    });
  });
}

AiTurnFollowUpRunner _runner(
  List<String> calls, {
  GameLogger? logger,
  bool localAiRuntimeEnabled = true,
  List<HandoffData>? handoffs,
}) {
  return AiTurnFollowUpRunner(
    logger: logger ?? _RecordingGameLogger(),
    localAiRuntimeEnabled: (_) => localAiRuntimeEnabled,
    controlPlayerId: () => 'human',
    playTurnAdvanceEffects:
        ({required saveId, required terminalUiEffects}) async {
          calls.add('effects:$saveId:${terminalUiEffects.length}');
          return terminalUiEffects.length;
        },
    confirmHumanTurn: (playerId) async {
      calls.add('confirm:$playerId');
    },
    focusTurnStartMapTarget: (playerId) async {
      calls.add('focus:$playerId');
    },
    canContinue: () => true,
    clearHandoff: () {
      calls.add('clear');
    },
    setHandoff: (handoff) {
      calls.add('handoff:${handoff.playerId}');
      handoffs?.add(handoff);
    },
    playerNameFormatter: (player) => 'formatted ${player.name}',
  );
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
    name: 'Follow-up runner test',
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

final class _RecordingGameLogger implements GameLogger {
  final infoMessages = <String>[];
  final warnMessages = <String>[];

  @override
  void info(String tag, String message) {
    infoMessages.add('$tag: $message');
  }

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    warnMessages.add('$tag: $message');
  }
}
