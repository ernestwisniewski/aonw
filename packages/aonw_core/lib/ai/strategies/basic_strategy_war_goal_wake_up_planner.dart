import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/command.dart';

final class BasicStrategyWarGoalWakeUpPlanner {
  const BasicStrategyWarGoalWakeUpPlanner({
    this.militaryAssessment = const AiMilitaryAssessment(),
  });

  final AiMilitaryAssessment militaryAssessment;

  List<GameCommand> plan(GameView view, StrategicPlan strategicPlan) {
    final goals =
        [
          for (final goal in strategicPlan.warGoals)
            if (goal.kind != WarGoalKind.defend &&
                view.canTargetPlayer(goal.targetPlayerId))
              goal,
        ]..sort((a, b) {
          final priorityCompare = b.priority.compareTo(a.priority);
          if (priorityCompare != 0) return priorityCompare;
          return a.targetPlayerId.compareTo(b.targetPlayerId);
        });
    if (goals.isEmpty) return const [];

    final unitsById = {for (final unit in view.ownUnits) unit.id: unit};
    final commands = <GameCommand>[];
    final usedUnitIds = <String>{};
    for (final goal in goals) {
      final unitIds = [...goal.assignedUnitIds]..sort();
      for (final unitId in unitIds) {
        if (!usedUnitIds.add(unitId)) continue;
        final unit = unitsById[unitId];
        if (unit == null ||
            !unit.isFortified ||
            unit.isWorking ||
            unit.queuedPath != null ||
            !militaryAssessment.isMilitaryUnit(unit)) {
          continue;
        }
        commands.add(CancelUnitActionCommand(unit.id));
        if (commands.length >= 4) return List.unmodifiable(commands);
      }
    }
    return List.unmodifiable(commands);
  }
}
