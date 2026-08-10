part of 'city_site_planner.dart';

extension _CitySiteCandidateRanking on CitySitePlanner {
  List<CitySiteCandidate> _greedyRanking(
    List<CitySiteCandidate> raw, {
    required int maxCandidates,
    required AiContext context,
  }) {
    final selected = <CitySiteCandidate>[];
    final remaining = [...raw];

    while (remaining.isNotEmpty && selected.length < maxCandidates) {
      CitySiteCandidate? best;
      var bestIndex = -1;
      for (var i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        final penalty = _overlapPenalty(candidate, selected, context);
        if (penalty.isInfinite) continue;
        final adjusted = candidate.copyWith(
          score: candidate.baseScore + candidate.futureYieldScore - penalty,
          overlapPenalty: penalty,
        );
        if (best == null || _compareCandidates(adjusted, best) < 0) {
          best = adjusted;
          bestIndex = i;
        }
      }
      if (best == null || bestIndex < 0) break;
      selected.add(best);
      remaining.removeAt(bestIndex);
    }

    selected.sort(_compareCandidates);
    return selected;
  }

  double _overlapPenalty(
    CitySiteCandidate candidate,
    List<CitySiteCandidate> selected,
    AiContext context,
  ) {
    var penalty = 0.0;
    final candidateTerritory = candidate.projectedTerritory.toSet();
    final expansionDistance = context.civProfile.expansionDistance;
    final preferredDistance = (4.0 * expansionDistance).clamp(3.0, 7.0);

    for (final selectedCandidate in selected) {
      final selectedTerritory = selectedCandidate.projectedTerritory.toSet();
      final overlap = candidateTerritory.intersection(selectedTerritory).length;
      penalty += overlap * 2.2 * expansionDistance;

      final distance = HexDistance.between(
        HexCoordinate(col: candidate.center.col, row: candidate.center.row),
        HexCoordinate(
          col: selectedCandidate.center.col,
          row: selectedCandidate.center.row,
        ),
      );
      if (distance < preferredDistance) {
        penalty += (preferredDistance - distance) * 3.0 * expansionDistance;
      }
      if (distance < CityFoundingRules.minimumCenterDistance) {
        return double.infinity;
      }
    }
    return penalty;
  }

  List<CityHex> _sortedHexes(Iterable<CityHex> hexes) {
    final sorted = [...hexes]
      ..sort((a, b) {
        final col = a.col.compareTo(b.col);
        if (col != 0) return col;
        return a.row.compareTo(b.row);
      });
    return sorted;
  }

  int _compareCandidates(CitySiteCandidate a, CitySiteCandidate b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final distance = a.nearestFounderDistance.compareTo(
      b.nearestFounderDistance,
    );
    if (distance != 0) return distance;
    final col = a.center.col.compareTo(b.center.col);
    if (col != 0) return col;
    return a.center.row.compareTo(b.center.row);
  }
}
