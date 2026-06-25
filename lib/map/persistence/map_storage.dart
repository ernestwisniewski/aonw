import 'dart:io';

import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/shared/persistence/app_data_directory.dart';
import 'package:flutter/services.dart';

abstract final class MapStorage {
  static const String mapsAssetDir = 'assets/maps/';

  static final RegExp _invalidMapNameChars = RegExp(r'[^A-Za-z0-9_-]+');
  static final Set<String> _reservedWindowsNames = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

  static String sanitizeMapName(String rawName) {
    final sanitized = rawName
        .trim()
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(_invalidMapNameChars, '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) return 'map';
    if (_reservedWindowsNames.contains(sanitized.toUpperCase())) {
      return '${sanitized}_map';
    }
    return sanitized;
  }

  /// Resolves the image path for a map.
  ///
  /// Saved maps: looks in `<documents>/maps/<name>/` — sliced (`1x1.jpg`)
  /// first, then single (`image.jpg`).
  ///
  /// Asset maps: looks in `assets/maps/<name>/` — sliced (`1x1.jpg`) first,
  /// then single (`image.jpg`).
  ///
  /// Returns the first-slice path when sliced so [MapImageLayer.loadAuto]
  /// can detect and load all tiles.
  static Future<String?> resolveImagePath(
    String mapName, {
    MapSource source = MapSource.saved,
  }) async {
    if (mapName.trim().isEmpty) return null;
    final safeName = sanitizeMapName(mapName);

    if (source == MapSource.saved) {
      final firstSlice = await sliceFile(safeName, 0, 0);
      if (await firstSlice.exists()) return firstSlice.path;
      final file = await imageFile(safeName);
      if (await file.exists()) return file.path;
      return null;
    }

    final assetSlicePath = '$mapsAssetDir$safeName/1x1.jpg';
    try {
      await rootBundle.load(assetSlicePath);
      return assetSlicePath;
    } catch (_) {}

    final assetImagePath = '$mapsAssetDir$safeName/image.jpg';
    try {
      await rootBundle.load(assetImagePath);
      return assetImagePath;
    } catch (_) {}

    return null;
  }

  /// Root directory: `<documents>/maps/`
  static Future<Directory> mapsDirectory() async {
    final docs = await AppDataDirectory.documentsDirectory();
    return Directory('${docs.path}/maps');
  }

  /// Per-map directory: `<documents>/maps/<mapName>/`
  static Future<Directory> mapDirectory(String mapName) async {
    final root = await mapsDirectory();
    return Directory('${root.path}/$mapName');
  }

  /// JSON file: `<documents>/maps/<mapName>/map.json`
  static Future<File> jsonFile(String mapName) async {
    final dir = await mapDirectory(mapName);
    return File('${dir.path}/map.json');
  }

  /// Single image: `<documents>/maps/<mapName>/image.jpg`
  static Future<File> imageFile(String mapName) async {
    final dir = await mapDirectory(mapName);
    return File('${dir.path}/image.jpg');
  }

  /// Sliced tile: `<documents>/maps/<mapName>/{col+1}x{row+1}.jpg`
  static Future<File> sliceFile(String mapName, int col, int row) async {
    final dir = await mapDirectory(mapName);
    return File('${dir.path}/${col + 1}x${row + 1}.jpg');
  }
}
