import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_effect_normalizer.dart';
import 'package:aonw/game/presentation/services/hidden_ai_command_presenter.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw_core/game/domain/command.dart';

typedef AiTurnPresentationSessionReader = GameSession? Function();
typedef AiTurnPresentationStateReader = GameState? Function(String saveId);
typedef AiTurnHiddenCommandDispatcher =
    Future<DispatchCommandResult> Function({
      required String saveId,
      required GameCommand command,
      required GameCommandContext context,
    });

final class AiTurnPresentationDriver {
  final AiTurnPresentationSessionReader sessionReader;
  final AiTurnPresentationStateReader stateReader;
  final HiddenAiLocalizationReader localizationReader;
  final HiddenAiTransitionApplier applyTransition;
  final AiTurnHiddenCommandDispatcher hiddenDispatch;

  const AiTurnPresentationDriver({
    required this.sessionReader,
    required this.stateReader,
    required this.localizationReader,
    required this.applyTransition,
    required this.hiddenDispatch,
  });

  Future<DispatchCommandResult> dispatchCommand({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    required GameCommandContext context,
  }) async {
    final session = sessionReader();
    if (session == null || session.saveId != saveId) {
      return DispatchCommandResult(state: currentState);
    }

    final presenter = HiddenAiCommandPresenter.withPlayback(
      rendererPlayback: HiddenAiRendererPlayback(
        rendererStateReader: () => stateReader(saveId),
        localizationReader: localizationReader,
        applyTransition: applyTransition,
      ),
      dispatchTransition: (command, {required context}) {
        return hiddenDispatch(
          saveId: saveId,
          command: command,
          context: context,
        );
      },
    );
    return presenter.dispatchAndPresent(
      currentState: currentState,
      command: command,
      context: context,
    );
  }

  Future<int> playTurnAdvanceEffects({
    required String saveId,
    required Iterable<UiEffect> terminalUiEffects,
  }) async {
    final rendererEffects = GameCameraEffectNormalizer.forTurnAdvance(
      effects: terminalUiEffects.rendererEffects,
    );
    if (rendererEffects.isEmpty) return 0;

    final state = stateReader(saveId);
    if (state == null) return 0;

    await applyTransition(state, rendererEffects);
    return rendererEffects.length;
  }
}
