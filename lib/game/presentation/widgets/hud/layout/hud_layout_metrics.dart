import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:flutter/material.dart';

class HudLayoutMetrics {
  static const double tinyPhoneWidth = 360;
  static const double landscapePhoneHeight = 520;
  static const double tabletShortestSide = 600;
  static const double tabletLongestSide = 1200;

  final bool tinyPhone;
  final bool landscapePhone;
  final bool tablet;
  final bool portraitPhone;
  final bool useBottomGlobalActions;
  final bool useSideSelectionDetail;
  final bool showTopResources;
  final bool useStackedTopResources;
  final double panelTopPadding;
  final double panelRightPadding;
  final double panelBottomPadding;
  final double bottomClusterGap;

  const HudLayoutMetrics({
    required this.tinyPhone,
    required this.landscapePhone,
    required this.tablet,
    required this.portraitPhone,
    required this.useBottomGlobalActions,
    required this.useSideSelectionDetail,
    required this.showTopResources,
    required this.useStackedTopResources,
    required this.panelTopPadding,
    required this.panelRightPadding,
    required this.panelBottomPadding,
    required this.bottomClusterGap,
  });

  factory HudLayoutMetrics.fromSize({
    required Size size,
    required bool canShowGlobalActions,
    required bool showTopResources,
  }) {
    final tinyPhone = size.width < tinyPhoneWidth;
    final landscapePhone =
        size.height < landscapePhoneHeight && size.width > size.height;
    final tablet =
        size.shortestSide >= tabletShortestSide &&
        size.longestSide < tabletLongestSide;
    final portraitPhone = size.width < 520 && size.height >= size.width;
    const useBottomGlobalActions = false;
    final useSideSelectionDetail = tablet && !landscapePhone;
    final useStackedTopResources =
        showTopResources && size.width < 900 && size.height >= size.width;
    final panelBottomPadding = portraitPhone
        ? HudActionDeck.expandedBottomPadding
        : 112.0;

    return HudLayoutMetrics(
      tinyPhone: tinyPhone,
      landscapePhone: landscapePhone,
      tablet: tablet,
      portraitPhone: portraitPhone,
      useBottomGlobalActions: useBottomGlobalActions,
      useSideSelectionDetail: useSideSelectionDetail,
      showTopResources: showTopResources,
      useStackedTopResources: useStackedTopResources,
      panelTopPadding: showTopResources
          ? useStackedTopResources
                ? 132.0
                : 92.0
          : 12.0,
      panelRightPadding: 12.0,
      panelBottomPadding: panelBottomPadding,
      bottomClusterGap: tinyPhone ? 16.0 : 4.0,
    );
  }

  EdgeInsets get panelPadding => EdgeInsets.fromLTRB(
    66,
    panelTopPadding,
    panelRightPadding,
    panelBottomPadding,
  );

  double get contextualHintLeftPadding => panelPadding.left;
}
