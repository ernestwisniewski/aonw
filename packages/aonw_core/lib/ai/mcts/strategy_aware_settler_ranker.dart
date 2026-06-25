import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'strategy_aware_settler_move_ranker.dart';
part 'strategy_aware_settler_policies.dart';
part 'strategy_aware_settler_support_rankers.dart';

const _military = StrategyAwareMilitaryContext();
const _strategicSettlerRanker = _StrategicSettlerRanker();
const _citySiteDiscoveryRanker = _CitySiteDiscoveryRanker();
const _settlerEscortRanker = _SettlerEscortRanker();

CommandRanking? rankStrategicSettlerCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _strategicSettlerRanker.rank(command, view, context, plan);
}

CommandRanking? rankCitySiteDiscoveryCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _citySiteDiscoveryRanker.rank(command, view, context, plan);
}

CommandRanking? rankSettlerEscortCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _settlerEscortRanker.rank(command, view, context, plan);
}
