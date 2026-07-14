part of 'workspace.dart';

void _rewriteNativeAssets({
  required MutationGitRepository repository,
  required String snapshotRoot,
  required String relativePath,
}) {
  final file = File(_resolve(snapshotRoot, relativePath));
  final source = file.readAsStringSync();
  final jsonOffset = source.indexOf('{');
  if (jsonOffset < 0) {
    throw MutationFailure('$relativePath contains no native-assets object.');
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(source.substring(jsonOffset));
  } on FormatException catch (error) {
    throw MutationFailure('$relativePath is invalid: $error');
  }

  Object? rewrite(Object? value) {
    if (value is List<Object?>) return value.map(rewrite).toList();
    if (value is Map<String, Object?>) {
      return {
        for (final entry in value.entries) entry.key: rewrite(entry.value),
      };
    }
    if (value is! String || !_isAbsolutePath(value)) return value;
    final localPath = _inside(repository.repository, value);
    if (localPath == null) return value;
    repository.requireRegularFile(localPath, '$relativePath native asset');
    final destination = File(_resolve(snapshotRoot, localPath));
    _copyRegularFile(
      File(repository.resolve(localPath)),
      destination,
      description: '$relativePath native asset $localPath',
    );
    return destination.absolute.path;
  }

  final header = source.substring(0, jsonOffset).trimRight();
  file.writeAsStringSync(
    '$header\n\n${const JsonEncoder.withIndent('  ').convert(rewrite(decoded))}\n',
    flush: true,
  );
}

void _rewriteLocalPackageRoots({
  required MutationGitRepository repository,
  required String snapshotRoot,
  required String packageRoot,
  required String relativeConfig,
}) {
  final liveConfig = File(repository.resolve(relativeConfig));
  final snapshotConfig = File(_resolve(snapshotRoot, relativeConfig));
  late final Object? decoded;
  try {
    decoded = jsonDecode(liveConfig.readAsStringSync());
  } on Object catch (error) {
    throw MutationFailure('$relativeConfig is invalid JSON: $error');
  }
  if (decoded is! Map<String, Object?> ||
      decoded['configVersion'] != 2 ||
      decoded['packages'] is! List<Object?>) {
    throw MutationFailure('$relativeConfig is not a package_config v2 file.');
  }
  final packages = decoded['packages']! as List<Object?>;
  var ownsPackageRoot = false;
  for (var index = 0; index < packages.length; index += 1) {
    final value = packages[index];
    if (value is! Map<String, Object?> ||
        value['name'] is! String ||
        value['rootUri'] is! String ||
        value['packageUri'] is! String) {
      throw MutationFailure(
        '$relativeConfig.packages[$index] has an invalid package entry.',
      );
    }
    final rootUriText = value['rootUri']! as String;
    final parsedRootUri = Uri.tryParse(rootUriText);
    if (parsedRootUri == null) {
      throw MutationFailure(
        '$relativeConfig.packages[$index].rootUri is invalid.',
      );
    }
    final liveRootUri = liveConfig.uri.resolveUri(parsedRootUri);
    if (liveRootUri.scheme != 'file') {
      throw MutationFailure(
        '$relativeConfig.packages[$index].rootUri must resolve to file:.',
      );
    }
    final liveRootDirectory = Directory.fromUri(liveRootUri).absolute;
    final liveRoot = liveRootDirectory.existsSync()
        ? liveRootDirectory.resolveSymbolicLinksSync()
        : liveRootDirectory.path;
    final localPath = _inside(repository.repository, liveRoot);
    if (localPath == null) {
      if (!parsedRootUri.isAbsolute) {
        throw MutationFailure(
          '$relativeConfig contains an external relative package root: '
          '$rootUriText',
        );
      }
      continue;
    }
    repository.requireDirectory(
      localPath,
      '$relativeConfig local package root',
    );
    final snapshotPackageRoot = localPath == '.'
        ? snapshotRoot
        : _resolve(snapshotRoot, localPath);
    value['rootUri'] = Directory(snapshotPackageRoot).absolute.uri.toString();
    if (localPath == packageRoot) ownsPackageRoot = true;

    final packageUri = Uri.tryParse(value['packageUri']! as String);
    if (packageUri == null || packageUri.isAbsolute) {
      throw MutationFailure(
        '$relativeConfig.packages[$index].packageUri must be relative.',
      );
    }
    final packageDirectory = Directory.fromUri(
      Directory(snapshotPackageRoot).absolute.uri.resolveUri(packageUri),
    );
    if (_inside(snapshotPackageRoot, packageDirectory.path) == null) {
      throw MutationFailure(
        '$relativeConfig.packages[$index].packageUri escapes its package.',
      );
    }
  }
  if (!ownsPackageRoot) {
    throw MutationFailure(
      '$relativeConfig does not map package root $packageRoot to the isolated '
      'workspace.',
    );
  }
  snapshotConfig.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(decoded)}\n',
    flush: true,
  );
}
