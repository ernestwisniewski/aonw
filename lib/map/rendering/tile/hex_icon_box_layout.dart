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
  static const double terrainIconSize = 20.0;
  static const double terrainSlotPadding = 2.5;
  static const double terrainSlotGap = 2.0;
  static const double resourceIconSize = 24.0;
  static const double resourceSlotPadding = 4.0;
  static const double resourceSlotGap = 4.0;
  static const int _resourceColumns = 3;

  static HexIconBoxGeometry terrain({
    required Offset center,
    required int iconCount,
  }) {
    if (iconCount == 0) return HexIconBoxGeometry.empty;

    final boxSize = _terrainClusterSize(iconCount);
    final topY = center.dy - boxSize.height / 2;
    final left = center.dx - boxSize.width / 2;
    return _buildIconClusterGeometry(
      left: left,
      top: topY,
      clusterWidth: boxSize.width,
      iconSize: terrainIconSize,
      slotPadding: terrainSlotPadding,
      slotGap: terrainSlotGap,
      iconCount: iconCount,
    );
  }

  static HexIconBoxGeometry resource({
    required Offset topCenter,
    required double hexRadius,
    required int iconCount,
    double? wallBottomY,
    double wallMargin = 0.0,
  }) {
    if (iconCount == 0) return HexIconBoxGeometry.empty;

    final boxSize = _resourceClusterSize(iconCount);
    final defaultBottomY = topCenter.dy + hexRadius * 0.866;
    final wallBottomYOrDefault = wallBottomY == null
        ? defaultBottomY
        : wallBottomY + resourceSlotPadding - wallMargin;
    final bottomY = wallBottomYOrDefault;
    final topY = bottomY - boxSize.height;
    final left = topCenter.dx - boxSize.width / 2;
    return _buildIconClusterGeometry(
      left: left,
      top: topY,
      clusterWidth: boxSize.width,
      iconSize: resourceIconSize,
      slotPadding: resourceSlotPadding,
      slotGap: resourceSlotGap,
      iconCount: iconCount,
    );
  }

  static double get _resourceSlotSize =>
      resourceIconSize + resourceSlotPadding * 2;

  static double get _terrainSlotSize {
    return terrainIconSize + terrainSlotPadding * 2;
  }

  static Size _resourceClusterSize(int iconCount) {
    final columns = _resourceColumnCount(iconCount);
    final rows = _resourceRowCount(iconCount);
    return Size(
      _resourceSlotSize * columns + (columns - 1) * resourceSlotGap,
      _resourceSlotSize * rows + (rows - 1) * resourceSlotGap,
    );
  }

  static Size _terrainClusterSize(int iconCount) {
    final columns = _resourceColumnCount(iconCount);
    final rows = _resourceRowCount(iconCount);
    final slotSize = _terrainSlotSize;
    return Size(
      slotSize * columns + (columns - 1) * terrainSlotGap,
      slotSize * rows + (rows - 1) * terrainSlotGap,
    );
  }

  static int _resourceColumnCount(int iconCount) {
    return iconCount < _resourceColumns ? iconCount : _resourceColumns;
  }

  static int _resourceRowCount(int iconCount) {
    return ((iconCount + _resourceColumns - 1) / _resourceColumns).floor();
  }

  static HexIconBoxGeometry _buildIconClusterGeometry({
    required double left,
    required double top,
    required double clusterWidth,
    required int iconCount,
    required double iconSize,
    required double slotPadding,
    required double slotGap,
  }) {
    final columns = _resourceColumnCount(iconCount);
    final slotSize = iconSize + slotPadding * 2;
    final iconRects = List<Rect>.generate(iconCount, (i) {
      final col = i % columns;
      final row = i ~/ columns;
      final iconsRemainingInRow = iconCount - row * columns;
      final rowCount = iconsRemainingInRow < columns ? iconsRemainingInRow : columns;
      final rowWidth =
          slotSize * rowCount + (rowCount - 1) * slotGap;
      final rowLeft = left + (clusterWidth - rowWidth) / 2;
      final leftOffset = rowLeft + col * (slotSize + slotGap);
      final topOffset = top + row * (slotSize + slotGap);
      final badgeRect = Rect.fromLTWH(
        leftOffset,
        topOffset,
        slotSize,
        slotSize,
      );
      return Rect.fromCenter(
        center: badgeRect.center,
        width: iconSize,
        height: iconSize,
      );
    }, growable: false);
    return HexIconBoxGeometry(
      boxRect: null,
      iconRects: iconRects,
      badgeRects: const [],
    );
  }
}
