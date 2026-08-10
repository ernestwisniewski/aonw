part of 'map_image_layer.dart';

const double _sliceAtlasPreferredScale = 2.0;
const int _sliceAtlasMaxPixels = 16000000;

extension _MapImageLayerAtlas on MapImageLayer {
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
