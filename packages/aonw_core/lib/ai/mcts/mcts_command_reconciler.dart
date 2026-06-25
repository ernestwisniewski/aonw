import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_baseline_command_merger.dart';
import 'package:aonw_core/ai/mcts/mcts_command_validator.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulator.dart';
import 'package:aonw_core/game/domain/command.dart';

const _defaultValidator = MctsCommandValidator();
const _defaultMerger = MctsBaselineCommandMerger();

final class MctsCommandReconciler {
  final MctsCommandValidator _validator;
  final MctsBaselineCommandMerger _merger;

  const MctsCommandReconciler({
    MctsCommandValidator validator = _defaultValidator,
    MctsBaselineCommandMerger merger = _defaultMerger,
  }) : _validator = validator,
       _merger = merger;

  List<GameCommand> validatedCommands(
    List<MctsAction> actions, {
    required SimulatedState rootState,
    required MctsSimulator simulator,
  }) {
    return _validator.validatedCommands(
      actions,
      rootState: rootState,
      simulator: simulator,
    );
  }

  List<GameCommand> withBaselineSupportCommands(
    List<GameCommand> commands,
    List<GameCommand> baseline,
    GameView view,
    AiContext context, {
    required MctsSimulator simulator,
  }) {
    return _merger.withBaselineSupportCommands(
      commands,
      baseline,
      view,
      context,
      simulator: simulator,
    );
  }
}
