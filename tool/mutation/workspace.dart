import 'dart:convert';
import 'dart:io';

import 'failure.dart';
import 'git_repository.dart';

part 'workspace_metadata.dart';

final class MutationWorkspace {
  MutationWorkspace._(
    this.root,
    this._temporaryDirectory,
    this._indexTree,
    this._mutablePrefixes,
    this._runtimeTemplateRoot,
    this._runtimeDirectories,
  );

  static MutationWorkspace create(
    MutationGitRepository repository,
    Iterable<String> packageRoots,
  ) {
    final roots = packageRoots.toSet().toList()..sort();
    final createdTemporaryDirectory = Directory.systemTemp.createTempSync(
      'aonw-mutations-',
    );
    final temporaryDirectory = Directory(
      createdTemporaryDirectory.resolveSymbolicLinksSync(),
    );
    final root = Directory('${temporaryDirectory.path}/repository')
      ..createSync(recursive: true);
    final index = File('${temporaryDirectory.path}/head.index');
    final patch = File('${temporaryDirectory.path}/workspace.patch');
    try {
      final head = repository.resolveCommit('HEAD', 'workspace HEAD');
      repository.checkoutTree(head, root.path, index.path);
      if (index.existsSync()) index.deleteSync();
      _run('git', const ['init', '--quiet'], workingDirectory: root.path);

      final patchBytes = repository.workspacePatch(head);
      if (patchBytes.isNotEmpty) {
        patch.writeAsBytesSync(patchBytes, flush: true);
        _run('git', [
          'apply',
          '--binary',
          '--whitespace=nowarn',
          patch.path,
        ], workingDirectory: root.path);
      }
      for (final path in repository.untrackedFiles()) {
        repository.requireRegularFile(path, 'untracked workspace file');
        _copyRegularFile(
          File(repository.resolve(path)),
          File(_resolve(root.path, path)),
          description: 'untracked workspace file $path',
        );
      }
      for (final packageRoot in roots) {
        _copyDependencyMetadata(repository, root.path, packageRoot);
      }
      _rejectLinks(root, root.path);
      final runtimeDirectories = <String>{
        for (final packageRoot in roots) ...[
          packageRoot == '.' ? '.dart_tool' : '$packageRoot/.dart_tool',
          packageRoot == '.' ? 'build' : '$packageRoot/build',
        ],
      }.toList()..sort();
      final runtimeTemplate = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}runtime-template',
      )..createSync();
      for (final relativePath in runtimeDirectories) {
        final source = Directory(_resolve(root.path, relativePath));
        if (source.existsSync()) {
          _copyDirectory(
            source,
            Directory(_resolve(runtimeTemplate.path, relativePath)),
            description: 'mutation runtime template $relativePath',
          );
        }
      }
      _run('git', const [
        'add',
        '--all',
        '--force',
      ], workingDirectory: root.path);
      final indexTree = _runText('git', const [
        'write-tree',
      ], workingDirectory: root.path).trim();
      if (!_isObjectId(indexTree)) {
        throw const MutationFailure(
          'Mutation workspace Git index returned an invalid tree ID.',
        );
      }
      final mutablePrefixes = <String>{
        for (final packageRoot in roots) ...[
          packageRoot == '.' ? '.dart_tool/' : '$packageRoot/.dart_tool/',
          packageRoot == '.' ? 'build/' : '$packageRoot/build/',
        ],
      }.toList()..sort();
      final workspace = MutationWorkspace._(
        root.path,
        temporaryDirectory,
        indexTree,
        List.unmodifiable(mutablePrefixes),
        runtimeTemplate.path,
        List.unmodifiable(runtimeDirectories),
      )..assertControlledTreeClean();
      return workspace;
    } catch (_) {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
      rethrow;
    }
  }

  final String root;
  final Directory _temporaryDirectory;
  final String _indexTree;
  final List<String> _mutablePrefixes;
  final String _runtimeTemplateRoot;
  final List<String> _runtimeDirectories;

  void assertControlledTreeClean() {
    final currentTree = _runText('git', const [
      'write-tree',
    ], workingDirectory: root).trim();
    if (currentTree != _indexTree) {
      throw const MutationFailure(
        'Mutation tests changed the isolated workspace Git index.',
      );
    }
    final changed = _gitNulPaths(root, const [
      'diff',
      '--name-only',
      '-z',
      '--no-ext-diff',
    ]);
    final untracked = _gitNulPaths(root, const ['ls-files', '-z', '--others']);
    final unexpected = <String>{
      ...changed.where((path) => !_isMutable(path)),
      ...untracked.where((path) => !_isMutable(path)),
    }.toList()..sort();
    if (unexpected.isNotEmpty) {
      throw MutationFailure(
        'Mutation tests changed controlled workspace files: $unexpected',
      );
    }
  }

  bool _isMutable(String path) =>
      _mutablePrefixes.any((prefix) => path.startsWith(prefix));

  void requireControlledRegularFile(String relativePath, String description) {
    _requireDirectoryAncestors(root, relativePath, description);
    final type = FileSystemEntity.typeSync(
      _resolve(root, relativePath),
      followLinks: false,
    );
    if (type != FileSystemEntityType.file) {
      throw MutationFailure(
        '$description must remain a regular file inside the mutation '
        'workspace: $relativePath',
      );
    }
  }

  void resetRuntimeState() {
    for (final relativePath in _runtimeDirectories) {
      _requireDirectoryAncestors(root, relativePath, 'Mutation runtime state');
      final livePath = _resolve(root, relativePath);
      final type = FileSystemEntity.typeSync(livePath, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw MutationFailure(
          'Mutation runtime state must not contain symbolic links: '
          '$relativePath',
        );
      }
      if (type == FileSystemEntityType.directory) {
        final directory = Directory(livePath);
        _rejectLinks(directory, directory.path);
        directory.deleteSync(recursive: true);
      } else if (type != FileSystemEntityType.notFound) {
        throw MutationFailure(
          'Mutation runtime state must be a directory: $relativePath',
        );
      }

      final template = Directory(_resolve(_runtimeTemplateRoot, relativePath));
      if (template.existsSync()) {
        _copyDirectory(
          template,
          Directory(livePath),
          description: 'mutation runtime reset $relativePath',
        );
      }
    }
    assertControlledTreeClean();
  }

  void dispose() {
    if (Platform.environment['AONW_KEEP_MUTATION_WORKSPACE'] == '1') {
      stderr.writeln('Mutation workspace kept at $root.');
      return;
    }
    if (_temporaryDirectory.existsSync()) {
      _temporaryDirectory.deleteSync(recursive: true);
    }
  }

  static void _copyDependencyMetadata(
    MutationGitRepository repository,
    String snapshotRoot,
    String packageRoot,
  ) {
    final prefix = packageRoot == '.' ? '' : '$packageRoot/';
    for (final name in const [
      'package_config.json',
      'package_graph.json',
      'native_assets.yaml',
      'version',
    ]) {
      final relative = '$prefix.dart_tool/$name';
      if (!repository.regularFileExists(
        relative,
        'dependency metadata $relative',
      )) {
        continue;
      }
      _copyRegularFile(
        File(repository.resolve(relative)),
        File(_resolve(snapshotRoot, relative)),
        description: 'dependency metadata $relative',
      );
    }
    final relativeConfig = '$prefix.dart_tool/package_config.json';
    final config = File(_resolve(snapshotRoot, relativeConfig));
    if (!config.existsSync()) {
      throw MutationFailure(
        'Missing dependency metadata for mutation package $packageRoot. '
        'Run make bootstrap first.',
      );
    }
    _rewriteLocalPackageRoots(
      repository: repository,
      snapshotRoot: snapshotRoot,
      packageRoot: packageRoot,
      relativeConfig: relativeConfig,
    );
    final nativeAssetsPath = '$prefix.dart_tool/native_assets.yaml';
    final nativeAssets = File(_resolve(snapshotRoot, nativeAssetsPath));
    if (nativeAssets.existsSync()) {
      _rewriteNativeAssets(
        repository: repository,
        snapshotRoot: snapshotRoot,
        relativePath: nativeAssetsPath,
      );
    }
  }
}

