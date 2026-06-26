import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class GameRendererEffectSequenceBuilder {
  static List<RendererEffect> build({
    required Iterable<RendererEffect> commandEffects,
    required Iterable<GameEvent> events,
    required GameState state,
    GameState? previousState,
    AppLocalizations? l10n,
  }) {
    final visibleCommandEffects = commandEffects.toList(growable: false);
    return [
      ...visibleCommandEffects,
      ...GameEventRendererEffectMapper.effectsFor(
        events: events,
        state: state,
        previousState: previousState,
        l10n: l10n,
        skipUnitMoveIds: _animatedUnitIds(visibleCommandEffects),
      ),
    ];
  }

  static Set<String> _animatedUnitIds(Iterable<RendererEffect> effects) {
    return {
      for (final effect in effects.whereType<AnimateUnitMoveEffect>())
        effect.unitId,
    };
  }
}
