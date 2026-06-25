import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluation_queries.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'mcts_command_movement_settler_scorer.dart';
part 'mcts_command_movement_support_scorer.dart';

final class MctsCommandMovementScorer {
  const MctsCommandMovementScorer()
    : _settlerScorer = const _MctsSettlerMovementScorer(),
      _supportScorer = const _MctsSupportMovementScorer();

  static const double _baseMoveScore = 0.04;

  final _MctsSettlerMovementScorer _settlerScorer;
  final _MctsSupportMovementScorer _supportScorer;

  double score(
    MoveUnitCommand command, {
    required SimulatedState state,
    AiContext? context,
  }) {
    final unit = mctsOwnUnitById(state.ownUnits, command.unitId);
    if (unit == null) return _baseMoveScore;

    final score = CityFoundingRules.canFoundCityWith(unit)
        ? _settlerScorer.score(
            command,
            unit: unit,
            state: state,
            context: context,
          )
        : _supportScorer.score(
            command,
            unit: unit,
            state: state,
            context: context,
          );
    return _baseMoveScore + score;
  }
}
