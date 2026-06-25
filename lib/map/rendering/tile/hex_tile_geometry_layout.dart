import 'dart:ui';

import 'package:flame/components.dart';

class HexTileGeometrySnapshot {
  final Offset topCenter;
  final List<Vector2> topCorners;
  final Path topPath;
  final List<bool> topOutlineEdges;
  final List<Path?> wallPaths;

  const HexTileGeometrySnapshot({
    required this.topCenter,
    required this.topCorners,
    required this.topPath,
    required this.topOutlineEdges,
    required this.wallPaths,
  });
}

abstract final class HexTileGeometryLayout {
  static const double sqrt3 = 1.7320508075688772;
  static const double sqrt3Half = sqrt3 / 2;
  static const double baseWallDepth = 3.0;
  static const double depthPerHeight = 2.0;

  static HexTileGeometrySnapshot build({
    required double hexRadius,
    required double liftOffset,
    required int tileHeight,
    required List<int?> neighborHeights,
    List<int?> outlineNeighborHeights = const [],
  }) {
    final centerX = hexRadius;
    final centerY = hexRadius * sqrt3Half + liftOffset;
    final topCorners = _topCorners(
      centerX: centerX,
      centerY: centerY,
      hexRadius: hexRadius,
    );
    final topPath = _pathFromCorners(topCorners);
    final wallPaths = <Path?>[
      _wallPath(
        topCorners: topCorners,
        tileHeight: tileHeight,
        neighborHeights: neighborHeights,
        cornerA: 0,
        cornerB: 1,
        neighborIdx: 0,
      ),
      _wallPath(
        topCorners: topCorners,
        tileHeight: tileHeight,
        neighborHeights: neighborHeights,
        cornerA: 1,
        cornerB: 2,
        neighborIdx: 1,
      ),
      _wallPath(
        topCorners: topCorners,
        tileHeight: tileHeight,
        neighborHeights: neighborHeights,
        cornerA: 2,
        cornerB: 3,
        neighborIdx: 2,
      ),
    ];

    return HexTileGeometrySnapshot(
      topCenter: Offset(centerX, centerY),
      topCorners: topCorners,
      topPath: topPath,
      topOutlineEdges: _topOutlineEdges(
        tileHeight: tileHeight,
        outlineNeighborHeights: outlineNeighborHeights,
      ),
      wallPaths: wallPaths,
    );
  }

  static List<Vector2> _topCorners({
    required double centerX,
    required double centerY,
    required double hexRadius,
  }) {
    final halfR = hexRadius / 2;
    final vertical = hexRadius * sqrt3Half;
    return <Vector2>[
      Vector2(centerX + hexRadius, centerY),
      Vector2(centerX + halfR, centerY + vertical),
      Vector2(centerX - halfR, centerY + vertical),
      Vector2(centerX - hexRadius, centerY),
      Vector2(centerX - halfR, centerY - vertical),
      Vector2(centerX + halfR, centerY - vertical),
    ];
  }

  static Path _pathFromCorners(List<Vector2> corners) {
    final path = Path()..moveTo(corners[0].x, corners[0].y);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].x, corners[i].y);
    }
    return path..close();
  }

  static Path? _wallPath({
    required List<Vector2> topCorners,
    required int tileHeight,
    required List<int?> neighborHeights,
    required int cornerA,
    required int cornerB,
    required int neighborIdx,
  }) {
    final neighborHeight = neighborHeights.length > neighborIdx
        ? (neighborHeights[neighborIdx] ?? 0)
        : 0;
    final delta = tileHeight - neighborHeight;
    if (delta <= 0) return null;

    final depth = baseWallDepth + delta * depthPerHeight;
    final a = topCorners[cornerA];
    final b = topCorners[cornerB];
    return Path()
      ..moveTo(a.x, a.y)
      ..lineTo(b.x, b.y)
      ..lineTo(b.x, b.y + depth)
      ..lineTo(a.x, a.y + depth)
      ..close();
  }

  static List<bool> _topOutlineEdges({
    required int tileHeight,
    required List<int?> outlineNeighborHeights,
  }) {
    if (outlineNeighborHeights.length < 6) {
      return List<bool>.filled(6, true, growable: false);
    }
    return List<bool>.generate(6, (edge) {
      final neighborHeight = outlineNeighborHeights[edge];
      if (neighborHeight == null) return true;
      if (neighborHeight < tileHeight) return true;
      if (neighborHeight > tileHeight) return false;
      return edge <= 2;
    }, growable: false);
  }
}
