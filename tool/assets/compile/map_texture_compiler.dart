import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'map_asset_bundle_compiler.dart';
import 'map_atlas_builder.dart';
import 'source_manifest.dart';

final class MapTextureCompiler {
  const MapTextureCompiler({
    required this.sources,
    required this.sourceRoot,
    required this.outputRoot,
  });

  final AssetSourceManifest sources;
  final Directory sourceRoot;
  final Directory outputRoot;

  Future<void> compile() async {
    if (await outputRoot.exists()) await outputRoot.delete(recursive: true);
    await outputRoot.create(recursive: true);
    for (final spec in sources.list('maps')) {
      await _compileMap(MapSourceSpec.fromJson(spec));
    }
  }

  Future<void> _compileMap(MapSourceSpec spec) async {
    final files = _sourceFiles(spec);
    await _verifySources(spec, files);
    await MapAssetBundleCompiler(
      spec: MapAssetBundleSpec(
        mapId: spec.id,
        mapContentHash: spec.mapContentHash,
        cols: spec.columns,
        rows: spec.rows,
      ),
      source: FileMapTileImageSource(files: files, rows: spec.rows),
      output: Directory('${outputRoot.path}/${spec.id}'),
    ).compile();
  }

  List<File> _sourceFiles(MapSourceSpec spec) => [
    for (var column = 0; column < spec.columns; column++)
      for (var row = 0; row < spec.rows; row++)
        File(
          '${sourceRoot.path}/maps/${spec.id}/'
          '${column + 1}x${row + 1}.jpg',
        ),
  ];

  Future<void> _verifySources(MapSourceSpec spec, List<File> files) async {
    final missing = <String>[];
    for (final file in files) {
      if (!await file.exists()) missing.add(file.path);
    }
    if (missing.isNotEmpty) {
      throw StateError('${spec.id} is missing ${missing.length} source slices');
    }
    final digest = await _aggregateDigest(files);
    if (digest != spec.aggregateSha256) {
      throw StateError(
        '${spec.id} source digest mismatch: '
        '$digest != ${spec.aggregateSha256}',
      );
    }
  }

  Future<String> _aggregateDigest(List<File> files) async {
    final sorted = [...files]..sort((a, b) => a.path.compareTo(b.path));
    final buffer = StringBuffer();
    for (final file in sorted) {
      final digest = sha256.convert(await file.readAsBytes());
      final relative = file.path.substring(sourceRoot.path.length + 1);
      buffer.writeln('$digest  $relative');
    }
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }
}

final class MapSourceSpec {
  const MapSourceSpec({
    required this.id,
    required this.columns,
    required this.rows,
    required this.aggregateSha256,
    required this.mapContentHash,
  });

  factory MapSourceSpec.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final columns = json['cols'] as int;
    final rows = json['rows'] as int;
    if (id.isEmpty || columns <= 0 || rows <= 0) {
      throw FormatException('Invalid map source contract: $id');
    }
    return MapSourceSpec(
      id: id,
      columns: columns,
      rows: rows,
      aggregateSha256: json['aggregateSha256'] as String,
      mapContentHash: _contentHash(json['mapContentHash'], id),
    );
  }

  final String id;
  final int columns;
  final int rows;
  final String aggregateSha256;
  final String mapContentHash;

  static String _contentHash(Object? value, String id) {
    if (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw FormatException('$id mapContentHash must be a SHA-256 digest');
    }
    return value;
  }
}
