import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/hud/hud_game_outcome_summary.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class HudGameOutcomeOverlay extends StatelessWidget {
  final HudGameOutcomeSummary summary;
  final VoidCallback onReturnToMenu;

  const HudGameOutcomeOverlay({
    required this.summary,
    required this.onReturnToMenu,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = _accent(summary.tone);
    return Material(
      key: const Key('gameHud.outcomeOverlay'),
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(color: GameUiTheme.bg.withAlpha(190)),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GameUiTheme.surface.withAlpha(246),
                    border: Border.all(color: accent.withAlpha(190)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OutcomeHeader(summary: summary, accent: accent),
                        const SizedBox(height: 14),
                        Text(
                          summary.subtitle,
                          style: GameUiTheme.body.copyWith(
                            color: GameUiTheme.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        if (summary.metrics.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _OutcomeMetrics(
                            metrics: summary.metrics,
                            accent: accent,
                          ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            key: const Key('gameHud.outcome.returnToMenu'),
                            style: GameUiTheme.primaryButtonStyle(
                              background: accent,
                            ),
                            onPressed: onReturnToMenu,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const GameIcon(
                                  GameIcons.back,
                                  size: 17,
                                  color: GameUiTheme.bg,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  GameText.actionLabel(l10n.returnToMenuAction),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accent(HudGameOutcomeTone tone) {
    return switch (tone) {
      HudGameOutcomeTone.victory => GameUiTheme.success,
      HudGameOutcomeTone.defeat => GameUiTheme.danger,
      HudGameOutcomeTone.draw => GameUiTheme.warning,
      HudGameOutcomeTone.complete => GameUiTheme.gold,
    };
  }
}

class _OutcomeHeader extends StatelessWidget {
  final HudGameOutcomeSummary summary;
  final Color accent;

  const _OutcomeHeader({required this.summary, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: accent.withAlpha(34),
            border: Border.all(color: accent.withAlpha(160)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: GameIcon(_icon(summary.tone), size: 28, color: accent),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameUiEpicHeader(
                label: summary.title,
                alignment: Alignment.centerLeft,
                accent: accent,
                compact: false,
                textKey: const Key('gameHud.outcome.title'),
              ),
              const SizedBox(height: 5),
              Text(
                summary.conditionLabel,
                key: const Key('gameHud.outcome.condition'),
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  GameIconData _icon(HudGameOutcomeTone tone) {
    return switch (tone) {
      HudGameOutcomeTone.victory => GameIcons.checkCircle,
      HudGameOutcomeTone.defeat => GameIcons.warning,
      HudGameOutcomeTone.draw => GameIcons.hourglass,
      HudGameOutcomeTone.complete => GameIcons.flag,
    };
  }
}

class _OutcomeMetrics extends StatelessWidget {
  final List<HudGameOutcomeMetric> metrics;
  final Color accent;

  const _OutcomeMetrics({required this.metrics, required this.accent});

  @override
  Widget build(BuildContext context) {
    final maxNumericValue = metrics.fold<int>(
      0,
      (max, metric) =>
          math.max(max, _OutcomeMetricVisual.numericValue(metric.value) ?? 0),
    );
    return Column(
      children: [
        for (final metric in metrics)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _OutcomeMetricRow(
              metric: metric,
              accent: accent,
              maxNumericValue: maxNumericValue,
            ),
          ),
      ],
    );
  }
}

class _OutcomeMetricRow extends StatelessWidget {
  const _OutcomeMetricRow({
    required this.metric,
    required this.accent,
    required this.maxNumericValue,
  });

  final HudGameOutcomeMetric metric;
  final Color accent;
  final int maxNumericValue;

  @override
  Widget build(BuildContext context) {
    final visual = _OutcomeMetricVisual.fromValue(
      metric.value,
      maxNumericValue: maxNumericValue,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                metric.label,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              metric.value,
              style: GameUiTheme.bodyStrong.copyWith(
                color: GameUiTheme.textPrimary,
              ),
            ),
          ],
        ),
        if (visual != null) ...[
          const SizedBox(height: 5),
          _OutcomeMetricBar(visual: visual, accent: accent),
        ],
      ],
    );
  }
}

class _OutcomeMetricBar extends StatelessWidget {
  const _OutcomeMetricBar({required this.visual, required this.accent});

  final _OutcomeMetricVisual visual;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: ColoredBox(
          color: GameUiTheme.surfaceDeep.withAlpha(155),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: visual.factor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withAlpha(220),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeMetricVisual {
  const _OutcomeMetricVisual({required this.current, required this.target});

  final int current;
  final int target;

  double get factor => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  static int? numericValue(String value) {
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
    return int.tryParse(trimmed);
  }

  static _OutcomeMetricVisual? fromValue(
    String value, {
    required int maxNumericValue,
  }) {
    final trimmed = value.trim();
    final ratio = RegExp(r'^(\d+)\s*/\s*(\d+)').firstMatch(trimmed);
    if (ratio != null) {
      final current = int.tryParse(ratio.group(1)!);
      final target = int.tryParse(ratio.group(2)!);
      if (current != null && target != null && target > 0) {
        return _OutcomeMetricVisual(current: current, target: target);
      }
    }

    final percent = RegExp(r'^(\d+)%$').firstMatch(trimmed);
    if (percent != null) {
      final current = int.tryParse(percent.group(1)!);
      if (current != null) {
        return _OutcomeMetricVisual(current: current, target: 100);
      }
    }

    final numeric = numericValue(trimmed);
    if (numeric != null && maxNumericValue > 0) {
      return _OutcomeMetricVisual(current: numeric, target: maxNumericValue);
    }

    return null;
  }
}
