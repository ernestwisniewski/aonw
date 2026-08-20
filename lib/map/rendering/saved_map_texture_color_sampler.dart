import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/saved_map_texture_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

const int _targetSamples = 48;
const int _minimumAlpha = 16;

class SavedMapTextureColorSampler {
  const SavedMapTextureColorSampler();

  Future<Map<(int, int), Color>> sampleSingleImage(
    ui.Image image,
    SavedMapTextureLayout layout,
  ) async {
    final pixels = await _readPixels(image);
    if (pixels == null) return const {};
    final scaleX = image.width / layout.worldSize.width;
    final scaleY = image.height / layout.worldSize.height;
    final colors = <(int, int), Color>{};
    for (var col = 0; col < layout.cols; col++) {
      for (var row = 0; row < layout.rows; row++) {
        final tile = layout.tileDestination(col, row);
        final source = ui.Rect.fromLTRB(
          tile.left * scaleX,
          tile.top * scaleY,
          tile.right * scaleX,
          tile.bottom * scaleY,
        );
        final color = _averageFromPixels(pixels, source);
        if (color != null) colors[(col, row)] = color;
      }
    }
    return colors;
  }

  Future<Color?> sampleHex(ui.Image image, ui.Rect source) async {
    final pixels = await _readPixels(image);
    return pixels == null ? null : _averageFromPixels(pixels, source);
  }

  Future<_ImagePixels?> _readPixels(ui.Image image) async {
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;
      return _ImagePixels(
        width: image.width,
        height: image.height,
        bytes: data.buffer.asUint8List(),
      );
    } catch (_) {
      return null;
    }
  }

  Color? _averageFromPixels(_ImagePixels pixels, ui.Rect source) {
    if (source.width <= 0 || source.height <= 0) return null;
    final left = source.left.floor().clamp(0, pixels.width - 1).toInt();
    final top = source.top.floor().clamp(0, pixels.height - 1).toInt();
    final right = source.right.ceil().clamp(left + 1, pixels.width).toInt();
    final bottom = source.bottom.ceil().clamp(top + 1, pixels.height).toInt();
    final stride = math.max(
      1,
      math.min(right - left, bottom - top) ~/ _targetSamples,
    );
    var red = 0;
    var green = 0;
    var blue = 0;
    var weight = 0;
    for (var y = top; y < bottom; y += stride) {
      final v = ((y + 0.5 - source.top) / source.height).clamp(0, 1);
      for (var x = left; x < right; x += stride) {
        final u = ((x + 0.5 - source.left) / source.width).clamp(0, 1);
        if (!_unitHexContains(u.toDouble(), v.toDouble())) continue;
        final offset = (y * pixels.width + x) * 4;
        final alpha = pixels.bytes[offset + 3];
        if (alpha <= _minimumAlpha) continue;
        red += pixels.bytes[offset] * alpha;
        green += pixels.bytes[offset + 1] * alpha;
        blue += pixels.bytes[offset + 2] * alpha;
        weight += alpha;
      }
    }
    if (weight == 0) return null;
    return Color.fromARGB(
      255,
      (red / weight).round(),
      (green / weight).round(),
      (blue / weight).round(),
    );
  }

  bool _unitHexContains(double u, double v) {
    final left = v <= 0.5 ? 0.25 - 0.5 * v : 0.5 * v - 0.25;
    final right = v <= 0.5 ? 0.75 + 0.5 * v : 1.25 - 0.5 * v;
    return u >= left && u <= right;
  }
}

class _ImagePixels {
  const _ImagePixels({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}
