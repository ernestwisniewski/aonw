import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/map/rendering/tile/hex_tile_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HexTilePainter', () {
    test('fills the top face when not in outline-only mode', () async {
      final filled = await _renderTile(outlineOnlyTopFace: false);
      final outlineOnly = await _renderTile(outlineOnlyTopFace: true);

      final topCenter = filled.geometry.topCenter;
      expect(filled.alphaAt(topCenter), greaterThan(200));
      expect(outlineOnly.alphaAt(topCenter), 0);
    });

    test('respects transparent top outline color', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        outlineColor: const Color(0x00000000),
      );

      expect(rendered.alphaAt(rendered.topEdgeSample(4)), 0);
    });

    test(
      'renders no hex overlay when wall and border opacity are zero',
      () async {
        final rendered = await _renderTile(
          outlineOnlyTopFace: true,
          outlineColor: const Color(0x00000000),
          wallTintColor: const Color(0x00000000),
        );

        expect(rendered.maxAlpha(), 0);
      },
    );

    test(
      'preserves configured wall opacity when brightening wall sides',
      () async {
        final rendered = await _renderTile(
          outlineOnlyTopFace: false,
          outlineColor: const Color(0x00000000),
          wallTintColor: const Color(0x40264e36),
        );

        expect(
          rendered.alphaAt(rendered.bottomWallSample()),
          inInclusiveRange(56, 68),
        );
      },
    );

    test('keeps outline-mode wall shading as a solid 3d face', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        outlineColor: const Color(0x00000000),
        wallTintColor: const Color(0xFF264e36),
      );

      expect(
        rendered.maxAlphaAround(rendered.topEdgeSample(1)),
        greaterThan(80),
      );
      expect(
        rendered.alphaAt(rendered.wallFaceSample(1, 0.35)),
        greaterThan(220),
      );
      expect(
        rendered.alphaAt(rendered.wallFaceSample(1, 0.98)),
        greaterThan(220),
      );
      expect(
        rendered.alphaAt(rendered.wallFaceSample(1, 0.75)),
        greaterThan(220),
      );
    });

    test(
      'merges outline-mode border and wall shading into one edge stroke',
      () async {
        final rendered = await _renderTile(
          outlineOnlyTopFace: true,
          outlineColor: const Color(0xFF102018),
          wallTintColor: const Color(0xFF264e36),
        );

        expect(
          rendered.maxAlphaAround(rendered.topEdgeSample(1)),
          greaterThan(80),
        );
        expect(
          rendered.alphaAt(rendered.wallFaceSample(1, 0.35)),
          greaterThan(220),
        );
        expect(
          rendered.alphaAt(rendered.wallFaceSample(1, 0.98)),
          greaterThan(220),
        );
        expect(
          rendered.alphaAt(rendered.wallFaceSample(1, 0.75)),
          greaterThan(220),
        );
      },
    );

    test('skips top outline edge hidden by a taller neighbor', () async {
      final visible = await _renderTile(
        tileHeight: 0,
        outlineOnlyTopFace: true,
        outlineNeighborHeights: const [0, 0, 0, 0, 0, 0],
      );
      final hidden = await _renderTile(
        tileHeight: 0,
        outlineOnlyTopFace: true,
        outlineNeighborHeights: const [0, 2, 0, 0, 0, 0],
      );

      final sample = visible.topEdgeSample(1);
      expect(visible.maxAlphaAround(sample), greaterThan(80));
      expect(hidden.maxAlphaAround(sample), 0);
    });

    test('draws only one owner edge between equal-height neighbors', () async {
      final rendered = await _renderTile(
        tileHeight: 0,
        outlineOnlyTopFace: true,
        outlineNeighborHeights: const [0, 0, 0, 0, 0, 0],
      );

      expect(
        rendered.maxAlphaAround(rendered.topEdgeSample(1)),
        greaterThan(80),
      );
      expect(rendered.maxAlphaAround(rendered.topEdgeSample(4)), 0);
    });

    test('draws forced height badge even when tile height is zero', () async {
      final hidden = await _renderTile(
        tileHeight: 0,
        outlineOnlyTopFace: true,
        showHeightBadge: true,
      );
      final visible = await _renderTile(
        tileHeight: 0,
        outlineOnlyTopFace: true,
        showHeightBadge: true,
        alwaysShowHeight: true,
      );

      final badgeCenter =
          visible.overlays.heightBadge.badgeRect.outerRect.center;
      expect(hidden.alphaAt(badgeCenter), 0);
      expect(visible.alphaAt(badgeCenter), greaterThan(100));
    });

    test('attack marker takes priority over other planning markers', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        showCitySiteMarker: true,
        showCityGrowthMarker: true,
        showWorkerImprovementNowMarker: true,
        showWorkerImprovementTechMarker: true,
        showAttackTargetMarker: true,
      );

      final topCenter = rendered.geometry.topCenter;
      expect(rendered.alphaAt(topCenter.translate(0, 6)), greaterThan(100));
    });

    test('draws movement blocker overlay over the top face', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        showMovementBlockerOverlay: true,
      );

      expect(rendered.alphaAt(rendered.geometry.topCenter), greaterThan(60));
    });

    test('draws worker build borders in green or red inside the hex', () async {
      final available = await _renderTile(
        outlineOnlyTopFace: true,
        showWorkerBuildAvailableBorder: true,
      );
      final blocked = await _renderTile(
        outlineOnlyTopFace: true,
        showWorkerBuildBlockedBorder: true,
      );

      final sample = available.innerTopBorderSample();
      final availableColor = available.colorAt(sample);
      final blockedColor = blocked.colorAt(sample);

      expect(available.alphaAt(sample), greaterThan(120));
      expect(blocked.alphaAt(sample), greaterThan(120));
      expect(availableColor.g, greaterThan(availableColor.r));
      expect(blockedColor.r, greaterThan(blockedColor.g));
    });

    test('draws worker improvement candidate marker inside the hex', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        showWorkerImprovementCandidateMarker: true,
      );

      final borderSample = rendered.workerImprovementCandidateBorderSample();
      final iconSample = rendered.workerImprovementCandidateIconSample();
      final color = rendered.colorAt(borderSample);

      expect(rendered.alphaAt(borderSample), greaterThan(120));
      expect(rendered.alphaAt(iconSample), greaterThan(120));
      expect(color.g, greaterThan(color.r));
    });

    test('city planning markers center alone and split as a pair', () async {
      final siteOnly = await _renderTile(
        outlineOnlyTopFace: true,
        showCitySiteMarker: true,
      );
      final growthOnly = await _renderTile(
        outlineOnlyTopFace: true,
        showCityGrowthMarker: true,
      );
      final both = await _renderTile(
        outlineOnlyTopFace: true,
        showCitySiteMarker: true,
        showCityGrowthMarker: true,
      );

      final singleCenter = siteOnly.geometry.topCenter.translate(0, -6);
      expect(siteOnly.alphaAt(singleCenter), greaterThan(100));
      expect(growthOnly.alphaAt(singleCenter), greaterThan(100));

      final leftPair = both.geometry.topCenter.translate(-11.5, -6);
      final rightPair = both.geometry.topCenter.translate(11.5, -6);
      expect(both.alphaAt(leftPair), greaterThan(100));
      expect(both.alphaAt(rightPair), greaterThan(100));
    });

    test('recommended city site marker uses green background', () async {
      final regular = await _renderTile(
        outlineOnlyTopFace: true,
        showCitySiteMarker: true,
      );
      final recommended = await _renderTile(
        outlineOnlyTopFace: true,
        showCitySiteMarker: true,
        showRecommendedCitySiteMarker: true,
      );

      final center = regular.geometry.topCenter.translate(0, -6);
      final regularColor = regular.colorAt(center);
      final recommendedColor = recommended.colorAt(center);

      expect(recommendedColor.g, greaterThan(regularColor.g));
      expect(recommendedColor.g, greaterThan(recommendedColor.r));
    });

    test('city planning markers render above terrain and resources', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        showIcon: true,
        showTerrain: true,
        showResources: true,
        terrainIconCount: 1,
        resourceIconCount: 2,
        showCitySiteMarker: true,
        showCityGrowthMarker: true,
      );

      final cityAnchor = rendered.geometry.topCenter.translate(
        24.0 * 0.16,
        -24.0 * 0.55,
      );
      final leftPair = cityAnchor.translate(-11.5, 0);
      final rightPair = cityAnchor.translate(11.5, 0);
      expect(rendered.alphaAt(leftPair), greaterThan(220));
      expect(rendered.alphaAt(rightPair), greaterThan(220));
      expect(
        rendered.alphaAt(
          rendered.overlays.terrainIcons.iconRects.single.center,
        ),
        greaterThan(100),
      );
      expect(
        rendered.alphaAt(
          rendered.overlays.resourceIcons.badgeRects.first.outerRect.center,
        ),
        greaterThan(100),
      );
    });
  });
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
      'assets/icons/terrain_grassland.png',
    ),
    resourceIconPaths: List.filled(resourceIconCount, 'assets/icons/gold.png'),
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

  Offset workerImprovementCandidateIconSample() {
    return geometry.topCenter.translate(0, 1);
  }
}
