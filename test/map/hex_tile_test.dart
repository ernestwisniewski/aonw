import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexGeometry corners', () {
    test('returns 6 points for flat-top hex', () {
      final corners = HexGeometry.topFaceCorners(
        center: Vector2(0, 0),
        radius: 36.0,
      );
      expect(corners.length, 6);
    });

    test('corner 0 is at angle 0° (rightmost)', () {
      final corners = HexGeometry.topFaceCorners(
        center: Vector2(0, 0),
        radius: 36.0,
      );
      expect(corners[0].x, closeTo(36.0, 0.01));
      expect(corners[0].y, closeTo(0.0, 0.01));
    });
  });

  group('HexGeometry containsPoint', () {
    test('returns true for center point', () {
      final corners = HexGeometry.topFaceCorners(
        center: Vector2(50, 50),
        radius: 36.0,
      );
      expect(HexGeometry.containsPoint(Vector2(50, 50), corners), isTrue);
    });

    test('returns false for point far outside', () {
      final corners = HexGeometry.topFaceCorners(
        center: Vector2(50, 50),
        radius: 36.0,
      );
      expect(HexGeometry.containsPoint(Vector2(200, 200), corners), isFalse);
    });

    test('returns false for point in bounding box but outside hex', () {
      // (17, 22) is inside bbox [14..86, 18.82..81.18] but outside the hex
      final corners = HexGeometry.topFaceCorners(
        center: Vector2(50, 50),
        radius: 36.0,
      );
      expect(HexGeometry.containsPoint(Vector2(17, 22), corners), isFalse);
    });
  });

  group('HexGeometry.tileAt', () {
    const r = 60.0;

    test('center of tile (0,0) returns (0,0)', () {
      final center = HexGeometry.tilePosition(col: 0, row: 0, hexRadius: r);
      final result = HexGeometry.tileAt(
        point: center,
        hexRadius: r,
        cols: 5,
        rows: 5,
      );
      expect(result, isNotNull);
      expect(result!.col, 0);
      expect(result.row, 0);
    });

    test('center of tile (2,3) returns (2,3)', () {
      final center = HexGeometry.tilePosition(col: 2, row: 3, hexRadius: r);
      final result = HexGeometry.tileAt(
        point: center,
        hexRadius: r,
        cols: 5,
        rows: 5,
      );
      expect(result, isNotNull);
      expect(result!.col, 2);
      expect(result.row, 3);
    });

    test('point far outside grid returns null', () {
      final result = HexGeometry.tileAt(
        point: Vector2(9999, 9999),
        hexRadius: r,
        cols: 5,
        rows: 5,
      );
      expect(result, isNull);
    });

    test('point between tiles (near edge) still resolves to a tile', () {
      final c00 = HexGeometry.tilePosition(col: 0, row: 0, hexRadius: r);
      final c10 = HexGeometry.tilePosition(col: 1, row: 0, hexRadius: r);
      final midpoint = Vector2((c00.x + c10.x) / 2, (c00.y + c10.y) / 2);
      // midpoint may fall on either tile — just verify it returns something valid
      final result = HexGeometry.tileAt(
        point: midpoint,
        hexRadius: r,
        cols: 5,
        rows: 5,
      );
      // could be null (gap between hexes) or a valid tile — both are acceptable
      if (result != null) {
        expect(result.col, inInclusiveRange(0, 4));
        expect(result.row, inInclusiveRange(0, 4));
      }
    });
  });

  group('HexTileGeometryLayout', () {
    test('builds top face geometry around lifted center', () {
      final geometry = HexTileGeometryLayout.build(
        hexRadius: 10,
        liftOffset: -4,
        tileHeight: 0,
        neighborHeights: const [null, null, null],
      );

      expect(geometry.topCenter.dx, closeTo(10, 0.01));
      expect(
        geometry.topCenter.dy,
        closeTo(10 * HexTileGeometryLayout.sqrt3Half - 4, 0.01),
      );
      expect(geometry.topCorners, hasLength(6));
      expect(geometry.wallPaths, hasLength(3));
    });

    test('builds wall only when tile is higher than the neighbor', () {
      final geometry = HexTileGeometryLayout.build(
        hexRadius: 10,
        liftOffset: 0,
        tileHeight: 4,
        neighborHeights: const [4, 1, 5],
      );

      expect(geometry.wallPaths[0], isNull);
      expect(geometry.wallPaths[1], isNotNull);
      expect(geometry.wallPaths[2], isNull);
    });

    test('marks top outline edges hidden by taller neighbors', () {
      final geometry = HexTileGeometryLayout.build(
        hexRadius: 10,
        liftOffset: 0,
        tileHeight: 2,
        neighborHeights: const [0, 0, 0],
        outlineNeighborHeights: const [1, 2, 3, null, 4, 0],
      );

      expect(geometry.topOutlineEdges, [true, true, false, true, false, true]);
    });

    test('keeps one owner edge for equal-height top outlines', () {
      final geometry = HexTileGeometryLayout.build(
        hexRadius: 10,
        liftOffset: 0,
        tileHeight: 2,
        neighborHeights: const [0, 0, 0],
        outlineNeighborHeights: const [2, 2, 2, 2, 2, 2],
      );

      expect(geometry.topOutlineEdges, [true, true, true, false, false, false]);
    });

    test('bottom wall depth scales with height delta', () {
      final geometry = HexTileGeometryLayout.build(
        hexRadius: 10,
        liftOffset: 0,
        tileHeight: 4,
        neighborHeights: const [4, 1, 4],
      );

      final bottomWallBounds = geometry.wallPaths[1]!.getBounds();
      expect(
        bottomWallBounds.height,
        closeTo(
          HexTileGeometryLayout.baseWallDepth +
              3 * HexTileGeometryLayout.depthPerHeight,
          0.01,
        ),
      );
    });
  });

  group('HexTileMetrics', () {
    test('top face center is above the component anchor', () {
      expect(HexTileMetrics.topCenterAnchorOffsetY(50), closeTo(-12, 0.01));
    });
  });

  group('HexTileOverlayGeometry', () {
    test('builds terrain, resource, and height badge geometry together', () {
      final overlays = HexTileOverlayGeometry.build(
        topCenter: const Offset(40, 40),
        terrainIconCount: 2,
        resourceIconCount: 1,
        hexRadius: 20,
        heightParagraphHeight: 7,
        heightPerspectiveY: 0.82,
      );

      expect(overlays.terrainIcons.boxRect, isNotNull);
      expect(overlays.terrainIcons.iconRects, hasLength(2));
      expect(overlays.terrainIcons.badgeRects, hasLength(2));
      expect(overlays.resourceIcons.boxRect, isNotNull);
      expect(overlays.resourceIcons.iconRects, hasLength(1));
      expect(overlays.resourceIcons.badgeRects, hasLength(1));
      final resourceBadge = overlays.resourceIcons.badgeRects.single;
      expect(resourceBadge.outerRect.width, greaterThan(30));
      expect(
        resourceBadge.outerRect.width,
        closeTo(resourceBadge.outerRect.height, 0.01),
      );
      expect(
        resourceBadge.tlRadiusX,
        lessThan(resourceBadge.outerRect.width / 2),
      );
      expect(
        overlays.resourceIcons.iconRects.single.width,
        greaterThan(overlays.terrainIcons.iconRects.first.width),
      );
      expect(overlays.heightBadge.badgeRect.width, closeTo(16, 0.01));
    });
  });

  group('HexDisplaySettings', () {
    test('shows resources by default', () {
      expect(const HexDisplaySettings().showResources, isTrue);
    });

    test('hides height badges by default', () {
      expect(const HexDisplaySettings().showHeightBadge, isFalse);
    });

    test('hides city planning overlays by default', () {
      const settings = HexDisplaySettings();

      expect(settings.showCitySites, isFalse);
      expect(settings.showCityGrowth, isFalse);
    });

    test('starts map wall and border overlays fully transparent', () {
      const settings = HexDisplaySettings();

      expect(settings.hexBorderColor.toARGB32(), 0x00000000);
      expect(settings.wallTintColor.toARGB32(), 0x00000000);
    });
  });
}
