import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objective_score_breakdown.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objective_visuals.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

class GameObjectiveRow extends StatelessWidget {
  const GameObjectiveRow({
    required this.objective,
    required this.presentation,
    required this.microTooltipLabel,
    required this.adviceLabel,
    this.scoreBreakdown,
    super.key,
  });

  final GameObjectiveProgress objective;
  final GameObjectivePresentation presentation;
  final String microTooltipLabel;
  final String? adviceLabel;
  final HudObjectiveScoreBreakdown? scoreBreakdown;

  @override
  Widget build(BuildContext context) {
    final color = objectiveToneColor(objective.definition.tone);
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: color,
        background: GameUiTheme.surface,
        backgroundAlpha: 150,
        borderAlpha: 0,
        borderRadius: GameUiTheme.borderRadius,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ObjectiveIcon(objective: objective, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: _ObjectiveContent(
                objective: objective,
                presentation: presentation,
                microTooltipLabel: microTooltipLabel,
                adviceLabel: adviceLabel,
                scoreBreakdown: scoreBreakdown,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectiveIcon extends StatelessWidget {
  const _ObjectiveIcon({required this.objective, required this.color});

  final GameObjectiveProgress objective;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: color,
        background: color,
        backgroundAlpha: 26,
        borderAlpha: 92,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: GameIcon(
            objectiveIconFor(objective.definition.id),
            size: GameIconSize.regular,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ObjectiveContent extends StatelessWidget {
  const _ObjectiveContent({
    required this.objective,
    required this.presentation,
    required this.microTooltipLabel,
    required this.adviceLabel,
    required this.scoreBreakdown,
    required this.color,
  });

  final GameObjectiveProgress objective;
  final GameObjectivePresentation presentation;
  final String microTooltipLabel;
  final String? adviceLabel;
  final HudObjectiveScoreBreakdown? scoreBreakdown;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ObjectiveTitle(
          title: presentation.title,
          progress: objective.progressLabel,
          color: color,
        ),
        const SizedBox(height: 5),
        _ObjectiveProgress(value: objective.fraction, color: color),
        const SizedBox(height: 5),
        Text(
          _hintText(presentation.hint, adviceLabel),
          maxLines: adviceLabel == null ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textSecondary,
            fontSize: 10,
            height: 1.15,
          ),
        ),
        if (scoreBreakdown case final breakdown?) ...[
          const SizedBox(height: 6),
          GameObjectiveScoreBreakdownMini(breakdown: breakdown, accent: color),
        ],
        const SizedBox(height: 4),
        _ObjectiveFooter(
          objectiveId: objective.definition.id,
          presentation: presentation,
          microTooltipLabel: microTooltipLabel,
          color: color,
        ),
      ],
    );
  }
}

class _ObjectiveTitle extends StatelessWidget {
  const _ObjectiveTitle({
    required this.title,
    required this.progress,
    required this.color,
  });

  final String title;
  final String progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodySmall.copyWith(
              color: GameUiTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          progress,
          style: GameUiTheme.toolbarLabel.copyWith(color: color, fontSize: 9),
        ),
      ],
    );
  }
}

class _ObjectiveProgress extends StatelessWidget {
  const _ObjectiveProgress({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        minHeight: 4,
        value: value,
        backgroundColor: SurfaceElevation.flat.fill(
          background: GameUiTheme.chipSurfaceDim,
          alpha: 132,
        ),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _ObjectiveFooter extends StatelessWidget {
  const _ObjectiveFooter({
    required this.objectiveId,
    required this.presentation,
    required this.microTooltipLabel,
    required this.color,
  });

  final GameObjectiveId objectiveId;
  final GameObjectivePresentation presentation;
  final String microTooltipLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            presentation.rewardLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.toolbarLabel.copyWith(
              color: SurfaceElevation.flat.fill(
                background: color,
                alpha: BorderEmphasis.active.alpha,
              ),
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ObjectiveTooltip(
          objectiveId: objectiveId,
          presentation: presentation,
          label: microTooltipLabel,
          color: color,
        ),
      ],
    );
  }
}

class _ObjectiveTooltip extends StatelessWidget {
  const _ObjectiveTooltip({
    required this.objectiveId,
    required this.presentation,
    required this.label,
    required this.color,
  });

  final GameObjectiveId objectiveId;
  final GameObjectivePresentation presentation;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: Key('gameObjectives.microTooltip.${objectiveId.name}'),
      message: presentation.microTooltip,
      child: Semantics(
        label: '$label: ${presentation.microTooltip}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(GameIcons.info, size: GameIconSize.tiny, color: color),
            const SizedBox(width: 3),
            Text(
              presentation.phaseLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.textMuted,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hintText(String hint, String? adviceLabel) {
  if (adviceLabel == null || adviceLabel.isEmpty) return hint;
  return '$hint\n$adviceLabel';
}
