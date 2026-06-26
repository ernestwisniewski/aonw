import 'dart:io';
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (int row = 0; row < 2; row++)
      for (int col = 0; col < 2; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

void main() {
  group('FogOfWarOverlay', () {
    test('declares a fragment shader asset', () {
      expect(FogOfWarOverlay.shaderAssetPath, 'shaders/fog_of_war.frag');
    });

    test('loads the fragment shader asset', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final program = await ui.FragmentProgram.fromAsset(
        FogOfWarOverlay.shaderAssetPath,
      );

      expect(program, isA<ui.FragmentProgram>());
    });

    test('keeps hidden fog fully opaque', () {
      expect(FogOfWarOverlay.hiddenColor.toARGB32(), 0xFF000000);
    });

    test('extends the mask beyond edge tiles in fallback rendering', () async {
      final overlay = _singleVisibleTileOverlay();

      final rendered = await _renderOverlay(overlay);
      final offMapAlpha = await rendered.alphaAt(
        ui.Offset(rendered.bounds.left + 2, rendered.bounds.top + 2),
      );
      final visibleTileAlpha = await rendered.alphaAt(
        overlay.mapBoundsForTesting.center,
      );

      expect(
        overlay.maskBoundsForTesting.left,
        lessThan(overlay.mapBoundsForTesting.left),
      );
      expect(
        overlay.maskBoundsForTesting.top,
        lessThan(overlay.mapBoundsForTesting.top),
      );
      expect(offMapAlpha, greaterThan(240));
      expect(visibleTileAlpha, 0);
    });

    test('extends the shader mask beyond edge tiles', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final overlay = _singleVisibleTileOverlay();
      await overlay.onLoad();

      final rendered = await _renderOverlay(overlay);
      final offMapAlpha = await rendered.alphaAt(
        ui.Offset(rendered.bounds.left + 2, rendered.bounds.top + 2),
      );
      final visibleTileAlpha = await rendered.alphaAt(
        overlay.mapBoundsForTesting.center,
      );

      expect(offMapAlpha, greaterThan(240));
      expect(visibleTileAlpha, 0);
    });

    test('uses blur for both hidden and discovered fog layers', () {
      expect(FogOfWarOverlay.hiddenBlurSigma, 3.2);
      expect(FogOfWarOverlay.discoveredBlurSigma, 2.4);
      expect(FogOfWarOverlay.discoveredColor.toARGB32(), 0x80000000);
    });

    test('shader samples neighboring mask pixels for softened fog edges', () {
      final source = File(FogOfWarOverlay.shaderAssetPath).readAsStringSync();

      expect(source, contains('blurredFog'));
      expect(source, contains('vec2(2.9)'));
      expect(source, contains('wideTexel'));
      expect(source, contains('sampleFog(uv + vec2(texel.x, 0.0))'));
      expect(source, contains('hiddenCore'));
    });

    test('maps visibility states to shader mask intensities', () {
      expect(FogOfWarOverlay.shaderMaskIntensityFor(FogVisibility.visible), 0);
      expect(
        FogOfWarOverlay.shaderMaskIntensityFor(FogVisibility.discovered),
        0.54,
      );
      expect(FogOfWarOverlay.shaderMaskIntensityFor(FogVisibility.hidden), 1);
    });
  });

  group('FogOfWarOverlayLayer', () {
    test('queues overlay even when parent is not mounted yet', () {
      final map = _map();
      final parent = PositionComponent();
      final layer = FogOfWarOverlayLayer();
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      );

      layer.sync(
        parent: parent,
        mapData: map,
        visibility: FogVisibilityQuery(playerId: 'player_1', state: fog),
      );

      expect(parent.children.whereType<FogOfWarOverlayLayer>(), hasLength(1));
      expect(layer.componentForTesting, isA<FogOfWarOverlay>());
    });

    test('updates an existing overlay instead of replacing it', () {
      final map = _map();
      final parent = PositionComponent();
      final layer = FogOfWarOverlayLayer();
      final firstFog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      );
      final secondFog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 1, row: 1)},
          ),
        },
      );

      layer.sync(
        parent: parent,
        mapData: map,
        visibility: FogVisibilityQuery(playerId: 'player_1', state: firstFog),
      );
      final overlay = layer.componentForTesting!;

      layer.sync(
        parent: parent,
        mapData: map,
        visibility: FogVisibilityQuery(playerId: 'player_1', state: secondFog),
      );

      expect(layer.componentForTesting, same(overlay));
      expect(
        overlay.visibilityByHex[const HexCoordinate(col: 0, row: 0)],
        FogVisibility.hidden,
      );
      expect(
        overlay.visibilityByHex[const HexCoordinate(col: 1, row: 1)],
        FogVisibility.visible,
      );
    });
  });
}

FogOfWarOverlay _singleVisibleTileOverlay() {
  final map = MapData(
    cols: 1,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
    ],
  );
  return FogOfWarOverlay(
    mapData: map,
    hexRadius: 20,
    visibilityByHex: {
      const HexCoordinate(col: 0, row: 0): FogVisibility.visible,
    },
  );
}

Future<_RenderedFogOverlay> _renderOverlay(FogOfWarOverlay overlay) async {
  final bounds = overlay.maskBoundsForTesting;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..translate(-bounds.left, -bounds.top);
  overlay.render(canvas);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(
      bounds.width.ceil(),
      bounds.height.ceil(),
    );
    return _RenderedFogOverlay(image: image, bounds: bounds);
  } finally {
    picture.dispose();
  }
}

class _RenderedFogOverlay {
  const _RenderedFogOverlay({required this.image, required this.bounds});

  final ui.Image image;
  final ui.Rect bounds;

  Future<int> alphaAt(ui.Offset worldPoint) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List();
    final x = (worldPoint.dx - bounds.left).round().clamp(0, image.width - 1);
    final y = (worldPoint.dy - bounds.top).round().clamp(0, image.height - 1);
    final offset = (y * image.width + x) * 4;
    return bytes[offset + 3];
  }
}
