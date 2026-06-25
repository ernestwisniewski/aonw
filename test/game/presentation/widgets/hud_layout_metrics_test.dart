import 'package:aonw/game/presentation/widgets/hud/hud_layout_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudLayoutMetrics', () {
    test('keeps global actions out of the bottom deck on portrait phones', () {
      final metrics = HudLayoutMetrics.fromSize(
        size: const Size(390, 844),
        canShowGlobalActions: true,
        showTopResources: true,
      );

      expect(metrics.portraitPhone, isTrue);
      expect(metrics.tinyPhone, isFalse);
      expect(metrics.landscapePhone, isFalse);
      expect(metrics.tablet, isFalse);
      expect(metrics.useBottomGlobalActions, isFalse);
      expect(metrics.useSideSelectionDetail, isFalse);
      expect(metrics.useStackedTopResources, isTrue);
      expect(metrics.panelTopPadding, 132);
      expect(metrics.panelRightPadding, 12);
      expect(metrics.panelBottomPadding, 188);
      expect(metrics.bottomClusterGap, 4);
    });

    test('marks tiny phones and adds bottom cluster safe gap', () {
      final metrics = HudLayoutMetrics.fromSize(
        size: const Size(359, 720),
        canShowGlobalActions: true,
        showTopResources: true,
      );

      expect(metrics.tinyPhone, isTrue);
      expect(metrics.portraitPhone, isTrue);
      expect(metrics.landscapePhone, isFalse);
      expect(metrics.tablet, isFalse);
      expect(metrics.useBottomGlobalActions, isFalse);
      expect(metrics.useSideSelectionDetail, isFalse);
      expect(metrics.useStackedTopResources, isTrue);
      expect(metrics.bottomClusterGap, 16);
    });

    test('keeps global actions out of the bottom deck on wide layouts', () {
      final metrics = HudLayoutMetrics.fromSize(
        size: const Size(1366, 768),
        canShowGlobalActions: true,
        showTopResources: false,
      );

      expect(metrics.portraitPhone, isFalse);
      expect(metrics.tinyPhone, isFalse);
      expect(metrics.landscapePhone, isFalse);
      expect(metrics.tablet, isFalse);
      expect(metrics.useBottomGlobalActions, isFalse);
      expect(metrics.useSideSelectionDetail, isFalse);
      expect(metrics.useStackedTopResources, isFalse);
      expect(metrics.panelTopPadding, 12);
      expect(metrics.panelRightPadding, 12);
      expect(metrics.panelBottomPadding, 112);
      expect(metrics.bottomClusterGap, 4);
    });

    test('uses side detail sheets on tablets', () {
      final metrics = HudLayoutMetrics.fromSize(
        size: const Size(1024, 768),
        canShowGlobalActions: true,
        showTopResources: true,
      );

      expect(metrics.tablet, isTrue);
      expect(metrics.landscapePhone, isFalse);
      expect(metrics.useBottomGlobalActions, isFalse);
      expect(metrics.useSideSelectionDetail, isTrue);
      expect(metrics.useStackedTopResources, isFalse);
      expect(metrics.panelTopPadding, 92);
      expect(metrics.panelRightPadding, 12);
      expect(metrics.panelBottomPadding, 112);
    });

    test('keeps the toolbar in the bottom deck on landscape phones', () {
      final metrics = HudLayoutMetrics.fromSize(
        size: const Size(740, 360),
        canShowGlobalActions: true,
        showTopResources: true,
      );

      expect(metrics.landscapePhone, isTrue);
      expect(metrics.tablet, isFalse);
      expect(metrics.portraitPhone, isFalse);
      expect(metrics.useBottomGlobalActions, isFalse);
      expect(metrics.useSideSelectionDetail, isFalse);
      expect(metrics.useStackedTopResources, isFalse);
      expect(metrics.panelTopPadding, 92);
      expect(metrics.panelRightPadding, 12);
      expect(metrics.panelBottomPadding, 112);
    });

    test('stacks top resources on tall medium-width mobile layouts', () {
      final metrics = HudLayoutMetrics.fromSize(
        size: const Size(840, 1436),
        canShowGlobalActions: true,
        showTopResources: true,
      );

      expect(metrics.portraitPhone, isFalse);
      expect(metrics.landscapePhone, isFalse);
      expect(metrics.useStackedTopResources, isTrue);
      expect(metrics.panelTopPadding, 132);
    });
  });
}
