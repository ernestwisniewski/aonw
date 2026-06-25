import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_registry.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI runtime mode', () {
    test('treats local single-player save as local AI runtime', () {
      final save = _save(gameMode: GameMode.multiplayer);

      expect(
        shouldRunLocalAiForMode(
          gameMode: save.gameMode,
          saveId: save.id,
          networkSession: null,
        ),
        isTrue,
      );
      expect(
        isLocalSinglePlayerAiRuntime(save: save, networkSession: null),
        isTrue,
      );
    });

    test(
      'keeps connected matching multiplayer out of local single-player mode',
      () {
        final save = _save(gameMode: GameMode.multiplayer);
        final session = _connectedSession(matchId: save.id);

        expect(
          shouldRunLocalAiForMode(
            gameMode: save.gameMode,
            saveId: save.id,
            networkSession: session,
          ),
          isFalse,
        );
        expect(
          isLocalSinglePlayerAiRuntime(save: save, networkSession: session),
          isFalse,
        );
      },
    );

    test(
      'late local single-player gets battery-saver MCTS runtime profile',
      () {
        final save = _save(
          gameMode: GameMode.multiplayer,
          turn: AiRuntimeThrottler.adaptiveLateGameTurnThreshold,
        );
        final localSinglePlayer = isLocalSinglePlayerAiRuntime(
          save: save,
          networkSession: null,
        );
        final throttle = AiRuntimeThrottler().snapshotFor(
          localSinglePlayer: localSinglePlayer,
          turn: save.turn,
          totalUnitCount: 0,
          totalCityCount: 0,
        );

        final strategy = buildRuntimeAiStrategyRegistry(
          throttle: throttle,
        ).resolve(AiStrategyId.mcts);

        expect(localSinglePlayer, isTrue);
        expect(throttle.adaptiveLateGame, isTrue);
        expect(strategy, isA<MctsStrategy>());
        expect(
          (strategy as MctsStrategy).runtimeProfile,
          MctsRuntimeProfile.batterySaver,
        );
      },
    );
  });
}

NetworkSession _connectedSession({required String matchId}) {
  return NetworkSession(
    userId: 'user_1',
    token: AuthToken('token'),
    matchId: matchId,
    connectionState: const NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
    ),
  );
}

GameSave _save({required GameMode gameMode, int turn = 1}) {
  return GameSave(
    id: 'save_1',
    name: 'AI runtime mode test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 5, 29),
    camera: CameraState.zero,
    players: [
      const Player(id: 'player_1', name: 'Human', colorValue: 0xFF2563EB),
      const Player(
        id: 'player_2',
        name: 'AI',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.mcts,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 1001,
        ),
      ),
    ],
    gameMode: gameMode,
  );
}
