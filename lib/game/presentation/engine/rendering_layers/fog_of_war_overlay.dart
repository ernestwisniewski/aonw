import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_palette.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';

class FogOfWarOverlay extends PositionComponent {
  final MapData mapData;
  Map<HexCoordinate, FogVisibility> visibilityByHex;
  final double hexRadius;
  double _time = 0;
  ui.FragmentProgram? _shaderProgram;
  ui.Image? _visibilityMask;
  Rect _mapBounds = Rect.zero;
  Rect _shaderBounds = Rect.zero;
  List<Path> _tilePaths = const [];

  static const String shaderAssetPath = 'shaders/fog_of_war.frag';
  static const Color hiddenColor = MapPalette.fogHidden;
  static const Color discoveredColor = MapPalette.fogDiscovered;
  static const double edgeMaskPaddingHexes = 3.0;
  static const double hiddenBlurSigma = 3.2;
  static const double discoveredBlurSigma = 2.4;
  static final Decorator _hiddenFogDecorator = PaintDecorator.blur(
    hiddenBlurSigma,
  );
  static final Decorator _discoveredFogDecorator = PaintDecorator.blur(
    discoveredBlurSigma,
  );
  static ui.FragmentProgram? _cachedShaderProgram;
  static Future<ui.FragmentProgram?>? _pendingShaderProgram;

  FogOfWarOverlay({
    required this.mapData,
    required this.visibilityByHex,
    this.hexRadius = MapConfig.defaultHexRadius,
  }) {
    _rebuildStaticGeometry();
  }

  @visibleForTesting
  Rect get mapBoundsForTesting => _mapBounds;

  @visibleForTesting
  Rect get maskBoundsForTesting => _shaderBounds;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadShaderProgram();
    _rebuildVisibilityMask();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void onRemove() {
    _visibilityMask?.dispose();
    _visibilityMask = null;
    super.onRemove();
  }

  void updateVisibility(Map<HexCoordinate, FogVisibility> next) {
    visibilityByHex = next;
    _rebuildVisibilityMask();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_renderShaderFog(canvas)) return;

