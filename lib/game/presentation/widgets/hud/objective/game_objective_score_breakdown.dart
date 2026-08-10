import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameObjectiveScoreBreakdownMini extends StatelessWidget {
  const GameObjectiveScoreBreakdownMini({
    required this.breakdown,
    required this.accent,
    super.key,
  });

  final HudObjectiveScoreBreakdown breakdown;
  final Color accent;

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
            _BreakdownHeader(
              header: _header(l10n),
              totals: _totals(l10n),
              accent: accent,
            ),
            const SizedBox(height: 4),
            _BreakdownRows(
              breakdown: breakdown,
              deltaLabel: (delta) => _delta(l10n, delta),
            ),
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

  String _totals(AppLocalizations l10n) => switch (breakdown.mode) {
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

  String _delta(AppLocalizations l10n, int delta) => switch (breakdown.mode) {
    HudObjectiveScoreBreakdownMode.catchUp =>
      l10n.objectiveScoreBreakdownCatchUpDelta(delta),
    HudObjectiveScoreBreakdownMode.protectLead =>
      l10n.objectiveScoreBreakdownProtectDelta(delta),
  };
}

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader({
    required this.header,
    required this.totals,
    required this.accent,
  });

  final String header;
  final String totals;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            header,
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
            totals,
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
    );
  }
}

class _BreakdownRows extends StatelessWidget {
  const _BreakdownRows({required this.breakdown, required this.deltaLabel});

  final HudObjectiveScoreBreakdown breakdown;
  final String Function(int delta) deltaLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (var index = 0; index < breakdown.rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 2),
          _BreakdownRow(
            label: GameObjectiveLabels.scoreCategory(
              l10n,
              breakdown.rows[index].advice,
            ),
            delta: deltaLabel(breakdown.rows[index].delta),
          ),
        ],
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.delta});

  final String label;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
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
          delta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.textPrimary,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
