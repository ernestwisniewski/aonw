import 'dart:async';

import 'package:aonw/game/presentation/widgets/hud/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_delta_badge.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

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
            child: _PulsingPillSurface(
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
    final label = l10n.topResourceTurnShortLabel(turnNumber);
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
          child: _PulsingPillSurface(
            active: false,
            color: GameUiTheme.gold,
            compact: compact,
            critical: false,
            child: Center(
              child: Text(
                label,
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
    final l10n = context.l10n;
    final secondary = secondaryLabel;
    final label = condensed
        ? compactLabel
        : secondary == null || compact
        ? primaryLabel
        : '$primaryLabel · $secondary';
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
          onLongPress: () => showHudLongPressInfoSheet(
            context: context,
            icon: GameIcons.stats,
            title: l10n.gameGoalTitle,
            body: tooltip,
            accent: color,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: condensed
                  ? 54
                  : compact
                  ? 132
                  : 190,
            ),
            child: _PulsingPillSurface(
              active: active,
              color: color,
              compact: compact,
              critical: critical,
              child: Row(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingPillSurface extends StatefulWidget {
  const _PulsingPillSurface({
    required this.active,
    required this.color,
    required this.compact,
    required this.critical,
    required this.child,
  });

  final bool active;
  final Color color;
  final bool compact;
  final bool critical;
  final Widget child;

  @override
  State<_PulsingPillSurface> createState() => _PulsingPillSurfaceState();
}

class _PulsingPillSurfaceState extends State<_PulsingPillSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    if (widget.critical) {
      unawaited(_pulse.repeat(reverse: true));
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingPillSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.critical && !_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    } else if (!widget.critical && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.critical) {
      return _buildSurface(0, widget.child);
    }
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) => _buildSurface(_pulse.value, child!),
    );
  }

  Widget _buildSurface(double pulse, Widget child) {
    final borderColor = widget.critical
        ? GameUiTheme.danger
        : widget.active
        ? GameUiTheme.goldLight
        : widget.color;
    final borderAlpha = widget.critical
        ? (160 + pulse * 95).round()
        : widget.active
        ? 255
        : SurfaceElevation.floating.borderAlpha;
    final borderWidth = widget.critical
        ? 1.5 + pulse * 0.7
        : widget.active
        ? 1.4
        : 1.0;
    final surface = widget.active
        ? SurfaceElevation.modal
        : SurfaceElevation.floating;

    return Container(
      height: 34,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 7 : 9),
      decoration: surface.decoration(
        accent: widget.color,
        background: widget.active ? widget.color : null,
        backgroundAlpha: widget.active ? 230 : null,
        border: borderColor,
        borderAlpha: borderAlpha,
        borderWidth: borderWidth,
        shape: SurfaceShape.pill,
      ),
      child: child,
    );
  }
}
