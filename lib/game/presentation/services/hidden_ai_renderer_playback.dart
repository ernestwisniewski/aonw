import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

typedef HiddenAiRendererStateReader = GameState? Function();
typedef HiddenAiLocalizationReader = AppLocalizations? Function();
typedef HiddenAiTransitionApplier =
    Future<void> Function(GameState state, List<RendererEffect> effects);
typedef HiddenAiProjectedTransitionApplier =
    Future<void> Function(GameState state, ProjectedGameEffectBatch effects);

final class HiddenAiRendererPlaybackReport {
  final GameState rendererState;
  final List<RendererEffect> rendererEffects;

  HiddenAiRendererPlaybackReport({
    required this.rendererState,
    required Iterable<RendererEffect> rendererEffects,
  }) : rendererEffects = List.unmodifiable(rendererEffects);

  bool get applied => rendererEffects.isNotEmpty;
}

final class HiddenAiRendererPlayback {
  final HiddenAiRendererStateReader rendererStateReader;
  final HiddenAiLocalizationReader localizationReader;
  final HiddenAiTransitionApplier applyTransition;
  final HiddenAiProjectedTransitionApplier? applyProjectedTransition;

  const HiddenAiRendererPlayback({
    required this.rendererStateReader,
    required this.localizationReader,
    required this.applyTransition,
    this.applyProjectedTransition,
  });

  GameState previousRendererState(GameState fallbackState) {
    return rendererStateReader() ?? fallbackState;
  }

  Future<HiddenAiRendererPlaybackReport> playCommandEffects({
    required GameState previousRendererState,
    required GameState commandState,
    required Iterable<UiEffect> uiEffects,
    required Iterable<GameEvent> events,
    String sourceId = 'hidden-ai-preview',
    int eventOffset = 0,
    Iterable<MovementCommandExecution> movementExecutions = const [],
    int? turn,
  }) async {
    final rendererState = withActionContext(
      commandState,
      previousRendererState,
    );
    final rendererEffects =
        DomainEventPresentationProjector.projectObservedBatch(
          identity: PresentationBatchIdentity(
            sourceId: sourceId,
            eventOffset: eventOffset,
          ),
          interactionEffects: uiEffects.rendererEffects.where(
            (effect) =>
                effect is JumpCameraEffect || effect is SmoothCameraEffect,
          ),
          events: events,
          visibleMovementExecutions: movementExecutions,
          state: rendererState,
          previousState: previousRendererState,
          l10n: localizationReader(),
          turn: turn,
        );

    if (rendererEffects.effects.isNotEmpty) {
      final projectedApplier = applyProjectedTransition;
      if (projectedApplier == null) {
        await applyTransition(rendererState, rendererEffects.effects);
      } else {
        await projectedApplier(rendererState, rendererEffects);
      }
    }

    return HiddenAiRendererPlaybackReport(
      rendererState: rendererState,
      rendererEffects: rendererEffects.effects,
    );
  }

  static GameState withActionContext(GameState state, GameState source) {
    return state.copyWith(
      activePlayerId: source.activePlayerId,
      activePlayerCanAct: source.activePlayerCanAct,
    );
  }
}
