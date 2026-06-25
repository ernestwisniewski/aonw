import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw_core/ai.dart';

AiStrategyRegistry buildRuntimeAiStrategyRegistry({
  required AiRuntimeThrottleSnapshot throttle,
}) {
  return AiStrategyRegistry({
    AiStrategyId.random: const RandomStrategy(),
    AiStrategyId.basic: const BasicStrategy(),
    AiStrategyId.mcts: MctsStrategy(
      runtimeProfile: throttle.mctsRuntimeProfile,
    ),
  });
}