    _renderFallbackFog(canvas);
  }

  void _renderFallbackFog(Canvas canvas) {
    _drawOffMapFallbackMask(canvas);

    final paint = Paint()..style = PaintingStyle.fill;
    _hiddenFogDecorator.applyChain(
      (decoratedCanvas) => _drawFogTiles(
        decoratedCanvas,
        paint,
        targetVisibility: FogVisibility.hidden,
        color: hiddenColor,
      ),
      canvas,
    );
    _discoveredFogDecorator.applyChain(
      (decoratedCanvas) => _drawFogTiles(
        decoratedCanvas,
        paint,
        targetVisibility: FogVisibility.discovered,
        color: discoveredColor,
      ),
      canvas,
    );
  }

  bool _renderShaderFog(Canvas canvas) {
    final program = _shaderProgram;
    final mask = _visibilityMask;
    if (program == null || mask == null || _shaderBounds.isEmpty) {
      return false;
    }

    // Shader uniforms describe the full visibility mask (so UV sampling
    // stays correct) but the actual drawRect is clamped to the viewport,
    // otherwise the fragment shader runs once per pixel of the entire map
    // even when only a fraction is on screen.
    final clipBounds = canvas.getLocalClipBounds();
    final drawRect = clipBounds.isEmpty
        ? _shaderBounds
        : _shaderBounds.intersect(clipBounds);
    if (drawRect.isEmpty) return true;

    final shader = program.fragmentShader()
      ..setFloat(0, _shaderBounds.width)
      ..setFloat(1, _shaderBounds.height)
      ..setFloat(2, _time)
      ..setImageSampler(0, mask);

    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.srcOver;

    canvas
      ..save()
      ..translate(_shaderBounds.left, _shaderBounds.top)
      ..drawRect(drawRect.shift(-_shaderBounds.topLeft), paint)
      ..restore();
    return true;
  }

  Future<void> _loadShaderProgram() async {
    _shaderProgram = await preloadShaderProgram();
  }

  static Future<ui.FragmentProgram?> preloadShaderProgram() {
    final cached = _cachedShaderProgram;
    if (cached != null) return Future.value(cached);
    final pending = _pendingShaderProgram;
    if (pending != null) return pending;

    final future = _loadShaderProgramAsset();
    _pendingShaderProgram = future;
    return future;
  }

  static Future<ui.FragmentProgram?> _loadShaderProgramAsset() async {
    try {
      return _cachedShaderProgram = await ui.FragmentProgram.fromAsset(
        shaderAssetPath,
      );
    } catch (_) {
      return null;
    } finally {
      _pendingShaderProgram = null;
    }
  }

  void _rebuildVisibilityMask() {
    if (_shaderProgram == null) return;

    final bounds = _shaderBounds;
    if (bounds.isEmpty) {
      _visibilityMask?.dispose();
      _visibilityMask = null;
      return;
    }

    final width = math.max(1, bounds.width.ceil());
    final height = math.max(1, bounds.height.ceil());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..translate(-bounds.left, -bounds.top);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = BlendMode.src
      ..color = _shaderMaskColorFor(1);
    canvas.drawRect(bounds, paint);

    paint.color = _shaderMaskColorFor(0);
    for (final path in _tilePaths) {
      canvas.drawPath(path, paint);
    }

    for (var i = 0; i < mapData.tiles.length; i += 1) {
      final tile = mapData.tiles[i];
      final visibility =
          visibilityByHex[HexCoordinate.fromTile(tile)] ?? FogVisibility.hidden;
      final intensity = shaderMaskIntensityFor(visibility);
      if (intensity <= 0) continue;

      paint.color = _shaderMaskColorFor(intensity);
      canvas.drawPath(_tilePaths[i], paint);
    }

    final picture = recorder.endRecording();
    try {
      final nextMask = picture.toImageSync(width, height);
      _visibilityMask?.dispose();
      _visibilityMask = nextMask;
    } finally {
      picture.dispose();
    }
  }

  void _rebuildStaticGeometry() {
    _mapBounds = _mapBoundsForTiles();
    _shaderBounds = _mapBounds.isEmpty
        ? Rect.zero
        : _mapBounds.inflate(hexRadius * edgeMaskPaddingHexes);
    _tilePaths = [
      for (final tile in mapData.tiles) _hexPath(tile.col, tile.row),
    ];
  }

  Color _shaderMaskColorFor(double intensity) {
    return Color.fromARGB(
      MapAlpha.full,
      (intensity * MapAlpha.full).round(),
      0,
      0,
    );
  }

  Rect _mapBoundsForTiles() {
    if (mapData.tiles.isEmpty) return Rect.zero;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final tile in mapData.tiles) {
      final corners = HexGeometry.topFaceCorners(
        center: HexGeometry.tilePosition(
          col: tile.col,
          row: tile.row,
          hexRadius: hexRadius,
        ),
        radius: hexRadius,
      );
      for (final corner in corners) {
        minX = math.min(minX, corner.x);
        minY = math.min(minY, corner.y);
        maxX = math.max(maxX, corner.x);
        maxY = math.max(maxY, corner.y);
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Path _hexPath(int col, int row) {
    final center = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: hexRadius,
    );
    final corners = HexGeometry.topFaceCorners(
      center: center,
      radius: hexRadius,
    );
    final path = Path()..moveTo(corners.first.x, corners.first.y);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.x, corner.y);
    }
    return path..close();
  }

  void _drawFogTiles(
    Canvas canvas,
    Paint paint, {
    required FogVisibility targetVisibility,
    required Color color,
  }) {
    for (var i = 0; i < mapData.tiles.length; i += 1) {
      final tile = mapData.tiles[i];
      final visibility =
          visibilityByHex[HexCoordinate.fromTile(tile)] ?? FogVisibility.hidden;
      if (visibility != targetVisibility) continue;

      paint.color = color;
      canvas.drawPath(_tilePaths[i], paint);
    }
  }

  void _drawOffMapFallbackMask(Canvas canvas) {
    final bounds = _shaderBounds;
    if (bounds.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.saveLayer(bounds, Paint());
    paint
      ..blendMode = BlendMode.srcOver
      ..color = hiddenColor;
    canvas.drawRect(bounds, paint);

    paint
      ..blendMode = BlendMode.clear
      ..color = Colors.transparent;
    for (final path in _tilePaths) {
      canvas.drawPath(path, paint);
    }

    paint.blendMode = BlendMode.srcOver;
    canvas.restore();
  }

  static double shaderMaskIntensityFor(FogVisibility visibility) {
    return switch (visibility) {
      FogVisibility.visible => 0.0,
      FogVisibility.discovered => 0.54,
      FogVisibility.hidden => 1.0,
    };
  }
}
