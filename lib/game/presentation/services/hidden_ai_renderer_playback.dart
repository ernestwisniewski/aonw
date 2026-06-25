import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer_effect_sequence_builder.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';

typedef HiddenAiRendererStateReader = GameState? Function();
typedef HiddenAiLocalizationReader = AppLocalizations? Function();
typedef HiddenAiTransitionApplier =
    Future<void> Function(GameState state, List<RendererEffect> effects);

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

  const HiddenAiRendererPlayback({
    required this.rendererStateReader,
    required this.localizationReader,
    required this.applyTransition,
  });

  GameState previousRendererState(GameState fallbackState) {
    return rendererStateReader() ?? fallbackState;
  }

  Future<HiddenAiRendererPlaybackReport> playCommandEffects({
    required GameState previousRendererState,
    required GameState commandState,
    required Iterable<UiEffect> uiEffects,
    required Iterable<GameEvent> events,
  }) async {
    final rendererState = withActionContext(
      commandState,
      previousRendererState,
    );
    final rendererEffects = GameRendererEffectSequenceBuilder.build(
      commandEffects: uiEffects.rendererEffects,
      events: events,
      state: rendererState,
      previousState: previousRendererState,
      l10n: localizationReader(),
    );

    if (rendererEffects.isNotEmpty) {
      await applyTransition(rendererState, rendererEffects);
    }

    return HiddenAiRendererPlaybackReport(
      rendererState: rendererState,
      rendererEffects: rendererEffects,
    );
  }

  static GameState withActionContext(GameState state, GameState source) {
    return state.copyWith(
      activePlayerId: source.activePlayerId,
      activePlayerCanAct: source.activePlayerCanAct,
    );
  }
}
