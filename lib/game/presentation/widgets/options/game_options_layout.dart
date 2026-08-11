import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/hud/layout/hud_side_menu_metrics.dart';
import 'package:flutter/material.dart';

const _wideActionDeckMaxWidth = 840.0;
const _expandedActionDeckReserve = 188.0;

class GameOptionsOverlayLayout {
  const GameOptionsOverlayLayout({
    required this.buttonLeft,
    required this.buttonTop,
    required this.buttonStep,
    required this.helpButtonTop,
    required this.panelLeft,
    required this.panelTop,
    required this.panelWidth,
    required this.sidePanelWidth,
    required this.panelMaxHeight,
    required this.helpPanelTop,
    required this.helpPanelMaxHeight,
    required this.closedContentTop,
    required this.closedContentRight,
    required this.closedContentMaxWidth,
    required this.closedContentMaxHeight,
  });

  final double buttonLeft;
  final double buttonTop;
  final double buttonStep;
  final double helpButtonTop;
  final double panelLeft;
  final double panelTop;
  final double panelWidth;
  final double sidePanelWidth;
  final double panelMaxHeight;
  final double helpPanelTop;
  final double helpPanelMaxHeight;
  final double closedContentTop;
  final double closedContentRight;
  final double closedContentMaxWidth;
  final double closedContentMaxHeight;

  double sideActionButtonTop(int index) => buttonTop + buttonStep * (index + 1);

  factory GameOptionsOverlayLayout.resolve({
    required Size size,
    required EdgeInsets safePadding,
    required bool hasResignAction,
    required int sideActionCount,
  }) {
    final safeWidth = math.max(0.0, size.width - safePadding.horizontal);
    final safeHeight = math.max(0.0, size.height - safePadding.vertical);
    final portraitPhone = safeWidth < 520 && safeHeight >= safeWidth;
    final landscapePhone = safeHeight < 520 && safeWidth > safeHeight;
    final compact = portraitPhone || landscapePhone || safeWidth < 700;
    final margin = compact ? 8.0 : 10.0;
    final safeLeft = safePadding.left + margin;
    final safeTop = safePadding.top;
    final safeRight = safePadding.right + (compact ? 10.0 : 12.0);
    final avatarCompact = HudSideMenuMetrics.useCompactTop(
      width: safeWidth,
      height: safeHeight,
    );
    final buttonTop =
        safeTop +
        (avatarCompact
            ? HudSideMenuMetrics.compactTopOffset
            : HudSideMenuMetrics.topOffset);
    final buttonStep = landscapePhone ? 44.0 : 48.0;
    final helpButtonTop = buttonTop + buttonStep * (sideActionCount + 1);
    const buttonExtent = 44.0;
    final panelGap = compact ? 8.0 : 10.0;
    final panelLeft = safeLeft + buttonExtent + panelGap;
    final panelTop = buttonTop;
    final helpPanelTop = helpButtonTop;
    final availablePanelWidth =
        size.width - safePadding.right - margin - panelLeft;
    final maxPanelWidth = math.max(120.0, availablePanelWidth);
    final targetPanelWidth = portraitPhone
        ? 286.0
        : landscapePhone
        ? 280.0
        : 292.0;
    final targetSidePanelWidth = portraitPhone
        ? 286.0
        : landscapePhone
        ? 280.0
        : 292.0;
    final panelWidth = math.min(targetPanelWidth, maxPanelWidth);
    final sidePanelWidth = math.min(targetSidePanelWidth, maxPanelWidth);

    final panelHeights = _panelHeights(
      size: size,
      safePadding: safePadding,
      safeWidth: safeWidth,
      panelLeft: panelLeft,
      panelWidth: panelWidth,
      panelTop: panelTop,
      helpPanelTop: helpPanelTop,
      portraitPhone: portraitPhone,
      landscapePhone: landscapePhone,
      hasResignAction: hasResignAction,
    );
    final closedContentTop = buttonTop;
    final closedContentBottomReserve = landscapePhone ? 92.0 : 18.0;
    final closedContentMaxHeight = math.max(
      80.0,
      size.height -
          safePadding.bottom -
          closedContentTop -
          closedContentBottomReserve,
    );

    return GameOptionsOverlayLayout(
      buttonLeft: safeLeft,
      buttonTop: buttonTop,
      buttonStep: buttonStep,
      helpButtonTop: helpButtonTop,
      panelLeft: panelLeft,
      panelTop: panelTop,
      panelWidth: panelWidth,
      sidePanelWidth: sidePanelWidth,
      panelMaxHeight: panelHeights.panel,
      helpPanelTop: helpPanelTop,
      helpPanelMaxHeight: panelHeights.help,
      closedContentTop: closedContentTop,
      closedContentRight: safeRight,
      closedContentMaxWidth: math.max(48.0, safeWidth * 0.4),
      closedContentMaxHeight: closedContentMaxHeight,
    );
  }
}

({double panel, double help}) _panelHeights({
  required Size size,
  required EdgeInsets safePadding,
  required double safeWidth,
  required double panelLeft,
  required double panelWidth,
  required double panelTop,
  required double helpPanelTop,
  required bool portraitPhone,
  required bool landscapePhone,
  required bool hasResignAction,
}) {
  // Reserve the action deck only while it overlaps the options panel.
  final actionDeckWidth = math.min(_wideActionDeckMaxWidth, safeWidth);
  final actionDeckLeft = safePadding.left + (safeWidth - actionDeckWidth) / 2;
  final panelOverlapsActionDeck = panelLeft + panelWidth > actionDeckLeft;
  final bottomReserve = landscapePhone
      ? 92.0
      : panelOverlapsActionDeck
      ? _expandedActionDeckReserve
      : 24.0;
  final baseHeightCap = landscapePhone
      ? 420.0
      : portraitPhone
      ? 560.0
      : 720.0;
  final heightCap = baseHeightCap + (hasResignAction ? 56.0 : 0.0);
  final availablePanelHeight =
      size.height - safePadding.bottom - panelTop - bottomReserve;
  final availableHelpPanelHeight =
      size.height - safePadding.bottom - helpPanelTop - bottomReserve;
  return (
    panel: math.max(112.0, math.min(heightCap, availablePanelHeight)),
    help: math.max(96.0, math.min(260.0, availableHelpPanelHeight)),
  );
}
