import 'package:aonw_core/ai.dart';

class AiPlanRequest {
  final AiStrategy strategy;
  final GameView view;
  final AiContext context;

  const AiPlanRequest({
    required this.strategy,
    required this.view,
    required this.context,
  });
}

AiTurnPlan planAiTurnInBackground(AiPlanRequest request) {
  return request.strategy.plan(request.view, request.context);
}
