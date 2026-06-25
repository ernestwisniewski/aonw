import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/game_view.dart';

abstract interface class AiStrategy {
  AiTurnPlan plan(GameView view, AiContext context);
}
