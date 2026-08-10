import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/shared/performance/dev_performance.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

part 'map_image_layer_atlas.dart';
part 'map_image_layer_color_sampling.dart';
part 'map_image_layer_geometry.dart';

/// Renders a reference image (or a set of per-tile slices) as a background
/// layer under the hex grid.
///
/// **Single-image mode:** one image stretches across the full grid bounding box.
///
/// **Sliced mode:** per-tile images (`{col+1}x{row+1}.jpg`) are loaded from
/// a base directory and drawn aligned to each hex tile's axis-aligned bounding
/// box. Call [loadSlices] instead of [loadImage] to enter this mode.
class MapImageLayer extends PositionComponent {
  // Default Paint() uses FilterQuality.none (nearest-neighbour sampling),
  // which at sub-pixel camera offsets makes adjacent tiles sample different
  // texels each frame — visible as flickering edges on the hex grid.
  // FilterQuality.medium turns on bilinear sampling with mip selection so
  // edges stay stable as the camera pans.
  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final MapConfig config;
  int _cols;
  int _rows;

  // Single-image mode
  ui.Image? _image;
  Rect? _singleSrc;
  Rect? _singleDst;

  // Sliced mode: keyed by (col, row)
  final Map<(int, int), _SliceImage> _slices = {};
  final Map<(int, int), Color> _tileAverageColors = {};
  ui.Image? _sliceAtlas;
  Rect? _sliceAtlasSrc;
  Rect? _sliceAtlasDst;
  Path? _sliceAtlasClipPath;
  bool _isSliced = false;

  bool showImage = true;
  bool preferFastRendering = false;

  bool get hasImage =>
      _image != null || _sliceAtlas != null || _slices.isNotEmpty;

  bool get hasSliceAtlasForTesting => _sliceAtlas != null;

  Color? averageColorForTile(int col, int row) =>
      _tileAverageColors[(col, row)];

  MapImageLayer({required this.config, required int cols, required int rows})
    : _cols = cols,
      _rows = rows,
      super(scale: Vector2(1.0, HexGrid.perspectiveY)) {
    _updateSize();
  }

  /// Loads a single full-grid image.
  Future<void> loadImage(
    String imagePath, {
    ValueChanged<double>? onProgress,
  }) async {
    onProgress?.call(0);
    await DevPerformance.timeAsync('MapImageLayer.loadImage', () async {
      _isSliced = false;
      _disposeSliceImages();
      _disposeSliceAtlas();
      _tileAverageColors.clear();
      _disposeSingleImage();
      _singleSrc = null;
      _singleDst = null;
      _image = await _loadUiImage(imagePath);
      _singleSrc = _imageRect(_image!);
      _updateSingleDst();
      await _cacheSingleTileAverageColors();
    });
    onProgress?.call(1);
  }

  /// Loads per-tile slice images.
  ///
  /// [slicePathFor] returns the path for (col, row) — either a file-system
  /// path or an `assets/…` asset path.
  /// Missing tiles are silently skipped.
  static const int _sliceLoadConcurrency = 16;

  Future<void> loadSlices({
    required String Function(int col, int row) slicePathFor,
    ValueChanged<double>? onProgress,
  }) async {
    await DevPerformance.timeAsync(
      'MapImageLayer.loadSlices ${_cols}x$_rows',
      () async {
        onProgress?.call(0);
        _isSliced = true;
        _disposeSingleImage();
        _disposeSliceImages();
        _disposeSliceAtlas();
        _singleSrc = null;
        _singleDst = null;
        _tileAverageColors.clear();

        final total = _cols * _rows;
        if (total == 0) {
          onProgress?.call(1);
          return;
        }

        // Build the queue of (col, row) pairs to load, then drain it with a
        // bounded number of concurrent workers. Sequential awaits on a 30x20
        // map mean 600 round-trips one-by-one — terrible on the web, where
        // each slice is a separate HTTP fetch. Parallelism saturates the
        // browser's connection pool without overwhelming the server.
        final queue = <(int, int)>[
          for (int col = 0; col < _cols; col++)
            for (int row = 0; row < _rows; row++) (col, row),
        ];
        var nextIndex = 0;
        var completed = 0;

        Future<void> worker() async {
          while (true) {
            final index = nextIndex++;
            if (index >= queue.length) return;
            final (col, row) = queue[index];
            final path = slicePathFor(col, row);
            try {
              final img = await _loadUiImage(path);
              final imageRect = _imageRect(img);
              _slices[(col, row)] = _SliceImage(
                image: img,
                src: imageRect,
                dst: _sliceDst(col, row),
                clipPath: _sliceClipPath(col, row),
              );
              final averageColor = await _averageHexColor(img, imageRect);
              if (averageColor != null) {
                _tileAverageColors[(col, row)] = averageColor;
              }
            } catch (_) {
              // skip missing/corrupt slices
            } finally {
              completed++;
              onProgress?.call(completed / total);
            }
          }
        }

        final workerCount = total < _sliceLoadConcurrency
            ? total
            : _sliceLoadConcurrency;
        await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);
        await _buildSliceAtlas();
        onProgress?.call(1);
      },
    );
  }

  void clearImage() {
    _disposeSingleImage();
    _singleSrc = null;
    _singleDst = null;
    _disposeSliceImages();
    _disposeSliceAtlas();
    _tileAverageColors.clear();
    _isSliced = false;
  }

  void resize(int cols, int rows) {
    _cols = cols;
    _rows = rows;
    _updateSize();
    _tileAverageColors.clear();
  }

  @override
  void onRemove() {
    clearImage();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (!showImage) return;
    if (_isSliced) {
      _renderSlices(canvas);
    } else {
      _renderSingle(canvas);
    }
  }

  void _renderSingle(Canvas canvas) {
    final img = _image;
    final src = _singleSrc;
    final dst = _singleDst;
    if (img == null || src == null || dst == null) return;
    canvas.drawImageRect(img, src, dst, _imagePaint);
  }

  /// Detects whether [imagePath] is a slice marker (`…/1x1.jpg`) and loads
  /// accordingly — sliced or single-image.
  ///
  /// Works for both filesystem paths (`<dir>/1x1.jpg`) and asset paths
  /// (`assets/maps/<name>/1x1.jpg`) — the directory prefix is stripped and
  /// used to build the remaining slice paths.
  Future<void> loadAuto(
    String imagePath, {
    ValueChanged<double>? onProgress,
  }) async {
    if (imagePath.endsWith('/1x1.jpg')) {
      final dir = imagePath.substring(0, imagePath.lastIndexOf('/'));
      await loadSlices(
        slicePathFor: (col, row) => '$dir/${col + 1}x${row + 1}.jpg',
        onProgress: onProgress,
      );
    } else {
      await loadImage(imagePath, onProgress: onProgress);
    }
  }

  static Future<ui.Image> _loadUiImage(String path) async {
    final bytes = path.startsWith('assets/')
        ? (await rootBundle.load(path)).buffer.asUint8List()
        : await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  void _disposeSingleImage() {
    _image?.dispose();
    _image = null;
  }
}
