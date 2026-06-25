import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/shared/performance/dev_performance.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

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
  static const double _sliceAtlasPreferredScale = 2.0;
  static const int _sliceAtlasMaxPixels = 16000000;

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

  void _renderSlices(Canvas canvas) {
    if (preferFastRendering && _renderSliceAtlas(canvas)) {
      return;
    }
    for (final entry in _slices.entries) {
      final slice = entry.value;
      canvas
        ..save()
        ..clipPath(slice.clipPath)
        ..drawImageRect(slice.image, slice.src, slice.dst, _imagePaint)
        ..restore();
    }
  }

  bool _renderSliceAtlas(Canvas canvas) {
    final atlas = _sliceAtlas;
    final src = _sliceAtlasSrc;
    final dst = _sliceAtlasDst;
    final clipPath = _sliceAtlasClipPath;
    if (atlas == null || src == null || dst == null || clipPath == null) {
      return false;
    }
    canvas
      ..save()
      ..clipPath(clipPath)
      ..drawImageRect(atlas, src, dst, _imagePaint)
      ..restore();
    return true;
  }

  void _updateSize() {
    final r = config.hexRadius;
    final maxX = r + (_cols - 1) * 1.5 * r + r;
    final lastColIsOdd = (_cols - 1).isOdd;
    final maxY =
        (math.sqrt(3) / 2 * r) +
        (_rows - 1) * math.sqrt(3) * r +
        (lastColIsOdd ? math.sqrt(3) / 2 * r : 0) +
        (math.sqrt(3) / 2 * r);
    size = Vector2(maxX, maxY);
    _updateSingleDst();
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

  void _updateSingleDst() {
    if (_image == null) return;
    _singleDst = Rect.fromLTWH(0, 0, size.x, size.y);
  }

  void _disposeSingleImage() {
    _image?.dispose();
    _image = null;
  }

  void _disposeSliceImages() {
    for (final slice in _slices.values) {
      slice.image.dispose();
    }
    _slices.clear();
  }

  void _disposeSliceAtlas() {
    _sliceAtlas?.dispose();
    _sliceAtlas = null;
    _sliceAtlasSrc = null;
    _sliceAtlasDst = null;
    _sliceAtlasClipPath = null;
  }

  Future<void> _buildSliceAtlas() async {
    _disposeSliceAtlas();
    if (_slices.isEmpty || size.x <= 0 || size.y <= 0) return;

    _sliceAtlasClipPath = _combinedSliceClipPath();
    final scale = _sliceAtlasScale();
    final width = math.max(1, (size.x * scale).ceil());
    final height = math.max(1, (size.y * scale).ceil());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    for (final slice in _slices.values) {
      canvas
        ..save()
        ..clipPath(slice.clipPath)
        ..drawImageRect(slice.image, slice.src, slice.dst, _imagePaint)
        ..restore();
    }
    final picture = recorder.endRecording();
    try {
      _sliceAtlas = await picture.toImage(width, height);
      _sliceAtlasSrc = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
      _sliceAtlasDst = Rect.fromLTWH(0, 0, size.x, size.y);
    } finally {
      picture.dispose();
    }
  }

  Path _combinedSliceClipPath() {
    final path = Path();
    for (final slice in _slices.values) {
      path.addPath(slice.clipPath, Offset.zero);
    }
    return path;
  }

  double _sliceAtlasScale() {
    final pixelsAtPreferredScale =
        size.x * size.y * _sliceAtlasPreferredScale * _sliceAtlasPreferredScale;
    if (pixelsAtPreferredScale <= _sliceAtlasMaxPixels) {
      return _sliceAtlasPreferredScale;
    }
    final scale = math.sqrt(_sliceAtlasMaxPixels / (size.x * size.y));
    return scale.clamp(1.0, _sliceAtlasPreferredScale).toDouble();
  }

  Future<void> _cacheSingleTileAverageColors() async {
    final image = _image;
    final src = _singleSrc;
    final dst = _singleDst;
    if (image == null || src == null || dst == null) return;
    final pixels = await _readPixels(image);
    if (pixels == null) return;

    for (int col = 0; col < _cols; col++) {
      for (int row = 0; row < _rows; row++) {
        final sampleRect = _singleImageSourceRectFor(_sliceDst(col, row));
        final color = _averageHexColorFromPixels(pixels, sampleRect);
        if (color != null) {
          _tileAverageColors[(col, row)] = color;
        }
      }
    }
  }

  Rect _singleImageSourceRectFor(Rect tileDst) {
    final src = _singleSrc!;
    final dst = _singleDst!;
    final scaleX = src.width / dst.width;
    final scaleY = src.height / dst.height;
    return Rect.fromLTRB(
      src.left + (tileDst.left - dst.left) * scaleX,
      src.top + (tileDst.top - dst.top) * scaleY,
      src.left + (tileDst.right - dst.left) * scaleX,
      src.top + (tileDst.bottom - dst.top) * scaleY,
    );
  }

  Rect _sliceDst(int col, int row) {
    final r = config.hexRadius;
    final sqrt3 = math.sqrt(3);
    final tileH = sqrt3 * r;
    final cx = r + col * 1.5 * r;
    final cy =
        (sqrt3 / 2 * r) + row * sqrt3 * r + (col.isOdd ? sqrt3 / 2 * r : 0);
    return Rect.fromLTWH(cx - r, cy - tileH / 2, 2 * r, tileH);
  }

  Path _sliceClipPath(int col, int row) {
    final center = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: config.hexRadius,
    );
    final corners = HexGeometry.topFaceCorners(
      center: center,
      radius: config.hexRadius,
    );
    final path = Path()..moveTo(corners.first.x, corners.first.y);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.x, corner.y);
    }
    return path..close();
  }

  static Rect _imageRect(ui.Image image) =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  static const int _averageColorTargetSamples = 48;
  static const int _averageColorMinAlpha = 16;
  static bool _pixelReadDisabled = false;

  static Future<Color?> _averageHexColor(
    ui.Image image,
    Rect sourceRect,
  ) async {
    final pixels = await _readPixels(image);
    if (pixels == null) return null;
    return _averageHexColorFromPixels(pixels, sourceRect);
  }

  static Future<_ImagePixels?> _readPixels(ui.Image image) async {
    if (_pixelReadDisabled) return null;
    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return null;
      return _ImagePixels(
        width: image.width,
        height: image.height,
        bytes: byteData.buffer.asUint8List(),
      );
    } catch (_) {
      _pixelReadDisabled = true;
      return null;
    }
  }

  static Color? _averageHexColorFromPixels(
    _ImagePixels pixels,
    Rect sourceRect,
  ) {
    if (sourceRect.width <= 0 || sourceRect.height <= 0) return null;
    final left = sourceRect.left.floor().clamp(0, pixels.width - 1).toInt();
    final top = sourceRect.top.floor().clamp(0, pixels.height - 1).toInt();
    final right = sourceRect.right.ceil().clamp(left + 1, pixels.width).toInt();
    final bottom = sourceRect.bottom
        .ceil()
        .clamp(top + 1, pixels.height)
        .toInt();
    final sampleWidth = right - left;
    final sampleHeight = bottom - top;
    final stride = math.max(
      1,
      math.min(sampleWidth, sampleHeight) ~/ _averageColorTargetSamples,
    );

    var red = 0;
    var green = 0;
    var blue = 0;
    var weightTotal = 0;
    for (var y = top; y < bottom; y += stride) {
      final v = ((y + 0.5 - sourceRect.top) / sourceRect.height).clamp(
        0.0,
        1.0,
      );
      for (var x = left; x < right; x += stride) {
        final u = ((x + 0.5 - sourceRect.left) / sourceRect.width).clamp(
          0.0,
          1.0,
        );
        if (!_unitHexContains(u, v)) continue;
        final offset = (y * pixels.width + x) * 4;
        final alpha = pixels.bytes[offset + 3];
        if (alpha <= _averageColorMinAlpha) continue;
        red += pixels.bytes[offset] * alpha;
        green += pixels.bytes[offset + 1] * alpha;
        blue += pixels.bytes[offset + 2] * alpha;
        weightTotal += alpha;
      }
    }
    if (weightTotal == 0) return null;
    return Color.fromARGB(
      255,
      (red / weightTotal).round(),
      (green / weightTotal).round(),
      (blue / weightTotal).round(),
    );
  }

  static bool _unitHexContains(double u, double v) {
    final left = v <= 0.5 ? 0.25 - 0.5 * v : 0.5 * v - 0.25;
    final right = v <= 0.5 ? 0.75 + 0.5 * v : 1.25 - 0.5 * v;
    return u >= left && u <= right;
  }
}

class _ImagePixels {
  final int width;
  final int height;
  final Uint8List bytes;

  const _ImagePixels({
    required this.width,
    required this.height,
    required this.bytes,
  });
}

class _SliceImage {
  final ui.Image image;
  final Rect src;
  final Rect dst;
  final Path clipPath;

  const _SliceImage({
    required this.image,
    required this.src,
    required this.dst,
    required this.clipPath,
  });
}
