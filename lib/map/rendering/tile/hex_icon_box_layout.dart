import 'package:flutter/material.dart';

class HexIconBoxGeometry {
  final RRect? boxRect;
  final List<Rect> iconRects;
  final List<RRect> badgeRects;

  const HexIconBoxGeometry({
    required this.boxRect,
    required this.iconRects,
    this.badgeRects = const <RRect>[],
  });

  static const empty = HexIconBoxGeometry(boxRect: null, iconRects: <Rect>[]);
}

abstract final class HexIconBoxLayout {
  static const double terrainIconSize = 17.0;
  static const double terrainBadgeSize = 24.0;
  static const double resourceIconSize = 22.0;
  static const double terrainBoxPadding = 2.5;
  static const double resourceBadgePadding = 4.5;
  static const double resourceTrayPadding = 2.0;
  static const double boxGap = 5.0;
  static const double terrainBadgeGap = 3.0;
  static const double resourceBadgeGap = 4.0;
  static const int _resourceColumns = 3;

  static HexIconBoxGeometry terrain({
    required Offset center,
    required int iconCount,
    required bool hasResourceIcons,
  }) {
    if (iconCount == 0) return HexIconBoxGeometry.empty;

    final boxSize = _terrainBoxSize(iconCount);
    final totalHeight = hasResourceIcons
        ? boxSize.height + boxGap + resourceBadgeSize
        : boxSize.height;
    final topY = center.dy - totalHeight / 2;
    final left = center.dx - boxSize.width / 2;
    return _buildTerrainGeometry(
      left: left,
      top: topY,
      size: boxSize,
      iconCount: iconCount,
    );
  }

  static HexIconBoxGeometry resource({
    required Offset center,
    required int iconCount,
    required int terrainIconCount,
  }) {
    if (iconCount == 0) return HexIconBoxGeometry.empty;

    final boxSize = _resourceClusterSize(iconCount);
    final terrainBoxHeight = terrainIconCount > 0
        ? _terrainBoxSize(terrainIconCount).height
        : 0.0;
    final totalHeight = terrainBoxHeight > 0
        ? terrainBoxHeight + boxGap + boxSize.height
        : boxSize.height;
    final topY =
        center.dy -
        totalHeight / 2 +
        terrainBoxHeight +
        (terrainBoxHeight > 0 ? boxGap : 0);
    final left = center.dx - boxSize.width / 2;
    return _buildResourceGeometry(
      left: left,
      top: topY,
      size: boxSize,
      iconCount: iconCount,
    );
  }

  static double get resourceBadgeSize =>
      resourceIconSize + resourceBadgePadding * 2;

  static Size _terrainBoxSize(int iconCount) {
    return Size(
      terrainBadgeSize * iconCount +
          terrainBoxPadding * 2 +
          (iconCount - 1) * terrainBadgeGap,
      terrainBadgeSize + terrainBoxPadding * 2,
    );
  }

  static Size _resourceClusterSize(int iconCount) {
    final columns = _resourceColumnCount(iconCount);
    final rows = _resourceRowCount(iconCount);
    return Size(
      resourceBadgeSize * columns + (columns - 1) * resourceBadgeGap,
      resourceBadgeSize * rows + (rows - 1) * resourceBadgeGap,
    );
  }

  static int _resourceColumnCount(int iconCount) {
    return iconCount < _resourceColumns ? iconCount : _resourceColumns;
  }

  static int _resourceRowCount(int iconCount) {
    return ((iconCount + _resourceColumns - 1) / _resourceColumns).floor();
  }

  static HexIconBoxGeometry _buildTerrainGeometry({
    required double left,
    required double top,
    required Size size,
    required int iconCount,
  }) {
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, size.width, size.height),
      const Radius.circular(7),
    );
    final badgeRects = List<RRect>.generate(iconCount, (i) {
      final cx =
          left +
          terrainBoxPadding +
          i * (terrainBadgeSize + terrainBadgeGap) +
          terrainBadgeSize / 2;
      final cy = top + terrainBoxPadding + terrainBadgeSize / 2;
      return RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: terrainBadgeSize,
          height: terrainBadgeSize,
        ),
        const Radius.circular(8),
      );
    }, growable: false);
    final iconRects = badgeRects
        .map(
          (badge) => Rect.fromCenter(
            center: badge.outerRect.center,
            width: terrainIconSize,
            height: terrainIconSize,
          ),
        )
        .toList(growable: false);
    return HexIconBoxGeometry(
      boxRect: boxRect,
      iconRects: iconRects,
      badgeRects: badgeRects,
    );
  }

  static HexIconBoxGeometry _buildResourceGeometry({
    required double left,
    required double top,
    required Size size,
    required int iconCount,
  }) {
    final columns = _resourceColumnCount(iconCount);
    final badgeRects = List<RRect>.generate(iconCount, (i) {
      final col = i % columns;
      final row = i ~/ columns;
      final rowCount = i == iconCount - 1 && iconCount.isOdd ? 1 : columns;
      final rowWidth =
          resourceBadgeSize * rowCount + (rowCount - 1) * resourceBadgeGap;
      final rowLeft = left + (size.width - rowWidth) / 2;
      final leftOffset = rowLeft + col * (resourceBadgeSize + resourceBadgeGap);
      final topOffset = top + row * (resourceBadgeSize + resourceBadgeGap);
      final rect = Rect.fromLTWH(
        leftOffset,
        topOffset,
        resourceBadgeSize,
        resourceBadgeSize,
      );
      return RRect.fromRectAndRadius(rect, const Radius.circular(10));
    }, growable: false);
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left,
        top,
        size.width,
        size.height,
      ).inflate(resourceTrayPadding),
      const Radius.circular(10),
    );
    final iconRects = badgeRects
        .map(
          (badge) => Rect.fromCenter(
            center: badge.outerRect.center,
            width: resourceIconSize,
            height: resourceIconSize,
          ),
        )
        .toList(growable: false);
    return HexIconBoxGeometry(
      boxRect: boxRect,
      iconRects: iconRects,
      badgeRects: badgeRects,
    );
  }
}
