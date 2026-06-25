import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/selection_action_chip.dart';
import 'package:aonw/game/presentation/widgets/selection/selection_command_chip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class SelectionActionBar extends StatelessWidget {
  static const double infoChipExtent = 48;
  static const double actionChipWidth = SelectionCommandChip.extent;
  static const double actionChipHeight = SelectionCommandChip.extent;
  static const double actionGroupBreakExtent = 14;

  final List<SelectionInfoChipViewModel> chips;
  final String? openChipId;
  final ValueChanged<String> onToggleChip;
  final List<Widget> actions;
  final bool fillWidth;
  final bool includeBottomSafeArea;
  final Axis axis;

  const SelectionActionBar({
    required this.chips,
    required this.openChipId,
    required this.onToggleChip,
    this.actions = const [],
    this.fillWidth = false,
    this.includeBottomSafeArea = true,
    this.axis = Axis.horizontal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty && actions.isEmpty) return const SizedBox.shrink();

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final vertical = axis == Axis.vertical;
        final itemAxis = vertical ? Axis.vertical : Axis.horizontal;
        final maxExtent = vertical
            ? (constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0)
            : (constraints.maxWidth.isFinite
                  ? constraints.maxWidth - (fillWidth ? 8 : 16)
                  : 560.0);
        final maxMainExtent = maxExtent
            .clamp(0.0, vertical ? 320.0 : 560.0)
            .toDouble();
        final children = _groupChildren(vertical: vertical);

        if (vertical) {
          return Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 72,
                maxHeight: maxMainExtent,
              ),
              child: SingleChildScrollView(
                scrollDirection: itemAxis,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: Padding(
                  padding: _contentPadding(maxMainExtent, vertical: true),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ),
          );
        }

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth - (fillWidth ? 8 : 16)
            : 560.0;
        final maxWidth = availableWidth.clamp(0.0, 560.0).toDouble();

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(
              width: fillWidth ? maxWidth : null,
              child: SingleChildScrollView(
                scrollDirection: itemAxis,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: Padding(
                  padding: _contentPadding(maxWidth, vertical: false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!includeBottomSafeArea) return content;
    return SafeArea(top: false, child: content);
  }

  List<Widget> _groupChildren({required bool vertical}) {
    final children = <Widget>[];
    if (chips.isNotEmpty) {
      children.add(_infoGroup(vertical: vertical));
    }
    if (actions.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(_groupGap(vertical: vertical));
      }
      children.add(_actionGroup(vertical: vertical));
    }
    return children;
  }

  Widget _infoGroup({required bool vertical}) {
    return Flex(
      key: const Key('selectionInfo.group.info'),
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) _itemGap(vertical: vertical),
          SelectionActionChip(
            model: chips[i],
            active: openChipId == chips[i].id,
            density: SelectionDensity.comfortable,
            onTap: () => onToggleChip(chips[i].id),
          ),
        ],
      ],
    );
  }

  Widget _actionGroup({required bool vertical}) {
    return Flex(
      key: const Key('selectionInfo.group.actions'),
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: _actionChildren(vertical: vertical),
    );
  }

  List<Widget> _actionChildren({required bool vertical}) {
    final children = <Widget>[];
    var needsItemGap = false;
    for (final action in actions) {
      if (action is SelectionActionGroupBreak) {
        if (children.isNotEmpty && needsItemGap) {
          children.add(_actionGroupBreak(vertical: vertical));
          needsItemGap = false;
        }
        continue;
      }
      if (needsItemGap) {
        children.add(_itemGap(vertical: vertical));
      }
      children.add(action);
      needsItemGap = true;
    }
    return children;
  }

  SizedBox _itemGap({required bool vertical}) {
    return SizedBox(width: vertical ? 0 : 8, height: vertical ? 8 : 0);
  }

  SizedBox _groupGap({required bool vertical}) {
    return SizedBox(width: vertical ? 0 : 12, height: vertical ? 12 : 0);
  }

  Widget _actionGroupBreak({required bool vertical}) {
    return SizedBox(
      width: vertical ? actionChipWidth : actionGroupBreakExtent,
      height: vertical ? actionGroupBreakExtent : actionChipHeight,
      child: Center(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: SurfaceElevation.flat.fill(
              background: Colors.white,
              alpha: 36,
            ),
            shape: const StadiumBorder(),
          ),
          child: SizedBox(width: vertical ? 22 : 1, height: vertical ? 1 : 28),
        ),
      ),
    );
  }

  EdgeInsets _contentPadding(double maxExtent, {required bool vertical}) {
    const baseHorizontalPadding = 8.0;
    final contentWidth =
        baseHorizontalPadding * 2 + _contentMainExtent(vertical: vertical);
    final centeringPadding = fillWidth || vertical
        ? ((maxExtent - contentWidth) / 2).clamp(0.0, double.infinity)
        : 0.0;
    if (vertical) {
      return EdgeInsets.symmetric(
        horizontal: 6,
        vertical: baseHorizontalPadding + centeringPadding,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: baseHorizontalPadding + centeringPadding,
      vertical: 6,
    );
  }

  double _contentMainExtent({required bool vertical}) {
    const itemGap = 8.0;
    const groupGap = 12.0;
    final infoExtent = chips.isEmpty
        ? 0.0
        : chips.length * infoChipExtent + (chips.length - 1) * itemGap;
    final actionExtent = _actionsMainExtent(
      vertical: vertical,
      itemGap: itemGap,
    );
    return infoExtent +
        actionExtent +
        (chips.isNotEmpty && actions.isNotEmpty ? groupGap : 0.0);
  }

  double _actionsMainExtent({required bool vertical, required double itemGap}) {
    if (actions.isEmpty) return 0;
    var extent = 0.0;
    var hasVisibleAction = false;
    var needsItemGap = false;
    for (final action in actions) {
      if (action is SelectionActionGroupBreak) {
        if (hasVisibleAction && needsItemGap) {
          extent += actionGroupBreakExtent;
          needsItemGap = false;
        }
        continue;
      }
      if (needsItemGap) extent += itemGap;
      extent += vertical ? actionChipHeight : _actionMainExtent(action);
      hasVisibleAction = true;
      needsItemGap = true;
    }
    return extent;
  }

  double _actionMainExtent(Widget action) {
    if (action is SelectionCommandChip) return action.mainExtent;
    return actionChipWidth;
  }
}

class SelectionActionGroupBreak extends StatelessWidget {
  const SelectionActionGroupBreak({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
