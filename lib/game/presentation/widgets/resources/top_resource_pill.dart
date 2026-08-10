import 'package:aonw/game/presentation/widgets/hud/selection/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/resources/pulsing_resource_pill_surface.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_delta_badge.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

export 'turn_resource_pill.dart';
export 'victory_status_resource_pill.dart';

class TopResourcePill extends StatelessWidget {
  const TopResourcePill({
    required this.icon,
    required this.title,
    required this.value,
    this.delta,
    required this.color,
    required this.compact,
    this.critical = false,
    required this.tooltip,
    required this.active,
    required this.onTap,
    super.key,
  });

  final GameIconData icon;
  final String title;
  final String? value;
  final ResourceDelta? delta;
  final Color color;
  final bool compact;
  final bool critical;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        selected: active,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: GameUiTheme.pillBorderRadius,
          child: InkWell(
            borderRadius: GameUiTheme.pillBorderRadius,
            onTap: onTap,
            onLongPress: () => showHudLongPressInfoSheet(
              context: context,
              icon: icon,
              title: title,
              body: tooltip,
              accent: color,
              actionLabel: context.l10n.commonShowDetailsAction,
              onAction: onTap,
            ),
            child: PulsingResourcePillSurface(
              active: active,
              color: color,
              compact: compact,
              critical: critical,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameIcon(
                    icon,
                    size: compact ? GameIconSize.tiny : GameIconSize.small,
                    color: active ? GameUiTheme.bg : color,
                  ),
                  SizedBox(width: compact ? 4 : 5),
                  if (value != null) ...[
                    Text(
                      value!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: GameHudTheme.buttonTopLabel.copyWith(
                        color: active ? GameUiTheme.bg : GameUiTheme.goldLight,
                        fontSize: compact ? 10.5 : 11,
                        fontFeatures: GameUiTheme.tabularFigures,
                        shadows: topResourceNumberShadows,
                      ),
                    ),
                    if (delta != null) const SizedBox(width: 4),
                  ],
                  if (delta != null) ResourceDeltaBadge(delta!, active: active),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
