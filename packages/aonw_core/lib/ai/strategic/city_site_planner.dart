import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_site_scorer.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/city_site_candidate.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class CitySitePlan {
  final List<CitySiteCandidate> candidates;
  final Map<String, CityHex> settlerAssignments;

  CitySitePlan({
    required Iterable<CitySiteCandidate> candidates,
    required Map<String, CityHex> settlerAssignments,
  }) : candidates = List.unmodifiable(candidates),
       settlerAssignments = Map.unmodifiable(settlerAssignments);

  static final empty = CitySitePlan(
    candidates: const [],
    settlerAssignments: const {},
  );
}

class CitySitePlanner {
  static const int defaultMaxCandidates = 10;

  const CitySitePlanner({
    this.siteScorer = const AiCitySiteScorer(),
    this.useStrategicMapKnowledge = true,
  });

  final AiCitySiteScorer siteScorer;
  final bool useStrategicMapKnowledge;

  CitySitePlan compute({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    int maxCandidates = defaultMaxCandidates,
  }) {
    final founders = _founders(view);
    if (founders.isEmpty || maxCandidates <= 0) return CitySitePlan.empty;

    final knownCities = _knownCities(view);
    final reserved = _reservedHexes(knownCities);
    final raw = _rawCandidates(
      view: view,
      context: context,
      assessment: assessment,
      founders: founders,
      knownCities: knownCities,
      reservedHexes: reserved,
    );
    if (raw.isEmpty) return CitySitePlan.empty;

    final ranking = _greedyRanking(
      raw,
      maxCandidates: maxCandidates,
      context: context,
    );
    return CitySitePlan(
      candidates: ranking,
      settlerAssignments: _assignSettlers(
        founders: founders,
        candidates: ranking,
        view: view,
        context: context,
      ),
    );
  }

  List<CitySiteCandidate> _rawCandidates({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<GameUnit> founders,
    required List<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
  }) {
    final candidates = <CitySiteCandidate>[];
    for (final tile in view.mapData.tiles) {
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

  Map<String, CityHex> _assignSettlers({
    required List<GameUnit> founders,
    required List<CitySiteCandidate> candidates,
    required GameView view,
    required AiContext context,
  }) {
    if (candidates.isEmpty) return const {};

    final pathfinder = UnitMovementPathfinder(
      mapData: view.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: useStrategicMapKnowledge || view.ownCities.length >= 2
          ? null
          : (tile) => view.visibility.canSeeDynamicAt(tile.col, tile.row),
    );
    final assignments = <String, CityHex>{};
    final assignedCenters = <CityHex>{};

    for (final founder in founders) {
      ({CitySiteCandidate candidate, int distance, double utility})? best;
      for (final candidate in candidates) {
        if (assignedCenters.contains(candidate.center)) continue;
        final target = view.mapData.tileAt(
          candidate.center.col,
          candidate.center.row,
        );
        if (target == null) continue;

        final directDistance = HexDistance.between(
          HexCoordinate(col: founder.col, row: founder.row),
          HexCoordinate(col: candidate.center.col, row: candidate.center.row),
        );
        final canUseCurrentTile = founder.occupies(
          candidate.center.col,
          candidate.center.row,
        );
        final path = canUseCurrentTile
            ? null
            : pathfinder.plan(unit: founder, targetTile: target);
        if (!canUseCurrentTile && path == null) continue;
        if (path != null &&
            !UnitMovementFeasibility.canEventuallyTraverse(
              unit: founder,
              plan: path,
            )) {
          continue;
        }
        final pathDistance = path?.totalCost ?? directDistance;
        final travelPenalty =
            pathDistance * 0.85 / context.civProfile.expansionDistance;
        final utility = candidate.score - travelPenalty;

        if (best == null ||
            utility > best.utility ||
            (utility == best.utility && pathDistance < best.distance) ||
            (utility == best.utility &&
                pathDistance == best.distance &&
                _compareCandidates(candidate, best.candidate) < 0)) {
          best = (
            candidate: candidate,
            distance: pathDistance,
            utility: utility,
          );
        }
      }
      final chosen = best?.candidate;
      if (chosen == null) continue;
      assignments[founder.id] = chosen.center;
      assignedCenters.add(chosen.center);
    }

    return assignments;
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

    var projectedCity = GameCity(
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
            mapData: view.mapData,
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

  int _projectedMaxHexes(GameView view, AiContext context) {
    var projected = GameCity.defaultStartMaxHexes;
    final techPath =
        context.strategicPlan?.techPath ?? view.availableTechnologyIds;
    for (var i = 0; i < techPath.length; i++) {
      final technologyId = techPath[i];
      final technology = view.ruleset.technology.technologies[technologyId];
      if (technology == null) continue;
      for (final effect in technology.effects) {
        if (effect is MaxControlledHexesBonus) {
          final weight = switch (i) {
            0 => 0.5,
            1 => 0.25,
            _ => 0.125,
          };
          projected += (effect.amount * weight).round();
        }
      }
    }
    return projected
        .clamp(
          GameCity.defaultStartMaxHexes,
          CityProgressionCatalog.lateGameMaxHexes,
        )
        .toInt();
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

  List<GameUnit> _founders(GameView view) {
    final founders = [
      for (final unit in view.ownUnits)
        if (CityFoundingRules.canFoundCityWith(unit) &&
            unit.queuedPath == null &&
            !unit.isWorking)
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return founders;
  }

  GameUnit? _nearestFounder(List<GameUnit> founders, CityHex center) {
    GameUnit? best;
    var bestDistance = 1 << 30;
    for (final founder in founders) {
      final distance = HexDistance.between(
        HexCoordinate(col: founder.col, row: founder.row),
        HexCoordinate(col: center.col, row: center.row),
      );
      if (distance < bestDistance ||
          (distance == bestDistance &&
              (best == null || founder.id.compareTo(best.id) < 0))) {
        best = founder;
        bestDistance = distance;
      }
    }
    return best;
  }

  List<GameCity> _knownCities(GameView view) {
    return [...view.ownCities, ...view.rememberedEnemyCities];
  }

  Set<CityHex> _reservedHexes(Iterable<GameCity> cities) {
    return {
      for (final city in cities) city.center,
      for (final city in cities) ...city.controlledHexes,
    };
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

int _visibleResourceCount(
  TileData tile,
  Set<ResourceType> visibleResourceTypes,
) {
  return tile.resources.where(visibleResourceTypes.contains).length;
}
