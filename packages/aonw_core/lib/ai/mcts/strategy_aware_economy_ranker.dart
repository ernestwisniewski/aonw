import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'strategy_aware_economy_production_ranker.dart';
part 'strategy_aware_economy_production_inventory.dart';
part 'strategy_aware_economy_queue_ranker.dart';
part 'strategy_aware_economy_settler_escort.dart';
part 'strategy_aware_economy_settler_production.dart';
part 'strategy_aware_economy_worker_ranker.dart';

const _military = StrategyAwareMilitaryContext();
const _strategicEconomyRanker = _StrategicEconomyRanker();

CommandRanking? rankStrategicEconomyCommand(
  GameCommand command,
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  return _strategicEconomyRanker.rank(command, view, context, plan);
}

final class _StrategicEconomyRanker {
  const _StrategicEconomyRanker()
    : _workerRanker = const _EconomyWorkerCommandRanker(),
      _technologyRanker = const _EconomyTechnologyRanker(),
      _unitProductionRanker = const _EconomyUnitProductionRanker(),
      _queueRanker = const _EconomyQueueRanker();

  final _EconomyWorkerCommandRanker _workerRanker;
  final _EconomyTechnologyRanker _technologyRanker;
  final _EconomyUnitProductionRanker _unitProductionRanker;
  final _EconomyQueueRanker _queueRanker;

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    return switch (command) {
      MoveUnitCommand() => _workerRanker.rankMove(command, view, plan),
      AssignWorkerToHexCommand() => _workerRanker.rankAssignment(
        command,
        view,
        plan,
      ),
      SelectWorkerImprovementCommand() => _workerRanker.rankImprovement(
        command,
        view,
        plan,
      ),
      SelectTechnologyCommand() => _technologyRanker.rank(command, plan),
      StartUnitProductionCommand() => _unitProductionRanker.rank(
        command,
        view,
        context,
        plan.mode,
      ),
      StartBuildingCommand() => _queueRanker.rankBuilding(command, plan.mode),
      StartCityProjectCommand() => _queueRanker.rankProject(command, plan.mode),
      _ => null,
    };
  }
}
