import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_sprite_controller.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_style.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

part 'unit_move_preview_motion.dart';
part 'unit_move_preview_route_rendering.dart';
part 'unit_move_preview_target_rendering.dart';

class UnitMovePreview extends Component {
  static const double _routeDashLength = 12.0;
  static const double _routeGapLength = 7.0;
  static const double _routeDashPattern = _routeDashLength + _routeGapLength;
  static const double _flowSpeed = 24.0;
  static const double _routeBoundaryRadius = 2.8;
  static const double _routeBoundaryHaloRadius = 5.2;
  static const double _currentTurnBoundaryRadius = 4.4;
  static const double _currentTurnBoundaryHaloRadius = 7.4;

  final List<Vector2> points;
  final List<bool> reachablePoints;
  final List<int> turnBoundaryPointIndices;
  final Set<int> roadSegmentIndices;
  final GameUnitType? unitType;
  bool dimmed;
  bool subdued;
  bool showTargetOutline;

  /// Steps ending at or before this index are treated as travelled history.
  final int travelledUpToIndex;
  final UnitMovePreviewStyle _style = UnitMovePreviewStyle();
  final Map<int, Path> _routeSegmentCache = {};
  late final UnitMarkerSpriteController? _unitSpriteController =
      unitType == null ? null : UnitMarkerSpriteController(unitType!);
  double _flowPhase = 0;

  UnitMovePreview({
    required List<Vector2> points,
    required List<bool> reachablePoints,
    List<int> turnBoundaryPointIndices = const [],
    Set<int> roadSegmentIndices = const {},
    this.unitType,
    this.dimmed = false,
    this.subdued = false,
    this.showTargetOutline = false,
    this.travelledUpToIndex = 0,
  }) : points = [for (final point in points) point.clone()],
       reachablePoints = List.unmodifiable(reachablePoints),
       turnBoundaryPointIndices = List.unmodifiable(turnBoundaryPointIndices),
       roadSegmentIndices = Set.unmodifiable(roadSegmentIndices);

  Color get routeColor => UnitMovePreviewStyle.routeColor;

  Color get targetOutlineColor => UnitMovePreviewStyle.confirmedTargetColor;

  GameUnitType? get unitTypeForTesting => unitType;

  bool get usesUnitGhostForTesting => _unitSpriteController != null;

  bool get dimmedForTesting => dimmed;

  bool get subduedForTesting => subdued;

  bool get showTargetOutlineForTesting => showTargetOutline;

  @visibleForTesting
  List<double> dashStartsForTesting({
    required double pathLength,
    required double phase,
    double dashLength = _routeDashLength,
    double gapLength = _routeGapLength,
  }) {
    return _dashStartDistances(
      pathLength: pathLength,
      dashLength: dashLength,
      gapLength: gapLength,
      phase: phase,
    ).toList(growable: false);
  }

  @visibleForTesting
  Offset? travellingMarkerPositionForTesting({double? phase, int? startIndex}) {
    return _routeSample(
      startIndex ?? _clampedTravelledIndex,
      phase: phase,
    )?.position;
  }

  @visibleForTesting
  double routeSegmentLengthForTesting(int index) {
    return _routeSegmentPath(index).computeMetrics().single.length;
  }

  @visibleForTesting
  Rect routeSegmentBoundsForTesting(int index) {
    return _routeSegmentPath(index).getBounds();
  }

  @visibleForTesting
  bool routeSegmentFollowsRoadForTesting(int index) =>
      roadSegmentIndices.contains(index);

  @visibleForTesting
  bool routeSegmentAnimatedForTesting(int index) =>
      index > _clampedTravelledIndex;

  @visibleForTesting
  bool routeSegmentGlowingForTesting(int index) =>
      index > _clampedTravelledIndex && _isReachablePoint(index);

  @visibleForTesting
  double routeSegmentDashPhaseForTesting(int index) =>
      _dashPhaseForSegment(index);

  @visibleForTesting
  List<int> get routeBoundaryPointIndicesForTesting =>
      _routeBoundaryPointIndices.toList(growable: false);

  @visibleForTesting
  double routeBoundaryRadiusForTesting(int index) =>
      _routeBoundaryRadiusForPoint(index);

  @visibleForTesting
  bool routeBoundaryHasBorderForTesting(int index) =>
      _isCurrentTurnEndBoundary(index);

  @visibleForTesting
  bool get destinationMarkerHasBorderForTesting =>
      _destinationIsReachableThisTurn;

  void _drawRouteBoundaryDot(
    Canvas canvas,
    Offset center, {
    required bool emphasized,
  }) {
    final radius = emphasized
        ? UnitMovePreview._currentTurnBoundaryRadius
        : UnitMovePreview._routeBoundaryRadius;
    canvas
      ..drawCircle(
        center,
        emphasized
            ? UnitMovePreview._currentTurnBoundaryHaloRadius
            : UnitMovePreview._routeBoundaryHaloRadius,
        _style.routeBoundaryHaloPaint,
      )
      ..drawCircle(center, radius, _style.routeBoundaryDotPaint);
    if (emphasized) {
      canvas.drawCircle(center, radius, _style.currentTurnBoundaryBorderPaint);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _unitSpriteController?.loadIfNeeded();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _flowPhase = (_flowPhase + dt * _flowSpeed) % 10000.0;
    _syncUnitGhostAnimation();
    _unitSpriteController?.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (points.length < 2) return;
    final emphasisPaint = _emphasisLayerPaint;
    if (emphasisPaint != null) {
      canvas.saveLayer(null, emphasisPaint);
    }

    if (showTargetOutline) {
      _drawTargetHexOutline(canvas);
    }

    final travelledIndex = travelledUpToIndex < 0
        ? 0
        : math.min(travelledUpToIndex, points.length - 1);

    for (var i = 1; i < points.length; i++) {
      if (i <= travelledIndex) {
        _drawTravelledSegment(canvas, i);
      } else {
        _drawPlannedSegment(canvas, i);
      }
    }

    _drawRouteBoundaryMarkers(canvas);
    _drawTravellingMarker(canvas, travelledIndex);
    _drawDestinationMarker(canvas);
    if (emphasisPaint != null) {
      canvas.restore();
    }
  }
}
