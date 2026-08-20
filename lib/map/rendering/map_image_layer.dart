import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_texture_repository.dart';
import 'package:aonw/map/rendering/saved_map_texture_layout.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

part 'map_image_layer_texture_set.dart';

/// Renders every map image source through one paged texture-set pipeline.
///
/// Generated bundled maps load their checked manifest directly. Saved raster
/// images and saved slice directories are converted by
/// [SavedMapTextureAdapter] before they reach this component.
class MapImageLayer extends PositionComponent {
  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  MapImageLayer({
    required this.config,
    required int cols,
    required int rows,
    MapTextureRepository? textureRepository,
  }) : _textureRepository = textureRepository ?? FlutterMapTextureRepository(),
       _cols = cols,
       _rows = rows,
       super(scale: Vector2(1, HexGrid.perspectiveY)) {
    _updateSize();
  }

  final MapConfig config;
  final MapTextureRepository _textureRepository;
  int _cols;
  int _rows;
  MapTextureSet? _textureSet;
  Path? _textureClipPath;
  final Set<String> _pendingTexturePages = {};
  final Set<String> _failedTexturePages = {};
  var _loadGeneration = 0;

  bool showImage = true;

  bool get hasImage => _textureSet != null;

  @visibleForTesting
  bool get usesPagedTexturesForTesting => _textureSet != null;

  Color? averageColorForTile(int col, int row) =>
      _textureSet?.averageColors[(col, row)];

  Future<void> loadSource(
    MapImageSource source, {
    ValueChanged<double>? onProgress,
  }) {
    final generation = ++_loadGeneration;
    return switch (source) {
      BundledMapTextureSource(:final manifestAssetPath) => _loadTextureSet(
        manifestAssetPath,
        generation: generation,
        onProgress: onProgress,
      ),
      SavedMapImageSource() => _importSavedTextureSet(
        source,
        generation: generation,
        onProgress: onProgress,
      ),
    };
  }

  void clearImage() {
    _loadGeneration++;
    _clearTextureSet();
  }

  void resize(int cols, int rows) {
    if (_cols != cols || _rows != rows) clearImage();
    _cols = cols;
    _rows = rows;
    _updateSize();
  }

  @override
  void onRemove() {
    clearImage();
    _textureRepository.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (!showImage) return;
    final set = _textureSet;
    if (set != null) _renderTextureSet(canvas, set);
  }

  void _updateSize() {
    final radius = config.hexRadius;
    final maxX = radius + (_cols - 1) * 1.5 * radius + radius;
    final lastColIsOdd = (_cols - 1).isOdd;
    final maxY =
        (math.sqrt(3) / 2 * radius) +
        (_rows - 1) * math.sqrt(3) * radius +
        (lastColIsOdd ? math.sqrt(3) / 2 * radius : 0) +
        (math.sqrt(3) / 2 * radius);
    size = Vector2(maxX, maxY);
  }

  Path _combinedGridClipPath() {
    final path = Path();
    for (var col = 0; col < _cols; col++) {
      for (var row = 0; row < _rows; row++) {
        path.addPath(
          HexGeometry.tileOverlayPath(
            col: col,
            row: row,
            hexRadius: config.hexRadius,
          ),
          Offset.zero,
        );
      }
    }
    return path;
  }

  SavedMapTextureLayout _savedTextureLayout() => SavedMapTextureLayout(
    config: config,
    cols: _cols,
    rows: _rows,
    worldSize: Size(size.x, size.y),
  );
}
