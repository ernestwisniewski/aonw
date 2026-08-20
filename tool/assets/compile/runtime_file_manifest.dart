import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'atlas_packer.dart';
import 'source_manifest.dart';

const String runtimeAssetPrefix = 'assets/runtime';
const String runtimeManifestName = 'runtime_manifest.json';

final class RuntimeFileManifest {
  const RuntimeFileManifest({
    required this.sourceManifestSha256,
    required this.externalSource,
    required this.files,
  });

  static Future<RuntimeFileManifest> load(Directory runtimeRoot) async {
    final file = File('${runtimeRoot.path}/$runtimeManifestName');
    if (!await file.exists()) {
      throw StateError('Missing $runtimeAssetPrefix/$runtimeManifestName');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('Unsupported runtime asset manifest');
    }
    _expectKeys(decoded.keys.toSet(), const {
      'version',
      'assetRoot',
      'sourceManifestSha256',
      'externalSource',
      'toolchain',
      'files',
    }, 'runtime manifest');
    if (decoded['assetRoot'] != runtimeAssetPrefix) {
      throw const FormatException('Runtime manifest has an invalid assetRoot');
    }
    final sourceSha = decoded['sourceManifestSha256'];
    if (!_isSha256(sourceSha)) {
      throw const FormatException('Runtime manifest has an invalid source SHA');
    }
    final source = decoded['externalSource'];
    if (source is! Map<String, dynamic>) {
      throw const FormatException('Runtime manifest has no external source');
    }
    _expectKeys(source.keys.toSet(), const {
      'repository',
      'revision',
    }, 'runtime external source');
    final toolchain = decoded['toolchain'];
    if (toolchain is! Map<String, dynamic> ||
        toolchain['cwebp'] != requiredCwebpVersion ||
        toolchain['atlasPageSize'] != maxAtlasPageSize) {
      throw const FormatException('Runtime manifest toolchain differs');
    }
    final records = decoded['files'];
    if (records is! Map<String, dynamic>) {
      throw const FormatException('Runtime manifest files must be an object');
    }
    return RuntimeFileManifest(
      sourceManifestSha256: sourceSha as String,
      externalSource: Map.unmodifiable(source.cast<String, String>()),
      files: Map.unmodifiable({
        for (final entry in records.entries)
          _validatedPath(entry.key): RuntimeFileRecord.fromJson(
            entry.key,
            entry.value,
          ),
      }),
    );
  }

  static Future<RuntimeFileManifest> write({
    required Directory runtimeRoot,
    required AssetSourceManifest sources,
  }) async {
    final files = await _runtimeFiles(runtimeRoot);
    final records = <String, RuntimeFileRecord>{};
    for (final entry in files.entries) {
      records[entry.key] = await RuntimeFileRecord.fromFile(entry.value);
    }
    final manifest = RuntimeFileManifest(
      sourceManifestSha256: sources.sha256Digest,
      externalSource: Map.unmodifiable(sources.externalSource.toJson()),
      files: Map.unmodifiable(records),
    );
    final output = File('${runtimeRoot.path}/$runtimeManifestName');
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
      flush: true,
    );
    return manifest;
  }

  final String sourceManifestSha256;
  final Map<String, String> externalSource;
  final Map<String, RuntimeFileRecord> files;

  Map<String, Object> toJson() => {
    'version': 1,
    'assetRoot': runtimeAssetPrefix,
    'sourceManifestSha256': sourceManifestSha256,
    'externalSource': externalSource,
    'toolchain': {
      'cwebp': requiredCwebpVersion,
      'atlasPageSize': maxAtlasPageSize,
    },
    'files': {
      for (final entry in files.entries) entry.key: entry.value.toJson(),
    },
  };

  Future<List<String>> verify(
    Directory runtimeRoot,
    AssetSourceManifest sources,
  ) async {
    final errors = <String>[];
    if (sourceManifestSha256 != sources.sha256Digest) {
      errors.add('runtime was generated from a different source manifest');
    }
    if (!_sameSource(externalSource, sources.externalSource.toJson())) {
      errors.add(
        'runtime external source contract differs from source manifest',
      );
    }
    final actual = await _runtimeFiles(runtimeRoot);
    final expectedPaths = files.keys.toSet();
    final actualPaths = actual.keys.toSet();
    for (final path in expectedPaths.difference(actualPaths).toList()..sort()) {
      errors.add('missing runtime file: $path');
    }
    for (final path in actualPaths.difference(expectedPaths).toList()..sort()) {
      errors.add('unexpected runtime file: $path');
    }
    for (final path in expectedPaths.intersection(actualPaths)) {
      final mismatch = await files[path]!.mismatch(actual[path]!);
      if (mismatch != null) errors.add('$path $mismatch');
    }
    return errors;
  }
}

final class RuntimeFileRecord {
  const RuntimeFileRecord({required this.bytes, required this.sha256Digest});

  factory RuntimeFileRecord.fromJson(String path, Object? json) {
    if (json is! Map<String, dynamic> ||
        json['bytes'] is! int ||
        (json['bytes'] as int) < 0 ||
        !_isSha256(json['sha256'])) {
      throw FormatException('Invalid runtime file record: $path');
    }
    _expectKeys(json.keys.toSet(), const {'bytes', 'sha256'}, path);
    return RuntimeFileRecord(
      bytes: json['bytes'] as int,
      sha256Digest: json['sha256'] as String,
    );
  }

  static Future<RuntimeFileRecord> fromFile(File file) async {
    final data = await file.readAsBytes();
    return RuntimeFileRecord(
      bytes: data.length,
      sha256Digest: sha256.convert(data).toString(),
    );
  }

  final int bytes;
  final String sha256Digest;

  Map<String, Object> toJson() => {'bytes': bytes, 'sha256': sha256Digest};

  Future<String?> mismatch(File file) async {
    final actualBytes = await file.length();
    if (actualBytes != bytes) return 'size changed: $actualBytes != $bytes';
    final actualSha = sha256.convert(await file.readAsBytes()).toString();
    if (actualSha != sha256Digest) return 'SHA-256 changed';
    return null;
  }
}

Future<Map<String, File>> _runtimeFiles(Directory root) async {
  if (!await root.exists()) return const {};
  final files = <String, File>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is Link) {
      throw StateError('Runtime assets cannot contain links: ${entity.path}');
    }
    if (entity is! File) continue;
    final path = entity.path
        .substring(root.path.length + 1)
        .replaceAll('\\', '/');
    if (path == runtimeManifestName) continue;
    files[_validatedPath(path)] = entity;
  }
  return Map.fromEntries(
    files.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key)),
  );
}

String _validatedPath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw FormatException('Unsafe runtime asset path: $path');
  }
  return path;
}

bool _isSha256(Object? value) =>
    value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

bool _sameSource(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

void _expectKeys(Set<String> actual, Set<String> expected, String context) {
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException('$context has unexpected fields: $actual');
  }
}
