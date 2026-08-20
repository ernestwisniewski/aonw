import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

sealed class MapTexturePageSource {
  const MapTexturePageSource();

  String get cacheKey;
}

final class BundledMapTexturePageSource extends MapTexturePageSource {
  const BundledMapTexturePageSource(this.assetPath);

  final String assetPath;

  @override
  String get cacheKey => assetPath;
}

final class MemoryMapTexturePageSource extends MapTexturePageSource {
  const MemoryMapTexturePageSource(this.id);

  final String id;

  @override
  String get cacheKey => id;
}

class MapTexturePage {
  const MapTexturePage({
    required this.source,
    required this.pixelSize,
    required this.destination,
  });

  final MapTexturePageSource source;
  final ui.Size pixelSize;
  final ui.Rect destination;

  String get cacheKey => source.cacheKey;
}

class MapTextureSet {
  const MapTextureSet({
    required this.id,
    required this.cols,
    required this.rows,
    required this.worldSize,
    required this.pages,
    required this.averageColors,
  });

  final String id;
  final int cols;
  final int rows;
  final ui.Size worldSize;
  final List<MapTexturePage> pages;
  final Map<(int, int), Color> averageColors;
}
