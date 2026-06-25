import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';

part 'strategy_aware_defense_early_ranker.dart';
part 'strategy_aware_defense_general_ranker.dart';
part 'strategy_aware_defense_garrison_ranker.dart';
part 'strategy_aware_defense_reserve_ranker.dart';

const _military = StrategyAwareMilitaryContext();
const _earlyCityDefenseRanker = _EarlyCityDefenseRanker();
const _generalDefenseRanker = _GeneralDefenseRanker();
const _lastMilitaryReserveRanker = _LastMilitaryReserveRanker();
const _reservedGarrisonRanker = _ReservedGarrisonRanker();
const _blockedEarlyDefense = CommandRanking(CandidatePriority.fallback, -900);
const _blockedReserveMove = CommandRanking(CandidatePriority.fallback, -940);
const _blockedDefense = CommandRanking(CandidatePriority.fallback, -950);

CommandRanking? rankEarlyCityDefenseCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _earlyCityDefenseRanker.rank(command, view, context, plan);
}

CommandRanking? rankLastMilitaryReserveCommand(
  GameCommand command,
  GameView view,
  AiContext context,
) {
  return _lastMilitaryReserveRanker.rank(command, view, context);
}

CommandRanking? rankReservedGarrisonCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _reservedGarrisonRanker.rank(command, view, context, plan);
}

CommandRanking? rankPinnedGarrisonMove(
  MoveUnitCommand command,
  GameView view,
  StrategicPlan plan,
) {
  return _reservedGarrisonRanker.rankPinnedMove(command, view, plan);
}

CommandRanking? rankDefenseCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _generalDefenseRanker.rank(command, view, context, plan);
}
