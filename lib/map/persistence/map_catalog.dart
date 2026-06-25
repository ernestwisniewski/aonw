import 'dart:convert';
import 'dart:io';

import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw/map/persistence/map_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

abstract final class MapCatalog {
  static const String defaultMapName = MapSelection.defaultMapName;

  static Future<List<MapSelection>> listAvailableMaps({
    AssetBundle? bundle,
    Directory? savedMapsDirectory,
  }) async {
    final bundledMaps = await _listBundledMaps(bundle: bundle);
    final savedMaps = await _listSavedMaps(directory: savedMapsDirectory);

    final allMaps = [...savedMaps, ...bundledMaps]
      ..sort((a, b) {
        final sourceOrder = _sourceRank(
          a.source,
        ).compareTo(_sourceRank(b.source));
        if (sourceOrder != 0) return sourceOrder;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
    return allMaps;
  }

  static Future<MapData> loadMap(
    MapSelection selection, {
    AssetBundle? bundle,
    Directory? savedMapsDirectory,
  }) async {
    final mapData = switch (selection.source) {
      MapSource.asset => await _loadBundledMap(selection.name, bundle: bundle),
      MapSource.saved => await _loadSavedMap(
        selection.name,
        directory: savedMapsDirectory,
      ),
    };
    return mapData..mapName ??= selection.name;
  }

  /// Lists saved maps by scanning for `<mapsDir>/<name>/map.json`.
  static Future<List<MapSelection>> _listSavedMaps({
    Directory? directory,
  }) async {
    // Web has no on-disk saved maps directory; only bundled assets are
    // available. Skipping here avoids touching dart:io / Platform APIs.
    if (kIsWeb && directory == null) return const [];
    final mapsDir = directory ?? await MapStorage.mapsDirectory();
    if (!await mapsDir.exists()) return [];

    final results = <MapSelection>[];
    await for (final entity in mapsDir.list()) {
      if (entity is! Directory) continue;
      final jsonFile = File('${entity.path}/map.json');
      if (!await jsonFile.exists()) continue;
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      results.add(MapSelection(name: name, source: MapSource.saved));
    }
    return results;
  }

  static Future<MapData> _loadSavedMap(
    String name, {
    Directory? directory,
  }) async {
    if (kIsWeb && directory == null) {
      throw StateError('Saved maps are not available on the web build.');
    }
    final mapsDir = directory ?? await MapStorage.mapsDirectory();
    final file = File('${mapsDir.path}/$name/map.json');
    final json = await file.readAsString();
    return MapLoader.fromJson(json);
  }

  /// Lists bundled maps by scanning the asset manifest for
  /// `assets/maps/<name>/map.json` entries.
  static Future<List<MapSelection>> _listBundledMaps({
    AssetBundle? bundle,
  }) async {
    final manifest = await _loadAssetManifestEntries(bundle: bundle);
    final names = manifest
        .where(
          (path) =>
              path.startsWith(MapStorage.mapsAssetDir) &&
              path.endsWith('/map.json'),
        )
        .map(_folderName)
        .toSet()
        .toList();
    return names
        .map((name) => MapSelection(name: name, source: MapSource.asset))
        .toList();
  }

  static Future<MapData> _loadBundledMap(
    String name, {
    AssetBundle? bundle,
  }) async {
    final json = await (bundle ?? rootBundle).loadString(
      '${MapStorage.mapsAssetDir}$name/map.json',
    );
    return MapLoader.fromJson(json);
  }

  static Future<List<String>> _loadAssetManifestEntries({
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(assetBundle);
      return manifest.listAssets();
    } catch (_) {
      final manifestJson = await assetBundle.loadString('AssetManifest.json');
      final decoded = json.decode(manifestJson) as Map<String, dynamic>;
      return decoded.keys.toList();
    }
  }

  static int _sourceRank(MapSource source) => switch (source) {
    MapSource.saved => 0,
    MapSource.asset => 1,
  };

  /// Extracts the folder name from `assets/maps/<name>/map.json`.
  static String _folderName(String path) {
    final parts = path.split('/');
    return parts[parts.length - 2];
  }
}
