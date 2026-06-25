import 'dart:math' as math;

import 'package:aonw/map/domain/hex_grid_topology.dart';
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
