import 'package:flutter/material.dart';

class HexHeightBadgeGeometry {
  final Offset paragraphOffset;

  const HexHeightBadgeGeometry({
    required this.paragraphOffset,
  });
}

abstract final class HexHeightBadgeLayout {
  static const double _heightTextWidth = 16.0;

  static HexHeightBadgeGeometry build({
    required Offset center,
    required double hexRadius,
    required double paragraphHeight,
    required double perspectiveY,
    double? leftWallX,
    double wallMargin = 0.0,
  }) {
    final badgeX = leftWallX == null
        ? center.dx - hexRadius * 0.46
        : leftWallX + wallMargin + _heightTextWidth / 2;
    final badgeY = center.dy;
    return HexHeightBadgeGeometry(
      paragraphOffset: Offset(
        badgeX - _heightTextWidth / 2,
        (badgeY - paragraphHeight / 2) * perspectiveY,
      ),
    );
  }
}
