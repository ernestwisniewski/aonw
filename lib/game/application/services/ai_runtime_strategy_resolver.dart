import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_registry.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/ai.dart';

typedef AiRuntimeBatterySaverReader = bool Function();

final class AiRuntimeStrategyResolver {
  final GameLogger logger;
  final AiRuntimeThrottler throttler;
  final AiRuntimeBatterySaverReader forceBatterySaver;

  const AiRuntimeStrategyResolver({
    required this.logger,
    required this.throttler,
    required this.forceBatterySaver,
  });

  AiStrategyRegistry resolve({
    required String playerId,
    required GameSave save,
    required GameState gameState,
    required NetworkSession? networkSession,
  }) {
    final throttle = throttler.snapshotFor(
      localSinglePlayer: isLocalSinglePlayerAiRuntime(
        save: save,
        networkSession: networkSession,
      ),
      turn: save.turn,
      totalUnitCount: gameState.units.length,
      totalCityCount: gameState.cities.length,
      forceBatterySaver: forceBatterySaver(),
    );
    if (throttle.adaptiveLateGame) {
      logger.info(
        'AI Runtime',
        'adaptive late-game MCTS profile player=$playerId '
            'turn=${save.turn} '
            'units=${gameState.units.length} '
            'cities=${gameState.cities.length}; '
            'throttle=$throttle',
      );
    }
    return buildRuntimeAiStrategyRegistry(throttle: throttle);
  }
}
