import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_tile.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class FutureBuildingsSection extends StatelessWidget {
  const FutureBuildingsSection({
    required this.items,
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.onDetails,
    super.key,
  });

  final List<CityProductionItem> items;
  final String title;
  final String subtitle;
  final bool compact;
  final ValueChanged<CityProductionItem> onDetails;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GameUiTheme.toolbarLabel.copyWith(
      color: GameUiTheme.gold,
    );
    final subtitleStyle = GameUiTheme.bodySmall.copyWith(
      color: GameUiTheme.textMuted,
      fontWeight: FontWeight.w700,
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          decoration: SurfaceElevation.flat.decoration(
            background: GameUiTheme.bg,
            backgroundAlpha: 112,
            borderRadius: BorderRadius.circular(7),
            border: BorderEmphasis.regular,
            includeShadow: false,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
              childrenPadding: compact
                  ? const EdgeInsets.fromLTRB(8, 0, 8, 6)
                  : const EdgeInsets.fromLTRB(10, 0, 10, 8),
              collapsedIconColor: GameUiTheme.gold,
              iconColor: GameUiTheme.goldLight,
              title: Text(GameText.uppercase(title), style: titleStyle),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
              children: [
                for (final item in items)
                  ProductionListTile(
                    item: item,
                    compact: compact,
                    onDetails: () => onDetails(item),
                    onTap: null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
