import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objective_overview.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objective_row.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objective_visuals.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

class GameObjectivesPanel extends StatelessWidget {
  const GameObjectivesPanel({
    required this.objectives,
    required this.scoreBreakdown,
    required this.maxWidth,
    super.key,
  });

  final List<GameObjectiveProgress> objectives;
  final HudObjectiveScoreBreakdown? scoreBreakdown;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overview = GameObjectiveOverview.from(
      l10n: l10n,
      objectives: objectives,
      scoreBreakdown: scoreBreakdown,
    );
    return Material(
      color: Colors.transparent,
      borderRadius: GameUiTheme.borderRadius,
      child: Container(
        width: maxWidth,
        padding: const EdgeInsets.all(12),
        decoration: SurfaceElevation.flat.decoration(
          background: GameUiTheme.bg,
          backgroundAlpha: 235,
          borderRadius: GameUiTheme.borderRadius,
          border: BorderEmphasis.regular,
          includeShadow: false,
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: _PanelContent(
          l10n: l10n,
          overview: overview,
          objectives: objectives,
          scoreBreakdown: scoreBreakdown,
        ),
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.l10n,
    required this.overview,
    required this.objectives,
    required this.scoreBreakdown,
  });

  final AppLocalizations l10n;
  final GameObjectiveOverview overview;
  final List<GameObjectiveProgress> objectives;
  final HudObjectiveScoreBreakdown? scoreBreakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameUiEpicHeader(
          label: l10n.objectivesPanelTitle,
          textKey: const Key('gameObjectives.title'),
        ),
        const SizedBox(height: 10),
        GameObjectiveOverviewBand(overview: overview),
        const SizedBox(height: 10),
        _ObjectiveRows(
          l10n: l10n,
          objectives: objectives,
          scoreBreakdown: scoreBreakdown,
        ),
      ],
    );
  }
}

class _ObjectiveRows extends StatelessWidget {
  const _ObjectiveRows({
    required this.l10n,
    required this.objectives,
    required this.scoreBreakdown,
  });

  final AppLocalizations l10n;
  final List<GameObjectiveProgress> objectives;
  final HudObjectiveScoreBreakdown? scoreBreakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < objectives.length; index++) ...[
          if (index > 0) const SizedBox(height: 7),
          GameObjectiveRow(
            objective: objectives[index],
            presentation: GameObjectiveLabels.presentation(
              l10n,
              objectives[index].definition,
            ),
            microTooltipLabel: l10n.objectiveMicroTooltipLabel,
            adviceLabel: GameObjectiveLabels.advice(
              l10n,
              objectives[index].advice,
            ),
            scoreBreakdown:
                isScorePressureObjective(objectives[index].definition.id)
                ? scoreBreakdown
                : null,
          ),
        ],
      ],
    );
  }
}
