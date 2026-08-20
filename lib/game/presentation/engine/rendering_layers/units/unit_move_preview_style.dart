import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

/// Paint roles for the intentionally restrained movement-route language.
///
/// Reachability is communicated by motion and glow, not by changing hue:
/// history is quieter and still, this turn flows with a glow, and later turns
/// flow without a glow.
final class UnitMovePreviewStyle {
  static const Color routeColor = HudPalette.roadMarking;
  static const Color confirmedTargetColor = HudPalette.roadMarking;

  late final Paint travelledLinePaint = HudPaint.stroke(
    routeColor,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint currentTurnGlowPaint = HudPaint.stroke(
    routeColor,
    alpha: MapAlpha.full,
    strokeWidth: MapStroke.routeGlow + 2.4,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2);

  late final Paint currentTurnLinePaint = HudPaint.stroke(
    routeColor,
    alpha: MapAlpha.full,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint futureTurnLinePaint = HudPaint.stroke(
    routeColor,
    alpha: MapAlpha.full,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint routeBoundaryHaloPaint = HudPaint.fill(
    routeColor,
    alpha: MapAlpha.whisper,
  )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

  late final Paint routeBoundaryDotPaint = HudPaint.fill(
    routeColor,
    alpha: MapAlpha.opaque,
  );

  late final Paint currentTurnBoundaryBorderPaint = HudPaint.stroke(
    HudPalette.roadEdge,
    alpha: MapAlpha.strong,
    strokeWidth: 2.0,
  );

  late final Paint confirmedTargetGlowPaint = HudPaint.stroke(
    confirmedTargetColor,
    alpha: MapAlpha.soft,
    strokeWidth: MapStroke.glow + 1.4,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

  late final Paint confirmedTargetLinePaint = HudPaint.stroke(
    confirmedTargetColor,
    alpha: MapAlpha.full,
    strokeWidth: MapStroke.bold,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
}
