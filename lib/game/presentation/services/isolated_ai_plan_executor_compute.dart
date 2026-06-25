import 'package:aonw/game/presentation/services/ai_plan_executor_protocol.dart';
import 'package:aonw_core/ai.dart';
import 'package:flutter/foundation.dart';

Future<AiTurnPlan> executeAiPlan({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) {
  return compute(
    planAiTurnInBackground,
    AiPlanRequest(strategy: strategy, view: view, context: context),
    debugLabel: 'AI planning',
  );
}

Future<AiTurnPlan> precomputeAiPlan({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) {
  return compute(
    planAiTurnInBackground,
    AiPlanRequest(strategy: strategy, view: view, context: context),
    debugLabel: 'AI precompute',
  );
}

Future<void> shutdownAiPlanExecutorForTesting() async {}
