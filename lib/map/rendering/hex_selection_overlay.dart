import 'package:aonw/map/rendering/hex_outline_painter.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HexSelectionOverlay extends PositionComponent {
  HexSelectionOverlay({required double hexRadius, required Color color})
    : _color = color,
      _outlinePainter = HexOutlinePainter(color),
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
      );

  static const double highlightStrokeWidth =
      HexOutlinePainter.highlightStrokeWidth;

  final HexTileGeometrySnapshot _geometry;
  Color _color;
  bool _visible = false;

  final HexOutlinePainter _outlinePainter;

  bool get visibleForTesting => _visible;
  Color get colorForTesting => _color;
  double get highlightStrokeWidthForTesting => _outlinePainter.strokeWidth;

  void showAt({required Vector2 position, required Color color}) {
    this.position = position;
    if (_color != color) {
      _color = color;
      _outlinePainter.updateColor(color);
    }
    _visible = true;
  }

  void hide() {
    _visible = false;
  }

  void updateColor(Color color) {
    if (_color == color) return;
    _color = color;
    _outlinePainter.updateColor(color);
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
    );
  }
}
