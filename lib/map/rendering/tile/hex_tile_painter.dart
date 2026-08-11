import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/hex_outline_painter.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_icon_badge.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

part 'hex_tile_icon_rendering.dart';
part 'hex_tile_planning_markers.dart';
part 'hex_tile_surface_rendering.dart';

class HexTilePainter {
  final bool outlineOnlyTopFace;
  final int tileHeight;

  late final Paint _paintTop;
  late final Paint? _paintOutline;
  late final _WallPaints _wallPaints;
  late final Paint _paintIconDot;
  late final Paint _paintSelectionDash;
  late final Paint _paintCitySiteCompactFill;
  late final Paint _paintCitySiteCompactBorder;
  late final Paint _paintCityGrowthMarker;
  late final Paint _paintWorkerImprovementNowMarker;
  late final Paint _paintWorkerImprovementCandidateFill;
  late final Paint _paintWorkerImprovementCandidateBorder;
  late final Paint _paintWorkerImprovementTechFill;
  late final Paint _paintWorkerImprovementTechBorder;
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

  static const double _intentMarkerPairGap = 4.0;
  static const double _heightBadgeParagraphWidth = 16.0;
  static const int _heightBadgeBackgroundAlpha = 238;
  static const int _heightBadgeBorderAlpha = 230;
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
    _paintCitySiteCompactFill = HudPaint.fill(
      HudPalette.surface,
      alpha: MapAlpha.strong,
    );
    _paintCitySiteCompactBorder = HudPaint.stroke(
      HudPalette.goldLight,
      alpha: MapAlpha.opaque,
      strokeWidth: MapStroke.thin,
    );
    _paintCityGrowthMarker = HudPaint.fill(HudPalette.successLight);
    _paintWorkerImprovementNowMarker = HudPaint.fill(
      HudPalette.success,
      alpha: _planningMarkerAlpha,
    );
    _paintWorkerImprovementCandidateFill = HudPaint.fill(
      HudPalette.success,
      alpha: MapAlpha.whisper,
    );
    _paintWorkerImprovementCandidateBorder =
        HudPaint.stroke(
            HudPalette.successLight,
            alpha: MapAlpha.strong,
            strokeWidth: MapStroke.thin,
          )
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    _paintWorkerImprovementTechFill = HudPaint.fill(
      HudPalette.gold,
      alpha: MapAlpha.whisper,
    );
    _paintWorkerImprovementTechBorder = HudPaint.stroke(
      HudPalette.goldLight,
      alpha: MapAlpha.strong,
      strokeWidth: MapStroke.hairline,
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

    _drawVisiblePlanningMarkers(
      canvas: canvas,
      geometry: geometry,
      showIcon: showIcon,
      showTerrain: showTerrain,
      showResources: showResources,
      terrainIconPaths: terrainIconPaths,
      resourceIconPaths: resourceIconPaths,
      visibility: (
        citySite: showCitySiteMarker,
        recommendedCitySite: showRecommendedCitySiteMarker,
        cityGrowth: showCityGrowthMarker,
        workerNow: showWorkerImprovementNowMarker,
        workerTechnology: showWorkerImprovementTechMarker,
        workerCandidate: showWorkerImprovementCandidateMarker,
        workerAvailabilityHint:
            !showWorkerBuildAvailableBorder && !showWorkerBuildBlockedBorder,
        attackTarget: showAttackTargetMarker,
      ),
    );
  }

  void _drawVisiblePlanningMarkers({
    required Canvas canvas,
    required HexTileGeometrySnapshot geometry,
    required bool showIcon,
    required bool showTerrain,
    required bool showResources,
    required List<String> terrainIconPaths,
    required List<String> resourceIconPaths,
    required _PlanningMarkerVisibility visibility,
  }) {
    if (!_hasPlanningMarkers(visibility)) return;
    final hasMapInfo = _hasMapInfo(
      showIcon,
      showTerrain,
      showResources,
      terrainIconPaths,
      resourceIconPaths,
    );
    _drawPlanningMarkers(
      canvas: canvas,
      geometry: geometry,
      avoidMapInfo: hasMapInfo,
      showCitySiteMarker: visibility.citySite,
      showRecommendedCitySiteMarker: visibility.recommendedCitySite,
      showCityGrowthMarker: visibility.cityGrowth,
      showWorkerImprovementNowMarker: _showWorkerNow(visibility),
      showWorkerImprovementTechMarker: _showWorkerTechnology(visibility),
      showWorkerImprovementCandidateMarker: visibility.workerCandidate,
      showAttackTargetMarker: visibility.attackTarget,
    );
  }
}

typedef _PlanningMarkerVisibility = ({
  bool citySite,
  bool recommendedCitySite,
  bool cityGrowth,
  bool workerNow,
  bool workerTechnology,
  bool workerCandidate,
  bool workerAvailabilityHint,
  bool attackTarget,
});

bool _hasPlanningMarkers(_PlanningMarkerVisibility visibility) =>
    visibility.citySite ||
    visibility.cityGrowth ||
    _showWorkerNow(visibility) ||
    _showWorkerTechnology(visibility) ||
    visibility.attackTarget;

bool _hasMapInfo(
  bool showIcon,
  bool showTerrain,
  bool showResources,
  List<String> terrainIconPaths,
  List<String> resourceIconPaths,
) =>
    showIcon &&
    ((showTerrain && terrainIconPaths.isNotEmpty) ||
        (showResources && resourceIconPaths.isNotEmpty));

bool _showWorkerNow(_PlanningMarkerVisibility visibility) =>
    visibility.workerAvailabilityHint && visibility.workerNow;

bool _showWorkerTechnology(_PlanningMarkerVisibility visibility) =>
    visibility.workerAvailabilityHint && visibility.workerTechnology;
