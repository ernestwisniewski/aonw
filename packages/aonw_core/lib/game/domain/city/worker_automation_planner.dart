import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/city_yield_calculator.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/city/worker_assignment_rules.dart';
import 'package:aonw_core/game/domain/city/worker_automation_target.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_recommendation.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_scoring.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Finds the nearest legal worker task without mutating canonical state.
final class WorkerAutomationPlanner {
  const WorkerAutomationPlanner();

  WorkerAutomationTarget? targetFor({
    required GameUnit unit,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required MapTileLookup mapTiles,
    required UnitMovementPathfinder pathfinder,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (!unit.isWorker) return null;
    final costs = pathfinder.movementCostsFrom(unit: unit);
    final reservedHexes = _reservedHexes(unit: unit, units: units);
    final ownCities = cities
        .where((city) => city.ownerPlayerId == unit.ownerPlayerId)
        .toList(growable: false);

    if (unit.workerBuildCharges > 0) {
      final build = _bestBuildTarget(
        unit: unit,
        cities: ownCities,
        allCities: cities,
        fieldImprovements: fieldImprovements,
        research: research,
        mapTiles: mapTiles,
        costs: costs,
        reservedHexes: reservedHexes,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      );
      if (build != null) return build;
    }
    return _bestAssignmentTarget(
      unit: unit,
      units: units,
      cities: ownCities,
      allCities: cities,
      fieldImprovements: fieldImprovements,
      mapTiles: mapTiles,
      costs: costs,
      reservedHexes: reservedHexes,
      cityRuleset: cityRuleset,
    );
  }

  WorkerAutomationBuildTarget? _bestBuildTarget({
    required GameUnit unit,
    required List<GameCity> cities,
    required List<GameCity> allCities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required MapTileLookup mapTiles,
    required Map<({int col, int row}), int> costs,
    required Set<CityHex> reservedHexes,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    WorkerAutomationBuildTarget? best;
    for (final city in cities) {
      for (final hex in city.controlledHexes) {
        final candidate = _buildCandidate(
          unit: unit,
          city: city,
          hex: hex,
          cities: allCities,
          fieldImprovements: fieldImprovements,
          research: research,
          mapTiles: mapTiles,
          costs: costs,
          reservedHexes: reservedHexes,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          paceBalance: paceBalance,
        );
        if (candidate != null &&
            (best == null || _compareBuild(candidate, best) < 0)) {
          best = candidate;
        }
      }
    }
    return best;
  }

  WorkerAutomationAssignmentTarget? _bestAssignmentTarget({
    required GameUnit unit,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<GameCity> allCities,
    required List<FieldImprovement> fieldImprovements,
    required MapTileLookup mapTiles,
    required Map<({int col, int row}), int> costs,
    required Set<CityHex> reservedHexes,
    required CityRuleset cityRuleset,
  }) {
    WorkerAutomationAssignmentTarget? best;
    for (final city in cities) {
      if (!_hasAssignmentCapacity(city, unit, units, fieldImprovements)) {
        continue;
      }
      for (final improvement in fieldImprovements) {
        final candidate = _assignmentCandidate(
          unit: unit,
          city: city,
          improvement: improvement,
          cities: allCities,
          fieldImprovements: fieldImprovements,
          units: units,
          mapTiles: mapTiles,
          costs: costs,
          reservedHexes: reservedHexes,
          cityRuleset: cityRuleset,
        );
        if (candidate != null &&
            (best == null || _compareAssignment(candidate, best) < 0)) {
          best = candidate;
        }
      }
    }
    return best;
  }
}

WorkerAutomationBuildTarget? _buildCandidate({
  required GameUnit unit,
  required GameCity city,
  required CityHex hex,
  required List<GameCity> cities,
  required List<FieldImprovement> fieldImprovements,
  required ResearchState research,
  required MapTileLookup mapTiles,
  required Map<({int col, int row}), int> costs,
  required Set<CityHex> reservedHexes,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required PaceBalance paceBalance,
}) {
  if (reservedHexes.contains(hex)) return null;
  final movementCost = _movementCost(unit, hex, costs);
  if (movementCost == null) return null;
  final recommendation = WorkerImprovementRecommendation.bestForHex(
    unit: unit,
    targetHex: hex,
    cities: cities,
    fieldImprovements: fieldImprovements,
    mapTiles: mapTiles,
    research: research,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
  );
  if (recommendation == null) return null;
  return WorkerAutomationBuildTarget(
    cityId: city.id,
    hex: hex,
    movementCost: movementCost,
    improvementType: recommendation.type,
    recommendationScore: recommendation.score,
    buildTurns: FieldImprovementRules.buildTurnsFor(
      recommendation.type,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
    ),
  );
}

WorkerAutomationAssignmentTarget? _assignmentCandidate({
  required GameUnit unit,
  required GameCity city,
  required FieldImprovement improvement,
  required List<GameCity> cities,
  required List<FieldImprovement> fieldImprovements,
  required List<GameUnit> units,
  required MapTileLookup mapTiles,
  required Map<({int col, int row}), int> costs,
  required Set<CityHex> reservedHexes,
  required CityRuleset cityRuleset,
}) {
  final hex = improvement.hex;
  if (!city.controlledHexes.contains(hex) || reservedHexes.contains(hex)) {
    return null;
  }
  final movementCost = _movementCost(unit, hex, costs);
  if (movementCost == null) return null;
  final legality = WorkerAssignmentRules.evaluate(
    unit: unit,
    targetHex: hex,
    cities: cities,
    fieldImprovements: fieldImprovements,
    units: units,
    mapTiles: mapTiles,
    requireReadyWorker: false,
  );
  if (!legality.allowed) return null;
  final tileYield = CityTileYieldRules.forCityHex(
    city: city,
    hex: hex,
    tile: mapTiles.tileAt(hex.col, hex.row),
    fieldImprovements: fieldImprovements,
    ruleset: cityRuleset,
  );
  final workerYield =
      (city.workedHexes.contains(hex) ? TileYield.zero : tileYield) +
      CityYieldCalculator.workerAssignmentBonusFor(tileYield);
  return WorkerAutomationAssignmentTarget(
    cityId: city.id,
    hex: hex,
    movementCost: movementCost,
    yieldScore: WorkerImprovementScoring.scoreTileYield(workerYield),
  );
}

bool _hasAssignmentCapacity(
  GameCity city,
  GameUnit unit,
  List<GameUnit> units,
  List<FieldImprovement> fieldImprovements,
) {
  final assigned = _assignedWorkers(city, units, excludingUnitId: unit.id);
  final reserved = _reservedAssignmentSlots(
    city: city,
    unit: unit,
    units: units,
    fieldImprovements: fieldImprovements,
  );
  return assigned + reserved <
      WorkerAssignmentRules.maxAssignmentsForCity(city);
}

int? _movementCost(
  GameUnit unit,
  CityHex hex,
  Map<({int col, int row}), int> costs,
) {
  if (unit.occupies(hex.col, hex.row)) return 0;
  return costs[(col: hex.col, row: hex.row)];
}

Set<CityHex> _reservedHexes({
  required GameUnit unit,
  required Iterable<GameUnit> units,
}) {
  final result = <CityHex>{};
  for (final other in units) {
    if (other.id == unit.id || other.ownerPlayerId != unit.ownerPlayerId) {
      continue;
    }
    if (other.workerJob case final job?) result.add(job.targetHex);
    if (other.workerAssignment case final assignment?) {
      result.add(assignment.targetHex);
    }
    if (other.isAutoWorking) {
      final path = other.queuedPath;
      if (path != null) {
        result.add(CityHex(col: path.targetCol, row: path.targetRow));
      }
    }
  }
  return result;
}

int _reservedAssignmentSlots({
  required GameCity city,
  required GameUnit unit,
  required Iterable<GameUnit> units,
  required Iterable<FieldImprovement> fieldImprovements,
}) {
  var count = 0;
  for (final other in units) {
    if (other.id == unit.id ||
        other.ownerPlayerId != unit.ownerPlayerId ||
        !other.isAutoWorking) {
      continue;
    }
    final path = other.queuedPath;
    if (path == null) continue;
    final hex = CityHex(col: path.targetCol, row: path.targetRow);
    if (!city.controlledHexes.contains(hex)) continue;
    if (fieldImprovements.any((item) => item.hex == hex)) count++;
  }
  return count;
}

int _assignedWorkers(
  GameCity city,
  Iterable<GameUnit> units, {
  required String excludingUnitId,
}) {
  var count = 0;
  for (final unit in units) {
    if (unit.id == excludingUnitId ||
        unit.ownerPlayerId != city.ownerPlayerId) {
      continue;
    }
    final assignment = unit.workerAssignment;
    if (assignment != null &&
        city.controlledHexes.contains(assignment.targetHex)) {
      count++;
    }
  }
  return count;
}

int _compareBuild(
  WorkerAutomationBuildTarget first,
  WorkerAutomationBuildTarget second,
) {
  final movement = first.movementCost.compareTo(second.movementCost);
  if (movement != 0) return movement;
  final score = second.recommendationScore.compareTo(first.recommendationScore);
  if (score != 0) return score;
  final turns = first.buildTurns.compareTo(second.buildTurns);
  if (turns != 0) return turns;
  return _compareIdentity(
    first,
    second,
    typeName: (target) {
      return (target as WorkerAutomationBuildTarget).improvementType.name;
    },
  );
}

int _compareAssignment(
  WorkerAutomationAssignmentTarget first,
  WorkerAutomationAssignmentTarget second,
) {
  final movement = first.movementCost.compareTo(second.movementCost);
  if (movement != 0) return movement;
  final score = second.yieldScore.compareTo(first.yieldScore);
  if (score != 0) return score;
  return _compareIdentity(first, second);
}

int _compareIdentity(
  WorkerAutomationTarget first,
  WorkerAutomationTarget second, {
  String Function(WorkerAutomationTarget target)? typeName,
}) {
  final city = first.cityId.compareTo(second.cityId);
  if (city != 0) return city;
  final col = first.hex.col.compareTo(second.hex.col);
  if (col != 0) return col;
  final row = first.hex.row.compareTo(second.hex.row);
  if (row != 0) return row;
  return typeName == null ? 0 : typeName(first).compareTo(typeName(second));
}
