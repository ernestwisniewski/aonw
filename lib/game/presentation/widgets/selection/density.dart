import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';

enum SelectionDensity { compact, comfortable }

class SelectionDensitySpec {
  const SelectionDensitySpec({
    required this.chipPadding,
    required this.chipFontSize,
    required this.chipHeight,
    required this.actionChipSize,
    required this.iconSize,
    required this.rowHeight,
    required this.sectionSpacing,
    required this.tagHeight,
    required this.tagPadding,
    required this.tagFontSize,
    required this.tagIconSize,
    required this.tagMaxWidth,
    required this.visibleTagCount,
    required this.yieldTitleFontSize,
    required this.yieldTitleGap,
    required this.yieldMetricHeight,
    required this.yieldMetricPadding,
    required this.yieldMetricGap,
    required this.yieldValueBreakpoint,
    required this.yieldIconSize,
    required this.yieldIconGap,
    required this.troopIconSize,
    required this.troopIconGap,
    required this.troopDetachButtonWidth,
    required this.troopDetachButtonHeight,
    required this.troopDetachIconSize,
    required this.selectionIconTileSize,
    required this.selectionIconSize,
  });

  final EdgeInsets chipPadding;
  final double chipFontSize;
  final double chipHeight;
  final double actionChipSize;
  final double iconSize;
  final double rowHeight;
  final double sectionSpacing;
  final double tagHeight;
  final EdgeInsets tagPadding;
  final double tagFontSize;
  final double tagIconSize;
  final double tagMaxWidth;
  final int visibleTagCount;
  final double yieldTitleFontSize;
  final double yieldTitleGap;
  final double yieldMetricHeight;
  final EdgeInsets yieldMetricPadding;
  final double yieldMetricGap;
  final double yieldValueBreakpoint;
  final double yieldIconSize;
  final double yieldIconGap;
  final double troopIconSize;
  final double troopIconGap;
  final double troopDetachButtonWidth;
  final double troopDetachButtonHeight;
  final double troopDetachIconSize;
  final double selectionIconTileSize;
  final double selectionIconSize;

  static SelectionDensitySpec of(SelectionDensity density) {
    return switch (density) {
      SelectionDensity.compact => const SelectionDensitySpec(
        chipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        chipFontSize: 11,
        chipHeight: 28,
        actionChipSize: 36,
        iconSize: GameIconSize.tiny,
        rowHeight: 32,
        sectionSpacing: 6,
        tagHeight: 23,
        tagPadding: EdgeInsets.symmetric(horizontal: 7),
        tagFontSize: 10,
        tagIconSize: GameIconSize.tiny,
        tagMaxWidth: 124,
        visibleTagCount: 1,
        yieldTitleFontSize: 9,
        yieldTitleGap: 3,
        yieldMetricHeight: 32,
        yieldMetricPadding: EdgeInsets.symmetric(horizontal: 4),
        yieldMetricGap: 4,
        yieldValueBreakpoint: 24,
        yieldIconSize: GameIconSize.tiny,
        yieldIconGap: 3,
        troopIconSize: GameIconSize.tiny,
        troopIconGap: 5,
        troopDetachButtonWidth: 28,
        troopDetachButtonHeight: 26,
        troopDetachIconSize: GameIconSize.tiny,
        selectionIconTileSize: 56,
        selectionIconSize: GameIconSize.large,
      ),
      SelectionDensity.comfortable => const SelectionDensitySpec(
        chipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        chipFontSize: 13,
        chipHeight: 36,
        actionChipSize: 48,
        iconSize: GameIconSize.regular,
        rowHeight: 44,
        sectionSpacing: 10,
        tagHeight: 28,
        tagPadding: EdgeInsets.symmetric(horizontal: 9),
        tagFontSize: 11,
        tagIconSize: GameIconSize.small,
        tagMaxWidth: 170,
        visibleTagCount: 2,
        yieldTitleFontSize: 10,
        yieldTitleGap: 4,
        yieldMetricHeight: 36,
        yieldMetricPadding: EdgeInsets.symmetric(horizontal: 7),
        yieldMetricGap: 6,
        yieldValueBreakpoint: 30,
        yieldIconSize: GameIconSize.small,
        yieldIconGap: 5,
        troopIconSize: GameIconSize.small,
        troopIconGap: 6,
        troopDetachButtonWidth: 30,
        troopDetachButtonHeight: 28,
        troopDetachIconSize: GameIconSize.small,
        selectionIconTileSize: 72,
        selectionIconSize: GameIconSize.hero,
      ),
    };
  }
}
