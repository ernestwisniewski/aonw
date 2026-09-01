import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'map_asset_bundle_manifest.dart';
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
    final manifest = MapAssetBundleManifest.decode(await file.readAsString());
    try {
      manifest.verifyMapIdentity(
        mapId: spec.id,
        mapContentHash: spec.mapContentHash,
        cols: spec.columns,
        rows: spec.rows,
      );
    } on FormatException catch (error) {
      errors.add('${spec.id}: ${error.message}');
    }
    if ((manifest.worldWidth - mapWorldWidth(spec.columns)).abs() > 1e-6 ||
        (manifest.worldHeight - mapWorldHeight(spec.columns, spec.rows)).abs() >
            1e-6) {
      errors.add('${spec.id}: world bounds do not match odd-q geometry');
    }
    _verifyAverageColors(manifest, spec, errors);
    for (final page in manifest.pages) {
      await _verifyPage(spec.id, page, root, expectedFiles, errors);
    }
  }

  void _verifyAverageColors(
    MapAssetBundleManifest manifest,
    MapSourceSpec spec,
    List<String> errors,
  ) {
    final colors = manifest.averageColors;
    if (colors.length != spec.columns * spec.rows) {
      errors.add('${spec.id} has incomplete average colors');
      return;
    }
    for (var column = 0; column < spec.columns; column++) {
      for (var row = 0; row < spec.rows; row++) {
        if (!colors.containsKey('$column,$row')) {
          errors.add('${spec.id} has invalid average color $column,$row');
          return;
        }
      }
    }
  }

  Future<void> _verifyPage(
    String id,
    MapAssetBundlePage page,
    Directory root,
    Set<String> expectedFiles,
    List<String> errors,
  ) async {
    final name = _pageName(id, page, errors);
    if (name == null ||
        !_validDimensions(
          id,
          name,
          page.pixelWidth,
          page.pixelHeight,
          errors,
        )) {
      return;
    }
    final relative = '$id/$name';
    if (!expectedFiles.add(relative)) errors.add('$id repeats page $name');
    final file = File('${root.path}/$relative');
    if (!await file.exists()) {
      errors.add('missing map texture page: ${page.asset}');
      return;
    }
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (digest != page.sha256) {
      errors.add('${page.asset} SHA-256 does not match its bundle record');
    }
    final decoded = img.decodeJpg(bytes);
    if (decoded == null ||
        decoded.width != page.pixelWidth ||
        decoded.height != page.pixelHeight) {
      errors.add(
        '${page.asset} does not decode to '
        '${page.pixelWidth}x${page.pixelHeight}',
      );
    }
    if (!_validDestination(page.destination)) {
      errors.add('${page.asset} has an invalid destination rectangle');
    }
  }

  String? _pageName(String id, MapAssetBundlePage page, List<String> errors) {
    final prefix = '$mapRuntimeRoot/$id/';
    if (page.asset != '$prefix${page.file}') {
      errors.add('$id has an unsafe texture page asset: ${page.asset}');
      return null;
    }
    return page.file;
  }

  bool _validDimensions(
    String id,
    String name,
    int width,
    int height,
    List<String> errors,
  ) {
    final valid =
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
