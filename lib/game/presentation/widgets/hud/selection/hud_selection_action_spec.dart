import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/widgets.dart';

class HudSelectionActionSpec {
  const HudSelectionActionSpec({
    required this.icon,
    required this.actionId,
    required this.label,
    required this.onTap,
    this.color = GameUiTheme.gold,
    this.active = false,
    this.enabled = true,
    this.prominent = false,
    this.pulseBorder = false,
    this.showLabel = false,
    this.dangerOutlined = false,
    this.disabledOpacity = 0.42,
    this.disabledReason,
    this.badgeLabel,
  });

  final GameIconData icon;
  final String actionId;
  final String label;
  final Color color;
  final bool active;
  final bool enabled;
  final bool prominent;
  final bool pulseBorder;
  final bool showLabel;
  final bool dangerOutlined;
  final double disabledOpacity;
  final String? disabledReason;
  final String? badgeLabel;
  final VoidCallback? onTap;

  SelectionCommandChip toChip() {
    return SelectionCommandChip(
      icon: icon,
      actionId: actionId,
      label: label,
      color: color,
      active: active,
      enabled: enabled,
      prominent: prominent,
      pulseBorder: pulseBorder,
      showLabel: showLabel,
      dangerOutlined: dangerOutlined,
      disabledOpacity: disabledOpacity,
      disabledReason: disabledReason,
      badgeLabel: badgeLabel,
      onTap: onTap,
    );
  }
}
