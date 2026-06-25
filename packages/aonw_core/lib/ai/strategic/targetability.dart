import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/strategic/rival_snapshot.dart';

class TargetabilityScore {
  final String playerId;
  final RivalSnapshot rival;
  final double score;
  final double territoryValue;
  final double relativeMilitary;
  final double distanceFactor;
  final bool priorityTarget;

  const TargetabilityScore({
    required this.playerId,
    required this.rival,
    required this.score,
    required this.territoryValue,
    required this.relativeMilitary,
    required this.distanceFactor,
    this.priorityTarget = false,
  });

  @override
  bool operator ==(Object other) {
    return other is TargetabilityScore &&
        other.playerId == playerId &&
        other.rival == rival &&
        other.score == score &&
        other.territoryValue == territoryValue &&
        other.relativeMilitary == relativeMilitary &&
        other.distanceFactor == distanceFactor &&
        other.priorityTarget == priorityTarget;
  }

  @override
  int get hashCode {
    return Object.hash(
      playerId,
      rival,
      score,
      territoryValue,
      relativeMilitary,
      distanceFactor,
      priorityTarget,
    );
  }
}

class TargetabilityScorer {
  const TargetabilityScorer();

  List<TargetabilityScore> rank({
    required AiEmpireAssessment assessment,
    required Iterable<RivalSnapshot> rivals,
    required AiContext context,
    Iterable<String> priorityTargetPlayerIds = const [],
  }) {
    final priorityTargets = priorityTargetPlayerIds.toSet();
    final scores = [
      for (final rival in rivals)
        TargetabilityScore(
          playerId: rival.playerId,
          rival: rival,
          score: _score(
            assessment: assessment,
            rival: rival,
            context: context,
            priorityTarget: priorityTargets.contains(rival.playerId),
          ),
          territoryValue: _territoryValue(rival),
          relativeMilitary: _relativeMilitary(
            assessment: assessment,
            rival: rival,
          ),
          distanceFactor: _distanceFactor(rival.nearestDistance),
          priorityTarget: priorityTargets.contains(rival.playerId),
        ),
    ]..sort(_compareScores);
    return List.unmodifiable(scores);
  }

  double _score({
    required AiEmpireAssessment assessment,
    required RivalSnapshot rival,
    required AiContext context,
    required bool priorityTarget,
  }) {
    final aggression =
        context.civProfile.belligerence * context.effectiveWeights.aggression;
    final hostility = rival.isHostile ? 1.2 : 1.0;
    final priority = priorityTarget ? 1.65 : 1.0;
    return _territoryValue(rival) *
        _distanceFactor(rival.nearestDistance) *
        aggression *
        hostility /
        _relativeMilitary(assessment: assessment, rival: rival) *
        priority;
  }

  double _territoryValue(RivalSnapshot rival) {
    return 1.0 +
        rival.rememberedCityCount * 1.35 +
        rival.visibleUnitCount * 0.2;
  }

  double _relativeMilitary({
    required AiEmpireAssessment assessment,
    required RivalSnapshot rival,
  }) {
    final ownMilitary = math.max(0.75, assessment.militaryCount.toDouble());
    final rivalMilitary = math.max(
      0.75,
      rival.visibleMilitaryCount + rival.militaryPower / 8.0,
    );
    return rivalMilitary / ownMilitary;
  }

  double _distanceFactor(int nearestDistance) {
    return switch (nearestDistance) {
      <= 2 => 1.25,
      <= 4 => 1.0,
      <= 7 => 0.75,
      <= 10 => 0.55,
      _ => 0.35,
    };
  }

  int _compareScores(TargetabilityScore a, TargetabilityScore b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    final priorityCompare = (b.priorityTarget ? 1 : 0).compareTo(
      a.priorityTarget ? 1 : 0,
    );
    if (priorityCompare != 0) return priorityCompare;
    return a.playerId.compareTo(b.playerId);
  }
}
