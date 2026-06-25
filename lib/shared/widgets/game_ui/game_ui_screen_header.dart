import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class GameUiScreenHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> meta;
  final Widget? trailing;

  const GameUiScreenHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: SurfaceElevation.flat.strokeColor(
                color: GameUiTheme.gold,
                alpha: 92,
              ),
            ),
          ),
          boxShadow: [
            BoxShadow(color: GameUiTheme.bg.withAlpha(90), blurRadius: 22),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GameUiEpicHeader(
                      label: title,
                      compact: false,
                      textKey: const Key('gameUiScreenHeader.title'),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.bodySmall,
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Wrap(spacing: 6, runSpacing: 6, children: meta),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class GameUiMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const GameUiMetaPill({
    required this.icon,
    required this.label,
    this.color = GameUiTheme.gold,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(
          background: GameUiTheme.surface,
          alpha: 210,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
          side: BorderSide(
            color: SurfaceElevation.flat.strokeColor(color: color, alpha: 120),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.chipLabel.copyWith(
                color: GameUiTheme.textPrimary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameUiEmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? message;
  final Widget? action;

  const GameUiEmptyState({
    this.icon,
    this.iconWidget,
    required this.title,
    this.message,
    this.action,
    super.key,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderIcon(icon: icon, iconWidget: iconWidget, large: true),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GameUiTheme.cardTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: 7),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GameUiTheme.bodySmall,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final bool large;

  const _HeaderIcon({this.icon, this.iconWidget, this.large = false})
    : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final size = large ? 44.0 : 38.0;
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameUiTheme.gold.withAlpha(44),
            GameUiTheme.bg.withAlpha(128),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
          side: BorderSide(
            color: SurfaceElevation.flat.strokeColor(
              color: GameUiTheme.gold,
              alpha: 120,
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child:
            iconWidget ??
            Icon(icon, size: large ? 22 : 19, color: GameUiTheme.goldLight),
      ),
    );
  }
}
