part of '../run_save_ai_benchmark.dart';

class _BenchmarkRuntimeReport {
  const _BenchmarkRuntimeReport({
    required this.shouldRunLocalAi,
    required this.localSinglePlayer,
    required this.throttle,
    required this.turn,
    required this.totalUnitCount,
    required this.totalCityCount,
    required this.findings,
  });
  final bool shouldRunLocalAi;
  final bool localSinglePlayer;
  final AiRuntimeThrottleSnapshot throttle;
  final int turn;
  final int totalUnitCount;
  final int totalCityCount;
  final List<_Finding> findings;
  factory _BenchmarkRuntimeReport.fromSnapshot(CanonicalGameSnapshot snapshot) {
    final domain = snapshot.domain;
    final shouldRunLocalAi = shouldRunLocalAiForMode(
      gameMode: snapshot.domain.gameMode,
      saveId: snapshot.metadata.id,
      networkSession: null,
    );
    final localSinglePlayer = isLocalSinglePlayerAiRuntimeForParticipants(
      gameMode: snapshot.domain.gameMode,
      saveId: snapshot.metadata.id,
      participants: snapshot.persistedPlayers,
      networkSession: null,
    );
    final throttle = AiRuntimeThrottler().snapshotFor(
      localSinglePlayer: localSinglePlayer,
      turn: domain.turn,
      totalUnitCount: domain.units.length,
      totalCityCount: domain.cities.length,
    );
    final findings = <_Finding>[];
    final lateGameThresholdReached =
        domain.turn >= AiRuntimeThrottler.adaptiveLateGameTurnThreshold ||
        domain.units.length >=
            AiRuntimeThrottler.adaptiveLateGameUnitThreshold ||
        domain.cities.length >=
            AiRuntimeThrottler.adaptiveLateGameCityThreshold;
    if (localSinglePlayer &&
        lateGameThresholdReached &&
        throttle.mctsRuntimeProfile != MctsRuntimeProfile.batterySaver) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message:
              'Local single-player late-game runtime should use batterySaver MCTS.',
        ),
      );
    }
    return _BenchmarkRuntimeReport(
      shouldRunLocalAi: shouldRunLocalAi,
      localSinglePlayer: localSinglePlayer,
      throttle: throttle,
      turn: domain.turn,
      totalUnitCount: domain.units.length,
      totalCityCount: domain.cities.length,
      findings: findings,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'shouldRunLocalAi': shouldRunLocalAi,
      'localSinglePlayer': localSinglePlayer,
      'turn': turn,
      'totalUnitCount': totalUnitCount,
      'totalCityCount': totalCityCount,
      'pressureLevel': throttle.pressureLevel,
      'precomputeDebounceMs':
          throttle.precomputeDebounceDuration.inMilliseconds,
      'precomputeMinimumStartIntervalMs':
          throttle.precomputeMinimumStartInterval.inMilliseconds,
      'mctsRuntimeProfile': throttle.mctsRuntimeProfile.name,
      'adaptiveLateGame': throttle.adaptiveLateGame,
      'thresholds': {
        'turn': AiRuntimeThrottler.adaptiveLateGameTurnThreshold,
        'units': AiRuntimeThrottler.adaptiveLateGameUnitThreshold,
        'cities': AiRuntimeThrottler.adaptiveLateGameCityThreshold,
      },
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}
