import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import 'map_page_writer.dart';
import 'map_texture_compiler.dart';
import 'map_texture_geometry.dart';
import 'source_manifest.dart';

final class MapRuntimeVerifier {
  const MapRuntimeVerifier({
    required this.runtimeRoot,
    required this.contentRoot,
    required this.sources,
  });

  final Directory runtimeRoot;
  final Directory contentRoot;
  final AssetSourceManifest sources;

  Future<List<String>> verify() async {
    final errors = <String>[];
    final mapRoot = Directory('${runtimeRoot.path}/maps');
    final expectedFiles = <String>{};
    for (final json in sources.list('maps')) {
      final spec = MapSourceSpec.fromJson(json);
      await _verifyContentExists(spec.id, errors);
      await _verifyMap(spec, mapRoot, expectedFiles, errors);
    }
    await _verifyFileSet(mapRoot, expectedFiles, errors);
    return errors;
  }

  Future<void> _verifyContentExists(String id, List<String> errors) async {
    final file = File('${contentRoot.path}/maps/$id/map.json');
    if (!await file.exists()) errors.add('missing canonical content map: $id');
  }

  Future<void> _verifyMap(
    MapSourceSpec spec,
    Directory root,
    Set<String> expectedFiles,
    List<String> errors,
  ) async {
    final relativeManifest = '${spec.id}/map_texture_manifest.json';
    final file = File('${root.path}/$relativeManifest');
    expectedFiles.add(relativeManifest);
    if (!await file.exists()) {
      errors.add('missing map texture manifest for ${spec.id}');
      return;
    }
    final manifest = _decode(await file.readAsString(), spec.id);
    if (manifest['mapId'] != spec.id ||
        manifest['cols'] != spec.columns ||
        manifest['rows'] != spec.rows) {
      errors.add('${spec.id} map texture contract has wrong identity or size');
    }
    _verifyAverageColors(manifest, spec, errors);
    final pages = manifest['pages'];
    if (pages is! List<dynamic> || pages.isEmpty) {
      errors.add('${spec.id} has no texture pages');
      return;
    }
    for (final value in pages) {
      if (value is! Map<String, dynamic>) {
        errors.add('${spec.id} has an invalid texture page');
        continue;
      }
      await _verifyPage(spec.id, value, root, expectedFiles, errors);
    }
  }

  Map<String, dynamic> _decode(String contents, String id) {
    final value = jsonDecode(contents);
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      throw FormatException('Unsupported map texture manifest for $id');
    }
    return value;
  }

  void _verifyAverageColors(
    Map<String, dynamic> manifest,
    MapSourceSpec spec,
    List<String> errors,
  ) {
    final colors = manifest['averageColors'];
    if (colors is! Map<String, dynamic> ||
        colors.length != spec.columns * spec.rows) {
      errors.add('${spec.id} has incomplete average colors');
      return;
    }
    for (var column = 0; column < spec.columns; column++) {
      for (var row = 0; row < spec.rows; row++) {
        if (colors['$column,$row'] is! int) {
          errors.add('${spec.id} has invalid average color $column,$row');
          return;
        }
      }
    }
  }

  Future<void> _verifyPage(
    String id,
    Map<String, dynamic> page,
    Directory root,
    Set<String> expectedFiles,
    List<String> errors,
  ) async {
    final asset = page['asset'];
    final width = page['pixelWidth'];
    final height = page['pixelHeight'];
    final name = _pageName(id, asset, errors);
    if (name == null || !_validDimensions(id, name, width, height, errors)) {
      return;
    }
    final relative = '$id/$name';
    if (!expectedFiles.add(relative)) errors.add('$id repeats page $name');
    final file = File('${root.path}/$relative');
    if (!await file.exists()) {
      errors.add('missing map texture page: $asset');
      return;
    }
    final decoded = img.decodeJpg(await file.readAsBytes());
    if (decoded == null || decoded.width != width || decoded.height != height) {
      errors.add('$asset does not decode to ${width}x$height');
    }
    if (!_validDestination(page['destination'])) {
      errors.add('$asset has an invalid destination rectangle');
    }
  }

  String? _pageName(String id, Object? asset, List<String> errors) {
    final prefix = '$mapRuntimeRoot/$id/';
    if (asset is! String || !asset.startsWith(prefix)) {
      errors.add('$id has an unsafe texture page asset: $asset');
      return null;
    }
    final name = asset.substring(prefix.length);
    if (name.contains('/') || !RegExp(r'^page_[0-9]+\.jpg$').hasMatch(name)) {
      errors.add('$id has an invalid texture page name: $name');
      return null;
    }
    return name;
  }

  bool _validDimensions(
    String id,
    String name,
    Object? width,
    Object? height,
    List<String> errors,
  ) {
    final valid =
        width is int &&
        height is int &&
        width > 0 &&
        height > 0 &&
        width <= mapPageSize &&
        height <= mapPageSize;
    if (!valid) {
      errors.add('$id page $name has invalid dimensions ${width}x$height');
    }
    return valid;
  }

  bool _validDestination(Object? value) =>
      value is List<dynamic> &&
      value.length == 4 &&
      value.every(
        (coordinate) => coordinate is num && coordinate.toDouble().isFinite,
      );

  Future<void> _verifyFileSet(
    Directory root,
    Set<String> expected,
    List<String> errors,
  ) async {
    final actual = <String>{};
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          actual.add(
            entity.path.substring(root.path.length + 1).replaceAll('\\', '/'),
          );
        }
      }
    }
    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();
    if (missing.isNotEmpty) errors.add('missing map runtime files: $missing');
    if (extra.isNotEmpty) errors.add('unexpected map runtime files: $extra');
  }
}
