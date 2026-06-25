import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';

abstract final class SpriteAtlasFrameBoundsCache {
  static final Map<String, _SpriteAtlasFrameBoundsSet> _readySets = {};
  static final Map<String, Future<_SpriteAtlasFrameBoundsSet>> _pendingSets =
      {};

  static ui.Rect? cachedFrameRectFor({
    required String cacheKey,
    required ui.Image image,
    required int columns,
    required int rows,
    required int column,
    required int row,
    required double sourceInset,
    required double contentPadding,
  }) {
    final set =
        _readySets[_setKey(
          cacheKey: cacheKey,
          image: image,
          columns: columns,
          rows: rows,
          sourceInset: sourceInset,
          contentPadding: contentPadding,
        )];
    return set?.rectFor(column: column, row: row);
  }

  static Future<ui.Rect> frameRectFor({
    required String cacheKey,
    required ui.Image image,
    required int columns,
    required int rows,
    required int column,
    required int row,
    required double sourceInset,
    required double contentPadding,
    int alphaThreshold = 16,
  }) async {
    final key = _setKey(
      cacheKey: cacheKey,
      image: image,
      columns: columns,
      rows: rows,
      sourceInset: sourceInset,
      contentPadding: contentPadding,
    );
    final ready = _readySets[key];
    if (ready != null) return ready.rectFor(column: column, row: row);

    final pending = _pendingSets.putIfAbsent(
      key,
      () => _analyzeAtlas(
        image: image,
        columns: columns,
        rows: rows,
        sourceInset: sourceInset,
        contentPadding: contentPadding,
        alphaThreshold: alphaThreshold,
      ),
    );
    final set = await pending;
    _readySets[key] = set;
    _pendingSets.remove(key)?.ignore();
    return set.rectFor(column: column, row: row);
  }

  static String _setKey({
    required String cacheKey,
    required ui.Image image,
    required int columns,
    required int rows,
    required double sourceInset,
    required double contentPadding,
  }) {
    return '$cacheKey:${image.width}x${image.height}:$columns:$rows:'
        '$sourceInset:$contentPadding';
  }

  static Future<_SpriteAtlasFrameBoundsSet> _analyzeAtlas({
    required ui.Image image,
    required int columns,
    required int rows,
    required double sourceInset,
    required double contentPadding,
    required int alphaThreshold,
  }) async {
    final ByteData? byteData;
    try {
      byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } catch (_) {
      return _SpriteAtlasFrameBoundsSet.fromSourceRects(
        imageWidth: image.width,
        imageHeight: image.height,
        columns: columns,
        rows: rows,
        sourceInset: sourceInset,
      );
    }
    if (byteData == null) {
      return _SpriteAtlasFrameBoundsSet.fromSourceRects(
        imageWidth: image.width,
        imageHeight: image.height,
        columns: columns,
        rows: rows,
        sourceInset: sourceInset,
      );
    }

    final bytes = byteData.buffer.asUint8List();
    return _SpriteAtlasFrameBoundsSet(
      columns: columns,
      rows: rows,
      rects: [
        for (var row = 0; row < rows; row++)
          for (var column = 0; column < columns; column++)
            _contentRectForFrame(
              bytes: bytes,
              imageWidth: image.width,
              imageHeight: image.height,
              columns: columns,
              rows: rows,
              column: column,
              row: row,
              sourceInset: sourceInset,
              contentPadding: contentPadding,
              alphaThreshold: alphaThreshold,
            ),
      ],
    );
  }

  static ui.Rect _contentRectForFrame({
    required Uint8List bytes,
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
    required int column,
    required int row,
    required double sourceInset,
    required double contentPadding,
    required int alphaThreshold,
  }) {
    final source = SpriteAtlasGeometry.sourceRectFor(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      columns: columns,
      rows: rows,
      column: column,
      row: row,
      sourceInset: sourceInset,
    );
    final left = source.left.round().clamp(0, imageWidth - 1).toInt();
    final top = source.top.round().clamp(0, imageHeight - 1).toInt();
    final right = source.right.round().clamp(left + 1, imageWidth).toInt();
    final bottom = source.bottom.round().clamp(top + 1, imageHeight).toInt();

    var minX = right;
    var minY = bottom;
    var maxX = left - 1;
    var maxY = top - 1;

    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final alpha = bytes[((y * imageWidth + x) * 4) + 3];
        if (alpha <= alphaThreshold) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX < minX || maxY < minY) return source;

    final padding = math.max(0, contentPadding).round();
    return ui.Rect.fromLTRB(
      math.max(left, minX - padding).toDouble(),
      math.max(top, minY - padding).toDouble(),
      math.min(right, maxX + 1 + padding).toDouble(),
      math.min(bottom, maxY + 1 + padding).toDouble(),
    );
  }
}

class _SpriteAtlasFrameBoundsSet {
  final int columns;
  final int rows;
  final List<ui.Rect> rects;

  const _SpriteAtlasFrameBoundsSet({
    required this.columns,
    required this.rows,
    required this.rects,
  });

  factory _SpriteAtlasFrameBoundsSet.fromSourceRects({
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
    required double sourceInset,
  }) {
    return _SpriteAtlasFrameBoundsSet(
      columns: columns,
      rows: rows,
      rects: [
        for (var row = 0; row < rows; row++)
          for (var column = 0; column < columns; column++)
            SpriteAtlasGeometry.sourceRectFor(
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              columns: columns,
              rows: rows,
              column: column,
              row: row,
              sourceInset: sourceInset,
            ),
      ],
    );
  }

  ui.Rect rectFor({required int column, required int row}) {
    final safeColumn = column.clamp(0, columns - 1).toInt();
    final safeRow = row.clamp(0, rows - 1).toInt();
    return rects[safeRow * columns + safeColumn];
  }
}