void _requireDirectoryAncestors(
  String root,
  String relativePath,
  String description,
) {
  var currentPath = root;
  var displayPath = '.';

  void requireDirectory() {
    final type = FileSystemEntity.typeSync(currentPath, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw MutationFailure(
        '$description must not have symbolic-link ancestors: $displayPath',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw MutationFailure(
        '$description ancestor must be a directory: $displayPath',
      );
    }
  }

  requireDirectory();
  final segments = relativePath.split('/');
  for (var index = 0; index < segments.length - 1; index += 1) {
    final segment = segments[index];
    currentPath = '$currentPath${Platform.pathSeparator}$segment';
    displayPath = displayPath == '.' ? segment : '$displayPath/$segment';
    requireDirectory();
  }
}

void _copyRegularFile(
  File source,
  File destination, {
  required String description,
}) {
  if (FileSystemEntity.typeSync(source.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw MutationFailure('$description must be a regular file.');
  }
  destination.parent.createSync(recursive: true);
  source.copySync(destination.path);
}

void _copyDirectory(
  Directory source,
  Directory destination, {
  required String description,
}) {
  if (FileSystemEntity.typeSync(source.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw MutationFailure('$description must be a directory.');
  }
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere(
      (segment) => segment.isNotEmpty,
    );
    final target = '${destination.path}${Platform.pathSeparator}$name';
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      _copyRegularFile(
        File(entity.path),
        File(target),
        description: '$description/$name',
      );
    } else if (type == FileSystemEntityType.directory) {
      _copyDirectory(
        Directory(entity.path),
        Directory(target),
        description: '$description/$name',
      );
    } else {
      throw MutationFailure(
        '$description contains a non-regular filesystem entry: '
        '${entity.path}',
      );
    }
  }
}

void _rejectLinks(Directory directory, String root) {
  for (final entity in directory.listSync(followLinks: false)) {
    if (entity.path == '$root${Platform.pathSeparator}.git') continue;
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw MutationFailure(
        'Mutation workspace must not contain symbolic links: ${entity.path}',
      );
    }
    if (type == FileSystemEntityType.directory) {
      _rejectLinks(Directory(entity.path), root);
    }
  }
}

