import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';

abstract final class HexTileMetrics {
  static const double sizePadding = 8.0;
  static const double maxDepth = 16.0;

  static double width(double hexRadius) => hexRadius * 2;

  static double height(double hexRadius) =>
      hexRadius * HexTileGeometryLayout.sqrt3 + maxDepth + sizePadding;

  static double topCenterAnchorOffsetY(double hexRadius) {
    final topCenterY = hexRadius * HexTileGeometryLayout.sqrt3Half;
    return topCenterY - height(hexRadius) / 2;
  }
}
