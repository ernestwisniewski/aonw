import 'package:aonw/game/presentation/widgets/empire/empire_statistics_view_data.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class EmpireStatsGroupBlock extends StatelessWidget {
  const EmpireStatsGroupBlock({
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
    super.key,
  });

  final GameIconData icon;
  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GameIcon(icon, size: GameIconSize.small, color: accent),
            const SizedBox(width: 7),
            Text(
              GameText.uppercase(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.sectionHeader.copyWith(
                color: accent,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: _sectionDivider(accent)),
          ],
        ),
        const SizedBox(height: 9),
        ...children,
      ],
    );
  }

  Widget _sectionDivider(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withAlpha(130), accent.withAlpha(0)],
        ),
      ),
      child: const SizedBox(height: 1),
    );
  }
}

class EmpireStatsHeader extends StatelessWidget {
  const EmpireStatsHeader({required this.l10n, super.key});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GameIcon(
          GameIcons.stats,
          size: GameIconSize.small,
          color: GameUiTheme.gold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameText.uppercase(l10n.empireStatsTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.sectionHeader.copyWith(
                  color: GameUiTheme.goldLight,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.empireStatsSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmpireMetricGrid extends StatelessWidget {
  const EmpireMetricGrid({
    required this.items,
    required this.compact,
    super.key,
  });

  final List<EmpireMetricItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact || constraints.maxWidth < 640 ? 2 : 4;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _MetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final EmpireMetricItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 126,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Row(
          children: [
            GameIcon(item.icon, size: GameIconSize.small, color: item.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                GameText.uppercase(item.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.textSecondary,
                  fontSize: 8.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.value,
              style: TextStyle(
                color: item.color,
                fontFamily: GameUiTheme.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFeatures: GameUiTheme.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