String? _inside(String root, String candidate) {
  final rootUri = Directory(root).absolute.uri;
  final candidateUri = Directory(candidate).absolute.uri;
  if (rootUri.scheme != candidateUri.scheme ||
      rootUri.authority != candidateUri.authority) {
    return null;
  }
  String normalize(String segment) =>
      Platform.isWindows ? segment.toLowerCase() : segment;
  final rootSegments = rootUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  final candidateSegments = candidateUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (candidateSegments.length < rootSegments.length) return null;
  for (var index = 0; index < rootSegments.length; index += 1) {
    if (normalize(rootSegments[index]) != normalize(candidateSegments[index])) {
      return null;
    }
  }
  final relative = candidateSegments.sublist(rootSegments.length);
  return relative.isEmpty ? '.' : relative.join('/');
}

List<String> _gitNulPaths(String repository, List<String> arguments) {
  final result = Process.runSync(
    'git',
    ['-C', repository, ...arguments],
    stdoutEncoding: null,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw MutationFailure(
      'git ${arguments.join(' ')} failed in mutation workspace:\n'
      '${(result.stderr as String).trim()}',
    );
  }
  final bytes = result.stdout as List<int>;
  if (bytes.isEmpty) return const [];
  if (bytes.last != 0) {
    throw MutationFailure(
      'git ${arguments.join(' ')} returned unterminated NUL output.',
    );
  }
  late final String decoded;
  try {
    decoded = utf8.decode(bytes, allowMalformed: false);
  } on FormatException catch (error) {
    throw MutationFailure(
      'git ${arguments.join(' ')} returned non-UTF-8 paths: $error',
    );
  }
  return decoded.split('\u0000')..removeLast();
}

void _run(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) {
  _runText(executable, arguments, workingDirectory: workingDirectory);
}

String _runText(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) {
  final result = Process.runSync(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    stdoutEncoding: systemEncoding,
    stderrEncoding: systemEncoding,
  );
  if (result.exitCode != 0) {
    throw MutationFailure(
      '$executable ${arguments.join(' ')} failed:\n'
      '${(result.stdout as String).trim()}\n'
      '${(result.stderr as String).trim()}',
    );
  }
  return result.stdout as String;
}

String _resolve(String root, String repositoryPath) =>
    '$root${Platform.pathSeparator}'
    '${repositoryPath.replaceAll('/', Platform.pathSeparator)}';

bool _isObjectId(String value) =>
    RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(value);

bool _isAbsolutePath(String value) =>
    value.startsWith('/') ||
    value.startsWith(r'\\') ||
    RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
