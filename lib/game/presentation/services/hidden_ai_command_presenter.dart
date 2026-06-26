import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw_core/game/domain/command.dart';

typedef HiddenAiCommandDispatch =
    Future<DispatchCommandResult> Function(
      GameCommand command, {
      required GameCommandContext context,
    });

final class HiddenAiCommandPresenter {
  final HiddenAiCommandDispatch dispatchTransition;
  final HiddenAiRendererPlayback rendererPlayback;

  HiddenAiCommandPresenter({
    required this.dispatchTransition,
    required HiddenAiRendererStateReader rendererStateReader,
    required HiddenAiLocalizationReader localizationReader,
    required HiddenAiTransitionApplier applyTransition,
  }) : rendererPlayback = HiddenAiRendererPlayback(
         rendererStateReader: rendererStateReader,
         localizationReader: localizationReader,
         applyTransition: applyTransition,
       );

  const HiddenAiCommandPresenter.withPlayback({
    required this.dispatchTransition,
    required this.rendererPlayback,
  });

  Future<DispatchCommandResult> dispatchAndPresent({
    required GameState currentState,
    required GameCommand command,
    required GameCommandContext context,
  }) async {
    final previousRendererState = rendererPlayback.previousRendererState(
      currentState,
    );
    final result = await dispatchTransition(command, context: context);

    if (!_isTerminalCommand(command)) {
      await rendererPlayback.playCommandEffects(
        previousRendererState: previousRendererState,
        commandState: result.state,
        uiEffects: result.uiEffects,
        events: result.events,
      );
    }

    return DispatchCommandResult(
      state: HiddenAiRendererPlayback.withActionContext(
        result.state,
        currentState,
      ),
      uiEffects: result.uiEffects,
      events: result.events,
      snapshot: result.snapshot,
      offset: result.offset,
      storedSnapshot: result.storedSnapshot,
    );
  }

  static bool _isTerminalCommand(GameCommand command) => switch (command) {
    EndTurnCommand() || SubmitTurnCommand() => true,
    _ => false,
  };
}
