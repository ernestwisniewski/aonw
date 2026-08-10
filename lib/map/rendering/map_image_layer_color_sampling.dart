part of 'map_image_layer.dart';

const int _averageColorTargetSamples = 48;
const int _averageColorMinAlpha = 16;
bool _pixelReadDisabled = false;

extension _MapImageLayerColorSampling on MapImageLayer {
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
}

Rect _imageRect(ui.Image image) =>
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

Future<Color?> _averageHexColor(ui.Image image, Rect sourceRect) async {
  final pixels = await _readPixels(image);
  if (pixels == null) return null;
  return _averageHexColorFromPixels(pixels, sourceRect);
}

Future<_ImagePixels?> _readPixels(ui.Image image) async {
  if (_pixelReadDisabled) return null;
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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

Color? _averageHexColorFromPixels(_ImagePixels pixels, Rect sourceRect) {
  if (sourceRect.width <= 0 || sourceRect.height <= 0) return null;
  final left = sourceRect.left.floor().clamp(0, pixels.width - 1).toInt();
  final top = sourceRect.top.floor().clamp(0, pixels.height - 1).toInt();
  final right = sourceRect.right.ceil().clamp(left + 1, pixels.width).toInt();
  final bottom = sourceRect.bottom.ceil().clamp(top + 1, pixels.height).toInt();
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
    final v = ((y + 0.5 - sourceRect.top) / sourceRect.height).clamp(0.0, 1.0);
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

bool _unitHexContains(double u, double v) {
  final left = v <= 0.5 ? 0.25 - 0.5 * v : 0.5 * v - 0.25;
  final right = v <= 0.5 ? 0.75 + 0.5 * v : 1.25 - 0.5 * v;
  return u >= left && u <= right;
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
