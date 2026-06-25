import 'dart:math' as math;

import 'package:aonw_core/game/domain/outcome/empire_score_calculator.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class ScoreRaceAnalysis {
  final String playerId;
  final EmpireScoreBreakdown player;
  final EmpireScoreBreakdown? leader;
  final EmpireScoreBreakdown? runnerUp;
  final int turn;
  final int turnLimit;
  final int remainingTurns;
  final int pressureWindowTurns;

  const ScoreRaceAnalysis({
    required this.playerId,
    required this.player,
    required this.leader,
    required this.runnerUp,
    required this.turn,
    required this.turnLimit,
    required this.remainingTurns,
    required this.pressureWindowTurns,
  });

  bool get hasContestedScoreRace => leader != null;

  bool get isLeader => leader?.playerId == playerId;

  String? get leaderPlayerId => leader?.playerId;

  EmpireScoreBreakdown? get referenceOpponent => isLeader ? runnerUp : leader;

  int get referenceScore => referenceOpponent?.total ?? player.total;

  int get scoreGapToLeader {
    final top = leader;
    if (top == null || top.playerId == playerId) return 0;
    return math.max(0, top.total - player.total);
  }

  int get leadOverRunnerUp {
    if (!isLeader) return 0;
    final challenger = runnerUp;
    if (challenger == null) return 0;
    return math.max(0, player.total - challenger.total);
  }

  double get urgency {
    if (pressureWindowTurns <= 0) return 0.0;
    if (remainingTurns >= pressureWindowTurns) return 0.0;
    return (1.0 - remainingTurns / pressureWindowTurns)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double get normalizedGapToLeader {
    final top = leader;
    if (top == null || top.playerId == playerId) return 0.0;
    final denominator = math.max(1, top.total);
    return (scoreGapToLeader / denominator).clamp(0.0, 1.0).toDouble();
  }

  double get leaderPressure {
    if (leader == null || isLeader) return 0.0;
    final gapPressure = normalizedGapToLeader;
    final timePressure = urgency;
    return (gapPressure * 0.65 + timePressure * 0.35)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  bool get shouldPressureLeader {
    if (leader == null || isLeader) return false;
    if (scoreGapToLeader >= EmpireScoreCalculator.cityWeight) return true;
    return leaderPressure >= 0.18;
  }

  Set<String> pressureTargetPlayerIds() {
    final target = leaderPlayerId;
    if (target == null || target == playerId || !shouldPressureLeader) {
      return const {};
    }
    return {target};
  }
}

class ScoreRaceAnalyzer {
  final EmpireScoreCalculator scoreCalculator;

  const ScoreRaceAnalyzer({
    this.scoreCalculator = const EmpireScoreCalculator(),
  });

  ScoreRaceAnalysis? analyzeForPlayer({
    required String playerId,
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required int turn,
    required int? turnLimit,
    required bool scoreFallbackEnabled,
    MapData? mapData,
  }) {
    if (!scoreFallbackEnabled || turnLimit == null || turnLimit <= 0) {
      return null;
    }

    final breakdownByPlayerId = _breakdownByPlayerId(
      playerIds: playerIds,
      state: state,
      mapData: mapData,
    );
    final player = breakdownByPlayerId[playerId];
    if (player == null) return null;

    final sorted = breakdownByPlayerId.values.toList()
      ..sort(_compareBreakdowns);
    if (sorted.length <= 1) return null;

    final leader = sorted.first;
    final runnerUp = sorted.skip(1).firstOrNull;
    final remainingTurns = (turnLimit - turn).clamp(0, turnLimit).toInt();

    return ScoreRaceAnalysis(
      playerId: playerId,
      player: player,
      leader: leader,
      runnerUp: runnerUp,
      turn: turn,
      turnLimit: turnLimit,
      remainingTurns: remainingTurns,
      pressureWindowTurns: _pressureWindowTurns(turnLimit),
    );
  }

  Set<String> pressureTargetPlayerIds({
    required String playerId,
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required int turn,
    required int? turnLimit,
    required bool scoreFallbackEnabled,
    MapData? mapData,
  }) {
    return analyzeForPlayer(
          playerId: playerId,
          playerIds: playerIds,
          state: state,
          turn: turn,
          turnLimit: turnLimit,
          scoreFallbackEnabled: scoreFallbackEnabled,
          mapData: mapData,
        )?.pressureTargetPlayerIds() ??
        const {};
  }

  Map<String, EmpireScoreBreakdown> _breakdownByPlayerId({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required MapData? mapData,
  }) {
    return {
      for (final playerId in _cleanPlayerIds(playerIds))
        playerId: scoreCalculator.scoreFor(
          playerId: playerId,
          state: state,
          mapObjectives: mapData?.objectives ?? const [],
        ),
    };
  }

  List<String> _cleanPlayerIds(Iterable<String> playerIds) {
    final ids = {
      for (final id in playerIds)
        if (id.isNotEmpty) id,
    }.toList()..sort();
    return ids;
  }

  int _compareBreakdowns(
    EmpireScoreBreakdown left,
    EmpireScoreBreakdown right,
  ) {
    final scoreCompare = right.total.compareTo(left.total);
    if (scoreCompare != 0) return scoreCompare;
    return left.playerId.compareTo(right.playerId);
  }

  int _pressureWindowTurns(int turnLimit) {
    return math.max(5, (turnLimit * 0.15).ceil());
  }
}
