import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_parts.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class SpecializationListTile extends StatelessWidget {
  const SpecializationListTile({
    required this.item,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final CitySpecializationItem item;
  final bool compact;
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

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
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
                SpecializationLeading(item: item, compact: compact),
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
                        children: [
                          for (final label in item.metaLabels)
                            ProductionMetaPill(
                              label,
                              compact: compact,
                              highlighted: item.active,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
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
                      item.active
                          ? l10n.commonSelectedAction
                          : l10n.commonSelectAction,
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
