import 'package:aonw/map/rendering/tile/hex_height_badge_layout.dart';
import 'package:aonw/map/rendering/tile/hex_icon_box_layout.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HexTileOverlayGeometry {
  final HexIconBoxGeometry terrainIcons;
  final HexIconBoxGeometry resourceIcons;
  final HexHeightBadgeGeometry heightBadge;
  static const double resourceWallMargin = 4.0;
  static const double compactMarkerWallMargin = 12.0;

  const HexTileOverlayGeometry({
    required this.terrainIcons,
    required this.resourceIcons,
    required this.heightBadge,
  });

  static HexTileOverlayGeometry build({
    required Offset topCenter,
    required int terrainIconCount,
    required int resourceIconCount,
    required double hexRadius,
    required double heightParagraphHeight,
    required double heightPerspectiveY,
    List<Vector2>? topCorners,
  }) {
    final wallBounds = _wallBounds(
      topCenter: topCenter,
      hexRadius: hexRadius,
      topCorners: topCorners,
    );
    return HexTileOverlayGeometry(
      terrainIcons: HexIconBoxLayout.terrain(
        center: topCenter,
        iconCount: terrainIconCount,
      ),
      resourceIcons: HexIconBoxLayout.resource(
        topCenter: topCenter,
        hexRadius: hexRadius,
        iconCount: resourceIconCount,
        wallBottomY: wallBounds.bottom,
        wallMargin: resourceWallMargin,
      ),
      heightBadge: HexHeightBadgeLayout.build(
        center: topCenter,
        hexRadius: hexRadius,
        paragraphHeight: heightParagraphHeight,
        perspectiveY: heightPerspectiveY,
        leftWallX: wallBounds.left,
        wallMargin: compactMarkerWallMargin,
      ),
    );
  }

  static ({double left, double bottom}) _wallBounds({
    required Offset topCenter,
    required double hexRadius,
    List<Vector2>? topCorners,
  }) {
    if (topCorners == null || topCorners.isEmpty) {
      final wallHeight = hexRadius * 0.8660254037844386;
      return (
        left: topCenter.dx - hexRadius,
        bottom: topCenter.dy + wallHeight,
      );
    }

    double left = topCorners.first.x;
    double bottom = topCorners.first.y;

    for (final corner in topCorners.skip(1)) {
      if (corner.x < left) left = corner.x;
      if (corner.y > bottom) bottom = corner.y;
    }

    return (left: left, bottom: bottom);
  }
}
