import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/outcome/empire_score_calculator.dart';

class ScorePressureAdvisor {
  const ScorePressureAdvisor();

  GameObjectiveAdvice adviceFor({
    required String playerId,
    required Map<String, EmpireScoreBreakdown> breakdownByPlayerId,
  }) {
    final active = breakdownByPlayerId[playerId];
    if (active == null || breakdownByPlayerId.isEmpty) {
      return GameObjectiveAdvice.protectLead;
    }

    final leader = _leaderFor(
      playerId: playerId,
      breakdownByPlayerId: breakdownByPlayerId,
    );
    if (leader == null) return GameObjectiveAdvice.protectLead;

    final bestGap = _gaps(active: active, leader: leader)
      ..sort((a, b) {
        final gapComparison = b.scoreGap.compareTo(a.scoreGap);
        if (gapComparison != 0) return gapComparison;
        return a.priority.compareTo(b.priority);
      });
    final actionable = bestGap.where((candidate) => candidate.scoreGap > 0);
    return actionable.firstOrNull?.advice ?? GameObjectiveAdvice.trainUnit;
  }

  EmpireScoreBreakdown? _leaderFor({
    required String playerId,
    required Map<String, EmpireScoreBreakdown> breakdownByPlayerId,
  }) {
    final active = breakdownByPlayerId[playerId];
    if (active == null) return null;

    final sorted = breakdownByPlayerId.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final top = sorted.firstOrNull;
    if (top == null) return null;
    if (top.playerId != playerId || _topTieCount(sorted, top.total) > 1) {
      return top.playerId == playerId
          ? sorted.firstWhere(
              (breakdown) => breakdown.playerId != playerId,
              orElse: () => top,
            )
          : top;
    }
    return null;
  }

  int _topTieCount(List<EmpireScoreBreakdown> sorted, int topScore) {
    var count = 0;
    for (final breakdown in sorted) {
      if (breakdown.total == topScore) count++;
    }
    return count;
  }

  List<_ScoreAdviceCandidate> _gaps({
    required EmpireScoreBreakdown active,
    required EmpireScoreBreakdown leader,
  }) {
    return [
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.trainUnit,
        scoreGap: leader.unitScore - active.unitScore,
        priority: 0,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.constructBuilding,
        scoreGap: leader.buildingScore - active.buildingScore,
        priority: 1,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.improveField,
        scoreGap: leader.improvementScore - active.improvementScore,
        priority: 2,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.unlockTechnology,
        scoreGap: leader.technologyScore - active.technologyScore,
        priority: 3,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.growPopulation,
        scoreGap: leader.populationScore - active.populationScore,
        priority: 4,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.foundCity,
        scoreGap: leader.cityScore - active.cityScore,
        priority: 5,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.claimTerritory,
        scoreGap: leader.territoryScore - active.territoryScore,
        priority: 6,
      ),
      _ScoreAdviceCandidate(
        advice: GameObjectiveAdvice.collectGold,
        scoreGap: leader.goldScore - active.goldScore,
        priority: 7,
      ),
    ];
  }
}

class _ScoreAdviceCandidate {
  final GameObjectiveAdvice advice;
  final int scoreGap;
  final int priority;

  const _ScoreAdviceCandidate({
    required this.advice,
    required this.scoreGap,
    required this.priority,
  });
}
