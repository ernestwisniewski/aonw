import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class HudMapInspectionPopoverFrame extends StatelessWidget {
  const HudMapInspectionPopoverFrame({
    required this.arrowOnLeft,
    required this.arrowTop,
    required this.maxHeight,
    required this.borderAlpha,
    required this.child,
    super.key,
  });

  final bool arrowOnLeft;
  final double arrowTop;
  final double maxHeight;
  final int borderAlpha;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _PopoverArrow(arrowOnLeft: arrowOnLeft, arrowTop: arrowTop),
          _PopoverBody(
            maxHeight: maxHeight,
            borderAlpha: borderAlpha,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PopoverArrow extends StatelessWidget {
  const _PopoverArrow({required this.arrowOnLeft, required this.arrowTop});

  final bool arrowOnLeft;
  final double arrowTop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: arrowOnLeft ? -5 : null,
      right: arrowOnLeft ? null : -5,
      top: arrowTop,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: GameUiTheme.surfaceDeep.withAlpha(244),
            border: Border.all(color: GameUiTheme.gold.withAlpha(145)),
          ),
        ),
      ),
    );
  }
}

class _PopoverBody extends StatelessWidget {
  const _PopoverBody({
    required this.maxHeight,
    required this.borderAlpha,
    required this.child,
  });

  final double maxHeight;
  final int borderAlpha;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GameUiTheme.surfaceDeep.withAlpha(246),
              GameUiTheme.bg.withAlpha(238),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameUiTheme.gold.withAlpha(borderAlpha)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(130),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
      ),
    );
  }
}

class HudMapInspectionSection extends StatelessWidget {
  const HudMapInspectionSection({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final GameIconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GameIcon(icon, size: 14, color: GameUiTheme.goldLight),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: GameUiTheme.gold.withAlpha(36)),
            const SizedBox(height: 7),
            child,
          ],
        ),
      ),
    );
  }
}

class HudMapInspectionValueLine extends StatelessWidget {
  const HudMapInspectionValueLine({
    required this.value,
    required this.color,
    super.key,
  });

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: GameUiTheme.bodyStrong.copyWith(color: color),
    );
  }
}

class HudMapInspectionSmallFact extends StatelessWidget {
  const HudMapInspectionSmallFact({required this.item, super.key});

  final SelectionInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameIcon(item.icon, size: 13, color: item.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.showLabel ? '${item.label}: ${item.value}' : item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodySmall.copyWith(
              color: GameUiTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class HudMapInspectionYieldPill extends StatelessWidget {
  const HudMapInspectionYieldPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  final GameIconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label: $value',
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(110)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: GameHudTheme.yieldValue.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
