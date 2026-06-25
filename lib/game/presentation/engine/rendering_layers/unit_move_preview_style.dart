import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

class UnitMovePreviewStyle {
  final Color reachableColor = HudPalette.gold;
  final Color reachableGlow = HudPalette.info;
  final Color reachableCore = HudPalette.textBright;
  final Color unreachableColor = HudPalette.danger;
  final Color unreachableGlow = HudPalette.warning;
  final Color unreachableCore = HudPalette.textBright;
  final Color tradeRouteColor = HudPalette.tradeRoute;
  final Color tradeRouteGlow = HudPalette.tradeRouteGlow;

  late final Paint shadowPaint = HudPaint.stroke(
    Colors.black,
    alpha: MapAlpha.solid,
    strokeWidth: MapStroke.routeShadow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint reachableRouteGlowPaint = HudPaint.stroke(
    reachableGlow,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.routeGlow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint unreachableRouteGlowPaint = HudPaint.stroke(
    unreachableGlow,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.routeGlow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint reachableRouteLinePaint = HudPaint.stroke(
    reachableColor,
    alpha: MapAlpha.solid,
    strokeWidth: MapStroke.routeLine,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint unreachableRouteLinePaint = HudPaint.stroke(
    unreachableColor,
    alpha: MapAlpha.solid,
    strokeWidth: MapStroke.routeLine,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint reachableRouteHighlightPaint = HudPaint.stroke(
    reachableCore,
    alpha: MapAlpha.strong,
    strokeWidth: MapStroke.hairline,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint unreachableRouteHighlightPaint = HudPaint.stroke(
    unreachableCore,
    alpha: MapAlpha.strong,
    strokeWidth: MapStroke.hairline,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint reachableRouteMutedGlowPaint = HudPaint.stroke(
    reachableGlow,
    alpha: MapAlpha.whisper,
    strokeWidth: MapStroke.routeGlow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint unreachableRouteMutedGlowPaint = HudPaint.stroke(
    unreachableGlow,
    alpha: MapAlpha.whisper,
    strokeWidth: MapStroke.routeGlow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint reachableRouteMutedLinePaint = HudPaint.stroke(
    reachableColor,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint unreachableRouteMutedLinePaint = HudPaint.stroke(
    unreachableColor,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint travelledShadowPaint = HudPaint.stroke(
    Colors.black,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.glow,
    strokeCap: StrokeCap.round,
  );

  late final Paint travelledLinePaint = HudPaint.stroke(
    reachableGlow,
    alpha: MapAlpha.soft,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
  );

  late final Paint tradeRouteFocusGlowPaint = HudPaint.stroke(
    tradeRouteGlow,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.routeGlow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint tradeRouteFocusLinePaint = HudPaint.stroke(
    tradeRouteColor,
    alpha: MapAlpha.opaque,
    strokeWidth: MapStroke.routeLine,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint tradeRouteMutedGlowPaint = HudPaint.stroke(
    tradeRouteGlow,
    alpha: MapAlpha.whisper,
    strokeWidth: MapStroke.routeGlow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint tradeRouteMutedLinePaint = HudPaint.stroke(
    tradeRouteColor,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint tradeRouteFocusNodePaint = HudPaint.fill(
    tradeRouteColor,
    alpha: MapAlpha.strong,
  );

  late final Paint tradeRouteMutedNodePaint = HudPaint.fill(
    tradeRouteColor,
    alpha: MapAlpha.regular,
  );

  late final Paint reachableNodePaint = HudPaint.fill(reachableColor);
  late final Paint unreachableNodePaint = HudPaint.fill(unreachableColor);
  late final Paint reachableMutedNodePaint = HudPaint.fill(
    reachableColor,
    alpha: MapAlpha.regular,
  );
  late final Paint unreachableMutedNodePaint = HudPaint.fill(
    unreachableColor,
    alpha: MapAlpha.regular,
  );
  late final Paint labelBgPaint = HudPaint.fill(
    HudPalette.bg,
    alpha: MapAlpha.solid,
  );
  late final Paint labelBorderPaint = HudPaint.stroke(
    reachableGlow,
    alpha: MapAlpha.strong,
    strokeWidth: MapStroke.hairline,
  );
}
