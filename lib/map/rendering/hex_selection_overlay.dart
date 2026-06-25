import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HexSelectionOverlay extends PositionComponent {
  HexSelectionOverlay({required double hexRadius, required Color color})
    : _color = color,
      _geometry = HexTileGeometryLayout.build(
        hexRadius: hexRadius,
        liftOffset: 0,
        tileHeight: 0,
        neighborHeights: const [0, 0, 0],
      ),
      super(
        size: Vector2(
          HexTileMetrics.width(hexRadius),
          HexTileMetrics.height(hexRadius),
        ),
        anchor: Anchor.center,
        priority: MapPriority.selectionOverlay,
      ) {
    _rebuildPaints();
  }

  static const double highlightStrokeWidth = MapStroke.bold + 1.0;

  final HexTileGeometrySnapshot _geometry;
  Color _color;
  bool _visible = false;

  late Paint _glowPaint;
  late Paint _backingPaint;
  late Paint _highlightPaint;

  bool get visibleForTesting => _visible;
  Color get colorForTesting => _color;
  double get highlightStrokeWidthForTesting => _highlightPaint.strokeWidth;

  void showAt({required Vector2 position, required Color color}) {
    this.position = position;
    if (_color != color) {
      _color = color;
      _rebuildPaints();
    }
    _visible = true;
  }

  void hide() {
    _visible = false;
  }

  void updateColor(Color color) {
    if (_color == color) return;
    _color = color;
    _rebuildPaints();
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    super.render(canvas);

    canvas
      ..drawPath(_geometry.topPath, _glowPaint)
      ..drawPath(_geometry.topPath, _backingPaint)
      ..drawPath(_geometry.topPath, _highlightPaint);
  }

  void _rebuildPaints() {
    _glowPaint = HudPaint.stroke(
      _color,
      alpha: MapAlpha.regular,
      strokeWidth: MapStroke.glow + 3.0,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.4);
    _backingPaint = HudPaint.stroke(
      Colors.black,
      alpha: MapAlpha.solid,
      strokeWidth: MapStroke.glow + 1.0,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    _highlightPaint = HudPaint.stroke(
      _color,
      alpha: MapAlpha.full,
      strokeWidth: highlightStrokeWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }
}
