import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objective_visuals.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

class GameObjectiveOverview {
  const GameObjectiveOverview({
    required this.statusLabel,
    required this.title,
    required this.detailLabel,
    required this.icon,
    required this.accent,
  });

  factory GameObjectiveOverview.from({
    required AppLocalizations l10n,
    required List<GameObjectiveProgress> objectives,
    required HudObjectiveScoreBreakdown? scoreBreakdown,
  }) {
    final objective = objectives.first;
    return GameObjectiveOverview(
      statusLabel: _statusLabel(l10n, objective),
      title: l10n.objectiveOverviewTitleLabel(
        GameObjectiveLabels.title(l10n, objective.definition.id),
      ),
      detailLabel: _detailLabel(l10n, objective, scoreBreakdown),
      icon: objectiveIconFor(objective.definition.id),
      accent: objectiveToneColor(objective.definition.tone),
    );
  }

  final String statusLabel;
  final String title;
  final String detailLabel;
  final GameIconData icon;
  final Color accent;
}

String _statusLabel(AppLocalizations l10n, GameObjectiveProgress objective) {
  return switch (objective.definition.id) {
    GameObjectiveId.holdDomination => l10n.objectiveOverviewDominationHoldLabel,
    GameObjectiveId.breakDominationHold =>
      l10n.objectiveOverviewDominationThreatLabel,
    GameObjectiveId.holdScoreLead => l10n.objectiveOverviewScoreProtectLabel,
    GameObjectiveId.overtakeScoreLeader =>
      l10n.objectiveOverviewScoreCatchUpLabel,
    _ =>
      objective.definition.track == GameObjectiveTrack.strategic
          ? l10n.objectiveOverviewStrategicLabel
          : l10n.objectiveOverviewGuidanceLabel,
  };
}

String _detailLabel(
  AppLocalizations l10n,
  GameObjectiveProgress objective,
  HudObjectiveScoreBreakdown? scoreBreakdown,
) {
  if (isScorePressureObjective(objective.definition.id) &&
      scoreBreakdown != null) {
    return switch (scoreBreakdown.mode) {
      HudObjectiveScoreBreakdownMode.catchUp =>
        l10n.objectiveScoreBreakdownCatchUpHeader(scoreBreakdown.delta),
      HudObjectiveScoreBreakdownMode.protectLead =>
        l10n.objectiveScoreBreakdownProtectHeader(scoreBreakdown.delta),
    };
  }
  return l10n.objectiveOverviewProgressLabel(objective.progressLabel);
}

class GameObjectiveOverviewBand extends StatelessWidget {
  const GameObjectiveOverviewBand({required this.overview, super.key});

  final GameObjectiveOverview overview;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('gameObjectives.overview'),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: SurfaceElevation.flat.fill(
              background: overview.accent,
              alpha: 88,
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _OverviewIcon(overview: overview),
            const SizedBox(width: 9),
            Expanded(child: _OverviewText(overview: overview)),
          ],
        ),
      ),
    );
  }
}

class _OverviewIcon extends StatelessWidget {
  const _OverviewIcon({required this.overview});

  final GameObjectiveOverview overview;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: overview.accent,
        background: overview.accent,
        backgroundAlpha: 22,
        borderAlpha: 84,
        shape: SurfaceShape.button,
        includeShadow: false,
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: GameIcon(
            overview.icon,
            size: GameIconSize.small,
            color: overview.accent,
          ),
        ),
      ),
    );
  }
}

class _OverviewText extends StatelessWidget {
  const _OverviewText({required this.overview});

  final GameObjectiveOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          overview.statusLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: overview.accent,
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          overview.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          overview.detailLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.textMuted,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
