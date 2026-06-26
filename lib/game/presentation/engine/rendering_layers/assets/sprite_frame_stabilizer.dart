import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';

abstract final class SpriteFrameStabilizerCache {
  static final Map<String, SpriteFrameStabilizer> _ready = {};
  static final Map<String, Future<SpriteFrameStabilizer>> _pending = {};

  static Future<SpriteFrameStabilizer> analyze({
    required String cacheKey,
    required ui.Image image,
    required int columns,
    required int rows,
    double sourceInset = 0,
  }) async {
    final key =
        '$cacheKey:${image.width}x${image.height}:$columns:$rows:$sourceInset';
    final ready = _ready[key];
    if (ready != null) return ready;

    final pending = _pending.putIfAbsent(
      key,
      () => SpriteFrameStabilizer.analyze(
        image: image,
        columns: columns,
        rows: rows,
        sourceInset: sourceInset,
      ),
    );
    try {
      final analyzed = await pending;
      _ready[key] = analyzed;
      return analyzed;
    } finally {
      if (identical(_pending[key], pending)) {
        _pending.remove(key)?.ignore();
      }
    }
  }
}

class SpriteFrameStabilizer {
  final int columns;
  final int rows;
  final List<List<_FrameCorrection>> _corrections;
  final List<_RowAnchor> _rowAnchors;

  const SpriteFrameStabilizer._({
    required this.columns,
    required this.rows,
    required List<List<_FrameCorrection>> corrections,
    required List<_RowAnchor> rowAnchors,
  }) : _corrections = corrections,
       _rowAnchors = rowAnchors;

  static Future<SpriteFrameStabilizer> analyze({
    required ui.Image image,
    required int columns,
    required int rows,
    double sourceInset = 0,
    int alphaThreshold = 16,
    int sampleStride = 1,
    double baseBandFraction = 0.18,
  }) async {
    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        return SpriteFrameStabilizer.empty(columns: columns, rows: rows);
      }

