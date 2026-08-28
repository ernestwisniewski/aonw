import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../local_game/application/local_game_catalog.dart';
import '../application/local_save_store.dart';

typedef LocalSaveDirectoryProvider = Future<Directory> Function();

final class AtomicLocalSaveStore implements LocalSaveStore {
  AtomicLocalSaveStore({required LocalSaveDirectoryProvider rootDirectory})
    : _rootDirectory = rootDirectory;

  factory AtomicLocalSaveStore.production() =>
      AtomicLocalSaveStore(rootDirectory: getApplicationSupportDirectory);

  final LocalSaveDirectoryProvider _rootDirectory;
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async {
    final paths = await _paths(scenario, createDirectory: false);
    return await paths.primary.exists() || await paths.backup.exists();
  }

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalSaveCopyView copy,
  ) async {
    final paths = await _paths(scenario, createDirectory: false);
    final file = switch (copy) {
      LocalSaveCopyView.primary => paths.primary,
      LocalSaveCopyView.backup => paths.backup,
    };
    if (!await file.exists()) return null;
    try {
      final length = await file.length();
      if (length <= 0 || length > maxLocalSaveDocumentBytes) {
        throw LocalSaveStoreException(
          code: 'save_size_invalid',
          message: 'The save document size is invalid.',
          diagnosticCause: StateError('Save document byte length: $length'),
          diagnosticStackTrace: StackTrace.current,
        );
      }
      return await file.readAsString();
    } on LocalSaveStoreException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw LocalSaveStoreException(
        code: 'save_read_failed',
        message: 'The save document could not be read.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) {
    final operation = _writeTail.then((_) => _write(scenario, document));
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _write(LocalGameScenarioView scenario, String document) async {
    final bytes = utf8.encode(document);
    if (bytes.isEmpty || bytes.length > maxLocalSaveDocumentBytes) {
      throw LocalSaveStoreException(
        code: 'save_size_invalid',
        message: 'The save document size is invalid.',
        diagnosticCause: StateError(
          'Save document byte length: ${bytes.length}',
        ),
        diagnosticStackTrace: StackTrace.current,
      );
    }
    final paths = await _paths(scenario, createDirectory: true);
    final temp = File(
      '${paths.primary.path}.tmp.${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await temp.writeAsBytes(bytes, flush: true);
      if (await paths.primary.exists()) {
        if (await paths.backup.exists()) await paths.backup.delete();
        await paths.primary.rename(paths.backup.path);
      }
      try {
        await temp.rename(paths.primary.path);
      } on Object {
        if (!await paths.primary.exists() && await paths.backup.exists()) {
          await paths.backup.rename(paths.primary.path);
        }
        rethrow;
      }
    } on LocalSaveStoreException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw LocalSaveStoreException(
        code: 'save_write_failed',
        message: 'The save document could not be stored.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<({File primary, File backup})> _paths(
    LocalGameScenarioView scenario, {
    required bool createDirectory,
  }) async {
    try {
      final root = await _rootDirectory();
      final directory = Directory.fromUri(root.uri.resolve('saves/'));
      if (createDirectory) await directory.create(recursive: true);
      final primary = File.fromUri(
        directory.uri.resolve('${scenario.name}.json'),
      );
      return (primary: primary, backup: File('${primary.path}.backup'));
    } on Object catch (error, stackTrace) {
      throw LocalSaveStoreException(
        code: 'save_directory_failed',
        message: 'The save directory is unavailable.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}
