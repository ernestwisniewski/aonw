import 'package:aonw/map/rendering/tile/hex_height_badge_layout.dart';
import 'package:aonw/map/rendering/tile/hex_icon_box_layout.dart';
import 'package:flutter/material.dart';

class HexTileOverlayGeometry {
  final HexIconBoxGeometry terrainIcons;
  final HexIconBoxGeometry resourceIcons;
  final HexHeightBadgeGeometry heightBadge;

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
  }) {
    final mapInfoCenter = topCenter.translate(0, hexRadius * 0.28);
    return HexTileOverlayGeometry(
      terrainIcons: HexIconBoxLayout.terrain(
        center: mapInfoCenter,
        iconCount: terrainIconCount,
        hasResourceIcons: resourceIconCount > 0,
      ),
      resourceIcons: HexIconBoxLayout.resource(
        center: mapInfoCenter,
        iconCount: resourceIconCount,
        terrainIconCount: terrainIconCount,
      ),
      heightBadge: HexHeightBadgeLayout.build(
        center: topCenter,
        hexRadius: hexRadius,
        paragraphHeight: heightParagraphHeight,
        perspectiveY: heightPerspectiveY,
      ),
    );
  }
}
