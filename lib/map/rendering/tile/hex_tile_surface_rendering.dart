part of 'hex_tile_painter.dart';

extension _HexTileSurfaceRendering on HexTilePainter {
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

  void _drawSelectionOutline(Canvas canvas, HexTileGeometrySnapshot geometry) {
    HexOutlinePainter.paintDashedPolygon(canvas, [
      for (final corner in geometry.topCorners) Offset(corner.x, corner.y),
    ], _paintSelectionDash);
  }
}

ui.Paragraph _createHeightParagraph(int tileHeight) {
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
      const ui.ParagraphConstraints(
        width: HexTilePainter._heightBadgeParagraphWidth,
      ),
    );
}

Paint? _strokePaintOrNull(Color color, {required double strokeWidth}) {
  if (!_paintsColor(color)) return null;
  return Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = color;
}

bool _paintsColor(Color color) => (color.a * 255).round() > 0;

class _WallPaints {
  final Paint right;
  final Paint bottom;
  final Paint left;
  final Color rightColor;
  final Color bottomColor;
  final Color leftColor;
  final bool visible;

  _WallPaints.fromTint(Color tint)
    : visible = _paintsColor(tint),
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
