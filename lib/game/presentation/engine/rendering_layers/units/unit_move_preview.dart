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

enum UnitMovePreviewRouteKind { movement, trade }

class UnitMovePreview extends Component {
  static const double _routeDashLength = 13.0;
  static const double _routeGapLength = 8.0;
  static const double _routeDashPattern = _routeDashLength + _routeGapLength;
  static const double _travelledDashLength = 7.5;
  static const double _travelledGapLength = 5.5;
  static const double _flowSpeed = 24.0;
  static const double _pulsePeriod = 42.0;
  static const int _focusedForwardHexes = 2;
  static const double _minRouteStrokeScale = 0.74;
  static const double _nearBackRouteStrokeScale = 0.90;
  static const double _backRouteStrokeFalloff = 0.055;
  static const double _frontRouteStrokeFalloff = 0.06;

  final List<Vector2> points;
  final List<bool> reachablePoints;
  final GameUnitType? unitType;
  final UnitMovePreviewRouteKind routeKind;
  bool dimmed;
  bool subdued;
  bool showTargetPulse;
  bool showTargetArrow;
  bool showConfirmedTarget;

  /// Points at index <= travelledUpToIndex are rendered as dashed (already travelled).
  final int travelledUpToIndex;
  final UnitMovePreviewStyle _style = UnitMovePreviewStyle();
  late final UnitMarkerSpriteController? _unitSpriteController =
      unitType == null ? null : UnitMarkerSpriteController(unitType!);
  double _flowPhase = 0;

  UnitMovePreview({
    required List<Vector2> points,
    required List<bool> reachablePoints,
    this.unitType,
    this.routeKind = UnitMovePreviewRouteKind.movement,
    this.dimmed = false,
    this.subdued = false,
    this.showTargetPulse = false,
    this.showTargetArrow = false,
    this.showConfirmedTarget = false,
    this.travelledUpToIndex = 0,
  }) : points = [for (final point in points) point.clone()],
       reachablePoints = List.unmodifiable(reachablePoints);

  Color get reachableColor => _style.reachableColor;

  Color get reachableGlow => _style.reachableGlow;

  Color get reachableCore => _style.reachableCore;

  Color get unreachableColor => _style.unreachableColor;

  Color get unreachableGlow => _style.unreachableGlow;

  Color get unreachableCore => _style.unreachableCore;

  GameUnitType? get unitTypeForTesting => unitType;

  bool get usesUnitGhostForTesting => _unitSpriteController != null;

  bool get dimmedForTesting => dimmed;

  bool get subduedForTesting => subdued;

  bool get showTargetPulseForTesting => showTargetPulse;

  bool get showTargetArrowForTesting => showTargetArrow;

  bool get showConfirmedTargetForTesting => showConfirmedTarget;

  bool get showStartMarkerForTesting => points.length >= 2;

  @visibleForTesting
  bool routePointMutedForTesting(int index) => _isMutedPoint(index);

  @visibleForTesting
  double routeStrokeScaleForTesting(int index) =>
      _routeStrokeScaleForPoint(index);

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

    if (showTargetPulse || showConfirmedTarget) {
      _drawTargetHexOutline(canvas);
    }

    final travelledIndex = travelledUpToIndex < 0
        ? 0
        : math.min(travelledUpToIndex, points.length - 1);

    for (var i = 1; i < points.length; i++) {
      if (i <= travelledIndex) {
        _drawDashedSegment(canvas, points[i - 1], points[i], i);
      } else {
        _drawLitSegment(canvas, points[i - 1], points[i], i);
      }
    }

    _drawStartRing(canvas);

    for (var i = 1; i < points.length - 1; i++) {
      if (i > travelledIndex) {
        _drawWaypointNode(canvas, i);
      }
    }

    _drawTravellingMarker(canvas, travelledIndex);
    _drawTargetRing(canvas);
    _drawDestinationMarker(canvas);
    if (showTargetArrow) {
      _drawTargetArrow(canvas);
    }
    if (emphasisPaint != null) {
      canvas.restore();
    }
  }
}
