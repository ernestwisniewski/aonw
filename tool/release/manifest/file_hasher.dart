import 'dart:io';

import 'package:crypto/crypto.dart';

import 'failure.dart';
import 'model.dart';
import 'validation.dart';

final class ReleaseFileHasher {
  const ReleaseFileHasher();

  Future<ManifestFileEntry> hashFile({
    required Directory root,
    required String path,
  }) async {
    final file = _regularFile(root, path);
    final before = await file.stat();
    var bytes = 0;
    final digest = await sha256
        .bind(
          file.openRead().map((chunk) {
            bytes += chunk.length;
            return chunk;
          }),
        )
        .single;
    final finalFile = _regularFile(root, path);
    final after = await finalFile.stat();
    if (!_sameStableStat(before, after) || after.size != bytes) {
      throw ReleaseManifestException('File changed while hashing: $path.');
    }
    return ManifestFileEntry(
      path: path,
      sha256: digest.toString(),
      bytes: bytes,
    );
  }

  Future<ManifestArtifact> hashArtifact({
    required Directory root,
    required String id,
    required String path,
    required String mediaType,
    required Iterable<ReleaseChannel> destinations,
  }) async {
    final file = await hashFile(root: root, path: path);
    return ManifestArtifact(
      id: id,
      path: file.path,
      sha256: file.sha256,
      bytes: file.bytes,
      mediaType: mediaType,
      destinations: destinations,
    );
  }

  Future<ManifestFileTree> hashTree(Directory root) async {
    final absoluteRoot = Directory(root.absolute.path);
    _requireDirectory(absoluteRoot);
    final first = await _hashTreeOnce(absoluteRoot);
    final second = await _hashTreeOnce(absoluteRoot);
    if (first.revision != second.revision ||
        first.files.length != second.files.length) {
      throw ReleaseManifestException(
        'Manifest tree changed while hashing: ${root.path}.',
      );
    }
    return second;
  }

  Future<ManifestFileTree> _hashTreeOnce(Directory root) async {
    final paths = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw ReleaseManifestException(
          'Symbolic links are forbidden in manifest trees: ${entity.path}.',
        );
      }
      if (type == FileSystemEntityType.file) {
        paths.add(_relativePath(root, entity.path));
      } else if (type != FileSystemEntityType.directory) {
        throw ReleaseManifestException(
          'Only regular files are supported in manifest trees: ${entity.path}.',
        );
      }
    }
    paths.sort();
    if (paths.isEmpty) {
      throw ReleaseManifestException('Manifest tree is empty: ${root.path}.');
    }
    final files = <ManifestFileEntry>[];
    for (final path in paths) {
      files.add(await hashFile(root: root, path: path));
    }
    return ManifestFileTree(files: files);
  }

  Future<void> verifyFiles({
    required Directory root,
    required Iterable<ManifestArtifact> artifacts,
  }) async {
    for (final expected in artifacts) {
      final actual = await hashFile(root: root, path: expected.path);
      _requireSameFile(expected.path, expected.sha256, expected.bytes, actual);
    }
  }

  Future<void> verifyTree({
    required Directory root,
    required ManifestFileTree expected,
  }) async {
    final actual = await hashTree(root);
    if (actual.revision != expected.revision ||
        actual.files.length != expected.files.length) {
      throw ReleaseManifestException(
        'Tree drift detected for ${root.path}: expected ${expected.revision}, '
        'found ${actual.revision}.',
      );
    }
    for (var index = 0; index < expected.files.length; index++) {
      final expectedFile = expected.files[index];
      final actualFile = actual.files[index];
      if (expectedFile.path != actualFile.path) {
        throw ReleaseManifestException(
          'Tree path drift detected: expected ${expectedFile.path}, found '
          '${actualFile.path}.',
        );
      }
      _requireSameFile(
        expectedFile.path,
        expectedFile.sha256,
        expectedFile.bytes,
        actualFile,
      );
    }
  }

  File _regularFile(Directory root, String relativePath) {
    requireRelativePosixPath(relativePath, 'file path');
    _requireDirectory(root);
    var current = root.absolute.path;
    final segments = relativePath.split('/');
    for (var index = 0; index < segments.length; index++) {
      current = '$current${Platform.pathSeparator}${segments[index]}';
      final type = FileSystemEntity.typeSync(current, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw ReleaseManifestException(
          'Symbolic links are forbidden in manifest paths: $relativePath.',
        );
      }
      final expected = index == segments.length - 1
          ? FileSystemEntityType.file
          : FileSystemEntityType.directory;
      if (type != expected) {
        throw ReleaseManifestException(
          'Missing or non-regular manifest file: $relativePath.',
        );
      }
    }
    return File(current);
  }

  void _requireDirectory(Directory root) {
    final type = FileSystemEntity.typeSync(
      root.absolute.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link) {
      throw ReleaseManifestException(
        'Manifest tree root must not be a symbolic link: ${root.path}.',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw ReleaseManifestException(
        'Manifest tree root is not a directory: ${root.path}.',
      );
    }
  }

  String _relativePath(Directory root, String absolutePath) {
    final prefix = '${root.absolute.path}${Platform.pathSeparator}';
    if (!absolutePath.startsWith(prefix)) {
      throw ReleaseManifestException(
        'Path escaped manifest root: $absolutePath.',
      );
    }
    final relative = absolutePath.substring(prefix.length);
    return relative.replaceAll(Platform.pathSeparator, '/');
  }

  void _requireSameFile(
    String path,
    String expectedSha,
    int expectedBytes,
    ManifestFileEntry actual,
  ) {
    if (actual.sha256 != expectedSha || actual.bytes != expectedBytes) {
      throw ReleaseManifestException(
        'Manifest file mismatch for $path: expected $expectedSha/'
        '$expectedBytes, found ${actual.sha256}/${actual.bytes}.',
      );
    }
  }
}

bool _sameStableStat(FileStat before, FileStat after) =>
    before.type == after.type &&
    before.size == after.size &&
    before.mode == after.mode &&
    before.modified == after.modified &&
    before.changed == after.changed;
