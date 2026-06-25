import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/strategic/rival_snapshot.dart';
import 'package:aonw_core/game/domain/outcome.dart';

class PlayerThreatScore {
  final String playerId;
  final RivalSnapshot rival;
  final double score;

  const PlayerThreatScore({
    required this.playerId,
    required this.rival,
    required this.score,
  });

  @override
  bool operator ==(Object other) {
    return other is PlayerThreatScore &&
        other.playerId == playerId &&
        other.rival == rival &&
        other.score == score;
  }

  @override
  int get hashCode => Object.hash(playerId, rival, score);
}

class ThreatAssessor {
  const ThreatAssessor();

  List<PlayerThreatScore> assess({
    required AiEmpireAssessment assessment,
    required Iterable<RivalSnapshot> rivals,
    ScoreRaceAnalysis? scoreRace,
  }) {
    final scores = [
      for (final rival in rivals)
        PlayerThreatScore(
          playerId: rival.playerId,
          rival: rival,
          score: _threatScore(assessment, rival, scoreRace: scoreRace),
        ),
    ]..sort(_compareScores);
    return List.unmodifiable(scores);
  }

  double _threatScore(
    AiEmpireAssessment assessment,
    RivalSnapshot rival, {
    ScoreRaceAnalysis? scoreRace,
  }) {
    final ownMilitary = assessment.militaryCount <= 0
        ? 0.75
        : assessment.militaryCount.toDouble();
    final rivalPressure =
        rival.visibleMilitaryCount + rival.militaryPower * 0.2;
    final relativeMilitary =
        rivalPressure.clamp(0.0, 12.0).toDouble() / ownMilitary;
    final proximity = switch (rival.nearestDistance) {
      <= 1 => 2.2,
      2 => 1.8,
      3 => 1.45,
      <= 5 => 1.0,
      <= 8 => 0.65,
      _ => 0.35,
    };
    final cityPresence = rival.rememberedCityCount > 0 ? 0.35 : 0.0;
    final recentHostilityPressure = rival.recentlyHostile ? 1.0 : 0.0;
    final leaderPressure = _scoreLeaderPressure(rival, scoreRace);
    final hostility = rival.isHostile
        ? 1.75
        : rival.recentlyHostile
        ? 1.35
        : 1.0;
    return (relativeMilitary * proximity +
            cityPresence +
            recentHostilityPressure +
            leaderPressure) *
        hostility;
  }

  double _scoreLeaderPressure(
    RivalSnapshot rival,
    ScoreRaceAnalysis? scoreRace,
  ) {
    if (scoreRace == null || scoreRace.isLeader) return 0.0;
    if (scoreRace.leaderPlayerId != rival.playerId) return 0.0;
    if (!scoreRace.shouldPressureLeader) return 0.0;
    return (0.35 + scoreRace.leaderPressure * 1.2 + scoreRace.urgency * 0.35)
        .clamp(0.0, 1.6)
        .toDouble();
  }

  int _compareScores(PlayerThreatScore a, PlayerThreatScore b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return a.playerId.compareTo(b.playerId);
  }
}
