import 'dart:convert';
import 'dart:ui' as ui;

import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw/map/rendering/map_texture_set.dart';
import 'package:aonw/map/rendering/saved_map_texture_adapter.dart';
import 'package:aonw/map/rendering/saved_map_texture_layout.dart';
import 'package:flutter/services.dart';

export 'package:aonw/map/rendering/map_texture_set.dart';

abstract interface class MapTextureRepository {
  Future<MapTextureSet> loadSet(String manifestPath);

  Future<MapTextureSet> importSaved(
    SavedMapImageSource source,
    SavedMapTextureLayout layout, {
    ValueChanged<double>? onProgress,
  });

  ui.Image? cachedPage(MapTexturePage page);

  Future<ui.Image> loadPage(MapTexturePage page);

  void disposeSet(MapTextureSet set);

  void dispose();
}

class FlutterMapTextureRepository implements MapTextureRepository {
  FlutterMapTextureRepository({
    AssetBundle? bundle,
    SavedMapTextureAdapter savedAdapter = const SavedMapTextureAdapter(),
  }) : bundle = bundle ?? rootBundle,
       _savedAdapter = savedAdapter;

  final AssetBundle bundle;
  final SavedMapTextureAdapter _savedAdapter;
  final Map<String, ui.Image> _pages = {};
  final Map<String, Future<ui.Image>> _pendingPages = {};
  final Map<String, int> _pageGenerations = {};
  var _generation = 0;
  var _disposed = false;

  @override
  Future<MapTextureSet> loadSet(String manifestPath) async {
    _ensureActive();
    final manifestMatch = RegExp(
      r'^assets/runtime/maps/([A-Za-z0-9_-]+)/map_texture_manifest\.json$',
    ).firstMatch(manifestPath);
    if (manifestMatch == null) {
      throw ArgumentError.value(
        manifestPath,
        'manifestPath',
        'Bundled texture manifests must be under assets/runtime/maps/',
      );
    }
    final generation = _generation;
    final json = jsonDecode(await bundle.loadString(manifestPath));
    if (_disposed || generation != _generation) {
      throw StateError('Map texture repository was disposed while loading');
    }
    if (json is! Map<String, dynamic> || json['version'] != 1) {
      throw const FormatException('Unsupported map texture manifest');
    }
    final mapId = json['mapId'];
    if (mapId is! String || mapId != manifestMatch.group(1)) {
      throw const FormatException(
        'Map texture manifest id does not match its asset directory',
      );
    }
    final pageJson = json['pages'];
    final colorJson = json['averageColors'];
    if (pageJson is! List || colorJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid map texture manifest structure');
    }
    return MapTextureSet(
      id: mapId,
      cols: json['cols'] as int,
      rows: json['rows'] as int,
      worldSize: ui.Size(
        (json['worldWidth'] as num).toDouble(),
        (json['worldHeight'] as num).toDouble(),
      ),
      pages: List.unmodifiable(
        pageJson.map((page) => _bundledPageFromJson(mapId, page)),
      ),
      averageColors: Map.unmodifiable({
        for (final entry in colorJson.entries)
          _tileKey(entry.key): Color(entry.value as int),
      }),
    );
  }

  MapTexturePage _bundledPageFromJson(String mapId, Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid map texture page');
    }
    final destination = (value['destination'] as List<dynamic>).cast<num>();
    if (destination.length != 4) {
      throw const FormatException('Invalid map texture page destination');
    }
    final assetPath = value['asset'] as String;
    final expectedPagePath = RegExp(
      '^assets/runtime/maps/${RegExp.escape(mapId)}/page_[0-9]+\\.jpg\$',
    );
    if (!expectedPagePath.hasMatch(assetPath)) {
      throw FormatException('Invalid bundled map page path: $assetPath');
    }
    return MapTexturePage(
      source: BundledMapTexturePageSource(assetPath),
      pixelSize: ui.Size(
        (value['pixelWidth'] as num).toDouble(),
        (value['pixelHeight'] as num).toDouble(),
      ),
      destination: ui.Rect.fromLTWH(
        destination[0].toDouble(),
        destination[1].toDouble(),
        destination[2].toDouble(),
        destination[3].toDouble(),
      ),
    );
  }

  @override
  Future<MapTextureSet> importSaved(
    SavedMapImageSource source,
    SavedMapTextureLayout layout, {
    ValueChanged<double>? onProgress,
  }) async {
    _ensureActive();
    final generation = _generation;
    final result = await _savedAdapter.compile(
      source,
      layout,
      onProgress: onProgress,
    );
    if (_disposed || generation != _generation) {
      for (final image in result.images.values) {
        image.dispose();
      }
      throw StateError('Saved map texture was disposed while importing');
    }
    for (final entry in result.images.entries) {
      _pages.remove(entry.key)?.dispose();
      _pages[entry.key] = entry.value;
    }
    return result.set;
  }

  @override
  ui.Image? cachedPage(MapTexturePage page) {
    _ensureActive();
    return _pages[page.cacheKey];
  }

  @override
  Future<ui.Image> loadPage(MapTexturePage page) async {
    _ensureActive();
    final ready = _pages[page.cacheKey];
    if (ready != null) return ready;
    final pending = _pendingPages[page.cacheKey];
    if (pending != null) return pending;
    final generation = _generation;
    final pageGeneration = _pageGenerations[page.cacheKey] ?? 0;
    final future = _loadAndCachePage(page, generation, pageGeneration);
    _pendingPages[page.cacheKey] = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingPages[page.cacheKey], future)) {
        _pendingPages.remove(page.cacheKey)?.ignore();
      }
    }
  }

  Future<ui.Image> _loadAndCachePage(
    MapTexturePage page,
    int generation,
    int pageGeneration,
  ) async {
    final image = await _decodePage(page);
    if (_disposed ||
        generation != _generation ||
        pageGeneration != (_pageGenerations[page.cacheKey] ?? 0)) {
      image.dispose();
      throw StateError('${page.cacheKey} was disposed while loading');
    }
    if (image.width != page.pixelSize.width.round() ||
        image.height != page.pixelSize.height.round()) {
      image.dispose();
      throw StateError('${page.cacheKey} dimensions do not match its manifest');
    }
    return _pages[page.cacheKey] = image;
  }

  Future<ui.Image> _decodePage(MapTexturePage page) async {
    final source = page.source;
    if (source is! BundledMapTexturePageSource) {
      throw StateError('Missing imported map texture page: ${page.cacheKey}');
    }
    final data = await bundle.load(source.assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void disposeSet(MapTextureSet set) {
    for (final page in set.pages) {
      _pageGenerations.update(
        page.cacheKey,
        (generation) => generation + 1,
        ifAbsent: () => 1,
      );
      _pages.remove(page.cacheKey)?.dispose();
      _pendingPages.remove(page.cacheKey)?.ignore();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    for (final image in _pages.values) {
      image.dispose();
    }
    _pages.clear();
    _pendingPages.clear();
    _pageGenerations.clear();
  }

  void _ensureActive() {
    if (_disposed) throw StateError('Map texture repository is disposed');
  }

  static (int, int) _tileKey(String key) {
    final values = key.split(',').map(int.parse).toList();
    if (values.length != 2) throw FormatException('Invalid tile key: $key');
    return (values[0], values[1]);
  }
}
