import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/city_site_planner.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/targetability.dart';
import 'package:aonw_core/ai/strategic/threat_assessor.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'war_goal_generation_context.dart';
part 'war_goal_generation_policies.dart';
part 'war_goal_generation_queries.dart';

class WarGoalGenerator {
  final TargetabilityScorer targetabilityScorer;
  final int maxGoals;

  const WarGoalGenerator({
    this.targetabilityScorer = const TargetabilityScorer(),
    this.maxGoals = 2,
  });

  List<WarGoal> generate({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<PlayerThreatScore> threats,
    required StrategicMode mode,
    Iterable<String> reservedUnitIds = const [],
    CitySitePlan? citySitePlan,
  }) {
    final request = _WarGoalGenerationRequest(
      view: view,
      context: context,
      assessment: assessment,
      threats: threats,
      mode: mode,
      maxGoals: maxGoals,
      reservedUnitIds: reservedUnitIds.toSet(),
      citySitePlan: citySitePlan,
      targetabilityScorer: targetabilityScorer,
    );
    return const _WarGoalGenerationPipeline().generate(request);
  }
}

final class _WarGoalGenerationPipeline {
  const _WarGoalGenerationPipeline();

  List<WarGoal> generate(_WarGoalGenerationRequest request) {
    if (!request.hasMinimumInputs) return const [];

    final targetPlan = _WarGoalTargetPlan.fromRequest(request);
    if (!targetPlan.canGenerateGoals) return const [];

    final availableUnits = _WarGoalUnitAllocator.availableMilitaryUnits(
      request,
    );
    if (availableUnits.isEmpty) return const [];

    final committedUnits = <String>{};
    final goals = <WarGoal>[];
    for (final target in targetPlan.orderedTargets.take(request.maxGoals)) {
      final proposal = _WarGoalProposal.fromTarget(
        request: request,
        target: target,
      );
      if (proposal == null) continue;

      final assigned = _WarGoalUnitAllocator.assignedUnitsForGoal(
        request: request,
        availableUnits: availableUnits,
        committedUnits: committedUnits,
        priorityTarget: target.priorityTarget,
      );
      if (assigned.isEmpty) continue;

      committedUnits.addAll(assigned.map((unit) => unit.id));
      goals.add(proposal.toGoal(assigned));
    }

    return List.unmodifiable(goals);
  }
}

final class _WarGoalProposal {
  const _WarGoalProposal({
    required this.target,
    required this.kind,
    required this.targetCity,
    required this.targetHex,
    required this.turnsBudget,
    required this.priority,
  });

  final TargetabilityScore target;
  final WarGoalKind kind;
  final CityHex? targetCity;
  final HexCoordinate targetHex;
  final int turnsBudget;
  final double priority;

  static _WarGoalProposal? fromTarget({
    required _WarGoalGenerationRequest request,
    required TargetabilityScore target,
  }) {
    final city = _WarGoalMapQueries.cityForGoal(
      request: request,
      playerId: target.playerId,
    );
    final kind = _WarGoalKindPolicy(
      request,
    ).kindFor(target: target, city: city);
    final targetHex = _WarGoalMapQueries.targetHexForGoal(
      request: request,
      playerId: target.playerId,
      kind: kind,
      preferredCity: city,
    );
    if (targetHex == null) return null;

    return _WarGoalProposal(
      target: target,
      kind: kind,
      targetCity: city?.center,
      targetHex: targetHex,
      turnsBudget: _turnBudgetFor(target),
      priority: _priorityFor(target, request.context),
    );
  }

  WarGoal toGoal(List<GameUnit> assignedUnits) {
    return WarGoal(
      targetPlayerId: target.playerId,
      kind: kind,
      targetCity: targetCity,
      targetHex: targetHex,
      turnsBudget: turnsBudget,
      assignedUnitIds: assignedUnits.map((unit) => unit.id),
      priority: priority,
    );
  }

  static int _turnBudgetFor(TargetabilityScore target) {
    return switch (target.rival.nearestDistance) {
      <= 3 => 4,
      <= 6 => 7,
      <= 10 => 10,
      _ => 14,
    };
  }

  static double _priorityFor(TargetabilityScore target, AiContext context) {
    return (target.score * context.civProfile.belligerence)
        .clamp(0.0, 10.0)
        .toDouble();
  }
}
