import 'dart:io';

import 'failure.dart';
import 'strict_json.dart';

final class ArchitecturePolicy {
  ArchitecturePolicy._({
    required this.enforcedSince,
    required this.generatedSuffixes,
    required this.buildRunnerScopes,
    required this.fileLineTargets,
    required this.declarationLineTarget,
    required this.scopes,
  });

  factory ArchitecturePolicy.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArchitectureFailure('Architecture policy does not exist: $path');
    }
    return ArchitecturePolicy.parse(file.readAsStringSync(), path);
  }

  factory ArchitecturePolicy.parse(String contents, String description) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {
      'schema',
      'enforcedSince',
      'generatedSuffixes',
      'buildRunnerScopes',
      'fileLineTargets',
      'declarationLineTarget',
      'scopes',
    }, description);
    if (readInt(root, 'schema', description) != 1) {
      throw ArchitectureFailure('$description has an unsupported schema.');
    }
    final enforcedSince = readString(root, 'enforcedSince', description);
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(enforcedSince)) {
      throw ArchitectureFailure(
        '$description.enforcedSince must be a full lowercase Git SHA.',
      );
    }
    final generatedSuffixes = readStringList(
      root,
      'generatedSuffixes',
      description,
    );
    if (!_sameSet(generatedSuffixes.toSet(), const {
      '.freezed.dart',
      '.g.dart',
    })) {
      throw ArchitectureFailure(
        '$description.generatedSuffixes must contain only canonical '
        'build_runner suffixes.',
      );
    }
    final buildRunnerScopes = readStringList(
      root,
      'buildRunnerScopes',
      description,
    );
    final rawFileLineTargets = readObject(root, 'fileLineTargets', description);
    if (rawFileLineTargets.isEmpty) {
      throw ArchitectureFailure(
        '$description.fileLineTargets must not be empty.',
      );
    }
    final fileLineTargets = <String, int>{};
    for (final entry in rawFileLineTargets.entries) {
      final value = entry.value;
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key) ||
          value is! int ||
          value < 1) {
        throw ArchitectureFailure(
          '$description has an invalid file line target: ${entry.key}',
        );
      }
      fileLineTargets[entry.key] = value;
    }
    if (!fileLineTargets.containsKey('default')) {
      throw ArchitectureFailure(
        '$description.fileLineTargets must define default.',
      );
    }
    final declarationLineTarget = readInt(
      root,
      'declarationLineTarget',
      description,
    );
    if (declarationLineTarget < 1) {
      throw ArchitectureFailure(
        '$description.declarationLineTarget must be positive.',
      );
    }

    final rawScopes = readObject(root, 'scopes', description);
    if (rawScopes.isEmpty) {
      throw ArchitectureFailure('$description.scopes must not be empty.');
    }
    final scopes = <String, ScopePolicy>{};
    for (final entry in rawScopes.entries) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key)) {
        throw ArchitectureFailure(
          '$description has an invalid scope name: ${entry.key}',
        );
      }
      scopes[entry.key] = ScopePolicy.parse(
        entry.value,
        '$description.scopes.${entry.key}',
        fileLineTargets,
        declarationLineTarget,
      );
    }
    final unknownBuildRunnerScopes =
        buildRunnerScopes.toSet().difference(scopes.keys.toSet()).toList()
          ..sort();
    if (unknownBuildRunnerScopes.isNotEmpty) {
      throw ArchitectureFailure(
        '$description.buildRunnerScopes contains unknown scopes: '
        '$unknownBuildRunnerScopes',
      );
    }
    final usedProfiles = scopes.values
        .expand((scope) => scope.fileProfiles.keys)
        .toSet();
    final unusedTargets =
        fileLineTargets.keys.toSet().difference(usedProfiles).toList()..sort();
    if (unusedTargets.isNotEmpty) {
      throw ArchitectureFailure(
        '$description.fileLineTargets contains unused profiles: '
        '$unusedTargets',
      );
    }
    final policy = ArchitecturePolicy._(
      enforcedSince: enforcedSince,
      generatedSuffixes: generatedSuffixes,
      buildRunnerScopes: buildRunnerScopes,
      fileLineTargets: Map.unmodifiable(sortedMap(fileLineTargets)),
      declarationLineTarget: declarationLineTarget,
      scopes: Map.unmodifiable(sortedMap(scopes)),
    );
    _validateDisjointScopeRoots(policy.scopes, description);
    requireCanonicalJson(contents, policy.toJson(), description);
    return policy;
  }

  final String enforcedSince;
  final List<String> generatedSuffixes;
  final List<String> buildRunnerScopes;
  final Map<String, int> fileLineTargets;
  final int declarationLineTarget;
  final Map<String, ScopePolicy> scopes;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'enforcedSince': enforcedSince,
    'generatedSuffixes': generatedSuffixes,
    'buildRunnerScopes': buildRunnerScopes,
    'fileLineTargets': fileLineTargets,
    'declarationLineTarget': declarationLineTarget,
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  bool isGenerated(String path, String scopeName, ScopePolicy scope) =>
      (buildRunnerScopes.contains(scopeName) &&
          generatedSuffixes.any(path.endsWith)) ||
      scope.generatedPrefixes.any(path.startsWith);
}

