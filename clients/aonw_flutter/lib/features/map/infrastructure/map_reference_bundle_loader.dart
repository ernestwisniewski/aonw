import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../application/map_repository.dart';
import '../read_model/map_reference_bundle.dart';
import '../read_model/map_view.dart';

final class MapReferenceBundleLoader {
  const MapReferenceBundleLoader(this.assets);

  final AssetBundle assets;

  Future<MapReferenceBundle> load({
    required String manifestAsset,
    required MapView map,
  }) async {
    try {
      final root = _object(
        jsonDecode(await assets.loadString(manifestAsset)),
        'map asset bundle',
      );
      _expectKeys(root, const {
        'version',
        'mapId',
        'mapContentHash',
        'gridLayout',
        'cols',
        'rows',
        'worldWidth',
        'worldHeight',
        'compiledScale',
        'filterQuality',
        'pageSizeLimit',
        'gutter',
        'pages',
        'averageColors',
      });
      _verifyIdentity(root, map);
      final pages = _list(root['pages'], 'bundle pages');
      if (pages.isEmpty) {
        throw const FormatException('Map bundle has no pages.');
      }
      final directory = manifestAsset.substring(
        0,
        manifestAsset.lastIndexOf('/'),
      );
      final seenFiles = <String>{};
      return MapReferenceBundle(
        mapId: map.mapId,
        mapContentHash: map.contentHash,
        worldWidth: _positiveDouble(root['worldWidth'], 'world width'),
        worldHeight: _positiveDouble(root['worldHeight'], 'world height'),
        pages: [
          for (final page in pages)
            await _loadPage(
              _object(page, 'bundle page'),
              directory: directory,
              mapId: map.mapId,
              seenFiles: seenFiles,
            ),
        ],
      );
    } on MapLoadException {
      rethrow;
    } on Object catch (error) {
      throw MapLoadException(
        code: 'invalid_map_bundle',
        message: 'The map reference bundle is invalid: $error',
      );
    }
  }

  Future<MapReferencePage> _loadPage(
    Map<String, Object?> page, {
    required String directory,
    required String mapId,
    required Set<String> seenFiles,
  }) async {
    _expectKeys(page, const {
      'file',
      'asset',
      'format',
      'sha256',
      'pixelWidth',
      'pixelHeight',
      'destination',
    });
    final file = _pageFile(page['file']);
    if (!seenFiles.add(file)) {
      throw FormatException('Duplicate map bundle page: $file');
    }
    if (page['asset'] != 'assets/runtime/maps/$mapId/$file') {
      throw FormatException('Map bundle page has an invalid asset path: $file');
    }
    if (page['format'] != 'jpeg') {
      throw FormatException('Map bundle page is not JPEG: $file');
    }
    final expectedHash = _digest(page['sha256'], 'page digest');
    final width = _positiveInt(page['pixelWidth'], 'page width');
    final height = _positiveInt(page['pixelHeight'], 'page height');
    final data = await assets.load('$directory/$file');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != expectedHash) {
      throw FormatException('Map bundle page hash does not match: $file');
    }
    await _verifyImageSize(bytes, width: width, height: height, file: file);
    final destination = _list(page['destination'], 'page destination');
    if (destination.length != 4) {
      throw FormatException('Map bundle page destination is invalid: $file');
    }
    final values = [
      for (final value in destination) _finiteDouble(value, 'page destination'),
    ];
    if (values[2] <= 0 || values[3] <= 0) {
      throw FormatException('Map bundle page destination is empty: $file');
    }
    return MapReferencePage(
      file: file,
      bytes: bytes,
      pixelWidth: width,
      pixelHeight: height,
      destination: (
        x: values[0],
        y: values[1],
        width: values[2],
        height: values[3],
      ),
    );
  }

  static void _verifyIdentity(Map<String, Object?> root, MapView map) {
    if (root['version'] != 1 || root['gridLayout'] != 'oddQFlatTop') {
      throw const FormatException('Unsupported map bundle contract.');
    }
    if (root['mapId'] != map.mapId ||
        root['mapContentHash'] != map.contentHash ||
        root['cols'] != map.cols ||
        root['rows'] != map.rows) {
      throw const FormatException(
        'Map bundle identity does not match MapView.',
      );
    }
    _digest(root['mapContentHash'], 'map content hash');
  }

  static Future<void> _verifyImageSize(
    Uint8List bytes, {
    required int width,
    required int height,
    required String file,
  }) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        if (frame.image.width != width || frame.image.height != height) {
          throw FormatException('Map bundle page size does not match: $file');
        }
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$field must be an object.');
  }
  return value;
}

List<Object?> _list(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('$field must be an array.');
  }
  return value;
}

void _expectKeys(Map<String, Object?> value, Set<String> expected) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw const FormatException('Map bundle contains unexpected fields.');
  }
}

String _pageFile(Object? value) {
  if (value is! String || !RegExp(r'^page_[0-9]+\.jpg$').hasMatch(value)) {
    throw const FormatException('Map bundle page name is unsafe.');
  }
  return value;
}

String _digest(Object? value, String field) {
  if (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw FormatException('$field is not a SHA-256 digest.');
  }
  return value;
}

int _positiveInt(Object? value, String field) {
  if (value is! int || value <= 0 || value > 16384) {
    throw FormatException('$field must be a supported positive integer.');
  }
  return value;
}

double _positiveDouble(Object? value, String field) {
  final number = _finiteDouble(value, field);
  if (number <= 0) throw FormatException('$field must be positive.');
  return number;
}

double _finiteDouble(Object? value, String field) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$field must be finite.');
  }
  return value.toDouble();
}
