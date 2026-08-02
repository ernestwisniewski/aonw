import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

typedef HiddenAiRendererStateReader = GameClientState? Function();
typedef HiddenAiLocalizationReader = AppLocalizations? Function();
typedef HiddenAiProjectedTransitionApplier =
    Future<void> Function(
      GameClientState state,
      ProjectedGameEffectBatch effects,
    );

final class HiddenAiRendererPlaybackReport {
  final GameClientState rendererState;
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
  final HiddenAiProjectedTransitionApplier applyProjectedTransition;

  const HiddenAiRendererPlayback({
    required this.rendererStateReader,
    required this.localizationReader,
    required this.applyProjectedTransition,
  });

  GameClientState previousRendererState(GameClientState fallbackState) {
    return rendererStateReader() ?? fallbackState;
  }

  Future<HiddenAiRendererPlaybackReport> playCommandEffects({
    required GameClientState previousRendererState,
    required GameClientState commandState,
    required Iterable<UiEffect> uiEffects,
    required Iterable<GameEvent> events,
    String sourceId = 'hidden-ai-preview',
    int eventOffset = 0,
    int? authoritativeTick,
    int? authoritativeStartMicrosUtc,
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
            authoritativeTick: authoritativeTick,
            authoritativeStartMicrosUtc: authoritativeStartMicrosUtc,
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
      await applyProjectedTransition(rendererState, rendererEffects);
    }

    return HiddenAiRendererPlaybackReport(
      rendererState: rendererState,
      rendererEffects: rendererEffects.effects,
    );
  }

  static GameClientState withActionContext(
    GameClientState state,
    GameClientState source,
  ) {
    return state.copyWith(
      activePlayerId: source.activePlayerId,
      activePlayerCanAct: source.activePlayerCanAct,
    );
  }
}
