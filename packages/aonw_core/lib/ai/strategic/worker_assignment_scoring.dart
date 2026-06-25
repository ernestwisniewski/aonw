part of 'worker_assignment_planner.dart';

final class _WorkerYieldFitScorecard {
  const _WorkerYieldFitScorecard({
    required this.yield,
    required this.city,
    required this.context,
    required this.assessment,
    required this.mode,
  });

  final TileYield yield;
  final GameCity city;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final StrategicMode mode;

  int score() {
    var score = _specializationScore();
    score += _smallCityGrowthScore();
    score += _goldReserveScore();
    score += _militaryNeedScore();
    score += _modeScore();
    score += _personaScore();
    return score;
  }

  int _specializationScore() {
    return switch (city.specialization) {
      CitySpecializationType.growth =>
        yield.food * (WorkerImprovementScoreBalance.foodWeight ~/ 3),
      CitySpecializationType.industry =>
        yield.production *
            (WorkerImprovementScoreBalance.productionWeight ~/ 2),
      CitySpecializationType.commerce =>
        yield.gold * WorkerImprovementScoreBalance.goldWeight,
      CitySpecializationType.science =>
        yield.food * WorkerImprovementScoreBalance.baseFoodWeight +
            yield.production *
                WorkerImprovementScoreBalance.baseProductionWeight,
      CitySpecializationType.military =>
        yield.production *
                (WorkerImprovementScoreBalance.productionWeight ~/ 2) +
            yield.defense * WorkerImprovementScoreBalance.defenseWeight,
      null => 0,
    };
  }

  int _smallCityGrowthScore() {
    return city.population <= 2
        ? yield.food * (WorkerImprovementScoreBalance.foodWeight ~/ 4)
        : 0;
  }

  int _goldReserveScore() {
    return assessment.needsGoldReserve
        ? yield.gold * WorkerImprovementScoreBalance.goldWeight
        : 0;
  }

  int _militaryNeedScore() {
    if (!assessment.needsMilitary && mode != StrategicMode.military) return 0;
    return yield.production *
            (WorkerImprovementScoreBalance.productionWeight ~/ 2) +
        yield.defense * WorkerImprovementScoreBalance.defenseWeight;
  }

  int _modeScore() {
    return switch (mode) {
      StrategicMode.expand =>
        yield.food * (WorkerImprovementScoreBalance.foodWeight ~/ 5) +
            yield.production *
                (WorkerImprovementScoreBalance.productionWeight ~/ 4),
      StrategicMode.recover =>
        yield.gold * WorkerImprovementScoreBalance.goldWeight +
            yield.production *
                (WorkerImprovementScoreBalance.productionWeight ~/ 4),
      _ => 0,
    };
  }

  int _personaScore() {
    final weights = context.effectiveWeights;
    var score = 0;
    if (weights.economy > 1.0) {
      score +=
          (yield.gold *
                  WorkerImprovementScoreBalance.goldWeight *
                  (weights.economy - 1.0))
              .round();
    }
    if (weights.expansion > 1.0) {
      score +=
          (yield.food *
                  WorkerImprovementScoreBalance.baseFoodWeight *
                  weights.expansion)
              .round();
    }
    return score;
  }
}

final class _WorkerTargetRanker {
  const _WorkerTargetRanker({
    required this.view,
    required this.plannedByCityId,
  });

  final GameView view;
  final Map<String, int> plannedByCityId;

  StrategicWorkerTarget? bestTargetForWorker({
    required GameUnit worker,
    required Map<String, List<StrategicWorkerTarget>> targetsByCityId,
    required Set<CityHex> reservedTargets,
  }) {
    StrategicWorkerTarget? best;
    final targetPool = _targetPoolForWorker(
      targetsByCityId: targetsByCityId,
      reservedTargets: reservedTargets,
    );
    for (final target in targetPool) {
      if (best == null ||
          compareWorkerTargets(worker: worker, a: target, b: best) < 0) {
        best = target;
      }
    }
    return best;
  }

  List<StrategicWorkerTarget> _targetPoolForWorker({
    required Map<String, List<StrategicWorkerTarget>> targetsByCityId,
    required Set<CityHex> reservedTargets,
  }) {
    final buildTargets = <StrategicWorkerTarget>[];
    final assignmentTargets = <StrategicWorkerTarget>[];
    for (final targets in targetsByCityId.values) {
      for (final target in targets) {
        if (reservedTargets.contains(target.targetHex)) continue;
        if (target.existingImprovement) {
          assignmentTargets.add(target);
        } else {
          buildTargets.add(target);
        }
      }
    }
    return buildTargets.isNotEmpty ? buildTargets : assignmentTargets;
  }

  int compareWorkerTargets({
    required GameUnit worker,
    required StrategicWorkerTarget a,
    required StrategicWorkerTarget b,
  }) {
    final score = adjustedTargetScore(
      worker: worker,
      target: b,
    ).compareTo(adjustedTargetScore(worker: worker, target: a));
    if (score != 0) return score;
    final distance =
        WorkerAssignmentPlanner._distanceFromWorker(
          worker,
          a.targetHex,
        ).compareTo(
          WorkerAssignmentPlanner._distanceFromWorker(worker, b.targetHex),
        );
    if (distance != 0) return distance;
    return WorkerAssignmentPlanner._compareTargets(a, b);
  }

  int adjustedTargetScore({
    required GameUnit worker,
    required StrategicWorkerTarget target,
  }) {
    final city = WorkerAssignmentPlanner._cityById(
      view.ownCities,
      target.cityId,
    );
    final currentHex = CityHex(col: worker.col, row: worker.row);
    final currentCityBonus = city != null && city.controlsHex(currentHex)
        ? WorkerAssignmentPlanner._distancePenalty * 2
        : 0;
    return target.score -
        WorkerAssignmentPlanner._distanceFromWorker(worker, target.targetHex) *
            WorkerAssignmentPlanner._distancePenalty -
        (plannedByCityId[target.cityId] ?? 0) *
            WorkerAssignmentPlanner._cityCrowdingPenalty +
        currentCityBonus +
        (target.existingImprovement
            ? 0
            : WorkerAssignmentPlanner._buildTargetPriorityBonus);
  }
}
