import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/hex_outline_painter.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frames.dart';
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
  late final Paint _paintWorkerImprovementNowMarker;
  late final Paint _paintWorkerImprovementCandidateFill;
  late final Paint _paintWorkerImprovementCandidateBorder;
  late final Paint _paintWorkerImprovementTechFill;
  late final Paint _paintWorkerImprovementTechBorder;
  late final Paint _paintAttackTargetMarker;
  late final Paint _paintAttackTargetHatch;
  late final Paint _paintMovementBlockerOverlay;
  late final Paint _paintMovementBlockerOutline;
  late final ui.Paragraph _heightParagraph;
  late final ui.Paragraph _heightParagraphShadow;

  static final _paintMapIconImage = Paint()
    ..filterQuality = FilterQuality.medium;
  static const double _heightBadgeParagraphWidth = 18.0;
  static const int _planningMarkerAlpha = 214;
  static const int _attackTargetFillAlpha = MapAlpha.soft;
  static const double _attackTargetHatchSpacing = 9.0;
  static const int _movementBlockerAlpha = 86;
  static const int _movementBlockerOutlineAlpha = 210;

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
      alpha: _attackTargetFillAlpha,
    );
    _paintAttackTargetHatch = HudPaint.stroke(
      HudPalette.dangerSubtle,
      alpha: MapAlpha.regular,
      strokeWidth: MapStroke.hairline,
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
    _heightParagraph = _createHeightParagraph(
      tileHeight: tileHeight,
      color: Colors.white,
    );
    _heightParagraphShadow = _createHeightParagraph(
      tileHeight: tileHeight,
      color: HudPalette.roadEdge,
    );
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
    required List<SpriteFrameId> terrainIconPaths,
    required List<SpriteFrameId> resourceIconPaths,
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
        paragraphOffset: overlays.heightBadge.paragraphOffset,
        perspectiveY: heightPerspectiveY,
      );
    }

    if (showTerrain) {
      _drawResourceIcons(
        canvas: canvas,
        iconRects: overlays.terrainIcons.iconRects,
        iconPaths: terrainIconPaths,
      );
    }
    if (showResources) {
      _drawResourceIcons(
        canvas: canvas,
        iconRects: overlays.resourceIcons.iconRects,
        iconPaths: resourceIconPaths,
      );
    }

    _drawVisiblePlanningMarkers(
      canvas: canvas,
      geometry: geometry,
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
    required _PlanningMarkerVisibility visibility,
  }) {
    if (!_hasPlanningMarkers(visibility)) return;
    _drawPlanningMarkers(
      canvas: canvas,
      geometry: geometry,
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

bool _showWorkerNow(_PlanningMarkerVisibility visibility) =>
    visibility.workerAvailabilityHint && visibility.workerNow;

bool _showWorkerTechnology(_PlanningMarkerVisibility visibility) =>
    visibility.workerAvailabilityHint && visibility.workerTechnology;
