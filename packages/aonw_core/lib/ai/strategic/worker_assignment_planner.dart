import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

part 'worker_assignment_scoring.dart';

class WorkerAssignmentPlanner {
  static const int defaultMaxTargetsPerWorker = 4;
  static const int _distancePenalty =
      WorkerImprovementScoreBalance.productionWeight ~/ 4;
  static const int _cityCrowdingPenalty =
      WorkerImprovementScoreBalance.foodWeight ~/ 2;
  static const int _readyImprovementBonus =
      WorkerImprovementScoreBalance.productionWeight;
  static const int _buildTargetPriorityBonus =
      WorkerImprovementScoreBalance.foodWeight * 100;

  const WorkerAssignmentPlanner();

  WorkerAssignmentPlan compute({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required StrategicMode mode,
    int maxTargetsPerWorker = defaultMaxTargetsPerWorker,
  }) {
    if (view.ownCities.isEmpty || maxTargetsPerWorker <= 0) {
      return WorkerAssignmentPlan.empty;
    }

    final workers = _eligibleWorkers(view);
    if (workers.isEmpty) return WorkerAssignmentPlan.empty;

    final targetsByCityId = <String, List<StrategicWorkerTarget>>{};
    for (final city in view.ownCities) {
      final targets = _targetsForCity(
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        mode: mode,
        probeWorker: workers.first,
      );
      if (targets.isNotEmpty) targetsByCityId[city.id] = targets;
    }
    if (targetsByCityId.isEmpty) return WorkerAssignmentPlan.empty;

    final assignments = <String, StrategicWorkerAssignment>{};
    final reservedTargets = <CityHex>{};
    final plannedByCityId = <String, int>{};
    final targetRanker = _WorkerTargetRanker(
      view: view,
      plannedByCityId: plannedByCityId,
    );

    for (final worker in workers) {
      final best = targetRanker.bestTargetForWorker(
        worker: worker,
        targetsByCityId: targetsByCityId,
        reservedTargets: reservedTargets,
      );
      if (best == null) continue;

      final cityTargets =
          [
            for (final target in targetsByCityId[best.cityId]!)
              if (!reservedTargets.contains(target.targetHex) ||
                  target.targetHex == best.targetHex)
                target,
          ]..sort(
            (a, b) =>
                targetRanker.compareWorkerTargets(worker: worker, a: a, b: b),
          );
      assignments[worker.id] = StrategicWorkerAssignment(
        workerId: worker.id,
        cityId: best.cityId,
        targets: cityTargets.take(maxTargetsPerWorker),
      );
      reservedTargets.add(best.targetHex);
      plannedByCityId[best.cityId] = (plannedByCityId[best.cityId] ?? 0) + 1;
    }

    return WorkerAssignmentPlan(assignments: assignments);
  }

