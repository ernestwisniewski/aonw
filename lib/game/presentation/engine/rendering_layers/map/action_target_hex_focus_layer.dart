import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_outline_painter.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Owns the transient full-tile cue for a focused map action target.
///
/// The effect is presentation-only. Domain state identifies the focused hex;
/// this layer owns its lifetime, reduced-motion behavior, and map rendering.
final class ActionTargetHexFocusLayer extends PositionComponent
    with LayerAttachment {
  ActionTargetHexFocusLayer({
    double hexRadius = MapConfig.defaultHexRadius,
    Vector2? Function(String unitId)? unitPositionFor,
  }) : _hexRadius = hexRadius,
       _unitPositionFor = unitPositionFor ?? _missingUnitPosition,
       _geometry = HexTileGeometryLayout.build(
         hexRadius: hexRadius,
         liftOffset: 0,
         tileHeight: 0,
         neighborHeights: const [0, 0, 0],
       ),
       _outlinePainter = HexOutlinePainter(HudPalette.goldLight),
       super(
         size: Vector2(
           HexTileMetrics.width(hexRadius),
           HexTileMetrics.height(hexRadius),
         ),
         anchor: Anchor.center,
         priority: MapPriority.selectionOverlay + 1,
       );

  static const double _blinkPeriod = 0.5;
  static const double _visibleFraction = 0.64;

  final double _hexRadius;
  final Vector2? Function(String unitId) _unitPositionFor;
  final HexTileGeometrySnapshot _geometry;
  final HexOutlinePainter _outlinePainter;

  String? _unitId;
  Vector2? _unitWorldPositionOrigin;
  late Vector2 _hexPositionOrigin;
  int? _col;
  int? _row;
  double _elapsed = 0;
  double _durationSeconds = 0;
  bool _reduceMotion = false;
  bool _active = false;

  void show({
    required Component parent,
    required ShowActionTargetFocusEffect effect,
    required bool reduceMotion,
  }) {
    ensureAttachedTo(parent);
    _unitId = effect.unitId;
    _col = effect.col;
    _row = effect.row;
    _hexPositionOrigin = HexGeometry.tilePosition(
      col: effect.col,
      row: effect.row,
      hexRadius: _hexRadius,
    );
    _unitWorldPositionOrigin = _trackedUnitWorldPosition();
    position = _hexPositionOrigin.clone();
    _durationSeconds =
        effect.duration.inMicroseconds / Duration.microsecondsPerSecond;
    _elapsed = 0;
    _reduceMotion = reduceMotion;
    _active = _durationSeconds > 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active || dt <= 0) return;
    _syncTrackedUnitPosition();
    if (_elapsed + dt + 1e-9 >= _durationSeconds) {
      _elapsed = _durationSeconds;
      _active = false;
      return;
    }
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    super.render(canvas);
    _outlinePainter.paint(
      canvas,
      path: _geometry.topPath,
      corners: [
        for (final corner in _geometry.topCorners) Offset(corner.x, corner.y),
      ],
      pattern: HexOutlinePattern.dashed,
    );
  }

  bool get _visible {
    if (!_active) return false;
    if (_reduceMotion) return true;
    final phase = (_elapsed % _blinkPeriod) / _blinkPeriod;
    return phase < _visibleFraction;
  }

  void _syncTrackedUnitPosition() {
    final current = _trackedUnitWorldPosition();
    if (current == null) return;
    final origin = _unitWorldPositionOrigin;
    if (origin == null) {
      _unitWorldPositionOrigin = current.clone();
      return;
    }
    position = Vector2(
      _hexPositionOrigin.x + current.x - origin.x,
      _hexPositionOrigin.y + (current.y - origin.y) / HexGrid.perspectiveY,
    );
  }

  Vector2? _trackedUnitWorldPosition() {
    final unitId = _unitId;
    return unitId == null ? null : _unitPositionFor(unitId);
  }

  static Vector2? _missingUnitPosition(String _) => null;

  bool get activeForTesting => _active;
  bool get visibleForTesting => _visible;
  int? get colForTesting => _col;
  int? get rowForTesting => _row;
  String? get unitIdForTesting => _unitId;
  Color get colorForTesting => _outlinePainter.color;
  Rect get outlineBoundsForTesting => _geometry.topPath.getBounds();
  double get dashLengthForTesting => HexOutlinePainter.dashLength;
  double get gapLengthForTesting => HexOutlinePainter.gapLength;
  HexOutlinePattern get patternForTesting => HexOutlinePattern.dashed;

  @override
  void onRemove() {
    _active = false;
    super.onRemove();
  }
}
