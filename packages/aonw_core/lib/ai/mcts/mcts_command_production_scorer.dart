import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluation_queries.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'mcts_command_production_policies.dart';
part 'mcts_command_production_situation.dart';

final class MctsCommandProductionScorer {
  const MctsCommandProductionScorer();

  double score(
    StartUnitProductionCommand command, {
    required SimulatedState state,
    AiContext? context,
  }) {
    if (context == null) return 0.11;

    final situation = _MctsProductionSituation(
      command: command,
      state: state,
      context: context,
      assessment: AiEmpireAssessment.fromView(state.view, context),
    );
    return _MctsProductionPolicy.forSituation(situation).score(situation);
  }
}
