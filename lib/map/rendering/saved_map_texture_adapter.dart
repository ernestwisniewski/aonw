import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw/map/rendering/map_texture_set.dart';
import 'package:aonw/map/rendering/saved_map_texture_color_sampler.dart';
import 'package:aonw/map/rendering/saved_map_texture_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

const int _sliceLoadConcurrency = 16;
const double _preferredAtlasScale = 2;
const int _maxAtlasPixels = 16000000;

// One opaque atlas pixel of overlap prevents filtered sampling from touching
// transparent texels at a shared hex edge. The final grid clip removes this
// bleed at the outside boundary of the map.
const double _sliceEdgeBleedPixels = 1;

class SavedMapTextureCompilation {
  const SavedMapTextureCompilation({required this.set, required this.images});

  final MapTextureSet set;
  final Map<String, ui.Image> images;
}

/// Converts saved/imported raster formats into the same paged model used by
/// generated bundled maps. The renderer never sees the source raster format.
class SavedMapTextureAdapter {
  const SavedMapTextureAdapter({
    SavedMapTextureColorSampler colorSampler =
        const SavedMapTextureColorSampler(),
  }) : _colorSampler = colorSampler;

  final SavedMapTextureColorSampler _colorSampler;

  Future<SavedMapTextureCompilation> compile(
    SavedMapImageSource source,
    SavedMapTextureLayout layout, {
    ValueChanged<double>? onProgress,
  }) => switch (source) {
    SavedMapSingleImageSource() => _compileSingle(
      source,
      layout,
      onProgress: onProgress,
    ),
    SavedMapSliceSetSource() => _compileSlices(
      source,
      layout,
      onProgress: onProgress,
    ),
  };

  Future<SavedMapTextureCompilation> _compileSingle(
    SavedMapSingleImageSource source,
    SavedMapTextureLayout layout, {
    ValueChanged<double>? onProgress,
  }) async {
    onProgress?.call(0);
    final image = await _decodeFile(source.filePath);
    try {
      final colors = await _colorSampler.sampleSingleImage(image, layout);
      final key = _pageKey(source, layout);
      final page = MapTexturePage(
        source: MemoryMapTexturePageSource(key),
        pixelSize: ui.Size(image.width.toDouble(), image.height.toDouble()),
        destination: ui.Offset.zero & layout.worldSize,
      );
      onProgress?.call(1);
      return SavedMapTextureCompilation(
        set: _set(layout, page, colors),
        images: {key: image},
      );
    } catch (_) {
      image.dispose();
      rethrow;
    }
  }

  Future<SavedMapTextureCompilation> _compileSlices(
    SavedMapSliceSetSource source,
    SavedMapTextureLayout layout, {
    ValueChanged<double>? onProgress,
  }) async {
    onProgress?.call(0);
    final atlasScale = _atlasScale(layout.worldSize);
    final edgeBleed = _sliceEdgeBleedPixels / atlasScale;
    final clipRadiusScale = 1 + edgeBleed / layout.config.hexRadius;
    final queue = <(int, int)>[
      for (var col = 0; col < layout.cols; col++)
        for (var row = 0; row < layout.rows; row++) (col, row),
    ];
    final slices = <_SavedSlice>[];
    final colors = <(int, int), Color>{};
    Object? firstError;
    StackTrace? firstStackTrace;
    var nextIndex = 0;
    var completed = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= queue.length) return;
        final (col, row) = queue[index];
        final path = source.slicePath(col, row);
        try {
          if (!await File(path).exists()) continue;
          final image = await _decodeFile(path);
          final sourceRect = _imageRect(image);
          slices.add(
            _SavedSlice(
              column: col,
              row: row,
              image: image,
              source: sourceRect,
              destination: layout.tileDestination(col, row).inflate(edgeBleed),
              clip: layout.tileClip(col, row, radiusScale: clipRadiusScale),
            ),
          );
          final average = await _colorSampler.sampleHex(image, sourceRect);
          if (average != null) colors[(col, row)] = average;
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        } finally {
          completed++;
          onProgress?.call(queue.isEmpty ? 1 : completed / queue.length);
        }
      }
    }

    try {
      final workerCount = math.min(queue.length, _sliceLoadConcurrency);
      await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);
      if (firstError case final error?) {
        Error.throwWithStackTrace(error, firstStackTrace!);
      }
      if (slices.isEmpty) {
        throw StateError(
          'Saved map slice set is empty: ${source.directoryPath}',
        );
      }
      slices.sort((left, right) {
        final columnOrder = left.column.compareTo(right.column);
        return columnOrder != 0 ? columnOrder : left.row.compareTo(right.row);
      });
      final atlas = await _composeAtlas(slices, layout, atlasScale);
      final key = _pageKey(source, layout);
      final page = MapTexturePage(
        source: MemoryMapTexturePageSource(key),
        pixelSize: ui.Size(atlas.width.toDouble(), atlas.height.toDouble()),
        destination: ui.Offset.zero & layout.worldSize,
      );
      onProgress?.call(1);
      return SavedMapTextureCompilation(
        set: _set(layout, page, colors),
        images: {key: atlas},
      );
    } finally {
      for (final slice in slices) {
        slice.image.dispose();
      }
    }
  }

  MapTextureSet _set(
    SavedMapTextureLayout layout,
    MapTexturePage page,
    Map<(int, int), Color> colors,
  ) {
    return MapTextureSet(
      id: 'saved-map',
      cols: layout.cols,
      rows: layout.rows,
      worldSize: layout.worldSize,
      pages: List.unmodifiable([page]),
      averageColors: Map.unmodifiable(colors),
    );
  }

  String _pageKey(SavedMapImageSource source, SavedMapTextureLayout layout) {
    return 'saved-map:${Object.hash(source, layout.cols, layout.rows)}:page-0';
  }

  Future<ui.Image> _composeAtlas(
    List<_SavedSlice> slices,
    SavedMapTextureLayout layout,
    double scale,
  ) async {
    final width = math.max(1, (layout.worldSize.width * scale).ceil());
    final height = math.max(1, (layout.worldSize.height * scale).ceil());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    for (final slice in slices) {
      canvas
        ..save()
        ..clipPath(slice.clip)
        ..drawImageRect(
          slice.image,
          slice.source,
          slice.destination,
          Paint()..filterQuality = FilterQuality.medium,
        )
        ..restore();
    }
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }

  double _atlasScale(ui.Size worldSize) {
    final preferredPixels =
        worldSize.width *
        worldSize.height *
        _preferredAtlasScale *
        _preferredAtlasScale;
    if (preferredPixels <= _maxAtlasPixels) return _preferredAtlasScale;
    return math
        .sqrt(_maxAtlasPixels / (worldSize.width * worldSize.height))
        .clamp(1, _preferredAtlasScale)
        .toDouble();
  }
}

class _SavedSlice {
  const _SavedSlice({
    required this.column,
    required this.row,
    required this.image,
    required this.source,
    required this.destination,
    required this.clip,
  });

  final int column;
  final int row;
  final ui.Image image;
  final ui.Rect source;
  final ui.Rect destination;
  final ui.Path clip;
}

Future<ui.Image> _decodeFile(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

ui.Rect _imageRect(ui.Image image) =>
    ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
