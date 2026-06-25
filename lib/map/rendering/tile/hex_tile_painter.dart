import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_icon_badge.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HexTilePainter {
  final bool outlineOnlyTopFace;
  final int tileHeight;

  late final Paint _paintTop;
  late final Paint? _paintOutline;
  late final _WallPaints _wallPaints;
  late final Paint _paintIconDot;
  late final Paint _paintSelectionDash;
  late final Paint _paintCitySiteMarker;
  late final Paint _paintCityGrowthMarker;
  late final Paint _paintWorkerImprovementNowMarker;
  late final Paint _paintWorkerImprovementTechMarker;
  late final Paint _paintWorkerImprovementCandidateGlow;
  late final Paint _paintWorkerImprovementCandidateBorder;
  late final Paint _paintWorkerImprovementCandidateIconBg;
  late final Paint _paintAttackTargetMarker;
  late final Paint _paintMovementBlockerOverlay;
  late final Paint _paintMovementBlockerOutline;
  late final ui.Paragraph _heightParagraph;

  static final _paintMapIconImage = Paint()
    ..filterQuality = FilterQuality.medium;
  static final _paintBadgeBg = HudPaint.fill(
    HudPalette.surface,
    alpha: _heightBadgeBackgroundAlpha,
  );
  static final _paintBadgeBorder = HudPaint.stroke(
    HudPalette.gold,
    alpha: _heightBadgeBorderAlpha,
    strokeWidth: 1.1,
  );

  static const double _selectionDash = 6.0;
  static const double _selectionGap = 4.0;
  static const double _intentMarkerPairGap = 4.0;
  static const double _heightBadgeParagraphWidth = 16.0;
  static const int _heightBadgeBackgroundAlpha = 238;
  static const int _heightBadgeBorderAlpha = 230;
  static const int _citySiteMarkerAlpha = 238;
  static const int _planningMarkerAlpha = 214;
  static const int _attackMarkerAlpha = 222;
  static const int _movementBlockerAlpha = 86;
  static const int _movementBlockerOutlineAlpha = 210;
  static const int _shadowAlpha = 153;

  HexTilePainter({
    required Color topColor,
    required this.outlineOnlyTopFace,
    required Color outlineColor,
    required Color selectionColor,
    required Color wallTintColor,
    required this.tileHeight,
  }) {
    _paintTop = HudPaint.fill(topColor);
    _paintOutline = _strokePaintOrNull(outlineColor, strokeWidth: 0.8);
    _paintSelectionDash = HudPaint.stroke(
      selectionColor,
      strokeWidth: MapStroke.bold,
      strokeCap: StrokeCap.round,
    );
    _wallPaints = _WallPaints.fromTint(wallTintColor);
    _paintIconDot = HudPaint.fill(HudPalette.goldLight, alpha: MapAlpha.strong);
    _paintCitySiteMarker = HudPaint.fill(
      HudPalette.goldLight,
      alpha: _citySiteMarkerAlpha,
    );
    _paintCityGrowthMarker = HudPaint.fill(HudPalette.successLight);
    _paintWorkerImprovementNowMarker = HudPaint.fill(
      HudPalette.success,
      alpha: _planningMarkerAlpha,
    );
    _paintWorkerImprovementTechMarker = HudPaint.fill(
      HudPalette.gold,
      alpha: _planningMarkerAlpha,
    );
    _paintWorkerImprovementCandidateGlow =
        HudPaint.stroke(
            HudPalette.success,
            alpha: MapAlpha.regular,
            strokeWidth: MapStroke.glow,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    _paintWorkerImprovementCandidateBorder =
        HudPaint.stroke(
            HudPalette.successLight,
            alpha: MapAlpha.opaque,
            strokeWidth: MapStroke.thin,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    _paintWorkerImprovementCandidateIconBg = HudPaint.fill(
      HudPalette.bg,
      alpha: MapAlpha.strong,
    );
    _paintAttackTargetMarker = HudPaint.fill(
      HudPalette.danger,
      alpha: _attackMarkerAlpha,
    );
    _paintMovementBlockerOverlay = HudPaint.fill(
      HudPalette.danger,
      alpha: _movementBlockerAlpha,
    );
    _paintMovementBlockerOutline = HudPaint.stroke(
      HudPalette.danger,
      alpha: _movementBlockerOutlineAlpha,
      strokeWidth: 1.5,
    );
    _heightParagraph = _createHeightParagraph(tileHeight);
  }

  double get heightParagraphHeight => _heightParagraph.height;

  void render({
    required Canvas canvas,
    required HexTileGeometrySnapshot geometry,
    required bool isSelected,
    required bool showIcon,
    required bool showTerrain,
    required bool showResources,
    required bool showCitySiteMarker,
    required bool showRecommendedCitySiteMarker,
    required bool showCityGrowthMarker,
    required bool showWorkerImprovementNowMarker,
    required bool showWorkerImprovementTechMarker,
    required bool showWorkerImprovementCandidateMarker,
    required bool showWorkerBuildAvailableBorder,
    required bool showWorkerBuildBlockedBorder,
    required bool showAttackTargetMarker,
    required bool showHeightBadge,
    required bool alwaysShowHeight,
    bool showMovementBlockerOverlay = false,
    required HexTileOverlayGeometry overlays,
    required List<String> terrainIconPaths,
    required List<String> resourceIconPaths,
    required double heightPerspectiveY,
  }) {
    _drawWalls(canvas, geometry);
    _drawTopFace(canvas, geometry);

    if (showMovementBlockerOverlay) {
      _drawMovementBlockerOverlay(canvas, geometry);
    }

    if (showWorkerImprovementCandidateMarker) {
      _drawWorkerImprovementCandidateMarker(canvas, geometry);
    }

    if (showWorkerBuildAvailableBorder) {
      _drawWorkerBuildBorder(
        canvas,
        geometry,
        color: HudPalette.successLight,
        glow: HudPalette.success,
        glyph: MapIntentGlyph.improve,
      );
    } else if (showWorkerBuildBlockedBorder) {
      _drawWorkerBuildBorder(
        canvas,
        geometry,
        color: HudPalette.danger,
        glow: HudPalette.warning,
        glyph: MapIntentGlyph.unavailable,
      );
    }

    if (isSelected) _drawSelectionOutline(canvas, geometry);

    if (showHeightBadge && (alwaysShowHeight || tileHeight > 0)) {
      _drawHeightBadge(
        canvas: canvas,
        rect: overlays.heightBadge.badgeRect,
        paragraphOffset: overlays.heightBadge.paragraphOffset,
        perspectiveY: heightPerspectiveY,
      );
    }

    if (showIcon && showTerrain) {
      _drawIconBox(
        canvas: canvas,
        box: overlays.terrainIcons.boxRect,
        badges: overlays.terrainIcons.badgeRects,
        iconRects: overlays.terrainIcons.iconRects,
        iconPaths: terrainIconPaths,
        accent: HudPalette.textMuted,
      );
    }
    if (showIcon && showResources) {
      _drawResourceIcons(
        canvas: canvas,
        box: overlays.resourceIcons.boxRect,
        badges: overlays.resourceIcons.badgeRects,
        iconRects: overlays.resourceIcons.iconRects,
        iconPaths: resourceIconPaths,
        accent: HudPalette.resourcesAccent,
      );
    }

    if (showCitySiteMarker ||
        showCityGrowthMarker ||
        showWorkerImprovementNowMarker ||
        showWorkerImprovementTechMarker ||
        showAttackTargetMarker) {
      final hasMapInfo =
          showIcon &&
          ((showTerrain && terrainIconPaths.isNotEmpty) ||
              (showResources && resourceIconPaths.isNotEmpty));
      _drawPlanningMarkers(
        canvas: canvas,
        geometry: geometry,
        avoidMapInfo: hasMapInfo,
        showCitySiteMarker: showCitySiteMarker,
        showRecommendedCitySiteMarker: showRecommendedCitySiteMarker,
        showCityGrowthMarker: showCityGrowthMarker,
        showWorkerImprovementNowMarker: showWorkerImprovementNowMarker,
        showWorkerImprovementTechMarker: showWorkerImprovementTechMarker,
        showWorkerImprovementCandidateMarker:
            showWorkerImprovementCandidateMarker,
        showAttackTargetMarker: showAttackTargetMarker,
      );
    }
  }

  static ui.Paragraph _createHeightParagraph(int tileHeight) {
    return (ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: 10,
              height: 1.0,
              fontWeight: ui.FontWeight.w800,
              textAlign: TextAlign.center,
            ),
          )
          ..pushStyle(ui.TextStyle(color: HudPalette.textBright))
          ..addText('$tileHeight'))
        .build()
      ..layout(
        const ui.ParagraphConstraints(width: _heightBadgeParagraphWidth),
      );
  }

  void _drawWalls(Canvas canvas, HexTileGeometrySnapshot geometry) {
    if (!_wallPaints.visible) return;
    if (outlineOnlyTopFace) {
      _drawOutlineWallFills(canvas, geometry);
      return;
    }

    final right = geometry.wallPaths[0];
    if (right != null) canvas.drawPath(right, _wallPaints.right);
    final bottom = geometry.wallPaths[1];
    if (bottom != null) canvas.drawPath(bottom, _wallPaints.bottom);
    final left = geometry.wallPaths[2];
    if (left != null) canvas.drawPath(left, _wallPaints.left);
  }

  void _drawOutlineWallFills(Canvas canvas, HexTileGeometrySnapshot geometry) {
    for (var edge = 0; edge < geometry.wallPaths.length; edge++) {
      final wall = geometry.wallPaths[edge];
      if (wall == null) continue;
      canvas.drawPath(wall, _wallPaints.outlineFill(edge));
    }
  }

  void _drawTopFace(Canvas canvas, HexTileGeometrySnapshot geometry) {
    if (outlineOnlyTopFace) {
      _drawTopOutline(canvas, geometry);
      return;
    }
    canvas.drawPath(geometry.topPath, _paintTop);
    _drawTopOutline(canvas, geometry);
  }

  void _drawTopOutline(Canvas canvas, HexTileGeometrySnapshot geometry) {
    final outlinePaint = _paintOutline;

    final corners = geometry.topCorners;
    for (var edge = 0; edge < corners.length; edge++) {
      if (!geometry.topOutlineEdges[edge]) continue;
      final edgePaint = _topOutlinePaintForEdge(geometry, edge, outlinePaint);
      if (edgePaint == null) continue;
      final from = corners[edge];
      final to = corners[(edge + 1) % corners.length];
      canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), edgePaint);
    }
  }

  Paint? _topOutlinePaintForEdge(
    HexTileGeometrySnapshot geometry,
    int edge,
    Paint? outlinePaint,
  ) {
    if (!outlineOnlyTopFace || edge >= geometry.wallPaths.length) {
      return outlinePaint;
    }
    if (geometry.wallPaths[edge] == null || !_wallPaints.visible) {
      return outlinePaint;
    }
    if (outlinePaint == null) return _wallPaints.outlineEdge(edge);
    return _wallPaints.mergedOutlineEdge(edge, outlinePaint);
  }

  void _drawMovementBlockerOverlay(
    Canvas canvas,
    HexTileGeometrySnapshot geometry,
  ) {
    canvas
      ..drawPath(geometry.topPath, _paintMovementBlockerOverlay)
      ..drawPath(geometry.topPath, _paintMovementBlockerOutline);
  }

  void _drawWorkerBuildBorder(
    Canvas canvas,
    HexTileGeometrySnapshot geometry, {
    required Color color,
    required Color glow,
    required MapIntentGlyph glyph,
  }) {
    final path = _innerTopPath(geometry, scale: 0.82);
    canvas
      ..drawPath(
        path,
        HudPaint.stroke(
            glow,
            alpha: MapAlpha.regular,
            strokeWidth: MapStroke.glow,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        path,
        HudPaint.stroke(
            Colors.black,
            alpha: MapAlpha.strong,
            strokeWidth: MapStroke.bold,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        path,
        HudPaint.stroke(
            color,
            alpha: MapAlpha.opaque,
            strokeWidth: MapStroke.regular + 0.5,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    _drawIntentBadge(
      canvas,
      geometry.topCenter.translate(0, 8),
      color: color,
      glow: glow,
      glyph: glyph,
    );
  }

  void _drawWorkerImprovementCandidateMarker(
    Canvas canvas,
    HexTileGeometrySnapshot geometry,
  ) {
    final path = _innerTopPath(geometry, scale: 0.68);
    final center = geometry.topCenter.translate(0, 1);
    canvas
      ..drawPath(path, _paintWorkerImprovementCandidateGlow)
      ..drawPath(path, _paintWorkerImprovementCandidateBorder)
      ..drawCircle(center, 8.5, _paintWorkerImprovementCandidateIconBg)
      ..drawCircle(
        center,
        8.5,
        HudPaint.stroke(
          HudPalette.goldLight,
          alpha: MapAlpha.strong,
          strokeWidth: MapStroke.hairline,
        ),
      );
    MapIntentMarker.paintGlyph(
      canvas,
      center,
      MapIntentGlyph.improve,
      scale: 1.12,
    );
  }

  Path _innerTopPath(
    HexTileGeometrySnapshot geometry, {
    required double scale,
  }) {
    final center = geometry.topCenter;
    final corners = geometry.topCorners
        .map((corner) {
          return Offset(
            center.dx + (corner.x - center.dx) * scale,
            center.dy + (corner.y - center.dy) * scale,
          );
        })
        .toList(growable: false);
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    return path..close();
  }

  void _drawSelectionOutline(Canvas canvas, HexTileGeometrySnapshot geometry) {
    final topCorners = geometry.topCorners;
    for (int i = 0; i < topCorners.length; i++) {
      _drawDashedLine(canvas, topCorners[i], topCorners[(i + 1) % 6]);
    }
  }

  void _drawDashedLine(Canvas canvas, Vector2 from, Vector2 to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len;
    final uy = dy / len;
    double travelled = 0.0;
    bool drawing = true;
    while (travelled < len) {
      final segLen = drawing ? _selectionDash : _selectionGap;
      final end = math.min(travelled + segLen, len);
      if (drawing) {
        canvas.drawLine(
          Offset(from.x + ux * travelled, from.y + uy * travelled),
          Offset(from.x + ux * end, from.y + uy * end),
          _paintSelectionDash,
        );
      }
      travelled = end;
      drawing = !drawing;
    }
  }

  void _drawPlanningMarkers({
    required Canvas canvas,
    required HexTileGeometrySnapshot geometry,
    required bool avoidMapInfo,
    required bool showCitySiteMarker,
    required bool showRecommendedCitySiteMarker,
    required bool showCityGrowthMarker,
    required bool showWorkerImprovementNowMarker,
    required bool showWorkerImprovementTechMarker,
    required bool showWorkerImprovementCandidateMarker,
    required bool showAttackTargetMarker,
  }) {
    if (showAttackTargetMarker) {
      _drawAttackTargetMarker(canvas, geometry.topCenter.translate(0, 6));
      return;
    }
    final hexRadius = _hexRadiusFor(geometry);
    final cityAnchor = avoidMapInfo
        ? geometry.topCenter.translate(hexRadius * 0.16, -hexRadius * 0.55)
        : geometry.topCenter.translate(0, -6);
    final cityMarkerCenters = _cityPlanningMarkerCenters(
      topCenter: cityAnchor,
      showCitySiteMarker: showCitySiteMarker,
      showCityGrowthMarker: showCityGrowthMarker,
    );
    if (showCitySiteMarker) {
      _drawCitySiteMarker(
        canvas,
        cityMarkerCenters.citySite!,
        recommended: showRecommendedCitySiteMarker,
      );
    }
    if (showCityGrowthMarker) {
      _drawCityGrowthMarker(canvas, cityMarkerCenters.cityGrowth!);
    }
    if (showWorkerImprovementNowMarker &&
        !showWorkerImprovementCandidateMarker) {
      _drawWorkerImprovementMarker(
        canvas,
        geometry.topCenter.translate(-9, 13),
        _paintWorkerImprovementNowMarker,
      );
    }
    if (showWorkerImprovementTechMarker) {
      _drawWorkerImprovementMarker(
        canvas,
        geometry.topCenter.translate(9, 13),
        _paintWorkerImprovementTechMarker,
      );
    }
  }

  double _hexRadiusFor(HexTileGeometrySnapshot geometry) {
    final center = geometry.topCenter;
    final corner = geometry.topCorners.first;
    final dx = corner.x - center.dx;
    final dy = corner.y - center.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  ({Offset? citySite, Offset? cityGrowth}) _cityPlanningMarkerCenters({
    required Offset topCenter,
    required bool showCitySiteMarker,
    required bool showCityGrowthMarker,
  }) {
    if (showCitySiteMarker && showCityGrowthMarker) {
      const offset =
          (MapIntentMarker.defaultBadgeSize + _intentMarkerPairGap) / 2;
      return (
        citySite: topCenter.translate(-offset, 0),
        cityGrowth: topCenter.translate(offset, 0),
      );
    }
    if (showCitySiteMarker) {
      return (citySite: topCenter, cityGrowth: null);
    }
    if (showCityGrowthMarker) {
      return (citySite: null, cityGrowth: topCenter);
    }
    return (citySite: null, cityGrowth: null);
  }

  void _drawAttackTargetMarker(Canvas canvas, Offset center) {
    _drawIntentBadge(
      canvas,
      center,
      color: _paintAttackTargetMarker.color,
      glow: HudPalette.warning,
      glyph: MapIntentGlyph.attack,
    );
  }

  void _drawCitySiteMarker(
    Canvas canvas,
    Offset center, {
    required bool recommended,
  }) {
    _drawIntentBadge(
      canvas,
      center,
      color: recommended ? HudPalette.successLight : _paintCitySiteMarker.color,
      glow: recommended ? HudPalette.success : HudPalette.gold,
      backgroundColor: recommended ? HudPalette.success : null,
      borderColor: recommended ? HudPalette.successLight : null,
      glyph: MapIntentGlyph.city,
    );
  }

  void _drawCityGrowthMarker(Canvas canvas, Offset center) {
    _drawIntentBadge(
      canvas,
      center,
      color: _paintCityGrowthMarker.color,
      glow: HudPalette.success,
      glyph: MapIntentGlyph.growth,
    );
  }

  void _drawWorkerImprovementMarker(
    Canvas canvas,
    Offset center,
    Paint markerPaint,
  ) {
    _drawIntentBadge(
      canvas,
      center,
      color: markerPaint.color,
      glow: markerPaint.color,
      glyph: MapIntentGlyph.improve,
      size: MapIntentMarker.compactBadgeSize,
    );
  }

  void _drawIntentBadge(
    Canvas canvas,
    Offset center, {
    required Color color,
    required Color glow,
    required MapIntentGlyph glyph,
    Color? backgroundColor,
    Color? borderColor,
    double size = MapIntentMarker.defaultBadgeSize,
  }) {
    MapIntentMarker.paintBadge(
      canvas,
      center,
      color: color,
      glow: glow,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      glyph: glyph,
      size: size,
    );
  }

  void _drawIconBox({
    required Canvas canvas,
    required RRect? box,
    required List<RRect> badges,
    required List<Rect> iconRects,
    required List<String> iconPaths,
    required Color accent,
  }) {
    if (box == null) return;
    MapIconBadgePainter.paintTray(canvas, box, accent: accent);
    final count = math.min(iconPaths.length, iconRects.length);
    for (int i = 0; i < count; i++) {
      final badge = i < badges.length
          ? badges[i]
          : _badgeForIconRect(iconRects[i]);
      MapIconBadgePainter.paintBadge(canvas, badge, accent: accent);
      _drawIcon(canvas, iconPaths[i], iconRects[i], clip: badge.deflate(3.0));
    }
  }

  void _drawResourceIcons({
    required Canvas canvas,
    required RRect? box,
    required List<RRect> badges,
    required List<Rect> iconRects,
    required List<String> iconPaths,
    required Color accent,
  }) {
    if (badges.isEmpty) return;
    if (box != null) {
      MapIconBadgePainter.paintTray(canvas, box, accent: accent);
    }
    final count = math.min(iconPaths.length, badges.length);
    for (int i = 0; i < count; i++) {
      final badge = badges[i];
      MapIconBadgePainter.paintBadge(
        canvas,
        badge,
        accent: accent,
        prominent: true,
      );
      _drawIcon(canvas, iconPaths[i], iconRects[i], clip: badge.deflate(4.0));
    }
  }

  void _drawIcon(Canvas canvas, String path, Rect iconRect, {RRect? clip}) {
    final image = HexIconCache.imageFor(path);
    final sourceRect = HexIconCache.sourceRectFor(path);
    if (image != null && sourceRect != null) {
      if (clip != null) {
        canvas
          ..save()
          ..clipRRect(clip)
          ..drawImageRect(image, sourceRect, iconRect, _paintMapIconImage)
          ..restore();
        return;
      }
      canvas.drawImageRect(image, sourceRect, iconRect, _paintMapIconImage);
    } else {
      canvas.drawCircle(iconRect.center, iconRect.width / 2, _paintIconDot);
    }
  }

  RRect _badgeForIconRect(Rect iconRect) {
    return RRect.fromRectAndRadius(
      iconRect.inflate(3.0),
      Radius.circular((iconRect.width + 6.0) * 0.32),
    );
  }

  void _drawHeightBadge({
    required Canvas canvas,
    required RRect? rect,
    required Offset paragraphOffset,
    required double perspectiveY,
  }) {
    if (rect == null) return;

    _drawRRectShadow(canvas, rect, 2.5);
    canvas
      ..drawRRect(rect, _paintBadgeBg)
      ..drawRRect(rect, _paintBadgeBorder)
      ..save()
      ..scale(1.0, 1.0 / perspectiveY)
      ..drawParagraph(_heightParagraph, paragraphOffset)
      ..restore();
  }

  void _drawRRectShadow(Canvas canvas, RRect rect, double elevation) {
    canvas.drawShadow(
      Path()..addRRect(rect),
      HudPaint.color(Colors.black, alpha: _shadowAlpha),
      elevation,
      true,
    );
  }

  static Paint? _strokePaintOrNull(Color color, {required double strokeWidth}) {
    if (!_paintsColor(color)) return null;
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
  }

  static bool _paintsColor(Color color) {
    return (color.a * 255).round() > 0;
  }
}

class _WallPaints {
  final Paint right;
  final Paint bottom;
  final Paint left;
  final Color rightColor;
  final Color bottomColor;
  final Color leftColor;
  final bool visible;

  _WallPaints.fromTint(Color tint)
    : visible = HexTilePainter._paintsColor(tint),
      rightColor = _wallShade(tint, 0.10),
      bottomColor = tint,
      leftColor = _wallShade(tint, 0.20),
      right = HudPaint.fill(_wallShade(tint, 0.10)),
      bottom = HudPaint.fill(tint),
      left = HudPaint.fill(_wallShade(tint, 0.20));

  Paint outlineEdge(int edge) {
    return switch (edge) {
      0 => _outlineEdgePaint(rightColor, strokeWidth: 0.8),
      1 => _outlineEdgePaint(bottomColor, strokeWidth: 0.8),
      2 => _outlineEdgePaint(leftColor, strokeWidth: 0.8),
      _ => _outlineEdgePaint(bottomColor, strokeWidth: 0.8),
    };
  }

  Paint outlineFill(int edge) {
    final wallColor = switch (edge) {
      0 => rightColor,
      1 => bottomColor,
      2 => leftColor,
      _ => bottomColor,
    };
    return Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false
      ..color = wallColor;
  }

  Paint mergedOutlineEdge(int edge, Paint outlinePaint) {
    final wallColor = switch (edge) {
      0 => rightColor,
      1 => bottomColor,
      2 => leftColor,
      _ => bottomColor,
    };
    final mergedColor = Color.alphaBlend(wallColor, outlinePaint.color);
    return _outlineEdgePaint(
      mergedColor,
      strokeWidth: outlinePaint.strokeWidth,
    );
  }

  static Paint _outlineEdgePaint(Color color, {required double strokeWidth}) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..color = color;
  }

  static Color _wallShade(Color tint, double amount) {
    return Color.lerp(
      tint,
      HudPalette.textBright.withValues(alpha: tint.a),
      amount,
    )!;
  }
}
