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
import 'package:aonw_core/util/collection_equality.dart';

class StrategicPlan {
  final int computedAtTurn;
  final StrategicMode mode;
  final EconomyExpectations expectations;
  final EconomyHealth economyHealth;
  final List<PlayerThreatScore> rivalRanking;
  final List<TechnologyId> techPath;
  final List<CityHex> citySiteRanking;
  final Map<String, CityHex> settlerAssignments;
  final Map<String, StrategicWorkerAssignment> workerAssignments;
  final Map<String, StrategicFrontierClearingAssignment>
  frontierClearingAssignments;
  final List<WarGoal> warGoals;
  final Map<String, StrategicDefenseAssignment> defenses;

  const StrategicPlan({
    required this.computedAtTurn,
    required this.mode,
    required this.expectations,
    this.economyHealth = EconomyHealth.stable,
    this.rivalRanking = const [],
    this.techPath = const [],
    this.citySiteRanking = const [],
    this.settlerAssignments = const {},
    this.workerAssignments = const {},
    this.frontierClearingAssignments = const {},
    this.warGoals = const [],
    this.defenses = const {},
  });

  StrategicPlan copyWith({
    int? computedAtTurn,
    StrategicMode? mode,
    EconomyExpectations? expectations,
    EconomyHealth? economyHealth,
    List<PlayerThreatScore>? rivalRanking,
    List<TechnologyId>? techPath,
    List<CityHex>? citySiteRanking,
    Map<String, CityHex>? settlerAssignments,
    Map<String, StrategicWorkerAssignment>? workerAssignments,
    Map<String, StrategicFrontierClearingAssignment>?
    frontierClearingAssignments,
    List<WarGoal>? warGoals,
    Map<String, StrategicDefenseAssignment>? defenses,
  }) {
    return StrategicPlan(
      computedAtTurn: computedAtTurn ?? this.computedAtTurn,
      mode: mode ?? this.mode,
      expectations: expectations ?? this.expectations,
      economyHealth: economyHealth ?? this.economyHealth,
      rivalRanking: rivalRanking ?? this.rivalRanking,
      techPath: techPath ?? this.techPath,
      citySiteRanking: citySiteRanking ?? this.citySiteRanking,
      settlerAssignments: settlerAssignments ?? this.settlerAssignments,
      workerAssignments: workerAssignments ?? this.workerAssignments,
      frontierClearingAssignments:
          frontierClearingAssignments ?? this.frontierClearingAssignments,
      warGoals: warGoals ?? this.warGoals,
      defenses: defenses ?? this.defenses,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StrategicPlan &&
        other.computedAtTurn == computedAtTurn &&
        other.mode == mode &&
        other.expectations == expectations &&
        other.economyHealth == economyHealth &&
        listEquals(other.rivalRanking, rivalRanking) &&
        listEquals(other.techPath, techPath) &&
        listEquals(other.citySiteRanking, citySiteRanking) &&
        mapEquals(other.settlerAssignments, settlerAssignments) &&
        mapEquals(other.workerAssignments, workerAssignments) &&
        mapEquals(
          other.frontierClearingAssignments,
          frontierClearingAssignments,
        ) &&
        listEquals(other.warGoals, warGoals) &&
        mapEquals(other.defenses, defenses);
  }

  @override
  int get hashCode {
    return Object.hash(
      computedAtTurn,
      mode,
      expectations,
      economyHealth,
      Object.hashAll(rivalRanking),
      Object.hashAll(techPath),
      Object.hashAll(citySiteRanking),
      mapHash(settlerAssignments),
      mapHash(workerAssignments),
      mapHash(frontierClearingAssignments),
      Object.hashAll(warGoals),
      mapHash(defenses),
    );
  }
}
