import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityTerritoryOverlay rendering', () {
    test('renders civ-like border stronger than the territory fill', () async {
      const hex = CityHex(col: 0, row: 0);
      final rendered = await _renderOverlay(
        CityTerritoryOverlay(
          territories: [
            CityTerritory(
              color: HudPalette.danger,
              center: hex,
              hexes: const [hex],
            ),
          ],
        ),
      );

      final center = rendered.translate(_hexCenter(hex));
      final border = rendered.translate(_edgeMidpoint(hex, CityHexEdge.south));
      final centerAlpha = rendered.alphaAt(center);
      final borderAlpha = rendered.alphaAt(border);
      final borderColor = rendered.colorAt(border);

      expect(centerAlpha, greaterThan(24));
      expect(centerAlpha, lessThan(96));
      expect(borderAlpha, greaterThan(centerAlpha + 100));
      expect(borderColor.r, greaterThan(borderColor.g));
    });

    test('strengthens territory color when zoomed out', () async {
      const hex = CityHex(col: 0, row: 0);
      final base = await _renderOverlay(
        CityTerritoryOverlay(
          territories: [
            CityTerritory(
              color: HudPalette.danger,
              center: hex,
              hexes: const [hex],
            ),
          ],
        ),
      );
      final zoomedOut = await _renderOverlay(
        CityTerritoryOverlay(
          territories: [
            CityTerritory(
              color: HudPalette.danger,
              center: hex,
              hexes: const [hex],
            ),
          ],
          zoomEmphasis: 1,
        ),
      );

      final center = base.translate(_hexCenter(hex));
      expect(zoomedOut.alphaAt(center), greaterThan(base.alphaAt(center)));
      expect(zoomedOut.alphaAt(center), greaterThan(135));
      expect(zoomedOut.alphaAt(center), lessThan(170));
    });

    test('keeps tile view territory fill at 90 percent overlay', () async {
      const hex = CityHex(col: 0, row: 0);
      const offscreenCenter = CityHex(col: 20, row: 20);
      final base = await _renderOverlay(
        CityTerritoryOverlay(
          territories: [
            CityTerritory(
              color: HudPalette.danger,
              center: offscreenCenter,
              hexes: const [hex],
            ),
          ],
          strategicView: true,
        ),
      );
      final zoomedOut = await _renderOverlay(
        CityTerritoryOverlay(
          territories: [
            CityTerritory(
              color: HudPalette.danger,
              center: offscreenCenter,
              hexes: const [hex],
            ),
          ],
          strategicView: true,
          zoomEmphasis: 1,
        ),
      );

      final center = base.translate(_hexCenter(hex));
      final baseAlpha = base.alphaAt(center);
      final zoomedOutAlpha = zoomedOut.alphaAt(center);
      expect(baseAlpha, closeTo(230, 2));
      expect(zoomedOutAlpha, baseAlpha);
    });
  });
}

Future<_RenderedOverlay> _renderOverlay(CityTerritoryOverlay overlay) async {
  const width = 240;
  const height = 220;
  const padding = ui.Offset(72, 72);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..translate(padding.dx, padding.dy);
  overlay.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final bytes = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();

  return _RenderedOverlay(
    width: width,
    height: height,
    padding: padding,
    bytes: bytes!,
  );
}

ui.Offset _hexCenter(CityHex hex) {
  final corners = _hexCorners(hex);
  var dx = 0.0;
  var dy = 0.0;
  for (final corner in corners) {
    dx += corner.dx;
    dy += corner.dy;
  }
  return ui.Offset(dx / corners.length, dy / corners.length);
}

ui.Offset _edgeMidpoint(CityHex hex, CityHexEdge side) {
  final corners = _hexCorners(hex);
  final indexes = switch (side) {
    CityHexEdge.northEast => (5, 0),
    CityHexEdge.southEast => (0, 1),
    CityHexEdge.south => (1, 2),
    CityHexEdge.southWest => (2, 3),
    CityHexEdge.northWest => (3, 4),
    CityHexEdge.north => (4, 5),
  };
  final a = corners[indexes.$1];
  final b = corners[indexes.$2];
  return ui.Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
}

List<ui.Offset> _hexCorners(CityHex hex) {
  final hexRadius = MapConfig.defaultConfig.hexRadius;
  final center = HexGeometry.tilePosition(
    col: hex.col,
    row: hex.row,
    hexRadius: hexRadius,
  );
  final topFaceCenter = Vector2(
    center.x,
    center.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius),
  );
  final corners = HexGeometry.topFaceCorners(
    center: topFaceCenter,
    radius: hexRadius,
  );
  return [for (final corner in corners) ui.Offset(corner.x, corner.y)];
}

class _RenderedOverlay {
  const _RenderedOverlay({
    required this.width,
    required this.height,
    required this.padding,
    required this.bytes,
  });

  final int width;
  final int height;
  final ui.Offset padding;
  final ByteData bytes;

  ui.Offset translate(ui.Offset offset) => offset + padding;

  int alphaAt(ui.Offset offset) {
    final index = _pixelIndex(offset);
    return bytes.getUint8(index + 3);
  }

  ({int r, int g, int b, int a}) colorAt(ui.Offset offset) {
    final index = _pixelIndex(offset);
    return (
      r: bytes.getUint8(index),
      g: bytes.getUint8(index + 1),
      b: bytes.getUint8(index + 2),
      a: bytes.getUint8(index + 3),
    );
  }

  int _pixelIndex(ui.Offset offset) {
    final x = offset.dx.round().clamp(0, width - 1);
    final y = offset.dy.round().clamp(0, height - 1);
    return (y * width + x) * 4;
  }
}