final class ScopePolicy {
  ScopePolicy._({
    required this.sourceRoot,
    required this.generatedPrefixes,
    required this.fileProfiles,
    required this.declarationLineTarget,
  });

  factory ScopePolicy.parse(
    Object? value,
    String description,
    Map<String, int> fileLineTargets,
    int declarationLineTarget,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'sourceRoot',
      'generatedPrefixes',
      'fileProfiles',
    }, description);
    final sourceRoot = readString(object, 'sourceRoot', description);
    validateRepositoryPath(sourceRoot, '$description.sourceRoot');
    final generatedPrefixes = readStringList(
      object,
      'generatedPrefixes',
      description,
    );
    for (final prefix in generatedPrefixes) {
      validateRepositoryPath(
        prefix,
        '$description.generatedPrefixes entry',
        requirePrefix: true,
      );
      if (!prefix.startsWith('$sourceRoot/')) {
        throw ArchitectureFailure(
          '$description generated prefix is outside $sourceRoot: $prefix',
        );
      }
    }
    final rawProfiles = readObject(object, 'fileProfiles', description);
    if (rawProfiles.isEmpty) {
      throw ArchitectureFailure('$description.fileProfiles must not be empty.');
    }
    final profiles = <String, FileProfile>{};
    for (final entry in rawProfiles.entries) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key)) {
        throw ArchitectureFailure(
          '$description has an invalid profile name: ${entry.key}',
        );
      }
      final lineTarget = fileLineTargets[entry.key];
      if (lineTarget == null) {
        throw ArchitectureFailure(
          '$description references an unknown file profile: ${entry.key}',
        );
      }
      profiles[entry.key] = FileProfile.parse(
        entry.key,
        entry.value,
        '$description.fileProfiles.${entry.key}',
        sourceRoot,
        lineTarget,
      );
    }
    final fallbackCount = profiles.values
        .where((value) => value.isFallback)
        .length;
    if (fallbackCount != 1 || profiles['default']?.isFallback != true) {
      throw ArchitectureFailure(
        '$description must define default as its only fallback file profile.',
      );
    }
    final explicitProfiles = profiles.values
        .where((profile) => !profile.isFallback)
        .toList();
    for (
      var firstIndex = 0;
      firstIndex < explicitProfiles.length;
      firstIndex++
    ) {
      final first = explicitProfiles[firstIndex];
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < explicitProfiles.length;
        secondIndex++
      ) {
        final second = explicitProfiles[secondIndex];
        for (final firstPattern in first.paths) {
          for (final secondPattern in second.paths) {
            if (patternsOverlap(firstPattern, secondPattern)) {
              throw ArchitectureFailure(
                '$description profiles ${first.name} and ${second.name} '
                'overlap: $firstPattern / $secondPattern',
              );
            }
          }
        }
      }
    }
    return ScopePolicy._(
      sourceRoot: sourceRoot,
      generatedPrefixes: generatedPrefixes,
      fileProfiles: Map.unmodifiable(sortedMap(profiles)),
      declarationLineTarget: declarationLineTarget,
    );
  }

  final String sourceRoot;
  final List<String> generatedPrefixes;
  final Map<String, FileProfile> fileProfiles;
  final int declarationLineTarget;

  FileProfile profileFor(String path) {
    final matches = fileProfiles.values
        .where(
          (profile) =>
              !profile.isFallback &&
              profile.paths.any((p) => pathMatches(path, p)),
        )
        .toList();
    if (matches.length > 1) {
      throw ArchitectureFailure(
        '$path matches multiple file profiles: '
        '${matches.map((profile) => profile.name).join(', ')}',
      );
    }
    if (matches.length == 1) return matches.single;
    return fileProfiles.values.singleWhere((profile) => profile.isFallback);
  }

  Map<String, Object?> toJson() => {
    'sourceRoot': sourceRoot,
    'generatedPrefixes': generatedPrefixes,
    'fileProfiles': {
      for (final entry in fileProfiles.entries) entry.key: entry.value.toJson(),
    },
  };
}

