import 'package:aonw/game/presentation/services/isolated_ai_plan_executor_compute.dart'
    if (dart.library.io) 'package:aonw/game/presentation/services/isolated_ai_plan_executor_worker.dart'
    as implementation;
import 'package:aonw_core/ai.dart';

Future<AiTurnPlan> isolatedAiPlanExecutor({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) {
  return implementation.executeAiPlan(
    strategy: strategy,
    view: view,
    context: context,
  );
}

Future<AiTurnPlan> isolatedAiPlanPrecomputeExecutor({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) {
  return implementation.precomputeAiPlan(
    strategy: strategy,
    view: view,
    context: context,
  );
}

Future<void> shutdownIsolatedAiPlanExecutorForTesting() {
  return shutdownIsolatedAiPlanExecutor();
}

Future<void> shutdownIsolatedAiPlanExecutor() {
  return implementation.shutdownAiPlanExecutorForTesting();
}
