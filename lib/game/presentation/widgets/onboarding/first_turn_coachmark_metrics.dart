import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_step.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class CoachmarkAnchorMetrics {
  const CoachmarkAnchorMetrics({
    required this.halo,
    required this.bubble,
    required this.accent,
    required this.haloRadius,
  });

  final Rect halo;
  final Rect bubble;
  final Color accent;
  final double haloRadius;

  static CoachmarkAnchorMetrics resolve(
    BuildContext context,
    CoachmarkAnchor anchor,
  ) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final wide = size.width >= 700;
    final landscapePhone = size.height < 520 && size.width > size.height;
    final bubbleWidth = wide
        ? 340.0
        : (size.width - 32).clamp(280.0, 340.0).toDouble();
    final topY = padding.top + 12;
    final bottomSafe = padding.bottom + 12;
    final bubbleMinY = topY + 10;
    final bubbleMaxY = size.height - 236;
    final fallbackHalo = _fallbackHalo(
      size: size,
      topY: topY,
      bottomSafe: bottomSafe,
      landscapePhone: landscapePhone,
      anchor: anchor,
    );
    final halo = _boundedHalo(
      (_targetRect(anchor) ?? fallbackHalo).inflate(_haloInflate(anchor)),
      size,
    );

    switch (anchor) {
      case CoachmarkAnchor.actionDeck:
        return CoachmarkAnchorMetrics(
          halo: halo,
          bubble: _bubbleAboveTarget(
            halo,
            size,
            bubbleWidth,
            bubbleMinY,
            bubbleMaxY,
          ),
          accent: GameUiTheme.goldLight,
          haloRadius: GameUiTheme.radiusCard,
        );
      case CoachmarkAnchor.topResources:
        return CoachmarkAnchorMetrics(
          halo: halo,
          bubble: _bubbleBelowTarget(halo, size, bubbleWidth, bubbleMinY),
          accent: GameUiTheme.resourcesAccent,
          haloRadius: GameUiTheme.radiusCard,
        );
      case CoachmarkAnchor.sideMenu:
        return CoachmarkAnchorMetrics(
          halo: halo,
          bubble: _bubbleBelowTarget(halo, size, bubbleWidth, bubbleMinY),
          accent: GameUiTheme.copper,
          haloRadius: GameUiTheme.radiusButton,
        );
      case CoachmarkAnchor.selectionActions:
        return CoachmarkAnchorMetrics(
          halo: halo,
          bubble: _bubbleAboveTarget(
            halo,
            size,
            bubbleWidth,
            bubbleMinY,
            bubbleMaxY,
          ),
          accent: GameUiTheme.gold,
          haloRadius: GameUiTheme.radiusCard,
        );
      case CoachmarkAnchor.bottomResearch:
        return CoachmarkAnchorMetrics(
          halo: halo,
          bubble: _bubbleAboveTarget(
            halo,
            size,
            bubbleWidth,
            bubbleMinY,
            bubbleMaxY,
          ),
          accent: GameUiTheme.scienceAccent,
          haloRadius: GameUiTheme.radiusButton,
        );
      case CoachmarkAnchor.endTurn:
        return CoachmarkAnchorMetrics(
          halo: halo,
          bubble: _bubbleAboveTarget(
            halo,
            size,
            bubbleWidth,
            bubbleMinY,
            bubbleMaxY,
          ),
          accent: GameUiTheme.success,
          haloRadius: GameUiTheme.radiusButton,
        );
    }
  }

  static double _clampY(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  static double _clampX(double value, Size size, double width) {
    final max = size.width - width - 12;
    if (max < 12) return 12;
    return value.clamp(12.0, max).toDouble();
  }

  static double _haloInflate(CoachmarkAnchor anchor) {
    return switch (anchor) {
      CoachmarkAnchor.actionDeck => 7,
      CoachmarkAnchor.topResources => 5,
      CoachmarkAnchor.sideMenu => 6,
      CoachmarkAnchor.selectionActions => 6,
      CoachmarkAnchor.bottomResearch => 5,
      CoachmarkAnchor.endTurn => 5,
    };
  }

  static Rect? _targetRect(CoachmarkAnchor anchor) {
    return switch (anchor) {
      CoachmarkAnchor.actionDeck => null,
      CoachmarkAnchor.topResources => _rectFor(
        FirstTurnCoachmarkTargets.resources,
      ),
      CoachmarkAnchor.sideMenu => _rectFor(FirstTurnCoachmarkTargets.sideMenu),
      CoachmarkAnchor.selectionActions =>
        _rectFor(FirstTurnCoachmarkTargets.selectionActions) ??
            _rectFor(FirstTurnCoachmarkTargets.actionDeck),
      CoachmarkAnchor.bottomResearch => _rectFor(
        FirstTurnCoachmarkTargets.research,
      ),
      CoachmarkAnchor.endTurn => _rectFor(FirstTurnCoachmarkTargets.endTurn),
    };
  }

  static Rect? _rectFor(GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  static Rect _fallbackHalo({
    required Size size,
    required double topY,
    required double bottomSafe,
    required bool landscapePhone,
    required CoachmarkAnchor anchor,
  }) {
    final actionDeckTop =
        size.height - bottomSafe - (landscapePhone ? 78 : 154);
    final commandTop = size.height - bottomSafe - 104;
    final compact = size.width < 360;
    final endTurnWidth = compact
        ? GameHudTheme.endTurnButtonWidthCompact
        : GameHudTheme.endTurnButtonWidthNormal;
    final commandClusterWidth = (44 * 3) + (4 * 2) + 10 + endTurnWidth;
    final commandClusterLeft = (size.width - commandClusterWidth) / 2;

    return switch (anchor) {
      CoachmarkAnchor.actionDeck => Rect.fromLTWH(
        10,
        actionDeckTop,
        size.width - 20,
        landscapePhone ? 78 : 154,
      ),
      CoachmarkAnchor.topResources => Rect.fromLTWH(
        size.width - 292,
        topY,
        280,
        44,
      ),
      CoachmarkAnchor.sideMenu => Rect.fromLTWH(8, topY + 54, 52, 240),
      CoachmarkAnchor.selectionActions => Rect.fromLTWH(
        10,
        actionDeckTop,
        size.width - 20,
        HudActionDeck.actionLineHeight,
      ),
      CoachmarkAnchor.bottomResearch => Rect.fromLTWH(
        commandClusterLeft,
        commandTop,
        44,
        44,
      ),
      CoachmarkAnchor.endTurn => Rect.fromLTWH(
        commandClusterLeft + commandClusterWidth - endTurnWidth,
        commandTop,
        endTurnWidth,
        44,
      ),
    };
  }

  static Rect _boundedHalo(Rect rect, Size size) {
    final width = rect.width.clamp(42.0, size.width - 16).toDouble();
    final height = rect.height.clamp(38.0, size.height - 16).toDouble();
    final maxLeft = size.width - width - 8;
    final maxTop = size.height - height - 8;
    return Rect.fromLTWH(
      rect.left.clamp(8.0, maxLeft < 8 ? 8.0 : maxLeft).toDouble(),
      rect.top.clamp(8.0, maxTop < 8 ? 8.0 : maxTop).toDouble(),
      width,
      height,
    );
  }

  static Rect _bubbleBelowTarget(
    Rect halo,
    Size size,
    double bubbleWidth,
    double bubbleMinY,
  ) {
    return Rect.fromLTWH(
      _clampX(halo.right - bubbleWidth, size, bubbleWidth),
      _clampY(halo.bottom + 12, bubbleMinY, size.height - 236),
      bubbleWidth,
      0,
    );
  }

  static Rect _bubbleAboveTarget(
    Rect halo,
    Size size,
    double bubbleWidth,
    double bubbleMinY,
    double bubbleMaxY,
  ) {
    return Rect.fromLTWH(
      _clampX(halo.center.dx - bubbleWidth / 2, size, bubbleWidth),
      _clampY(halo.top - 176, bubbleMinY, bubbleMaxY),
      bubbleWidth,
      0,
    );
  }
}
