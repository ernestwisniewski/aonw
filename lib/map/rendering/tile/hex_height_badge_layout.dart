import 'package:flutter/material.dart';

class HexHeightBadgeGeometry {
  final RRect badgeRect;
  final Offset paragraphOffset;

  const HexHeightBadgeGeometry({
    required this.badgeRect,
    required this.paragraphOffset,
  });
}

abstract final class HexHeightBadgeLayout {
  static const double badgeSize = 16.0;
  static const double badgeRadius = 5.0;

  static HexHeightBadgeGeometry build({
    required Offset center,
    required double hexRadius,
    required double paragraphHeight,
    required double perspectiveY,
  }) {
    final badgeX = center.dx - hexRadius * 0.46;
    final badgeY = center.dy - hexRadius * 0.26;
    return HexHeightBadgeGeometry(
      badgeRect: RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(badgeX, badgeY),
          width: badgeSize,
          height: badgeSize,
        ),
        const Radius.circular(badgeRadius),
      ),
      paragraphOffset: Offset(
        badgeX - badgeSize / 2,
        (badgeY - paragraphHeight / 2) * perspectiveY,
      ),
    );
  }
}