  List<GameUnit> _eligibleWorkers(GameView view) {
    return [
      for (final unit in view.ownUnits)
        if (unit.isWorker &&
            !unit.isWorking &&
            unit.workerAssignment == null &&
            unit.movementPoints > 0 &&
            unit.queuedPath == null)
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  List<StrategicWorkerTarget> _targetsForCity({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required StrategicMode mode,
    required GameUnit probeWorker,
  }) {
    final targets = <StrategicWorkerTarget>[];
    final research = ResearchState(
      players: {view.forPlayerId: view.ownResearch},
    );
    final workedHexes = CityWorkedHexSelector.effectiveWorkedHexes(
      city: city,
      mapData: view.mapData,
      fieldImprovements: view.ownImprovements,
      ruleset: view.ruleset.city,
    ).toSet();
    final assignmentSlots =
        WorkerAssignmentRules.maxAssignmentsForCity(city) -
        _assignedWorkerCountForCity(city, view.ownUnits);
    var plannedAssignments = 0;
    final hexes = [...city.controlledHexes]..sort(_compareHexes);

    for (final hex in hexes) {
      if (hex == city.center) continue;
      final tile = view.mapData.tileAt(hex.col, hex.row);
      if (tile == null || !view.visibility.canInspectTile(tile)) continue;

      final existingImprovement = _improvementAt(hex, view.ownImprovements);
      if (existingImprovement != null) {
        if (plannedAssignments >= assignmentSlots ||
            _hasAssignedWorkerAt(hex, view.ownUnits)) {
          continue;
        }
        plannedAssignments += 1;
        targets.add(
          StrategicWorkerTarget(
            cityId: city.id,
            targetHex: hex,
            improvementType: existingImprovement.type,
            score: _existingImprovementScore(
              city: city,
              hex: hex,
              tile: tile,
              fieldImprovements: view.ownImprovements,
              workedHexes: workedHexes,
              context: context,
              assessment: assessment,
              mode: mode,
            ),
            buildTurns: 0,
            existingImprovement: true,
          ),
        );
        continue;
      }

      final buildTarget = _bestBuildTargetForHex(
        city: city,
        hex: hex,
        tile: tile,
        view: view,
        context: context,
        assessment: assessment,
        mode: mode,
        research: research,
        probeWorker: probeWorker,
      );
      if (buildTarget != null) targets.add(buildTarget);
    }

    targets.sort(_compareTargets);
    return targets;
  }

  StrategicWorkerTarget? _bestBuildTargetForHex({
    required GameCity city,
    required CityHex hex,
    required TileData tile,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required StrategicMode mode,
    required ResearchState research,
    required GameUnit probeWorker,
  }) {
    final options = <StrategicWorkerTarget>[];
    final baseYield = CityTileYieldRules.forCityHex(
      city: city,
      hex: hex,
      tile: tile,
      fieldImprovements: view.ownImprovements,
      ruleset: view.ruleset.city,
    );

    for (final type in view.ruleset.city.improvements.keys) {
      final legality = WorkerImprovementRules.evaluate(
        unit: probeWorker,
        improvementType: type,
        cities: view.ownCities,
        fieldImprovements: view.ownImprovements,
        mapData: view.mapData,
        research: research,
        targetHex: hex,
        requireReadyWorker: false,
        cityRuleset: view.ruleset.city,
        technologyRuleset: view.ruleset.technology,
      );
      if (!legality.allowed || legality.city?.id != city.id) continue;

      final delta = FieldImprovementRules.yieldFor(
        type,
        ruleset: view.ruleset.city,
      );
      final buildTurns = FieldImprovementRules.buildTurnsFor(
        type,
        ruleset: view.ruleset.city,
        paceBalance: view.ruleset.paceBalance,
      );
      options.add(
        StrategicWorkerTarget(
          cityId: city.id,
          targetHex: hex,
          improvementType: type,
          score:
              WorkerImprovementScoring.scoreForYield(
                type: type,
                baseYield: baseYield,
                ruleset: view.ruleset.city,
              ) +
              _WorkerYieldFitScorecard(
                yield: delta,
                city: city,
                context: context,
                assessment: assessment,
                mode: mode,
              ).score(),
          buildTurns: buildTurns,
          existingImprovement: false,
        ),
      );
    }

    options.sort(_compareTargets);
    return options.isEmpty ? null : options.first;
  }

  int _existingImprovementScore({
    required GameCity city,
    required CityHex hex,
    required TileData tile,
    required Iterable<FieldImprovement> fieldImprovements,
    required Set<CityHex> workedHexes,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required StrategicMode mode,
  }) {
    final fullYield = CityTileYieldRules.forCityHex(
      city: city,
      hex: hex,
      tile: tile,
      fieldImprovements: fieldImprovements,
      ruleset: context.ruleset.city,
    );
    final workerBonus = CityYieldCalculator.workerAssignmentBonusFor(fullYield);
    final workerYield = workedHexes.contains(hex)
        ? workerBonus
        : fullYield + workerBonus;

    return WorkerImprovementScoring.scoreTileYield(workerYield) +
        _WorkerYieldFitScorecard(
          yield: workerYield,
          city: city,
          context: context,
          assessment: assessment,
          mode: mode,
        ).score() +
        _readyImprovementBonus;
  }

  static int _compareTargets(StrategicWorkerTarget a, StrategicWorkerTarget b) {
    if (a.existingImprovement != b.existingImprovement) {
      return a.existingImprovement ? 1 : -1;
    }
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final buildTurns = a.buildTurns.compareTo(b.buildTurns);
    if (buildTurns != 0) return buildTurns;
    final hex = _compareHexes(a.targetHex, b.targetHex);
    if (hex != 0) return hex;
    return a.improvementType.name.compareTo(b.improvementType.name);
  }

  static int _distanceFromWorker(GameUnit worker, CityHex hex) {
    return HexDistance.between(
      HexCoordinate(col: worker.col, row: worker.row),
      hex.toCoordinate(),
    );
  }

  static int _assignedWorkerCountForCity(
    GameCity city,
    Iterable<GameUnit> units,
  ) {
    var count = 0;
    for (final unit in units) {
      if (unit.ownerPlayerId != city.ownerPlayerId) continue;
      final assignment = unit.workerAssignment;
      if (assignment == null) continue;
      if (assignment.targetHex == city.center) continue;
      if (city.controlsHex(assignment.targetHex)) count++;
    }
    return count;
  }

  static bool _hasAssignedWorkerAt(CityHex hex, Iterable<GameUnit> units) {
    for (final unit in units) {
      if (unit.workerAssignment?.targetHex == hex) return true;
    }
    return false;
  }

  static FieldImprovement? _improvementAt(
    CityHex hex,
    Iterable<FieldImprovement> improvements,
  ) {
    for (final improvement in improvements) {
      if (improvement.hex == hex) return improvement;
    }
    return null;
  }

  static int _compareHexes(CityHex a, CityHex b) {
    final col = a.col.compareTo(b.col);
    if (col != 0) return col;
    return a.row.compareTo(b.row);
  }
}
