import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/map/rendering/tile/hex_tile_painter.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

part 'support/hex_tile_painter_rendering_support.dart';

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
      'grid-off graphic mode paints no overlay over the map image',
      () async {
        final rendered = await _renderTile(
          outlineOnlyTopFace: true,
          outlineColor: HexDisplaySettings.defaultHexBorderColor,
          wallTintColor: HexDisplaySettings.defaultWallTintColor,
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
          visible.overlays.heightBadge.paragraphOffset + const Offset(8, 3.5);
      expect(hidden.alphaAt(badgeCenter), 0);
      expect(visible.alphaAt(badgeCenter), greaterThan(100));
    });

    test('attack target uses a red fill with darker hatching', () async {
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        showCitySiteMarker: true,
        showCityGrowthMarker: true,
        showWorkerImprovementNowMarker: true,
        showWorkerImprovementTechMarker: true,
        showAttackTargetMarker: true,
      );
      final topCenter = rendered.geometry.topCenter;
      final fillColor = rendered.colorAt(topCenter);
      expect(rendered.alphaAt(topCenter), inInclusiveRange(85, 100));
      expect(rendered.maxAlphaAround(topCenter), greaterThan(100));
      expect(fillColor.r, greaterThan(fillColor.g));
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

    test('draws a lightweight worker improvement highlight', () async {
      final plain = await _renderTile(outlineOnlyTopFace: true);
      final rendered = await _renderTile(
        outlineOnlyTopFace: true,
        showWorkerImprovementCandidateMarker: true,
      );

      final borderSample = rendered.workerImprovementCandidateBorderSample();
      final color = rendered.colorAt(borderSample);
      final center = rendered.geometry.topCenter;
      final centerColor = rendered.colorAt(center);
      final plainCenterColor = plain.colorAt(plain.geometry.topCenter);

      expect(rendered.alphaAt(borderSample), greaterThan(120));
      expect(color.g, greaterThan(color.r));
      expect(centerColor, isNot(plainCenterColor));
    });

    test('city planning markers keep their map-relative anchors', () async {
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

      final siteCenter = _citySiteCenter(siteOnly.geometry);
      final growthCenter = _cityGrowthCenter(growthOnly.geometry);
      expect(siteOnly.alphaAt(siteCenter), greaterThan(60));
      expect(growthOnly.alphaAt(growthCenter), greaterThan(60));
      expect(both.alphaAt(_citySiteCenter(both.geometry)), greaterThan(60));
      expect(both.alphaAt(_cityGrowthCenter(both.geometry)), greaterThan(60));
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

      final center = _citySiteCenter(regular.geometry);
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

      expect(
        rendered.alphaAt(_citySiteCenter(rendered.geometry)),
        greaterThan(60),
      );
      expect(
        rendered.alphaAt(_cityGrowthCenter(rendered.geometry)),
        greaterThan(60),
      );
      expect(
        rendered.alphaAt(
          rendered.overlays.terrainIcons.iconRects.single.center,
        ),
        greaterThan(100),
      );
      expect(
        rendered.alphaAt(
          rendered.overlays.resourceIcons.iconRects.first.center,
        ),
        greaterThan(100),
      );
    });

    test('draws terrain icons when icon layer flag is disabled', () async {
      final withoutTerrainIcons = await _renderTile(
        outlineOnlyTopFace: true,
        showIcon: false,
        showTerrain: true,
        showResources: false,
        terrainIconCount: 0,
      );
      final withTerrainIcons = await _renderTile(
        outlineOnlyTopFace: true,
        showIcon: false,
        showTerrain: true,
        showResources: false,
        terrainIconCount: 1,
      );

      final terrainIconCenter =
          withTerrainIcons.overlays.terrainIcons.iconRects.single.center;

      expect(
        _maxChannelDelta(
          withoutTerrainIcons,
          withTerrainIcons,
          terrainIconCenter,
        ),
        greaterThan(0),
      );
    });

    test('draws resource icons when icon layer flag is disabled', () async {
      final withoutResourceIcons = await _renderTile(
        outlineOnlyTopFace: true,
        showIcon: false,
        showTerrain: false,
        showResources: false,
        resourceIconCount: 0,
      );
      final withResourceIcons = await _renderTile(
        outlineOnlyTopFace: true,
        showIcon: false,
        showTerrain: false,
        showResources: true,
        resourceIconCount: 1,
      );

      final resourceIconCenter =
          withResourceIcons.overlays.resourceIcons.iconRects.single.center;

      expect(
        _maxChannelDelta(
          withoutResourceIcons,
          withResourceIcons,
          resourceIconCenter,
        ),
        greaterThan(0),
      );
    });
  });
}
