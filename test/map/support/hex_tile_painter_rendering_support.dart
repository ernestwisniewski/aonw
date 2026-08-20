part of '../hex_tile_painter_test.dart';

Offset _citySiteCenter(HexTileGeometrySnapshot geometry) {
  final topVertexY = geometry.topCorners
      .map((corner) => corner.y)
      .reduce(math.min);
  return Offset(geometry.topCenter.dx, topVertexY + 18.5);
}

Offset _cityGrowthCenter(HexTileGeometrySnapshot geometry) {
  final rightEdgeX = geometry.topCorners
      .map((corner) => corner.x)
      .reduce(math.max);
  return Offset(rightEdgeX - 18.5, geometry.topCenter.dy);
}

Future<_RenderedTile> _renderTile({
  int tileHeight = 2,
  bool outlineOnlyTopFace = false,
  bool showHeightBadge = false,
  bool alwaysShowHeight = false,
  bool showCitySiteMarker = false,
  bool showRecommendedCitySiteMarker = false,
  bool showCityGrowthMarker = false,
  bool showWorkerImprovementNowMarker = false,
  bool showWorkerImprovementTechMarker = false,
  bool showWorkerImprovementCandidateMarker = false,
  bool showWorkerBuildAvailableBorder = false,
  bool showWorkerBuildBlockedBorder = false,
  bool showAttackTargetMarker = false,
  bool showMovementBlockerOverlay = false,
  bool showIcon = false,
  bool showTerrain = false,
  bool showResources = false,
  int terrainIconCount = 0,
  int resourceIconCount = 0,
  Color outlineColor = const Color(0xFF102018),
  Color wallTintColor = const Color(0xFF264e36),
  List<int?> outlineNeighborHeights = const [0, 0, 0, 0, 0, 0],
}) async {
  const imageWidth = 80;
  const imageHeight = 80;
  const hexRadius = 24.0;
  const perspectiveY = 0.82;
  final painter = HexTilePainter(
    topColor: const Color(0xFF3f8f5f),
    outlineOnlyTopFace: outlineOnlyTopFace,
    outlineColor: outlineColor,
    selectionColor: const Color(0xFFf6d365),
    wallTintColor: wallTintColor,
    tileHeight: tileHeight,
  );
  final geometry = HexTileGeometryLayout.build(
    hexRadius: hexRadius,
    liftOffset: 8,
    tileHeight: tileHeight,
    neighborHeights: const [0, 0, 0],
    outlineNeighborHeights: outlineNeighborHeights,
  );
  final overlays = HexTileOverlayGeometry.build(
    topCenter: geometry.topCenter,
    terrainIconCount: terrainIconCount,
    resourceIconCount: resourceIconCount,
    hexRadius: hexRadius,
    heightParagraphHeight: painter.heightParagraphHeight,
    heightPerspectiveY: perspectiveY,
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.render(
    canvas: canvas,
    geometry: geometry,
    isSelected: false,
    showIcon: showIcon,
    showTerrain: showTerrain,
    showResources: showResources,
    showCitySiteMarker: showCitySiteMarker,
    showRecommendedCitySiteMarker: showRecommendedCitySiteMarker,
    showCityGrowthMarker: showCityGrowthMarker,
    showWorkerImprovementNowMarker: showWorkerImprovementNowMarker,
    showWorkerImprovementTechMarker: showWorkerImprovementTechMarker,
    showWorkerImprovementCandidateMarker: showWorkerImprovementCandidateMarker,
    showWorkerBuildAvailableBorder: showWorkerBuildAvailableBorder,
    showWorkerBuildBlockedBorder: showWorkerBuildBlockedBorder,
    showAttackTargetMarker: showAttackTargetMarker,
    showHeightBadge: showHeightBadge,
    alwaysShowHeight: alwaysShowHeight,
    showMovementBlockerOverlay: showMovementBlockerOverlay,
    overlays: overlays,
    terrainIconPaths: List.filled(
      terrainIconCount,
      const SpriteFrameId('map.terrain.grassland'),
    ),
    resourceIconPaths: List.filled(
      resourceIconCount,
      const SpriteFrameId('map.resource.gold'),
    ),
    heightPerspectiveY: perspectiveY,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(imageWidth, imageHeight);
  picture.dispose();
  final bytes = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();

  return _RenderedTile(
    width: imageWidth,
    height: imageHeight,
    bytes: bytes!,
    geometry: geometry,
    overlays: overlays,
  );
}

class _RenderedTile {
  const _RenderedTile({
    required this.width,
    required this.height,
    required this.bytes,
    required this.geometry,
    required this.overlays,
  });

  final int width;
  final int height;
  final ByteData bytes;
  final HexTileGeometrySnapshot geometry;
  final HexTileOverlayGeometry overlays;

  int alphaAt(Offset offset) {
    final x = offset.dx.round().clamp(0, width - 1);
    final y = offset.dy.round().clamp(0, height - 1);
    return bytes.getUint8(((y * width + x) * 4) + 3);
  }

  int maxAlphaAround(Offset offset, {int radius = 1}) {
    final centerX = offset.dx.round().clamp(0, width - 1);
    final centerY = offset.dy.round().clamp(0, height - 1);
    var maxAlpha = 0;
    for (var y = centerY - radius; y <= centerY + radius; y++) {
      if (y < 0 || y >= height) continue;
      for (var x = centerX - radius; x <= centerX + radius; x++) {
        if (x < 0 || x >= width) continue;
        final alpha = bytes.getUint8(((y * width + x) * 4) + 3);
        if (alpha > maxAlpha) maxAlpha = alpha;
      }
    }
    return maxAlpha;
  }

  int maxAlpha() {
    var maxAlpha = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final alpha = bytes.getUint8(((y * width + x) * 4) + 3);
        if (alpha > maxAlpha) maxAlpha = alpha;
      }
    }
    return maxAlpha;
  }

  ({int r, int g, int b, int a}) colorAt(Offset offset) {
    final x = offset.dx.round().clamp(0, width - 1);
    final y = offset.dy.round().clamp(0, height - 1);
    final index = (y * width + x) * 4;
    return (
      r: bytes.getUint8(index),
      g: bytes.getUint8(index + 1),
      b: bytes.getUint8(index + 2),
      a: bytes.getUint8(index + 3),
    );
  }

  Offset innerTopBorderSample() {
    final center = geometry.topCenter;
    final corner = geometry.topCorners.first;
    return Offset(
      center.dx + (corner.x - center.dx) * 0.82,
      center.dy + (corner.y - center.dy) * 0.82,
    );
  }

  Offset topEdgeSample(int edgeIndex) {
    final from = geometry.topCorners[edgeIndex];
    final to =
        geometry.topCorners[(edgeIndex + 1) % geometry.topCorners.length];
    return Offset((from.x + to.x) / 2, (from.y + to.y) / 2);
  }

  Offset bottomWallSample() {
    return geometry.wallPaths[1]!.getBounds().center;
  }

  Offset wallFaceSample(int edgeIndex, double depthT) {
    final bounds = geometry.wallPaths[edgeIndex]!.getBounds();
    return Offset(
      bounds.center.dx,
      bounds.top + bounds.height * depthT.clamp(0, 1),
    );
  }

  Offset workerImprovementCandidateBorderSample() {
    final center = geometry.topCenter;
    final corner = geometry.topCorners.first;
    return Offset(
      center.dx + (corner.x - center.dx) * 0.68,
      center.dy + (corner.y - center.dy) * 0.68,
    );
  }
}

int _maxChannelDelta(_RenderedTile before, _RenderedTile after, Offset offset) {
  assert(before.width == after.width);
  assert(before.height == after.height);
  final x = offset.dx.round().clamp(0, before.width - 1);
  final y = offset.dy.round().clamp(0, before.height - 1);
  final beforeIndex = (y * before.width + x) * 4;
  final afterIndex = (y * after.width + x) * 4;
  var maxDelta = 0;
  for (var i = 0; i < 4; i++) {
    final a = before.bytes.getUint8(beforeIndex + i);
    final b = after.bytes.getUint8(afterIndex + i);
    final delta = (a - b).abs();
    if (delta > maxDelta) maxDelta = delta;
  }
  return maxDelta;
}
