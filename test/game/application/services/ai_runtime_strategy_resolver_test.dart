import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_resolver.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiRuntimeStrategyResolver', () {
    test('logs adaptive late-game and returns battery-saver MCTS registry', () {
      final logger = _RecordingGameLogger();
      final resolver = AiRuntimeStrategyResolver(
        logger: logger,
        throttler: AiRuntimeThrottler(),
        forceBatterySaver: () => false,
      );

      final registry = resolver.resolve(
        playerId: 'ai_1',
        save: _save(turn: AiRuntimeThrottler.adaptiveLateGameTurnThreshold),
        gameState: const GameState(),
        networkSession: null,
      );

      final strategy = registry.resolve(AiStrategyId.mcts);
      expect(strategy, isA<MctsStrategy>());
      expect(
        (strategy as MctsStrategy).runtimeProfile,
        MctsRuntimeProfile.batterySaver,
      );
      expect(
        logger.infoMessages.single,
        contains('adaptive late-game MCTS profile player=ai_1'),
      );
    });

    test('can force battery-saver profile without adaptive late-game log', () {
      final logger = _RecordingGameLogger();
      final resolver = AiRuntimeStrategyResolver(
        logger: logger,
        throttler: AiRuntimeThrottler(),
        forceBatterySaver: () => true,
      );

      final registry = resolver.resolve(
        playerId: 'ai_1',
        save: _save(turn: 1),
        gameState: const GameState(),
        networkSession: null,
      );

      final strategy = registry.resolve(AiStrategyId.mcts);
      expect(strategy, isA<MctsStrategy>());
      expect(
        (strategy as MctsStrategy).runtimeProfile,
        MctsRuntimeProfile.batterySaver,
      );
      expect(logger.infoMessages, isEmpty);
    });

    test('keeps interactive profile for early local runtime', () {
      final logger = _RecordingGameLogger();
      final resolver = AiRuntimeStrategyResolver(
        logger: logger,
        throttler: AiRuntimeThrottler(),
        forceBatterySaver: () => false,
      );

      final registry = resolver.resolve(
        playerId: 'ai_1',
        save: _save(turn: 1),
        gameState: const GameState(),
        networkSession: null,
      );

      final strategy = registry.resolve(AiStrategyId.mcts);
      expect(strategy, isA<MctsStrategy>());
      expect(
        (strategy as MctsStrategy).runtimeProfile,
        MctsRuntimeProfile.interactive,
      );
      expect(logger.infoMessages, isEmpty);
    });
  });
}

GameSave _save({required int turn}) {
  return GameSave(
    id: 'save_1',
    name: 'Runtime strategy resolver test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {
      'human': PlayerTurnState.active,
      'ai_1': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
    players: const [
      Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB),
      Player(
        id: 'ai_1',
        name: 'AI',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 99),
      ),
    ],
    gameMode: GameMode.multiplayer,
  );
}

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
