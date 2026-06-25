import 'dart:async';
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/preferred_image_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Shared image cache for hex terrain and resource icons.
///
/// Images are loaded once per asset path and reused for the lifetime of the app.
abstract final class HexIconCache {
  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<ui.Image>> _pendingImages = {};
  static final Map<String, String> _resolvedAssetPaths = {};
  static final Map<String, ui.Rect> _sourceRects = {};
  static final Set<String> _failedPreferredAssetPaths = {};

  static Future<void> loadAll(Iterable<String> paths) async {
    await Future.wait(paths.map(load));
  }

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

  static ui.Image? imageFor(String path) {
    return _images[path];
  }

  static ui.Rect? sourceRectFor(String path) {
    return _sourceRects[path];
  }

  static Future<ui.Image> _loadFromBundle(String path) async {
    for (final assetPath in _assetCandidatesFor(path)) {
      try {
        final image = await _decodeFromBundle(
          assetPath,
          targetWidth: _targetDecodeWidthFor(path),
        );
        _resolvedAssetPaths[path] = assetPath;
        _sourceRects[path] = ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        return _images[path] = image;
      } catch (_) {
        if (assetPath == path) rethrow;
        _failedPreferredAssetPaths.add(assetPath);
      }
    }

    throw StateError('No image asset candidate available for $path');
  }

  static Future<ui.Image> _decodeFromBundle(
    String path, {
    required int? targetWidth,
  }) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: targetWidth,
    );
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  static int? _targetDecodeWidthFor(String path) {
    final preferredWidth = PreferredImageAssets.targetDecodeWidthFor(path);
    if (preferredWidth != null) return preferredWidth;
    if (path.startsWith('assets/sprites/units/')) {
      return 1536;
    }
    return null;
  }

  static List<String> _assetCandidatesFor(String path) {
    final webpPath = PreferredImageAssets.webpPathFor(path);
    return PreferredImageAssets.candidatesFor(
      path,
      preferredCandidateFailed: _failedPreferredAssetPaths.contains(webpPath),
    );
  }

  @visibleForTesting
  static String? resolvedAssetPathForTesting(String path) {
    return _resolvedAssetPaths[path];
  }

  @visibleForTesting
  static void clearForTesting() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _pendingImages.clear();
    _resolvedAssetPaths.clear();
    _sourceRects.clear();
    _failedPreferredAssetPaths.clear();
  }
}
