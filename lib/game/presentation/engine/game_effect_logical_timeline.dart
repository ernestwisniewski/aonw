import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';

/// Renderer-neutral logical durations used to order authoritative effects.
///
/// These values are scheduling identities, not wall-clock synchronization.
abstract final class GameEffectLogicalTimeline {
  static const _movementStep = Duration(milliseconds: 180);
  static const _combat = Duration(milliseconds: 720);
  static const _transient = Duration(milliseconds: 180);

  static Duration durationFor(RendererEffect effect) {
    return switch (effect) {
      AnimateUnitMoveEffect(:final steps) => _movementStep * steps.length,
      PlayCombatAnimationEffect() => _combat,
      SmoothCameraEffect(:final duration) => _seconds(duration),
      JumpCameraEffect() => Duration.zero,
      ShowFloatingTextEffect(:final delay) => delay + _transient,
      ShowCityProductionBubbleEffect(:final delay) => delay + _transient,
      ShakeCameraEffect(:final duration) => _seconds(duration),
      SpawnParticleBurstEffect() || ShowCombatHexAlertEffect() => _transient,
    };
  }

  static Duration _seconds(double value) =>
      Duration(microseconds: (value * Duration.microsecondsPerSecond).round());
}
