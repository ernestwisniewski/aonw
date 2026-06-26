import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

class GameObjectivesOverlay extends StatelessWidget {
  final List<GameObjectiveProgress> objectives;
  final HudObjectiveScoreBreakdown? scoreBreakdown;
  final double maxWidth;

  const GameObjectivesOverlay({
    required this.objectives,
    this.scoreBreakdown,
    required this.maxWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final overview = _ObjectiveOverview.from(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameUiEpicHeader(
              label: l10n.objectivesPanelTitle,
              textKey: const Key('gameObjectives.title'),
            ),
            const SizedBox(height: 10),
            _ObjectiveOverviewBand(overview: overview),
            const SizedBox(height: 10),
            for (var i = 0; i < objectives.length; i++) ...[
              _ObjectiveRow(
                objective: objectives[i],
                presentation: GameObjectiveLabels.presentation(
                  l10n,
                  objectives[i].definition,
                ),
                microTooltipLabel: l10n.objectiveMicroTooltipLabel,
                adviceLabel: GameObjectiveLabels.advice(
                  l10n,
                  objectives[i].advice,
                ),
                scoreBreakdown:
                    _isScorePressureObjective(objectives[i].definition.id)
                    ? scoreBreakdown
                    : null,
              ),
              if (i < objectives.length - 1) const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}

class _ObjectiveOverview {
  final String statusLabel;
  final String title;
  final String detailLabel;
  final GameIconData icon;
  final Color accent;

  const _ObjectiveOverview({
    required this.statusLabel,
    required this.title,
    required this.detailLabel,
    required this.icon,
    required this.accent,
  });

  factory _ObjectiveOverview.from({
    required AppLocalizations l10n,
    required List<GameObjectiveProgress> objectives,
    required HudObjectiveScoreBreakdown? scoreBreakdown,
  }) {
    final objective = objectives.first;

    return _ObjectiveOverview(
      statusLabel: _statusLabel(l10n, objective),
      title: l10n.objectiveOverviewTitleLabel(
        GameObjectiveLabels.title(l10n, objective.definition.id),
      ),
      detailLabel: _detailLabel(l10n, objective, scoreBreakdown),
      icon: _ObjectiveRow._iconFor(objective.definition.id),
      accent: _ObjectiveRow._toneColor(objective.definition.tone),
    );
  }

  static String _statusLabel(
    AppLocalizations l10n,
    GameObjectiveProgress objective,
  ) {
    return switch (objective.definition.id) {
      GameObjectiveId.holdDomination =>
        l10n.objectiveOverviewDominationHoldLabel,
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

  static String _detailLabel(
    AppLocalizations l10n,
    GameObjectiveProgress objective,
    HudObjectiveScoreBreakdown? scoreBreakdown,
  ) {
    if (_isScorePressureObjective(objective.definition.id) &&
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
}

class _ObjectiveOverviewBand extends StatelessWidget {
  final _ObjectiveOverview overview;

  const _ObjectiveOverviewBand({required this.overview});

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
            DecoratedBox(
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
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  final GameObjectiveProgress objective;
  final GameObjectivePresentation presentation;
  final String microTooltipLabel;
  final String? adviceLabel;
  final HudObjectiveScoreBreakdown? scoreBreakdown;

  const _ObjectiveRow({
    required this.objective,
    required this.presentation,
    required this.microTooltipLabel,
    required this.adviceLabel,
    this.scoreBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(objective.definition.tone);

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
            DecoratedBox(
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
                    _iconFor(objective.definition.id),
                    size: GameIconSize.regular,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          presentation.title,
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
                        objective.progressLabel,
                        style: GameUiTheme.toolbarLabel.copyWith(
                          color: color,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: objective.fraction,
                      backgroundColor: SurfaceElevation.flat.fill(
                        background: GameUiTheme.chipSurfaceDim,
                        alpha: 132,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
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
                    _ScoreBreakdownMini(breakdown: breakdown, accent: color),
                  ],
                  const SizedBox(height: 4),
                  Row(
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
                      Tooltip(
                        key: Key(
                          'gameObjectives.microTooltip.${objective.definition.id.name}',
                        ),
                        message: presentation.microTooltip,
                        child: Semantics(
                          label:
                              '$microTooltipLabel: ${presentation.microTooltip}',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GameIcon(
                                GameIcons.info,
                                size: GameIconSize.tiny,
                                color: color,
                              ),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hintText(String hint, String? adviceLabel) {
    if (adviceLabel == null || adviceLabel.isEmpty) return hint;
    return '$hint\n$adviceLabel';
  }

  static GameIconData _iconFor(GameObjectiveId id) {
    return switch (id) {
      GameObjectiveId.chooseResearch => GameIcons.science,
      GameObjectiveId.foundCapital => GameIcons.foundCity,
      GameObjectiveId.exploreNearby => GameIcons.visibility,
      GameObjectiveId.queueWorker => GameIcons.production,
      GameObjectiveId.improveFirstHex => GameIcons.food,
      GameObjectiveId.foundSecondCity => GameIcons.cityFilled,
      GameObjectiveId.buildFirstBuilding => GameIcons.production,
      GameObjectiveId.improveThreeHexes => GameIcons.resources,
      GameObjectiveId.foundThirdCity => GameIcons.cityFilled,
      GameObjectiveId.exploreRegion => GameIcons.visibility,
      GameObjectiveId.buildCombatForce => GameIcons.attack,
      GameObjectiveId.overtakeScoreLeader => GameIcons.stats,
      GameObjectiveId.holdDomination ||
      GameObjectiveId.holdScoreLead ||
      GameObjectiveId.secureMapObjective => GameIcons.checkCircle,
      GameObjectiveId.breakDominationHold ||
      GameObjectiveId.breakMapObjectiveHold => GameIcons.warning,
    };
  }

  static Color _toneColor(GameObjectiveTone tone) {
    return switch (tone) {
      GameObjectiveTone.research => GameUiTheme.scienceAccent,
      GameObjectiveTone.expansion => GameUiTheme.gold,
      GameObjectiveTone.exploration => const Color(0xFFB7D47D),
      GameObjectiveTone.economy => GameUiTheme.resourcesAccent,
      GameObjectiveTone.victory => GameUiTheme.success,
      GameObjectiveTone.warning => GameUiTheme.warning,
    };
  }
}

bool _isScorePressureObjective(GameObjectiveId id) {
  return id == GameObjectiveId.holdScoreLead ||
      id == GameObjectiveId.overtakeScoreLeader;
}

class _ScoreBreakdownMini extends StatelessWidget {
  final HudObjectiveScoreBreakdown breakdown;
  final Color accent;

  const _ScoreBreakdownMini({required this.breakdown, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      key: const Key('gameObjectives.scoreBreakdown'),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: SurfaceElevation.flat.fill(background: accent, alpha: 80),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _header(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.toolbarLabel.copyWith(
                      color: accent,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _totals(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GameUiTheme.toolbarLabel.copyWith(
                      color: GameUiTheme.textMuted,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final row in breakdown.rows) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      GameObjectiveLabels.scoreCategory(l10n, row.advice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textSecondary,
                        fontSize: 9,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _delta(l10n, row.delta),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.toolbarLabel.copyWith(
                      color: GameUiTheme.textPrimary,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              if (row != breakdown.rows.last) const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }

  String _header(AppLocalizations l10n) => switch (breakdown.mode) {
    HudObjectiveScoreBreakdownMode.catchUp =>
      l10n.objectiveScoreBreakdownCatchUpHeader(breakdown.delta),
    HudObjectiveScoreBreakdownMode.protectLead =>
      l10n.objectiveScoreBreakdownProtectHeader(breakdown.delta),
  };

  String _totals(AppLocalizations l10n) {
    return switch (breakdown.mode) {
      HudObjectiveScoreBreakdownMode.catchUp =>
        l10n.objectiveScoreBreakdownCatchUpTotals(
          breakdown.playerScore,
          breakdown.comparisonScore,
        ),
      HudObjectiveScoreBreakdownMode.protectLead =>
        l10n.objectiveScoreBreakdownProtectTotals(
          breakdown.playerScore,
          breakdown.comparisonScore,
        ),
    };
  }

  String _delta(AppLocalizations l10n, int delta) => switch (breakdown.mode) {
    HudObjectiveScoreBreakdownMode.catchUp =>
      l10n.objectiveScoreBreakdownCatchUpDelta(delta),
    HudObjectiveScoreBreakdownMode.protectLead =>
      l10n.objectiveScoreBreakdownProtectDelta(delta),
  };
}
