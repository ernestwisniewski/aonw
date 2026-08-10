import 'dart:async';

import 'package:aonw/game/presentation/widgets/hud/selection/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/resources/pulsing_resource_pill_surface.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_delta_badge.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class VictoryStatusResourcePill extends StatelessWidget {
  const VictoryStatusResourcePill({
    required this.primaryLabel,
    required this.compactLabel,
    required this.secondaryLabel,
    required this.tooltip,
    required this.compact,
    required this.condensed,
    required this.critical,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String primaryLabel;
  final String compactLabel;
  final String? secondaryLabel;
  final String tooltip;
  final bool compact;
  final bool condensed;
  final bool critical;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = critical ? GameUiTheme.warning : GameUiTheme.info;
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        selected: active,
        label: tooltip,
        child: GestureDetector(
          key: const Key('gameHud.victoryStatus'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: () => _showInfo(context, color),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxWidth),
            child: PulsingResourcePillSurface(
              active: active,
              color: color,
              compact: compact,
              critical: critical,
              child: _VictoryStatusPillContent(
                label: _label,
                compact: compact,
                condensed: condensed,
                active: active,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get _maxWidth => condensed
      ? 54
      : compact
      ? 132
      : 190;

  String get _label => condensed
      ? compactLabel
      : secondaryLabel == null || compact
      ? primaryLabel
      : '$primaryLabel · $secondaryLabel';

  void _showInfo(BuildContext context, Color color) {
    unawaited(
      showHudLongPressInfoSheet(
        context: context,
        icon: GameIcons.stats,
        title: context.l10n.gameGoalTitle,
        body: tooltip,
        accent: color,
      ),
    );
  }
}

class _VictoryStatusPillContent extends StatelessWidget {
  const _VictoryStatusPillContent({
    required this.label,
    required this.compact,
    required this.condensed,
    required this.active,
    required this.color,
  });

  final String label;
  final bool compact;
  final bool condensed;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!condensed) ...[
          GameIcon(
            GameIcons.stats,
            size: compact ? GameIconSize.tiny : GameIconSize.small,
            color: active ? GameUiTheme.bg : color,
          ),
          SizedBox(width: compact ? 4 : 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: GameHudTheme.buttonTopLabel.copyWith(
              color: active ? GameUiTheme.bg : GameUiTheme.goldLight,
              fontSize: compact ? 10.5 : 11,
              fontFeatures: GameUiTheme.tabularFigures,
              shadows: topResourceNumberShadows,
            ),
          ),
        ),
      ],
    );
  }
}
