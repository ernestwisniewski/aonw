import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_style.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitMovePreviewStyle', () {
    test('uses shared HUD palette and stroke paint roles', () {
      final style = UnitMovePreviewStyle();

      expect(style.reachableColor, HudPalette.gold);
      expect(style.unreachableColor, HudPalette.danger);
      expect(style.shadowPaint.style, PaintingStyle.stroke);
      expect(style.reachableRouteGlowPaint.strokeCap, StrokeCap.round);
      expect(style.unreachableRouteGlowPaint.strokeJoin, StrokeJoin.round);
      expect(style.reachableRouteLinePaint.style, PaintingStyle.stroke);
      expect(
        style.reachableRouteMutedLinePaint.color.a,
        lessThan(style.reachableRouteLinePaint.color.a),
      );
      expect(
        style.unreachableRouteMutedLinePaint.strokeWidth,
        lessThan(style.unreachableRouteLinePaint.strokeWidth),
      );
      expect(style.unreachableRouteHighlightPaint.strokeWidth, 1);
      expect(style.reachableNodePaint.style, PaintingStyle.fill);
      expect(
        style.reachableMutedNodePaint.color.a,
        lessThan(style.reachableNodePaint.color.a),
      );
      expect(style.labelBorderPaint.style, PaintingStyle.stroke);
    });
  });
}
