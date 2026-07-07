import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/economy_health.dart';
import 'package:aonw_core/ai/strategic/frontier_clearing_plan.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/threat_assessor.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'strategic_plan.freezed.dart';

@freezed
abstract class StrategicPlan with _$StrategicPlan {
  const StrategicPlan._();

  const factory StrategicPlan({
    required int computedAtTurn,
    required StrategicMode mode,
    required EconomyExpectations expectations,
    @Default(EconomyHealth.stable) EconomyHealth economyHealth,
    @Default([]) List<PlayerThreatScore> rivalRanking,
    @Default([]) List<TechnologyId> techPath,
    @Default([]) List<CityHex> citySiteRanking,
    @Default({}) Map<String, CityHex> settlerAssignments,
    @Default({}) Map<String, StrategicWorkerAssignment> workerAssignments,
    @Default({})
    Map<String, StrategicFrontierClearingAssignment>
    frontierClearingAssignments,
    @Default([]) List<WarGoal> warGoals,
    @Default({}) Map<String, StrategicDefenseAssignment> defenses,
  }) = _StrategicPlan;
}