final class FileProfile {
  const FileProfile._({
    required this.name,
    required this.paths,
    required this.lineTarget,
    required this.isFallback,
  });

  factory FileProfile.parse(
    String name,
    Object? value,
    String description,
    String sourceRoot,
    int lineTarget,
  ) {
    final object = asObject(value, description);
    final isFallback = object.containsKey('fallback');
    expectKeys(
      object,
      isFallback ? const {'fallback'} : const {'paths'},
      description,
    );
    if (isFallback) {
      if (!readBool(object, 'fallback', description)) {
        throw ArchitectureFailure('$description.fallback must be true.');
      }
      return FileProfile._(
        name: name,
        paths: const [],
        lineTarget: lineTarget,
        isFallback: true,
      );
    }
    final paths = readStringList(object, 'paths', description);
    if (paths.isEmpty) {
      throw ArchitectureFailure('$description.paths must not be empty.');
    }
    for (final path in paths) {
      validateRepositoryPath(
        path,
        '$description.paths entry',
        requirePrefix: path.endsWith('/'),
      );
      if (path != sourceRoot && !path.startsWith('$sourceRoot/')) {
        throw ArchitectureFailure(
          '$description path is outside $sourceRoot: $path',
        );
      }
    }
    return FileProfile._(
      name: name,
      paths: paths,
      lineTarget: lineTarget,
      isFallback: false,
    );
  }

  final String name;
  final List<String> paths;
  final int lineTarget;
  final bool isFallback;

  Map<String, Object?> toJson() =>
      isFallback ? {'fallback': true} : {'paths': paths};
}

void _validateDisjointScopeRoots(
  Map<String, ScopePolicy> scopes,
  String description,
) {
  final entries = scopes.entries.toList();
  for (var firstIndex = 0; firstIndex < entries.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < entries.length;
      secondIndex++
    ) {
      final first = entries[firstIndex];
      final second = entries[secondIndex];
      if (_rootsOverlap(first.value.sourceRoot, second.value.sourceRoot)) {
        throw ArchitectureFailure(
          '$description scopes ${first.key} and ${second.key} overlap: '
          '${first.value.sourceRoot} / ${second.value.sourceRoot}',
        );
      }
    }
  }
}

bool _rootsOverlap(String first, String second) =>
    first == second ||
    first.startsWith('$second/') ||
    second.startsWith('$first/');

bool _sameSet<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);
