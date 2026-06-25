import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

abstract final class FieldImprovementSpriteCache {
  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<ui.Image>> _pendingImages = {};

  static Future<ui.Image> load(String path) async {
    final cached = _images[path];
    if (cached != null) return cached;
    final pending = _pendingImages[path];
    if (pending != null) return pending;

    final future = _loadFromBundle(path);
    _pendingImages[path] = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingImages[path], future)) {
        _pendingImages.remove(path)?.ignore();
      }
    }
  }

  static ui.Image? imageFor(String path) => _images[path];

  static void clearForTesting() {
    _images.clear();
    _pendingImages.clear();
  }

  static Future<ui.Image> _loadFromBundle(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    late final ui.Image image;
    try {
      final frame = await codec.getNextFrame();
      image = frame.image;
    } finally {
      codec.dispose();
    }
    return _images[path] = image;
  }
}
