import 'dart:convert';
import 'dart:io';

import 'failure.dart';

final class MutationGitRepository {
  factory MutationGitRepository(String repository) {
    final directory = Directory(repository).absolute;
    if (!directory.existsSync()) {
      throw MutationFailure('Repository does not exist: ${directory.path}');
    }
    final requestedRoot = directory.resolveSymbolicLinksSync();
    final result = Process.runSync(
      'git',
      ['-C', requestedRoot, 'rev-parse', '--show-toplevel'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw MutationFailure(
        'Cannot resolve Git repository root for $requestedRoot:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    final gitRoot = Directory(
      (result.stdout as String).trimRight(),
    ).resolveSymbolicLinksSync();
    if (gitRoot != requestedRoot) {
      throw MutationFailure(
        'Mutation repository must be the Git top level: '
        '$requestedRoot != $gitRoot',
      );
    }
    final gitDirectoryResult = Process.runSync(
      'git',
      ['-C', gitRoot, 'rev-parse', '--absolute-git-dir'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (gitDirectoryResult.exitCode != 0) {
      throw MutationFailure(
        'Cannot resolve Git directory for $gitRoot:\n'
        '${(gitDirectoryResult.stderr as String).trim()}',
      );
    }
    return MutationGitRepository._(
      gitRoot,
      Directory(
        (gitDirectoryResult.stdout as String).trimRight(),
      ).resolveSymbolicLinksSync(),
    );
  }

  const MutationGitRepository._(this.repository, this.gitDirectory);

  final String repository;
  final String gitDirectory;

  String resolveCommit(String ref, String description) {
    final result = _processText(['rev-parse', '--verify', '$ref^{commit}']);
    if (result.exitCode != 0) {
      throw MutationFailure(
        'Unknown $description $ref:\n${(result.stderr as String).trim()}',
      );
    }
    final objectId = (result.stdout as String).trim();
    if (!_isObjectId(objectId)) {
      throw MutationFailure('Git returned an invalid object ID for $ref.');
    }
    return objectId;
  }

  bool commitExists(String ref) =>
      _processText(['rev-parse', '--verify', '$ref^{commit}']).exitCode == 0;

  void requireCommit(String ref, String description) {
    resolveCommit(ref, description);
  }

  bool isAncestor(String ancestor, String descendant) {
    final result = _processText([
      'merge-base',
      '--is-ancestor',
      ancestor,
      descendant,
    ]);
    if (result.exitCode == 0) return true;
    if (result.exitCode == 1) return false;
    throw MutationFailure(
      'git merge-base failed: ${(result.stderr as String).trim()}',
    );
  }

  List<String> mergeBases(String first, String second) {
    final result = _processText(['merge-base', '--all', first, second]);
    if (result.exitCode == 1) return const [];
    if (result.exitCode != 0) {
      throw MutationFailure(
        'git merge-base failed: ${(result.stderr as String).trim()}',
      );
    }
    final bases = const LineSplitter()
        .convert(result.stdout as String)
        .where((line) => line.isNotEmpty)
        .toList();
    if (bases.any((sha) => !_isObjectId(sha))) {
      throw const MutationFailure('git merge-base returned an invalid SHA.');
    }
    return bases;
  }

  String? show(String ref, String repositoryPath) {
    final listing = _processBytes(['ls-tree', '-z', ref, '--', repositoryPath]);
    if (listing.exitCode != 0) {
      throw MutationFailure(
        'git ls-tree failed for $ref:$repositoryPath:\n'
        '${(listing.stderr as String).trim()}',
      );
    }
    final entries = _decodeNulBytes(
      listing.stdout as List<int>,
      'git ls-tree $ref -- $repositoryPath',
    );
    if (entries.isEmpty) return null;
    if (entries.length != 1) {
      throw MutationFailure(
        'Historical mutation path is ambiguous at $ref: $repositoryPath',
      );
    }
    final match = RegExp(
      r'^(100644|100755) blob ([0-9a-f]{40}|[0-9a-f]{64})\t(.+)$',
    ).firstMatch(entries.single);
    if (match == null || match.group(3) != repositoryPath) {
      throw MutationFailure(
        'Historical mutation path must be a regular Git blob: '
        '$ref:$repositoryPath',
      );
    }
    return runText(['show', '$ref:$repositoryPath']);
  }

  String repositoryRelativePath(String path) {
    final file = File(path).absolute;
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw MutationFailure(
        'Mutation policy and baseline must be regular files: $path',
      );
    }
    final canonicalParent = file.parent.resolveSymbolicLinksSync();
    final basename = file.path.substring(
      file.parent.path.length + Platform.pathSeparator.length,
    );
    final absolute = '$canonicalParent${Platform.pathSeparator}$basename';
    final root = repository.endsWith(Platform.pathSeparator)
        ? repository
        : '$repository${Platform.pathSeparator}';
    if (!absolute.startsWith(root)) {
      throw MutationFailure(
        'Mutation policy and baseline must be inside the repository: $path',
      );
    }
    return _portablePath(absolute.substring(root.length));
  }

  String resolve(String repositoryPath) =>
      '$repository${Platform.pathSeparator}'
      '${repositoryPath.replaceAll('/', Platform.pathSeparator)}';

  List<String> untrackedFiles() =>
      _nulPaths(['ls-files', '-z', '--others', '--exclude-standard']);

  void requireRegularFile(String repositoryPath, String description) {
    _requirePath(repositoryPath, description, FileSystemEntityType.file);
  }

  void requireDirectory(String repositoryPath, String description) {
    if (repositoryPath == '.') return;
    _requirePath(repositoryPath, description, FileSystemEntityType.directory);
  }

  void _requirePath(
    String repositoryPath,
    String description,
    FileSystemEntityType finalType,
  ) {
    var current = repository;
    final segments = repositoryPath.split('/');
    for (var index = 0; index < segments.length; index += 1) {
      current = '$current${Platform.pathSeparator}${segments[index]}';
      final type = FileSystemEntity.typeSync(current, followLinks: false);
      final expected = index == segments.length - 1
          ? finalType
          : FileSystemEntityType.directory;
      if (type != expected) {
        throw MutationFailure(
          '$description must not traverse links and must end in a regular '
          '${finalType == FileSystemEntityType.file ? 'file' : 'directory'}: '
          '$repositoryPath',
        );
      }
    }
  }

  bool regularFileExists(String repositoryPath, String description) {
    final absolute = resolve(repositoryPath);
    if (FileSystemEntity.typeSync(absolute, followLinks: false) ==
        FileSystemEntityType.notFound) {
      return false;
    }
    requireRegularFile(repositoryPath, description);
    return true;
  }

  List<int> workspacePatch(String baseRef) {
    final result = _processBytes([
      'diff',
      '--binary',
      '--full-index',
      baseRef,
      '--',
      '.',
    ]);
    if (result.exitCode != 0) {
      throw MutationFailure(
        'git diff failed: ${(result.stderr as String).trim()}',
      );
    }
    return result.stdout as List<int>;
  }

  void checkoutTree(String ref, String destination, String temporaryIndex) {
    final environment = {
      ...Platform.environment,
      'GIT_INDEX_FILE': temporaryIndex,
    };
    _runRepositoryGit(
      ['read-tree', ref],
      workTree: destination,
      environment: environment,
    );
    _runRepositoryGit(
      const ['checkout-index', '--all', '--force'],
      workTree: destination,
      environment: environment,
    );
  }

  String runText(List<String> arguments) {
    final result = _processText(arguments);
    if (result.exitCode != 0) {
      throw MutationFailure(
        'git ${arguments.join(' ')} failed:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    return result.stdout as String;
  }

  List<String> _nulPaths(List<String> arguments) {
    final result = _processBytes(arguments);
    if (result.exitCode != 0) {
      throw MutationFailure(
        'git ${arguments.join(' ')} failed:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    final paths = _decodeNulBytes(
      result.stdout as List<int>,
      'git ${arguments.join(' ')}',
    );
    if (paths.any((path) => path.isEmpty)) {
      throw MutationFailure(
        'git ${arguments.join(' ')} returned an empty path.',
      );
    }
    return paths.map(_portablePath).toList();
  }

  ProcessResult _processText(List<String> arguments) => Process.runSync(
    'git',
    ['-C', repository, ...arguments],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  ProcessResult _processBytes(List<String> arguments) => Process.runSync(
    'git',
    ['-C', repository, ...arguments],
    stdoutEncoding: null,
    stderrEncoding: utf8,
  );

  void _runRepositoryGit(
    List<String> arguments, {
    required String workTree,
    required Map<String, String> environment,
  }) {
    final result = Process.runSync(
      'git',
      ['--git-dir=$gitDirectory', '--work-tree=$workTree', ...arguments],
      environment: environment,
      includeParentEnvironment: false,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw MutationFailure(
        'git ${arguments.join(' ')} failed while materializing HEAD:\n'
        '${(result.stderr as String).trim()}',
      );
    }
  }
}

List<String> _decodeNulBytes(List<int> bytes, String description) {
  if (bytes.isEmpty) return const [];
  if (bytes.last != 0) {
    throw MutationFailure('$description returned unterminated NUL output.');
  }
  late final String decoded;
  try {
    decoded = utf8.decode(bytes, allowMalformed: false);
  } on FormatException catch (error) {
    throw MutationFailure('$description returned non-UTF-8 data: $error');
  }
  return decoded.split('\u0000')..removeLast();
}

bool _isObjectId(String value) =>
    RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(value);

String _portablePath(String path) => Platform.pathSeparator == '/'
    ? path
    : path.replaceAll(Platform.pathSeparator, '/');
