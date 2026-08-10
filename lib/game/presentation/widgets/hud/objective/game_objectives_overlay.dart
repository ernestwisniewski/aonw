import 'package:aonw/game/presentation/widgets/hud/objective/game_objectives_panel.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

class GameObjectivesOverlay extends StatelessWidget {
  const GameObjectivesOverlay({
    required this.objectives,
    this.scoreBreakdown,
    required this.maxWidth,
    super.key,
  });

  final List<GameObjectiveProgress> objectives;
  final HudObjectiveScoreBreakdown? scoreBreakdown;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) return const SizedBox.shrink();
    return GameObjectivesPanel(
      objectives: objectives,
      scoreBreakdown: scoreBreakdown,
      maxWidth: maxWidth,
    );
  }
}
