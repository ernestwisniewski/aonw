import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_parts.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class ProductionListTile extends StatelessWidget {
  const ProductionListTile({
    required this.item,
    required this.compact,
    required this.onDetails,
    required this.onTap,
    super.key,
  });

  final CityProductionItem item;
  final bool compact;
  final VoidCallback? onDetails;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = onTap != null;
    final borderColor = item.active
        ? GameUiTheme.gold
        : item.locked
        ? SurfaceElevation.flat.strokeColor(alpha: 86)
        : SurfaceElevation.flat.strokeColor(alpha: 150);
    final titleColor = item.locked
        ? GameUiTheme.textMuted
        : GameUiTheme.textPrimary;
    final rowTap = onTap;
    final eta = item.effectiveEta;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: rowTap,
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: SurfaceElevation.flat.decoration(
              background: item.active
                  ? GameUiTheme.goldDark
                  : item.locked
                  ? GameUiTheme.bg
                  : GameUiTheme.bg,
              backgroundAlpha: item.active
                  ? 70
                  : item.locked
                  ? 82
                  : 150,
              borderRadius: BorderRadius.circular(7),
              borderColor: borderColor,
              borderAlpha: 255,
              includeShadow: false,
            ),
            child: Row(
              children: [
                ProductionLeading(item: item, compact: compact),
                SizedBox(width: compact ? 9 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.body.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Wrap(
                        spacing: compact ? 6 : 8,
                        runSpacing: 4,
                        children: item.continuous
                            ? [
                                for (final label in item.metaLabels)
                                  ProductionMetaPill(
                                    label,
                                    compact: compact,
                                    highlighted: item.active,
                                  ),
                              ]
                            : [
                                ProductionMetaPill(
                                  l10n.cityProductionCostShort(item.totalCost),
                                  compact: compact,
                                ),
                                ProductionMetaPill(
                                  eta.turnsLabel(l10n),
                                  compact: compact,
                                ),
                                if (eta.completionTurnLabel(l10n) != null)
                                  ProductionMetaPill(
                                    eta.completionTurnLabel(l10n)!,
                                    compact: compact,
                                  ),
                                for (final label in item.metaLabels)
                                  ProductionMetaPill(label, compact: compact),
                                if (item.active)
                                  ProductionMetaPill(
                                    '${item.investedProduction}/${item.totalCost}',
                                    compact: compact,
                                    highlighted: true,
                                  ),
                                if (item.locked &&
                                    item.requirementLabel != null)
                                  ProductionMetaPill(
                                    item.requirementLabel!,
                                    compact: compact,
                                  ),
                              ],
                      ),
                      if (item.active && !item.continuous) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 4,
                            backgroundColor: SurfaceElevation.flat.fill(
                              background: GameUiTheme.goldDark,
                              alpha: 92,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              GameUiTheme.gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
                if (onDetails != null) ...[
                  ProductionHelpButton(
                    tooltip: item.unitType == null
                        ? l10n.buildingDetailsTooltip
                        : l10n.unitDetailsTooltip,
                    compact: compact,
                    onPressed: onDetails!,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: compact ? 78 : 92),
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 12,
                      ),
                      backgroundColor: enabled
                          ? SurfaceElevation.modal.fill(
                              background: GameUiTheme.gold,
                              alpha: 220,
                            )
                          : SurfaceElevation.flat.fill(
                              background: Colors.white,
                              alpha: 12,
                            ),
                      foregroundColor: enabled
                          ? GameUiTheme.bg
                          : GameUiTheme.textMuted,
                      disabledForegroundColor: GameUiTheme.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      item.locked
                          ? l10n.productionButtonLocked
                          : item.active
                          ? l10n.productionInProgressLabel
                          : l10n.productionButtonProduce,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: GameUiTheme.headingFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductionHelpButton extends StatelessWidget {
  const ProductionHelpButton({
    required this.tooltip,
    required this.compact,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Container(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          decoration: SurfaceElevation.flat.decoration(
            background: Colors.white,
            backgroundAlpha: 14,
            border: BorderEmphasis.regular,
            borderRadius: BorderRadius.circular(5),
            includeShadow: false,
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.help,
              size: GameIconSize.small,
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