      return _analyzeBytes(
        bytes: byteData.buffer.asUint8List(),
        imageWidth: image.width,
        imageHeight: image.height,
        columns: columns,
        rows: rows,
        sourceInset: sourceInset,
        alphaThreshold: alphaThreshold,
        sampleStride: sampleStride,
        baseBandFraction: baseBandFraction,
      );
    } catch (_) {
      return SpriteFrameStabilizer.empty(columns: columns, rows: rows);
    }
  }

  static SpriteFrameStabilizer empty({
    required int columns,
    required int rows,
  }) {
    return SpriteFrameStabilizer._(
      columns: columns,
      rows: rows,
      corrections: [
        for (var row = 0; row < rows; row++)
          [
            for (var column = 0; column < columns; column++)
              _FrameCorrection.zero,
          ],
      ],
      rowAnchors: [for (var row = 0; row < rows; row++) _RowAnchor.empty],
    );
  }

  static SpriteFrameStabilizer _analyzeBytes({
    required Uint8List bytes,
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
    required double sourceInset,
    required int alphaThreshold,
    required int sampleStride,
    required double baseBandFraction,
  }) {
    final metrics = [
      for (var row = 0; row < rows; row++)
        [
          for (var column = 0; column < columns; column++)
            _frameMetricsForCell(
              bytes: bytes,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              columns: columns,
              rows: rows,
              column: column,
              row: row,
              sourceInset: sourceInset,
              alphaThreshold: alphaThreshold,
              sampleStride: sampleStride,
              baseBandFraction: baseBandFraction,
            ),
        ],
    ];

    final rowAnchors = [
      for (var row = 0; row < rows; row++) _RowAnchor.fromMetrics(metrics[row]),
    ];
    final corrections = [
      for (var row = 0; row < rows; row++)
        [
          for (var column = 0; column < columns; column++)
            _FrameCorrection.fromMetric(
              metric: metrics[row][column],
              rowAnchor: rowAnchors[row],
            ),
        ],
    ];

    return SpriteFrameStabilizer._(
      columns: columns,
      rows: rows,
      corrections: corrections,
      rowAnchors: rowAnchors,
    );
  }

  static _FrameMetric? _frameMetricsForCell({
    required Uint8List bytes,
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
    required int column,
    required int row,
    required double sourceInset,
    required int alphaThreshold,
    required int sampleStride,
    required double baseBandFraction,
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
    final frameLeft = source.left.round().clamp(0, imageWidth - 1).toInt();
    final frameTop = source.top.round().clamp(0, imageHeight - 1).toInt();
    final frameRight = source.right
        .round()
        .clamp(frameLeft + 1, imageWidth)
        .toInt();
    final frameBottom = source.bottom
        .round()
        .clamp(frameTop + 1, imageHeight)
        .toInt();

    return _frameMetrics(
      bytes: bytes,
      imageWidth: imageWidth,
      frameLeft: frameLeft,
      frameTop: frameTop,
      frameRight: frameRight,
      frameBottom: frameBottom,
      alphaThreshold: alphaThreshold,
      sampleStride: sampleStride,
      baseBandFraction: baseBandFraction,
    );
  }

  ui.Offset offsetFor({
    required int row,
    required int column,
    required double width,
    required double height,
    double horizontalStrength = 1.0,
    double verticalStrength = 1.0,
  }) {
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      return ui.Offset.zero;
    }
    final correction = _corrections[row][column];
    return ui.Offset(
      correction.dxFraction * width * horizontalStrength,
      correction.dyFraction * height * verticalStrength,
    );
  }

  ui.Offset targetAnchorPointFor({
    required int row,
    required double width,
    required double height,
  }) {
    if (row < 0 || row >= rows) return ui.Offset(width * 0.5, height);
    final anchor = _rowAnchors[row];
    return ui.Offset(
      anchor.baseXFraction * width,
      anchor.bottomFraction * height,
    );
  }

  ui.Offset stabilizedAnchorPointFor({
    required int row,
    required int column,
    required double width,
    required double height,
    double horizontalStrength = 1.0,
    double verticalStrength = 1.0,
  }) {
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      return targetAnchorPointFor(row: row, width: width, height: height);
    }

    final anchor = _rowAnchors[row];
    final correction = _corrections[row][column];
    final frameBaseX = anchor.baseXFraction - correction.dxFraction;
    final frameBottom = anchor.bottomFraction - correction.dyFraction;
    return ui.Offset(
      (frameBaseX + correction.dxFraction * horizontalStrength) * width,
      (frameBottom + correction.dyFraction * verticalStrength) * height,
    );
  }

  double contentTopFractionForRow(int row) {
    if (row < 0 || row >= rows) return 0;
    return _rowAnchors[row].contentTopFraction;
  }

  static _FrameMetric? _frameMetrics({
    required Uint8List bytes,
    required int imageWidth,
    required int frameLeft,
    required int frameTop,
    required int frameRight,
    required int frameBottom,
    required int alphaThreshold,
    required int sampleStride,
    required double baseBandFraction,
  }) {
    var minX = frameRight;
    var minY = frameBottom;
    var maxX = frameLeft - 1;
    var maxY = frameTop - 1;

    for (var y = frameTop; y < frameBottom; y += sampleStride) {
      for (var x = frameLeft; x < frameRight; x += sampleStride) {
        final alpha = bytes[((y * imageWidth + x) * 4) + 3];
        if (alpha <= alphaThreshold) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX < minX || maxY < minY) return null;

    final contentHeight = math.max(1, maxY - minY + 1);
    final bandHeight = math.max(1, (contentHeight * baseBandFraction).round());
    final bandTop = math.max(minY, maxY - bandHeight + 1);
    var baseXTotal = 0.0;
    var baseSampleCount = 0;

    for (var y = bandTop; y <= maxY; y += sampleStride) {
      for (var x = frameLeft; x < frameRight; x += sampleStride) {
        final alpha = bytes[((y * imageWidth + x) * 4) + 3];
        if (alpha <= alphaThreshold) continue;
        baseXTotal += x - frameLeft + 0.5;
        baseSampleCount += 1;
      }
    }

    final frameWidth = math.max(1, frameRight - frameLeft);
    final frameHeight = math.max(1, frameBottom - frameTop);
    final baseX = baseSampleCount == 0
        ? ((minX + maxX + 1) / 2 - frameLeft) / frameWidth
        : (baseXTotal / baseSampleCount) / frameWidth;

    return _FrameMetric(
      baseXFraction: baseX.clamp(0.0, 1.0).toDouble(),
      bottomFraction: ((maxY + 1 - frameTop) / frameHeight)
          .clamp(0.0, 1.0)
          .toDouble(),
      topFraction: ((minY - frameTop) / frameHeight).clamp(0.0, 1.0).toDouble(),
    );
  }
}

class _FrameMetric {
  final double baseXFraction;
  final double bottomFraction;
  final double topFraction;

  const _FrameMetric({
    required this.baseXFraction,
    required this.bottomFraction,
    required this.topFraction,
  });
}

class _RowAnchor {
  final double baseXFraction;
  final double bottomFraction;
  final double contentTopFraction;

  const _RowAnchor({
    required this.baseXFraction,
    required this.bottomFraction,
    required this.contentTopFraction,
  });

  static const empty = _RowAnchor(
    baseXFraction: 0.5,
    bottomFraction: 1.0,
    contentTopFraction: 0.0,
  );

  factory _RowAnchor.fromMetrics(List<_FrameMetric?> metrics) {
    final available = metrics.whereType<_FrameMetric>().toList(growable: false);
    if (available.isEmpty) return empty;

    return _RowAnchor(
      baseXFraction: _median([
        for (final metric in available) metric.baseXFraction,
      ]),
      bottomFraction: _median([
        for (final metric in available) metric.bottomFraction,
      ]),
      contentTopFraction: _median([
        for (final metric in available) metric.topFraction,
      ]),
    );
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class _FrameCorrection {
  final double dxFraction;
  final double dyFraction;

  const _FrameCorrection({required this.dxFraction, required this.dyFraction});

  static const zero = _FrameCorrection(dxFraction: 0, dyFraction: 0);

  factory _FrameCorrection.fromMetric({
    required _FrameMetric? metric,
    required _RowAnchor rowAnchor,
  }) {
    if (metric == null) return zero;
    return _FrameCorrection(
      dxFraction: rowAnchor.baseXFraction - metric.baseXFraction,
      dyFraction: rowAnchor.bottomFraction - metric.bottomFraction,
    );
  }
}
