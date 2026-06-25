import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class HudActionLine extends StatelessWidget {
  const HudActionLine({required this.actions, super.key});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: FirstTurnCoachmarkTargets.selectionActions,
      child: SizedBox(
        key: const Key('hudActionDeck.line.actions'),
        height: SelectionActionBar.actionChipHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _actionChildren(),
          ),
        ),
      ),
    );
  }

  List<Widget> _actionChildren() {
    final children = <Widget>[];
    var needsItemGap = false;
    for (final action in actions) {
      if (action is SelectionActionGroupBreak) {
        if (children.isNotEmpty && needsItemGap) {
          children.add(const _HudActionLineGroupBreak());
          needsItemGap = false;
        }
        continue;
      }
      if (needsItemGap) children.add(const SizedBox(width: 8));
      children.add(action);
      needsItemGap = true;
    }
    return children;
  }
}

class _HudActionLineGroupBreak extends StatelessWidget {
  const _HudActionLineGroupBreak();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SelectionActionBar.actionGroupBreakExtent,
      height: SelectionActionBar.actionChipHeight,
      child: Center(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: SurfaceElevation.flat.fill(
              background: Colors.white,
              alpha: 36,
            ),
            shape: const StadiumBorder(),
          ),
          child: const SizedBox(width: 1, height: 28),
        ),
      ),
    );
  }
}
