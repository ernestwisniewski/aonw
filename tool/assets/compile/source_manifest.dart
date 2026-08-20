import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

final class AssetSourceManifest {
  AssetSourceManifest._({
    required this.path,
    required this.json,
    required this.sha256Digest,
    required this.externalSource,
  });

  static Future<AssetSourceManifest> load(String path) async {
    final file = File(path).absolute;
    if (!await file.exists()) {
      throw FormatException(
        'Asset source manifest does not exist: ${file.path}',
      );
    }
    final bytes = await file.readAsBytes();
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('Unsupported asset source manifest');
    }
    _validatePathsAndDigests(decoded);
    final external = ExternalAssetSource.fromJson(
      _object(decoded, 'externalSource'),
    );
    return AssetSourceManifest._(
      path: file.path,
      json: decoded,
      sha256Digest: sha256.convert(bytes).toString(),
      externalSource: external,
    );
  }

  final String path;
  final Map<String, dynamic> json;
  final String sha256Digest;
  final ExternalAssetSource externalSource;

  List<Map<String, dynamic>> list(String key) {
    final value = json[key];
    if (value is! List<dynamic>) {
      throw FormatException('$key must be an array');
    }
    return value
        .map((entry) {
          if (entry is! Map<String, dynamic>) {
            throw FormatException('$key entries must be objects');
          }
          return entry;
        })
        .toList(growable: false);
  }

  Map<String, dynamic> object(String key) => _object(json, key);

  List<UnitSourceSpec> get units =>
      list('units').map(UnitSourceSpec.fromJson).toList(growable: false);

  String get animationAdjustmentsPath {
    final metadata = object('metadata');
    final adjustments = _object(metadata, 'animationFrameAdjustments');
    return adjustments['source'] as String;
  }

  String get animationAdjustmentsSha256 {
    final metadata = object('metadata');
    final adjustments = _object(metadata, 'animationFrameAdjustments');
    return adjustments['sha256'] as String;
  }

  static void _validatePathsAndDigests(Map<String, dynamic> root) {
    void visit(Object? value, String context) {
      if (value is Map<String, dynamic>) {
        for (final entry in value.entries) {
          final path = '$context.${entry.key}';
          if (entry.key.toLowerCase().endsWith('sha256')) {
            _requireSha256(entry.value, path);
          }
          if (entry.key == 'source' || entry.key == 'logoSource') {
            _requireRelativePath(entry.value, path);
          }
          visit(entry.value, path);
        }
      } else if (value is List<dynamic>) {
        for (var index = 0; index < value.length; index++) {
          visit(value[index], '$context[$index]');
        }
      }
    }

    visit(root, r'$');
  }

  static void _requireSha256(Object? value, String context) {
    if (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw FormatException('$context must be a lowercase SHA-256 digest');
    }
  }

  static void _requireRelativePath(Object? value, String context) {
    if (value is! String ||
        value.isEmpty ||
        value.startsWith('/') ||
        value.startsWith(r'\') ||
        value.split('/').any((part) => part.isEmpty || part == '..')) {
      throw FormatException('$context must be a safe relative path');
    }
  }
}

final class ExternalAssetSource {
  const ExternalAssetSource({
    required this.repository,
    required this.revision,
    required this.rootEnvironmentVariable,
  });

  factory ExternalAssetSource.fromJson(Map<String, dynamic> json) {
    final repository = json['repository'];
    final revision = json['revision'];
    final environment = json['rootEnvironmentVariable'];
    if (repository is! String) {
      throw const FormatException(
        'externalSource.repository must be an immutable GitHub source contract',
      );
    }
    final repositoryUri = Uri.tryParse(repository);
    if (repositoryUri == null ||
        repositoryUri.scheme != 'https' ||
        repositoryUri.host != 'github.com' ||
        !repositoryUri.path.endsWith('.git') ||
        repository.contains('configure')) {
      throw const FormatException(
        'externalSource.repository must be an immutable GitHub source contract',
      );
    }
    if (revision is! String || !RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
      throw const FormatException(
        'externalSource.revision must be a full lowercase Git commit SHA',
      );
    }
    if (environment != 'AONW_ASSET_MASTERS') {
      throw const FormatException(
        'externalSource.rootEnvironmentVariable must be AONW_ASSET_MASTERS',
      );
    }
    return ExternalAssetSource(
      repository: repository,
      revision: revision,
      rootEnvironmentVariable: environment as String,
    );
  }

  final String repository;
  final String revision;
  final String rootEnvironmentVariable;

  Map<String, String> toJson() => {
    'repository': repository,
    'revision': revision,
  };
}

final class UnitSourceSpec {
  UnitSourceSpec._({
    required this.name,
    required this.columns,
    required this.rows,
    required this.targetWidth,
    required this.sourceInset,
    required this.sha256,
    required this.animations,
  });

  factory UnitSourceSpec.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final columns = json['columns'] as int;
    final rows = json['rows'] as int;
    final targetWidth = json['targetWidth'] as int;
    final sourceInset = json['sourceInset'] as int;
    final animations = (json['animations'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(UnitAnimationSourceSpec.fromJson)
        .toList(growable: false);
    _validateUnitGrid(
      name,
      columns,
      rows,
      targetWidth,
      sourceInset,
      animations,
    );
    return UnitSourceSpec._(
      name: name,
      columns: columns,
      rows: rows,
      targetWidth: targetWidth,
      sourceInset: sourceInset,
      sha256: json['sha256'] as String,
      animations: animations,
    );
  }

  final String name;
  final int columns;
  final int rows;
  final int targetWidth;
  final int sourceInset;
  final String sha256;
  final List<UnitAnimationSourceSpec> animations;
}

final class UnitAnimationSourceSpec {
  const UnitAnimationSourceSpec({
    required this.action,
    required this.row,
    required this.sourceColumns,
  });

  factory UnitAnimationSourceSpec.fromJson(Map<String, dynamic> json) =>
      UnitAnimationSourceSpec(
        action: json['action'] as String,
        row: json['row'] as int,
        sourceColumns: (json['sourceColumns'] as List<dynamic>).cast<int>(),
      );

  final String action;
  final int row;
  final List<int> sourceColumns;
}

void _validateUnitGrid(
  String name,
  int columns,
  int rows,
  int targetWidth,
  int sourceInset,
  List<UnitAnimationSourceSpec> animations,
) {
  if (columns <= 0 || rows <= 0 || targetWidth <= 0 || sourceInset < 0) {
    throw FormatException('$name has invalid source-grid dimensions');
  }
  if (animations.isEmpty) throw FormatException('$name has no animation rows');
  final actions = <String>{};
  final slots = <(int, int)>{};
  for (final animation in animations) {
    if (!actions.add(animation.action) || animation.sourceColumns.isEmpty) {
      throw FormatException('$name has an invalid ${animation.action} row');
    }
    if (animation.row < 0 || animation.row >= rows) {
      throw FormatException('$name ${animation.action} uses invalid row');
    }
    for (final column in animation.sourceColumns) {
      if (column < 0 ||
          column >= columns ||
          !slots.add((column, animation.row))) {
        throw FormatException('$name ${animation.action} uses an invalid slot');
      }
    }
  }
}

Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key must be an object');
  }
  return value;
}
