import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/visual/game_insight_pill.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameInsightProgressCard extends StatelessWidget {
  const GameInsightProgressCard({
    required this.title,
    required this.valueLabel,
    required this.progress,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.meta = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final String valueLabel;
  final double progress;
  final GameIconData icon;
  final Color accent;
  final List<String> meta;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.bg,
        backgroundAlpha: 124,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(7),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressHeader(
              title: title,
              valueLabel: valueLabel,
              icon: icon,
              accent: accent,
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              _ProgressSubtitle(subtitle!),
            _ProgressBar(progress: progress, accent: accent),
            if (meta.isNotEmpty) _ProgressMeta(labels: meta, accent: accent),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.title,
    required this.valueLabel,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String valueLabel;
  final GameIconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GameIcon(icon, size: GameIconSize.small, color: accent),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            GameText.uppercase(title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.sectionHeader.copyWith(
              color: accent,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valueLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GameUiTheme.textBright,
            fontFamily: GameUiTheme.headingFont,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFeatures: GameUiTheme.tabularFigures,
          ),
        ),
      ],
    );
  }
}

class _ProgressSubtitle extends StatelessWidget {
  const _ProgressSubtitle(this.subtitle);

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.bodySmall.copyWith(
          color: GameUiTheme.textSecondary,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: ColoredBox(
          color: GameUiTheme.surfaceDeep.withAlpha(170),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: accent.withAlpha(220),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressMeta extends StatelessWidget {
  const _ProgressMeta({required this.labels, required this.accent});

  final List<String> labels;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final label in labels)
            GameInsightPill(label: label, color: accent),
        ],
      ),
    );
  }
}
