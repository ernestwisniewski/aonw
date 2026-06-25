import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw_core/ai.dart';

class AiRuntimeThrottleSnapshot {
  final int pressureLevel;
  final Duration precomputeDebounceDuration;
  final Duration precomputeMinimumStartInterval;
  final MctsRuntimeProfile mctsRuntimeProfile;
  final bool adaptiveLateGame;
  final bool forcedBatterySaver;

  const AiRuntimeThrottleSnapshot({
    required this.pressureLevel,
    required this.precomputeDebounceDuration,
    required this.precomputeMinimumStartInterval,
    required this.mctsRuntimeProfile,
    this.adaptiveLateGame = false,
    this.forcedBatterySaver = false,
  });

  bool get isBatterySaver =>
      mctsRuntimeProfile == MctsRuntimeProfile.batterySaver;

  @override
  String toString() {
    return 'pressure=$pressureLevel '
        'debounce=${precomputeDebounceDuration.inMilliseconds}ms '
        'interval=${precomputeMinimumStartInterval.inMilliseconds}ms '
        'mcts=${mctsRuntimeProfile.name}'
        '${forcedBatterySaver ? ' forced=battery-saver' : ''}'
        '${adaptiveLateGame ? ' adaptive=late-game' : ''}';
  }
}

class AiRuntimeThrottler {
  static const basePrecomputeDebounceDuration = Duration(milliseconds: 900);
  static const basePrecomputeMinimumStartInterval = Duration(
    milliseconds: 2500,
  );
  static const slowPrecomputeThreshold = Duration(milliseconds: 1200);
  static const slowFreshPlanningThreshold = Duration(milliseconds: 650);
  static const fastPrecomputeThreshold = Duration(milliseconds: 650);
  static const fastPrecomputedPlanningThreshold = Duration(milliseconds: 80);
  static const maxPressureLevel = 3;
  static const adaptiveLateGameTurnThreshold = 55;
  static const adaptiveLateGameUnitThreshold = 36;
  static const adaptiveLateGameCityThreshold = 8;

  int _pressureLevel = 0;
  int _stableSamples = 0;

  AiRuntimeThrottleSnapshot get snapshot => _snapshot();

  AiRuntimeThrottleSnapshot snapshotFor({
    required bool localSinglePlayer,
    required int turn,
    required int totalUnitCount,
    required int totalCityCount,
    bool forceBatterySaver = false,
  }) {
    final adaptiveLateGame =
        localSinglePlayer &&
        (turn >= adaptiveLateGameTurnThreshold ||
            totalUnitCount >= adaptiveLateGameUnitThreshold ||
            totalCityCount >= adaptiveLateGameCityThreshold);
    return _snapshot(
      adaptiveLateGame: adaptiveLateGame,
      forcedBatterySaver: forceBatterySaver,
    );
  }

  AiRuntimeThrottleSnapshot _snapshot({
    bool adaptiveLateGame = false,
    bool forcedBatterySaver = false,
  }) {
    final batterySaver =
        forcedBatterySaver || _pressureLevel >= 2 || adaptiveLateGame;
    return AiRuntimeThrottleSnapshot(
      pressureLevel: _pressureLevel,
      precomputeDebounceDuration: Duration(
        milliseconds:
            basePrecomputeDebounceDuration.inMilliseconds +
            _pressureLevel * 300,
      ),
      precomputeMinimumStartInterval: Duration(
        milliseconds:
            basePrecomputeMinimumStartInterval.inMilliseconds +
            _pressureLevel * 1100,
      ),
      mctsRuntimeProfile: batterySaver
          ? MctsRuntimeProfile.batterySaver
          : MctsRuntimeProfile.interactive,
      adaptiveLateGame: adaptiveLateGame,
      forcedBatterySaver: forcedBatterySaver,
    );
  }

  bool recordPrecomputeQueued({required bool replaced}) {
    if (!replaced) return false;
    return _increasePressure();
  }

  bool recordPrecomputeCompleted(Duration duration) {
    if (duration >= slowPrecomputeThreshold) {
      return _increasePressure();
    }
    if (duration <= fastPrecomputeThreshold) {
      return _recordStableSample();
    }
    _stableSamples = 0;
    return false;
  }

  bool recordPrecomputeFailed() {
    return _increasePressure();
  }

  bool recordTurn({
    required AiPlanSource planningSource,
    required Duration planningDuration,
  }) {
    return switch (planningSource) {
      AiPlanSource.precomputed =>
        planningDuration <= fastPrecomputedPlanningThreshold
            ? _recordStableSample()
            : false,
      AiPlanSource.fresh =>
        planningDuration >= slowFreshPlanningThreshold
            ? _increasePressure()
            : false,
      AiPlanSource.freshAfterPrecomputeFailure => _increasePressure(),
    };
  }

  bool reset() {
    final changed = _pressureLevel != 0 || _stableSamples != 0;
    _pressureLevel = 0;
    _stableSamples = 0;
    return changed;
  }

  bool _increasePressure() {
    _stableSamples = 0;
    if (_pressureLevel >= maxPressureLevel) return false;
    _pressureLevel += 1;
    return true;
  }

  bool _recordStableSample() {
    if (_pressureLevel == 0) {
      _stableSamples = 0;
      return false;
    }

    _stableSamples += 1;
    if (_stableSamples < 3) return false;

    _stableSamples = 0;
    _pressureLevel -= 1;
    return true;
  }
}
