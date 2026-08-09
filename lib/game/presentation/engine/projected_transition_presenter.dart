import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/authoritative_presentation_scheduler.dart';
import 'package:aonw/game/presentation/engine/game_renderer_transition_handler.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';

/// Coordinates renderer readiness, authoritative timing, and presentation.
abstract final class ProjectedTransitionPresenter {
  static Future<void> present({
    required GameRendererTransitionHandler transitionHandler,
    required ProjectedGameTransition<GameClientState> transition,
    required Iterable<RendererEffect> effects,
    required Future<void> presentationReady,
    required void Function() ensureActive,
    required AuthoritativePresentationScheduler? scheduler,
  }) {
    return transitionHandler.enqueue(() async {
      await presentationReady;
      ensureActive();

      Future<void> apply() async {
        transition.onPresentationStart?.call();
        await transitionHandler.applyNow(
          transition.state,
          effects,
          currentTurn: transition.currentTurn,
          suppressCameraFocus:
              transition.batch.sequenceDirective ==
              PresentationSequenceDirective.resync,
        );
      }

      await (scheduler?.presentAtAuthoritativeStart(transition.batch, apply) ??
          apply());
    });
  }
}
