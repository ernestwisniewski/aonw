import 'package:aonw_core/game/domain/city.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'city_site_candidate.freezed.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class CitySiteCandidate with _$CitySiteCandidate {
  const CitySiteCandidate._();

  factory CitySiteCandidate({
    required CityHex center,
    required Iterable<CityHex> controlledHexes,
    required Iterable<CityHex> projectedTerritory,
    required double score,
    required double baseScore,
    required double futureYieldScore,
    required double overlapPenalty,
    required int nearestFounderDistance,
  }) {
    return CitySiteCandidate._internal(
      center: center,
      controlledHexes: List.unmodifiable(controlledHexes),
      projectedTerritory: List.unmodifiable(projectedTerritory),
      score: score,
      baseScore: baseScore,
      futureYieldScore: futureYieldScore,
      overlapPenalty: overlapPenalty,
      nearestFounderDistance: nearestFounderDistance,
    );
  }

  const factory CitySiteCandidate._internal({
    required CityHex center,
    required List<CityHex> controlledHexes,
    required List<CityHex> projectedTerritory,
    required double score,
    required double baseScore,
    required double futureYieldScore,
    required double overlapPenalty,
    required int nearestFounderDistance,
  }) = _CitySiteCandidate;
}
