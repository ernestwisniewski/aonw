import 'dart:math' as math;
import 'dart:ui';

import 'package:aonw/map/domain/hex_grid_topology.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:flame/components.dart';

/// Pure geometric helpers for flat-top hexagons.
///
/// Coordinate convention: corner 0 at angle 0° (rightmost),
/// going clockwise in screen coordinates (y-down).
abstract final class HexGeometry {
  /// Returns the 6 corners of a flat-top hexagon centered at [center].
  static List<Vector2> topFaceCorners({
    required Vector2 center,
    required double radius,
  }) {
    return List.generate(6, (i) {
      final angle = math.pi / 3 * i; // 0°, 60°, 120°, 180°, 240°, 300°
      return Vector2(
        center.x + radius * math.cos(angle),
        center.y + radius * math.sin(angle),
      );
    });
  }

  /// Returns the lifted top-face center used by board overlays.
  static Vector2 topFaceCenter({
    required int col,
    required int row,
    double? hexRadius,
  }) {
    final radius = hexRadius ?? MapConfig.defaultConfig.hexRadius;
    final center = tilePosition(col: col, row: row, hexRadius: radius);
    return Vector2(
      center.x,
      center.y + HexTileMetrics.topCenterAnchorOffsetY(radius),
    );
  }

  /// Returns top-face corner offsets for a board tile.
  static List<Offset> topFaceCornerOffsets({
    required int col,
    required int row,
    double radiusScale = 1.0,
    double? hexRadius,
    double perspectiveY = 1.0,
  }) {
    final radius = hexRadius ?? MapConfig.defaultConfig.hexRadius;
    final corners = topFaceCorners(
      center: topFaceCenter(col: col, row: row, hexRadius: radius),
      radius: radius * radiusScale,
    );
    return [
      for (final corner in corners) Offset(corner.x, corner.y * perspectiveY),
    ];
  }

  /// Returns the centroid of the rendered top-face corners for a board tile.
  static Offset topFaceCentroid({
    required int col,
    required int row,
    double radiusScale = 1.0,
    double? hexRadius,
    double perspectiveY = 1.0,
  }) {
    final corners = topFaceCornerOffsets(
      col: col,
      row: row,
      radiusScale: radiusScale,
      hexRadius: hexRadius,
      perspectiveY: perspectiveY,
    );
    final sum = corners.fold(Offset.zero, (total, point) => total + point);
    return Offset(sum.dx / corners.length, sum.dy / corners.length);
  }

  /// Returns a full-tile hex path centered on the board tile position.
  static Path tileOverlayPath({
    required int col,
    required int row,
    double? hexRadius,
    double radiusScale = 1.0,
    double perspectiveY = 1.0,
  }) {
    final radius = hexRadius ?? MapConfig.defaultConfig.hexRadius;
    final center = tilePosition(col: col, row: row, hexRadius: radius);
    final corners = topFaceCorners(
      center: center,
      radius: radius * radiusScale,
    );
    return _pathFromOffsets([
      for (final corner in corners) Offset(corner.x, corner.y * perspectiveY),
    ]);
  }

  static Path _pathFromOffsets(List<Offset> corners) {
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    return path..close();
  }

  /// Ray-casting point-in-polygon test.
  static bool containsPoint(Vector2 point, List<Vector2> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].x, yi = polygon[i].y;
      final xj = polygon[j].x, yj = polygon[j].y;
      final intersect =
          ((yi > point.y) != (yj > point.y)) &&
          (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  /// Center position for a tile at grid coordinates (col, row).
  static Vector2 tilePosition({
    required int col,
    required int row,
    required double hexRadius,
  }) {
    final x = hexRadius + col * 1.5 * hexRadius;
    final y =
        (math.sqrt(3) / 2 * hexRadius) +
        row * math.sqrt(3) * hexRadius +
        (col.isOdd ? math.sqrt(3) / 2 * hexRadius : 0);
    return Vector2(x, y);
  }

  /// Returns the six adjacent coordinates for the odd-q flat-top layout used
  /// by [tilePosition].
  static List<({int col, int row})> neighbors({
    required int col,
    required int row,
  }) => HexGridTopology.neighbors(col: col, row: row);

  static bool areNeighbors({
    required int col,
    required int row,
    required int targetCol,
    required int targetRow,
  }) => HexGridTopology.areNeighbors(
    col: col,
    row: row,
    targetCol: targetCol,
    targetRow: targetRow,
  );

  /// Converts a world-space [point] to the (col, row) of the hex tile at that
  /// position. Returns null if the point is outside grid bounds or in a gap
  /// between tiles.
  static ({int col, int row})? tileAt({
    required Vector2 point,
    required double hexRadius,
    required int cols,
    required int rows,
  }) {
    // Estimate the column from x coordinate
    final approxCol = ((point.x - hexRadius) / (1.5 * hexRadius)).round();

    // Check candidate columns: approxCol-1, approxCol, approxCol+1
    ({int col, int row})? best;
    double bestDist = double.infinity;

    for (int dc = -1; dc <= 1; dc++) {
      final col = approxCol + dc;
      if (col < 0 || col >= cols) continue;

      // Estimate row for this column
      final yOffset = col.isOdd ? math.sqrt(3) / 2 * hexRadius : 0.0;
      final approxRow =
          ((point.y - yOffset - math.sqrt(3) / 2 * hexRadius) /
                  (math.sqrt(3) * hexRadius))
              .round();

      for (int dr = -1; dr <= 1; dr++) {
        final row = approxRow + dr;
        if (row < 0 || row >= rows) continue;

        final center = tilePosition(col: col, row: row, hexRadius: hexRadius);
        final corners = topFaceCorners(center: center, radius: hexRadius);
        if (containsPoint(point, corners)) {
          final dist = (point - center).length;
          if (dist < bestDist) {
            bestDist = dist;
            best = (col: col, row: row);
          }
        }
      }
    }

    return best;
  }
}
