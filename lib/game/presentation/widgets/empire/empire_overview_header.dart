import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class EmpireOverviewHeader extends StatelessWidget {
  const EmpireOverviewHeader({
    required this.subtitle,
    required this.onClose,
    super.key,
  });

  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 232,
        border: BorderEmphasis.regular,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: SurfaceElevation.flat.decoration(
                background: GameUiTheme.gold,
                backgroundAlpha: 24,
                border: BorderEmphasis.regular,
                borderRadius: BorderRadius.circular(6),
                includeShadow: false,
              ),
              child: const Center(
                child: GameIcon(
                  GameIcons.cityFilled,
                  size: GameIconSize.regular,
                  color: GameUiTheme.gold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameUiEpicHeader(
                    label: GameText.uppercase(l10n.commonEmpire),
                    alignment: Alignment.centerLeft,
                    compact: false,
                    textKey: const Key('empireOverviewHeader.title'),
                    leading: const GameIcon(
                      GameIcons.army,
                      key: Key('empireOverviewHeader.titleIcon'),
                      size: GameIconSize.small,
                      color: GameUiTheme.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    GameText.uppercase(subtitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.toolbarLabel.copyWith(
                      color: GameUiTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.closeAction,
              onPressed: onClose,
              icon: const GameIcon(
                GameIcons.close,
                size: GameIconSize.regular,
                color: GameUiTheme.textMuted,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class EmpireSummaryItem {
  const EmpireSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final GameIconData icon;
  final String label;
  final String value;
}

List<EmpireSummaryItem> empireSummaryItems(
  AppLocalizations l10n,
  EmpireOverviewViewModel viewModel,
) {
  return [
    EmpireSummaryItem(
      icon: GameIcons.cityFilled,
      label: l10n.commonCities,
      value: '${viewModel.cities.length}',
    ),
    EmpireSummaryItem(
      icon: GameIcons.army,
      label: l10n.unitsSection,
      value: '${viewModel.units.length}',
    ),
    EmpireSummaryItem(
      icon: GameIcons.move,
      label: l10n.commonReady,
      value: '${viewModel.readyUnitCount}',
    ),
    EmpireSummaryItem(
      icon: GameIcons.food,
      label: l10n.commonPopulation,
      value: '${viewModel.totalPopulation}',
    ),
  ];
}

class EmpireSummaryStrip extends StatelessWidget {
  const EmpireSummaryStrip({required this.items, super.key});

  final List<EmpireSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final itemWidth = compact
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 24) / 4;

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                SizedBox(
                  width: itemWidth,
                  child: _EmpireSummaryTile(item: item),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmpireSummaryTile extends StatelessWidget {
  const _EmpireSummaryTile({required this.item});

  final EmpireSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 132,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            GameIcon(
              item.icon,
              size: GameIconSize.small,
              color: GameUiTheme.gold,
            ),
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
            const SizedBox(width: 8),
            Text(
              item.value,
              style: const TextStyle(
                color: GameUiTheme.textBright,
                fontFamily: GameUiTheme.headingFont,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
