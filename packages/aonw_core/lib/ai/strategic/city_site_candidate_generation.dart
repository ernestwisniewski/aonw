part of 'city_site_planner.dart';

extension _CitySiteCandidateGeneration on CitySitePlanner {
  List<CitySiteCandidate> _rawCandidates({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<GameUnit> founders,
    required List<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
  }) {
    final candidates = <CitySiteCandidate>[];
    for (final tile in view.mapData.tileViews) {
      if (!useStrategicMapKnowledge && !view.visibility.canInspectTile(tile)) {
        continue;
      }
      final center = CityHex(col: tile.col, row: tile.row);
      if (reservedHexes.contains(center)) continue;

      final founder = _nearestFounder(founders, center);
      if (founder == null) continue;
      final site = siteScorer.scoreSite(
        founder: founder,
        center: center,
        view: view,
        context: context,
        assessment: assessment,
        knownCities: knownCities,
        reservedHexes: reservedHexes,
        requireKnownExclusionZone: false,
        useStrategicMapKnowledge: useStrategicMapKnowledge,
      );
      if (site == null) continue;

      final projectedTerritory = _projectedTerritory(
        site: site,
        view: view,
        context: context,
        knownCities: knownCities,
      );
      final futureYieldScore = _futureYieldScore(
        site: site,
        projectedTerritory: projectedTerritory,
        view: view,
        context: context,
      );
      candidates.add(
        CitySiteCandidate(
          center: site.center,
          controlledHexes: site.controlledHexes,
          projectedTerritory: projectedTerritory,
          score: site.score + futureYieldScore,
          baseScore: site.score,
          futureYieldScore: futureYieldScore,
          overlapPenalty: 0,
          nearestFounderDistance: site.distanceFromFounder,
        ),
      );
    }

    candidates.sort(_compareCandidates);
    return candidates;
  }

  List<CityHex> _projectedTerritory({
    required AiCitySiteScore site,
    required GameView view,
    required AiContext context,
    required List<GameCity> knownCities,
  }) {
    final territory = <CityHex>{site.center, ...site.controlledHexes};
    final targetHexes = _projectedMaxHexes(view, context);
    if (territory.length >= targetHexes) {
      return _sortedHexes(territory);
    }

    var projectedCity = GameCity.snapshot(
      id: 'projected_${site.center.col}_${site.center.row}',
      ownerPlayerId: view.forPlayerId,
      name: 'Projected',
      center: site.center,
      controlledHexes: site.controlledHexes,
    );
    final cities = [...knownCities, projectedCity];

    while (territory.length < targetHexes) {
      final candidates =
          CityExpansionSelector.candidatesFor(
            city: projectedCity,
            mapTiles: view.mapData,
            cities: cities,
            ruleset: view.ruleset.city,
          ).where((candidate) {
            final tile = view.mapData.tileAt(
              candidate.hex.col,
              candidate.hex.row,
            );
            return tile != null &&
                (useStrategicMapKnowledge ||
                    view.visibility.canInspectTile(tile));
          }).toList();
      if (candidates.isEmpty) break;
      candidates.sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        final distance = a.distance.compareTo(b.distance);
        if (distance != 0) return distance;
        final col = a.hex.col.compareTo(b.hex.col);
        if (col != 0) return col;
        return a.hex.row.compareTo(b.hex.row);
      });
      final next = candidates.first.hex;
      if (!territory.add(next)) break;
      projectedCity = projectedCity.copyWith(
        controlledHexes: [...projectedCity.controlledHexes, next],
      );
      cities[cities.length - 1] = projectedCity;
    }

    return _sortedHexes(territory);
  }

  double _futureYieldScore({
    required AiCitySiteScore site,
    required List<CityHex> projectedTerritory,
    required GameView view,
    required AiContext context,
  }) {
    final initial = {site.center, ...site.controlledHexes};
    final visibleResourceTypes = ResourceVisibilityRules.visibleResourceTypes(
      playerId: view.forPlayerId,
      research: ResearchState(players: {view.forPlayerId: view.ownResearch}),
    );
    var score = 0.0;
    for (final hex in projectedTerritory) {
      if (initial.contains(hex)) continue;
      final tile = view.mapData.tileAt(hex.col, hex.row);
      if (tile == null) continue;
      final yield = CityTileYieldRules.forTile(
        tile,
        ruleset: view.ruleset.city,
      );
      score +=
          yield.food * 0.35 / context.ruleset.paceBalance.growthCostMultiplier +
          yield.production * 0.45 +
          yield.gold * 0.18 * context.effectiveWeights.economy +
          _visibleResourceCount(tile, visibleResourceTypes) * 0.5;
    }
    return score;
  }
}
