import 'package:aonw/game/presentation/widgets/hud/selection/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/resources/pulsing_resource_pill_surface.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_delta_badge.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class TurnResourcePill extends StatelessWidget {
  const TurnResourcePill({
    required this.turnNumber,
    required this.compact,
    this.onTap,
    super.key,
  });

  final int turnNumber;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tooltip = l10n.topResourceTurnTooltip(turnNumber);
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: onTap != null,
        label: tooltip,
        child: GestureDetector(
          key: const Key('gameHud.resource.turn'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: () => showHudLongPressInfoSheet(
            context: context,
            icon: GameIcons.info,
            title: l10n.commonTurn,
            body: tooltip,
            accent: GameUiTheme.gold,
            actionLabel: onTap == null ? null : l10n.commonShowDetailsAction,
            onAction: onTap,
          ),
          child: PulsingResourcePillSurface(
            active: false,
            color: GameUiTheme.gold,
            compact: compact,
            critical: false,
            child: Center(
              child: Text(
                l10n.topResourceTurnShortLabel(turnNumber),
                maxLines: 1,
                softWrap: false,
                style: GameHudTheme.buttonTopLabel.copyWith(
                  color: GameUiTheme.goldLight,
                  fontSize: compact ? 10.5 : 11,
                  fontFeatures: GameUiTheme.tabularFigures,
                  shadows: topResourceNumberShadows,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
