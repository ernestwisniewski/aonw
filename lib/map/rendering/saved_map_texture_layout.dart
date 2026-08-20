import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw_core/map/domain/map_config.dart';

class SavedMapTextureLayout {
  const SavedMapTextureLayout({
    required this.config,
    required this.cols,
    required this.rows,
    required this.worldSize,
  });

  final MapConfig config;
  final int cols;
  final int rows;
  final ui.Size worldSize;

  ui.Rect tileDestination(int col, int row) {
    final radius = config.hexRadius;
    final tileHeight = math.sqrt(3) * radius;
    final center = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: radius,
    );
    return ui.Rect.fromLTWH(
      center.x - radius,
      center.y - tileHeight / 2,
      2 * radius,
      tileHeight,
    );
  }

  ui.Path tileClip(int col, int row, {double radiusScale = 1}) =>
      HexGeometry.tileOverlayPath(
        col: col,
        row: row,
        hexRadius: config.hexRadius,
        radiusScale: radiusScale,
      );
}
