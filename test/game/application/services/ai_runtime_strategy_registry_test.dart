import 'package:aonw/game/application/services/ai_runtime_strategy_registry.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw_core/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildRuntimeAiStrategyRegistry', () {
    test('passes late-game battery-saver profile to MCTS strategy', () {
      final throttler = AiRuntimeThrottler();
      final throttle = throttler.snapshotFor(
        localSinglePlayer: true,
        turn: AiRuntimeThrottler.adaptiveLateGameTurnThreshold,
        totalUnitCount: 0,
        totalCityCount: 0,
      );

      final registry = buildRuntimeAiStrategyRegistry(throttle: throttle);

      final strategy = registry.resolve(AiStrategyId.mcts);
      expect(strategy, isA<MctsStrategy>());
      expect(
        (strategy as MctsStrategy).runtimeProfile,
        MctsRuntimeProfile.batterySaver,
      );
    });

    test('keeps interactive profile for early low-pressure runtime', () {
      final throttler = AiRuntimeThrottler();

      final registry = buildRuntimeAiStrategyRegistry(
        throttle: throttler.snapshot,
      );

      final strategy = registry.resolve(AiStrategyId.mcts);
      expect(strategy, isA<MctsStrategy>());
      expect(
        (strategy as MctsStrategy).runtimeProfile,
        MctsRuntimeProfile.interactive,
      );
    });
  });
}
