import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// Owns analyzer contexts used by architecture guards that need resolved ASTs.
///
/// Paths accepted by this class can be absolute or relative to [rootPath].
/// Source overrides are installed before the analysis contexts are created,
/// so imports and elements consistently observe the same virtual workspace.
final class ResolvedDartWorkspace {
  factory ResolvedDartWorkspace({
    required String rootPath,
    Map<String, String> sourceOverrides = const {},
  }) {
    final baseProvider = PhysicalResourceProvider.INSTANCE;
    final pathContext = baseProvider.pathContext;
    final normalizedRoot = pathContext.normalize(
      pathContext.absolute(rootPath),
    );
    if (!baseProvider.getFolder(normalizedRoot).exists) {
      throw ArgumentError.value(
        rootPath,
        'rootPath',
        'must identify an existing directory',
      );
    }

    final normalizedOverrides = <String, String>{};
    for (final entry in sourceOverrides.entries) {
      final path = _normalizeWorkspacePath(
        resourceProvider: baseProvider,
        rootPath: normalizedRoot,
        path: entry.key,
      );
      normalizedOverrides[path] = entry.value;
    }

    final overridePaths = normalizedOverrides.keys.toList()..sort();
    final OverlayResourceProvider? overlayProvider;
    final ResourceProvider resourceProvider;
    if (overridePaths.isEmpty) {
      overlayProvider = null;
      resourceProvider = baseProvider;
    } else {
      overlayProvider = OverlayResourceProvider(baseProvider);
      for (var index = 0; index < overridePaths.length; index++) {
        final path = overridePaths[index];
        overlayProvider.setOverlay(
          path,
          content: normalizedOverrides[path]!,
          modificationStamp: index + 1,
        );
      }
      resourceProvider = overlayProvider;
    }

    return ResolvedDartWorkspace._(
      rootPath: normalizedRoot,
      resourceProvider: resourceProvider,
      overlayProvider: overlayProvider,
      overridePaths: overridePaths,
      collection: AnalysisContextCollection(
        includedPaths: _analysisRoots(
          rootPath: normalizedRoot,
          resourceProvider: resourceProvider,
        ),
        resourceProvider: resourceProvider,
        sdkPath: _bundledDartSdkPath(resourceProvider),
      ),
    );
  }

  ResolvedDartWorkspace._({
    required this.rootPath,
    required ResourceProvider resourceProvider,
    required OverlayResourceProvider? overlayProvider,
    required List<String> overridePaths,
    required AnalysisContextCollection collection,
  }) : _resourceProvider = resourceProvider,
       _overlayProvider = overlayProvider,
       _overridePaths = overridePaths,
       _collection = collection;

  /// Absolute, normalized path to the workspace root.
  final String rootPath;

  final ResourceProvider _resourceProvider;
  final OverlayResourceProvider? _overlayProvider;
  final List<String> _overridePaths;
  final AnalysisContextCollection _collection;
  final Map<String, Future<ResolvedUnitResult>> _resolvedUnits = {};

  Future<void>? _disposeFuture;
  bool _disposed = false;

  /// Returns an absolute, normalized path contained by this workspace.
  String absolutePath(String path) {
    return _normalizeWorkspacePath(
      resourceProvider: _resourceProvider,
      rootPath: rootPath,
      path: path,
    );
  }

  /// Returns a stable, slash-separated path relative to [rootPath].
  String displayPath(String path) {
    final pathContext = _resourceProvider.pathContext;
    final relative = pathContext.relative(absolutePath(path), from: rootPath);
    return pathContext.split(relative).join('/');
  }

  /// Resolves [path], caching both successful and failed resolutions.
  ///
  /// Analyzer diagnostics are intentionally left on the returned result for
  /// the architecture guard to assess. Invalid result states fail immediately.
  Future<ResolvedUnitResult> resolve(String path) {
    _ensureOpen();
    final normalizedPath = absolutePath(path);
    return _resolvedUnits.putIfAbsent(
      normalizedPath,
      () => _resolve(normalizedPath),
    );
  }

