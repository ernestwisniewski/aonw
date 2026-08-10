import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class MenuRouteSection extends StatelessWidget {
  const MenuRouteSection({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(14, 13, 14, 14),
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.raised.decoration(
        gradient: GameUiTheme.panelSurfaceGradient(),
        borderColor: GameUiTheme.gold,
        borderAlpha: 120,
        radius: GameUiTheme.radiusCard,
        boxShadow: [
          BoxShadow(
            color: GameUiTheme.bg.withAlpha(165),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(color: GameUiTheme.copper.withAlpha(22), blurRadius: 34),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameUiEpicHeader(
              label: title,
              compact: false,
              leading: icon == null
                  ? null
                  : Icon(icon, size: 18, color: GameUiTheme.goldLight),
              trailing: trailing,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class MenuMetricPill extends StatelessWidget {
  const MenuMetricPill({
    required this.icon,
    required this.label,
    this.color = GameUiTheme.gold,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(142),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusPill),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.chipLabel.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
