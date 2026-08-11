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
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'city_site_candidate_generation.dart';
part 'city_site_candidate_ranking.dart';

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
      costResolver: view.traversalCostResolver,
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
}

int _visibleResourceCount(
  MapTileView tile,
  Set<ResourceType> visibleResourceTypes,
) {
  return tile.resources.where(visibleResourceTypes.contains).length;
}