  /// Resolves unique [paths] in deterministic repo-relative path order.
  Future<Map<String, ResolvedUnitResult>> resolveAll(
    Iterable<String> paths,
  ) async {
    _ensureOpen();
    final normalizedPaths = paths.map(absolutePath).toSet().toList()..sort();
    final entries = await Future.wait([
      for (final path in normalizedPaths)
        resolve(path).then((result) => MapEntry(displayPath(path), result)),
    ]);
    return Map.unmodifiable(Map.fromEntries(entries));
  }

  /// Disposes analyzer contexts once, after all cached resolutions settle.
  Future<void> dispose() {
    return _disposeFuture ??= _dispose();
  }

  Future<ResolvedUnitResult> _resolve(String path) async {
    final result = await _collection
        .contextFor(path)
        .currentSession
        .getResolvedUnit(path);
    if (result is ResolvedUnitResult) return result;
    throw StateError(
      'Analyzer could not resolve ${displayPath(path)} '
      '(${result.runtimeType}).',
    );
  }

  Future<void> _dispose() async {
    _disposed = true;
    final pending = _resolvedUnits.values.toList(growable: false);
    await Future.wait([
      for (final resolution in pending)
        resolution.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    ]);

    try {
      await _collection.dispose();
    } finally {
      for (final path in _overridePaths) {
        _overlayProvider?.removeOverlay(path);
      }
      _resolvedUnits.clear();
    }
  }

  void _ensureOpen() {
    if (_disposed) {
      throw StateError('ResolvedDartWorkspace has already been disposed.');
    }
  }
}

List<String> _analysisRoots({
  required String rootPath,
  required ResourceProvider resourceProvider,
}) {
  final pathContext = resourceProvider.pathContext;
  final roots = <String>{rootPath};
  for (final relativePath in const ['server', 'packages']) {
    final folder = resourceProvider.getFolder(
      pathContext.join(rootPath, relativePath),
    );
    if (!folder.exists) continue;
    if (relativePath == 'server') {
      roots.add(folder.path);
      continue;
    }
    for (final child in folder.getChildren()) {
      if (child is! Folder) continue;
      final pubspec = resourceProvider.getFile(
        pathContext.join(child.path, 'pubspec.yaml'),
      );
      if (pubspec.exists) roots.add(child.path);
    }
  }
  final ordered = roots.toList()..sort();
  return ordered;
}

String? _bundledDartSdkPath(ResourceProvider resourceProvider) {
  final pathContext = resourceProvider.pathContext;
  final executable = pathContext.normalize(Platform.resolvedExecutable);
  final marker =
      '${pathContext.separator}bin${pathContext.separator}'
      'cache${pathContext.separator}';
  final markerIndex = executable.indexOf(marker);
  if (markerIndex >= 0) {
    final flutterRoot = executable.substring(0, markerIndex);
    final candidate = pathContext.join(flutterRoot, 'bin', 'cache', 'dart-sdk');
    if (resourceProvider.getFolder(candidate).exists) return candidate;
  }

  final executableSdk = pathContext.dirname(pathContext.dirname(executable));
  final libraries = pathContext.join(
    executableSdk,
    'lib',
    '_internal',
    'sdk_library_metadata',
    'lib',
    'libraries.dart',
  );
  return resourceProvider.getFile(libraries).exists ? executableSdk : null;
}

String _normalizeWorkspacePath({
  required ResourceProvider resourceProvider,
  required String rootPath,
  required String path,
}) {
  final pathContext = resourceProvider.pathContext;
  final String normalizedPath = pathContext.normalize(
    pathContext.isAbsolute(path) ? path : pathContext.join(rootPath, path),
  );
  if (normalizedPath != rootPath &&
      !pathContext.isWithin(rootPath, normalizedPath)) {
    throw ArgumentError.value(
      path,
      'path',
      'must be contained by the workspace root',
    );
  }
  return normalizedPath;
}
