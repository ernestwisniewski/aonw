import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_style.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitMovePreviewStyle', () {
    test('encodes the three route states without legacy intent colors', () {
      final style = UnitMovePreviewStyle();

      expect(UnitMovePreviewStyle.routeColor, HudPalette.roadMarking);
      expect(UnitMovePreviewStyle.confirmedTargetColor, HudPalette.info);
      expect(style.travelledLinePaint.style, PaintingStyle.stroke);
      expect(
        style.travelledLinePaint.color.a,
        closeTo(MapAlpha.regular / MapAlpha.full, 0.001),
      );
      expect(style.currentTurnGlowPaint.color.a, 1);
      expect(style.currentTurnGlowPaint.maskFilter, isNotNull);
      expect(style.currentTurnLinePaint.color.a, 1);
      expect(style.currentTurnLinePaint.strokeWidth, MapStroke.regular);
      expect(style.futureTurnLinePaint.color.a, 1);
      expect(style.futureTurnLinePaint.maskFilter, isNull);
      expect(
        style.routeBoundaryDotPaint.color.a,
        closeTo(MapAlpha.opaque / MapAlpha.full, 0.001),
      );
      expect(
        style.currentTurnBoundaryBorderPaint.color.toARGB32(),
        HudPalette.roadEdge.withAlpha(MapAlpha.strong).toARGB32(),
      );
      expect(style.currentTurnBoundaryBorderPaint.strokeWidth, 2.0);
      expect(
        style.currentTurnGlowPaint.strokeWidth,
        greaterThan(style.currentTurnLinePaint.strokeWidth),
      );
      expect(
        style.confirmedTargetLinePaint.color.toARGB32(),
        HudPalette.info.toARGB32(),
      );
    });
  });
}
