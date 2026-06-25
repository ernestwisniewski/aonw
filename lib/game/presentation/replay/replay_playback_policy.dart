import 'package:aonw/game/application/services/replay_service.dart';

class ReplayPlaybackPolicy {
  static const int normalDelayMs = 1200;
  static const int fastForwardDelayMs = 160;

  final String? perspectivePlayerId;
  final double speed;

  const ReplayPlaybackPolicy({
    required this.perspectivePlayerId,
    required this.speed,
  });

  bool shouldFastForwardStep(ReplayStep step) {
    return shouldFastForwardActor(step.effectiveActorPlayerId);
  }

  bool shouldFastForwardActor(String? actorPlayerId) {
    final perspective = perspectivePlayerId;
    if (perspective == null || perspective.isEmpty) return false;
    if (actorPlayerId == null || actorPlayerId.isEmpty) return true;
    return actorPlayerId != perspective;
  }

  Duration delayBeforeStep(ReplayStep? step) {
    return delayBeforeActor(step?.effectiveActorPlayerId);
  }

  Duration delayBeforeActor(String? actorPlayerId) {
    final fastForward = shouldFastForwardActor(actorPlayerId);
    final baseMs = fastForward ? fastForwardDelayMs : normalDelayMs;
    final minMs = fastForward ? 8 : 50;
    final maxMs = fastForward ? 360 : 3000;
    return Duration(
      milliseconds: (baseMs / _safeSpeed).round().clamp(minMs, maxMs),
    );
  }

  double get _safeSpeed => speed.isFinite && speed > 0 ? speed : 1;
}
