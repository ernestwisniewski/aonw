import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';

abstract final class GameCameraEffectNormalizer {
  static const double turnStartCameraTransitionDuration = 0.85;

  static List<RendererEffect> forCommand({
    required GameCommand command,
    required Iterable<RendererEffect> effects,
  }) {
    return [
      for (final effect in effects) _normalizeCommandEffect(command, effect),
    ];
  }

  static List<RendererEffect> forTurnAdvance({
    required Iterable<RendererEffect> effects,
  }) {
    return [
      for (final effect in effects)
        if (effect is JumpCameraEffect)
          SmoothCameraEffect(
            col: effect.col,
            row: effect.row,
            duration: turnStartCameraTransitionDuration,
          )
        else
          effect,
    ];
  }

  static RendererEffect _normalizeCommandEffect(
    GameCommand command,
    RendererEffect effect,
  ) {
    if (command is FocusTurnStartActionCommand && effect is JumpCameraEffect) {
      return SmoothCameraEffect(
        col: effect.col,
        row: effect.row,
        duration: turnStartCameraTransitionDuration,
      );
    }
    if (command is FocusNextPendingActionCommand &&
        effect is JumpCameraEffect) {
      return SmoothCameraEffect(col: effect.col, row: effect.row);
    }
    return effect;
  }
}
