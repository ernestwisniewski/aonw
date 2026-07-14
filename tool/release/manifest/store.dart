import 'dart:io';

import 'failure.dart';
import 'model.dart';
import 'parser.dart';
import 'validation.dart';

final class StoredManifest {
  const StoredManifest({
    required this.file,
    required this.digest,
    required this.created,
  });

  final File file;
  final String digest;
  final bool created;
}

/// A same-filesystem, atomic manifest store serialized by its root lock.
///
/// Writers using this store never overwrite different bytes. Processes that
/// bypass the lock are outside this cooperative-writer contract.
final class ReleaseManifestStore {
  ReleaseManifestStore(this.root);

  final Directory root;

  Future<StoredManifest> put(ReleaseManifestV1 manifest) async {
    await root.create(recursive: true);
    _requireRealDirectory(root);
    final target = File(
      '${root.absolute.path}${Platform.pathSeparator}${manifest.fileName}',
    );
    final lock = File(
      '${root.absolute.path}${Platform.pathSeparator}.manifest-store.lock',
    );
    _requireNotLink(lock);
    final handle = await lock.open(mode: FileMode.writeOnlyAppend);
    await handle.lock(FileLock.blockingExclusive);
    Directory? temporaryDirectory;
    File? temporary;
    try {
      final existing = await _existingResult(target, manifest);
      if (existing != null) return existing;
      temporaryDirectory = await Directory(
        root.absolute.path,
      ).createTemp('.manifest-write-');
      _requireRealDirectory(temporaryDirectory);
      temporary = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}payload',
      );
      await temporary.create(exclusive: true);
      _requireRegularFile(temporary);
      final output = await temporary.open(mode: FileMode.writeOnly);
      try {
        await output.writeFrom(manifest.canonicalBytes);
        await output.flush();
      } finally {
        await output.close();
      }
      final raced = await _existingResult(target, manifest);
      if (raced != null) return raced;
      await temporary.rename(target.path);
      temporary = null;
      return StoredManifest(
        file: target,
        digest: manifest.digest,
        created: true,
      );
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (temporaryDirectory != null && await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
      await handle.unlock();
      await handle.close();
    }
  }

  Future<ReleaseManifestV1> read(String digest) async {
    requireSha256(digest, 'manifest digest');
    final path = '${root.absolute.path}${Platform.pathSeparator}$digest.json';
    final file = File(path);
    _requireRegularFile(file);
    final contents = await file.readAsString();
    final manifest = const ReleaseManifestParser().parseCanonical(contents);
    if (manifest.digest != digest ||
        manifest.fileName != _basename(file.path)) {
      throw const ReleaseManifestException(
        'Manifest filename does not match its canonical SHA-256 digest.',
      );
    }
    return manifest;
  }

  Future<StoredManifest?> _existingResult(
    File target,
    ReleaseManifestV1 manifest,
  ) async {
    final type = await FileSystemEntity.type(target.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw ReleaseManifestException(
        'Manifest destination is not a regular file: ${target.path}.',
      );
    }
    final existing = await target.readAsBytes();
    final expected = manifest.canonicalBytes;
    if (!_sameBytes(existing, expected)) {
      throw ReleaseManifestException(
        'Refusing to overwrite different manifest bytes at ${target.path}.',
      );
    }
    return StoredManifest(
      file: target,
      digest: manifest.digest,
      created: false,
    );
  }
}

void _requireRealDirectory(Directory directory) {
  final type = FileSystemEntity.typeSync(
    directory.absolute.path,
    followLinks: false,
  );
  if (type != FileSystemEntityType.directory) {
    throw ReleaseManifestException(
      'Manifest store root must be a real directory: ${directory.path}.',
    );
  }
}

void _requireNotLink(File file) {
  final type = FileSystemEntity.typeSync(file.path, followLinks: false);
  if (type == FileSystemEntityType.link) {
    throw ReleaseManifestException(
      'Manifest store lock must not be a symbolic link: ${file.path}.',
    );
  }
}

void _requireRegularFile(File file) {
  final type = FileSystemEntity.typeSync(file.path, followLinks: false);
  if (type != FileSystemEntityType.file) {
    throw ReleaseManifestException(
      'Manifest is missing or not a regular file: ${file.path}.',
    );
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _basename(String path) => path.split(Platform.pathSeparator).last;
