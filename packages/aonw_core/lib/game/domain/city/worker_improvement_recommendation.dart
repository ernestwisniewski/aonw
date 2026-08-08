import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_rules.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_scoring.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class WorkerImprovementCandidate {
  const WorkerImprovementCandidate({required this.type, required this.score});

  final FieldImprovementType type;
  final int score;
}

/// Shared deterministic recommendation used by manual and automated work.
abstract final class WorkerImprovementRecommendation {
  static FieldImprovementType? bestTypeForScores(
    Map<FieldImprovementType, int> scores,
  ) {
    MapEntry<FieldImprovementType, int>? best;
    for (final entry in scores.entries) {
      if (best == null ||
          entry.value > best.value ||
          (entry.value == best.value && entry.key.index < best.key.index)) {
        best = entry;
      }
    }
    return best?.key;
  }

  static WorkerImprovementCandidate? bestForHex({
    required GameUnit unit,
    required CityHex targetHex,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapTileLookup mapTiles,
    required ResearchState research,
    bool requireReadyWorker = false,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    return rankedLegalOptionsForHex(
      unit: unit,
      targetHex: targetHex,
      cities: cities,
      fieldImprovements: fieldImprovements,
      mapTiles: mapTiles,
      research: research,
      requireReadyWorker: requireReadyWorker,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    ).firstOrNull;
  }

  static List<WorkerImprovementCandidate> rankedLegalOptionsForHex({
    required GameUnit unit,
    required CityHex targetHex,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapTileLookup mapTiles,
    required ResearchState research,
    bool requireReadyWorker = false,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final tile = mapTiles.tileAt(targetHex.col, targetHex.row);
    if (tile == null) return const [];
    final candidates = <WorkerImprovementCandidate>[];
    for (final type in FieldImprovementType.values) {
      final legality = WorkerImprovementRules.evaluate(
        unit: unit,
        improvementType: type,
        cities: cities,
        fieldImprovements: fieldImprovements,
        mapTiles: mapTiles,
        research: research,
        targetHex: targetHex,
        requireReadyWorker: requireReadyWorker,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
      );
      if (!legality.allowed) continue;
      candidates.add(
        WorkerImprovementCandidate(
          type: type,
          score: WorkerImprovementScoring.scoreFor(
            type: type,
            tile: tile,
            ruleset: cityRuleset,
          ),
        ),
      );
    }
    candidates.sort((first, second) {
      final scoreOrder = second.score.compareTo(first.score);
      return scoreOrder != 0
          ? scoreOrder
          : first.type.index.compareTo(second.type.index);
    });
    return List.unmodifiable(candidates);
  }
}
