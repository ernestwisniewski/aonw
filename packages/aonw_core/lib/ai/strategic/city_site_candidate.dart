import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/util/collection_equality.dart';

class CitySiteCandidate {
  final CityHex center;
  final List<CityHex> controlledHexes;
  final List<CityHex> projectedTerritory;
  final double score;
  final double baseScore;
  final double futureYieldScore;
  final double overlapPenalty;
  final int nearestFounderDistance;

  CitySiteCandidate({
    required this.center,
    required Iterable<CityHex> controlledHexes,
    required Iterable<CityHex> projectedTerritory,
    required this.score,
    required this.baseScore,
    required this.futureYieldScore,
    required this.overlapPenalty,
    required this.nearestFounderDistance,
  }) : controlledHexes = List.unmodifiable(controlledHexes),
       projectedTerritory = List.unmodifiable(projectedTerritory);

  CitySiteCandidate copyWith({double? score, double? overlapPenalty}) {
    return CitySiteCandidate(
      center: center,
      controlledHexes: controlledHexes,
      projectedTerritory: projectedTerritory,
      score: score ?? this.score,
      baseScore: baseScore,
      futureYieldScore: futureYieldScore,
      overlapPenalty: overlapPenalty ?? this.overlapPenalty,
      nearestFounderDistance: nearestFounderDistance,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CitySiteCandidate &&
        other.center == center &&
        listEquals(other.controlledHexes, controlledHexes) &&
        listEquals(other.projectedTerritory, projectedTerritory) &&
        other.score == score &&
        other.baseScore == baseScore &&
        other.futureYieldScore == futureYieldScore &&
        other.overlapPenalty == overlapPenalty &&
        other.nearestFounderDistance == nearestFounderDistance;
  }

  @override
  int get hashCode => Object.hash(
    center,
    Object.hashAll(controlledHexes),
    Object.hashAll(projectedTerritory),
    score,
    baseScore,
    futureYieldScore,
    overlapPenalty,
    nearestFounderDistance,
  );
}
