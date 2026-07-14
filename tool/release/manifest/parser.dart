import 'dart:convert';

import '../canonical_json.dart';
import 'failure.dart';
import 'model.dart';

final class ReleaseManifestParser {
  const ReleaseManifestParser();

  ReleaseManifestV1 parseCanonical(String contents) {
    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error) {
      throw ReleaseManifestException('Invalid manifest JSON: ${error.message}');
    }
    if (encodeCanonicalJson(decoded) != contents) {
      throw const ReleaseManifestException(
        'Manifest JSON is not canonical; duplicate keys, key order, whitespace, '
        'and encoding must match canonical bytes exactly.',
      );
    }
    final root = _object(decoded, 'manifest');
    _requireKeys(root, 'manifest', const {
      'artifactPlan',
      'artifactPlanSha256',
      'artifacts',
      'build',
      'channels',
      'config',
      'migrations',
      'qualityGate',
      'schemaVersion',
      'serverImage',
      'sourceSha',
      'version',
    });
    final schema = _integer(root['schemaVersion'], 'schemaVersion');
    if (schema != ReleaseManifestV1.schemaVersion) {
      throw ReleaseManifestException(
        'Unsupported manifest schemaVersion $schema.',
      );
    }
    return ReleaseManifestV1(
      sourceSha: _string(root['sourceSha'], 'sourceSha'),
      version: _string(root['version'], 'version'),
      build: _integer(root['build'], 'build'),
      artifactPlan: ArtifactPlanEvidence.fromJson(
        _object(root['artifactPlan'], 'artifactPlan'),
        expectedSha256: _string(
          root['artifactPlanSha256'],
          'artifactPlanSha256',
        ),
      ),
      qualityGate: _qualityGate(root['qualityGate']),
      serverImage: _string(root['serverImage'], 'serverImage'),
      channels: _channels(root['channels'], 'channels'),
      artifacts: _artifacts(root['artifacts']),
      config: _tree(root['config'], 'config'),
      migrations: _tree(root['migrations'], 'migrations'),
    );
  }

  QualityGateEvidence _qualityGate(Object? value) {
    final object = _object(value, 'qualityGate');
    _requireKeys(object, 'qualityGate', const {'name', 'sourceSha', 'status'});
    return QualityGateEvidence.fromCanonical(
      name: _string(object['name'], 'qualityGate.name'),
      sourceSha: _string(object['sourceSha'], 'qualityGate.sourceSha'),
      status: _string(object['status'], 'qualityGate.status'),
    );
  }

  List<ReleaseChannel> _channels(Object? value, String name) {
    final list = _list(value, name);
    return list
        .asMap()
        .entries
        .map(
          (entry) =>
              ReleaseChannel.parse(_string(entry.value, '$name[${entry.key}]')),
        )
        .toList(growable: false);
  }

  List<ManifestArtifact> _artifacts(Object? value) {
    final list = _list(value, 'artifacts');
    return list
        .asMap()
        .entries
        .map((entry) => _artifact(entry.value, entry.key))
        .toList(growable: false);
  }

  ManifestArtifact _artifact(Object? value, int index) {
    final name = 'artifacts[$index]';
    final object = _object(value, name);
    _requireKeys(object, name, const {
      'bytes',
      'destinations',
      'id',
      'mediaType',
      'path',
      'sha256',
    });
    return ManifestArtifact(
      id: _string(object['id'], '$name.id'),
      path: _string(object['path'], '$name.path'),
      sha256: _string(object['sha256'], '$name.sha256'),
      bytes: _integer(object['bytes'], '$name.bytes'),
      mediaType: _string(object['mediaType'], '$name.mediaType'),
      destinations: _channels(object['destinations'], '$name.destinations'),
    );
  }

  ManifestFileTree _tree(Object? value, String name) {
    final object = _object(value, name);
    _requireKeys(object, name, const {'files', 'revision'});
    final list = _list(object['files'], '$name.files');
    final files = list
        .asMap()
        .entries
        .map((entry) => _file(entry.value, '$name.files[${entry.key}]'))
        .toList(growable: false);
    return ManifestFileTree(
      files: files,
      expectedRevision: _string(object['revision'], '$name.revision'),
    );
  }

  ManifestFileEntry _file(Object? value, String name) {
    final object = _object(value, name);
    _requireKeys(object, name, const {'bytes', 'path', 'sha256'});
    return ManifestFileEntry(
      path: _string(object['path'], '$name.path'),
      sha256: _string(object['sha256'], '$name.sha256'),
      bytes: _integer(object['bytes'], '$name.bytes'),
    );
  }
}

Map<String, Object?> _object(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw ReleaseManifestException('$name must be a JSON object.');
  }
  return value;
}

List<Object?> _list(Object? value, String name) {
  if (value is! List<Object?>) {
    throw ReleaseManifestException('$name must be a JSON array.');
  }
  return value;
}

String _string(Object? value, String name) {
  if (value is! String) {
    throw ReleaseManifestException('$name must be a JSON string.');
  }
  return value;
}

int _integer(Object? value, String name) {
  if (value is! int) {
    throw ReleaseManifestException('$name must be a JSON integer.');
  }
  return value;
}

void _requireKeys(
  Map<String, Object?> object,
  String name,
  Set<String> expected,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unknown = actual.difference(expected).toList()..sort();
  if (missing.isEmpty && unknown.isEmpty) return;
  final details = <String>[
    if (missing.isNotEmpty) 'missing: ${missing.join(', ')}',
    if (unknown.isNotEmpty) 'unknown: ${unknown.join(', ')}',
  ];
  throw ReleaseManifestException(
    '$name has invalid fields (${details.join('; ')}).',
  );
}
