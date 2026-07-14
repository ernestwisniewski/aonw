import 'dart:io';

import 'baseline.dart';
import 'dart_metrics.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'source_census.dart';
import 'strict_json.dart';

/// Preserves the schema-1 file/type ratchet during the one-time schema-2
/// rollout. It deliberately has no snapshot writer and cannot become a second
/// live policy surface.
List<String> legacySchemaOneRatchetFailures({
  required GitRepository repository,
  required ArchitecturePolicy currentPolicy,
  required SourceCensus currentCensus,
  required String policyContents,
  required String baselineContents,
}) {
  final legacy = _LegacyPolicy.parse(policyContents, currentPolicy);
  final historical = _LegacyBaseline.parse(baselineContents, legacy.scopeNames);
  final expectedLegacyTargets = <String, int>{};
  for (final scopeName in currentPolicy.scopes.keys) {
    final currentScope = currentPolicy.scopes[scopeName]!;
    final legacyScope = legacy.scopes[scopeName]!;
    for (final path in historical.scopes[scopeName]!.files.keys) {
      final oldTarget = legacyScope.fileTargetFor(path);
      if (oldTarget < currentScope.roleFor(path).fileLines) {
        expectedLegacyTargets[path] = oldTarget;
      }
    }
  }
  if (!_sameIntMap(
    currentPolicy.migration.legacyFileTargets,
    expectedLegacyTargets,
  )) {
    throw const ArchitectureFailure(
      'Schema-2 migration must carry every stricter schema-1 file debt.',
    );
  }
  final failures = <String>[];
  for (final scopeName in currentPolicy.scopes.keys) {
    final currentScope = currentPolicy.scopes[scopeName]!;
    final legacyScope = legacy.scopes[scopeName]!;
    final files = <String, int>{};
    final declarations = <String, int>{};
    for (final path in currentCensus.handwrittenFiles(scopeName)) {
      final metrics = measureDartSource(
        path,
        File(repository.resolve(path)).readAsStringSync(),
      );
      final fileTarget = legacyScope.fileTargetFor(path);
      if (metrics.fileLines > fileTarget) files[path] = metrics.fileLines;
      for (final declaration in metrics.declarations) {
        if (declaration.lines > legacy.declarationLineTarget) {
          if (declarations.containsKey(declaration.key)) {
            throw ArchitectureFailure(
              '$path contains duplicate legacy declaration key: '
              '${declaration.key}',
            );
          }
          declarations[declaration.key] = declaration.lines;
        }
      }
    }
    final old = historical.scopes[scopeName]!;
    failures
      ..addAll(
        ratchetMetricDifferences(files, old.files, '$scopeName schema-1 file'),
      )
      ..addAll(
        ratchetMetricDifferences(
          declarations,
          old.declarations,
          '$scopeName schema-1 declaration',
        ),
      );
    if (currentScope.sourceRoot != legacyScope.sourceRoot) {
      throw ArchitectureFailure(
        'Schema-2 migration changed the $scopeName source root.',
      );
    }
  }
  return failures;
}

final class _LegacyPolicy {
  const _LegacyPolicy({
    required this.declarationLineTarget,
    required this.scopes,
  });

  factory _LegacyPolicy.parse(
    String contents,
    ArchitecturePolicy currentPolicy,
  ) {
    final root = decodeObject(contents, 'schema-1 architecture policy');
    expectKeys(root, const {
      'schema',
      'enforcedSince',
      'generatedSuffixes',
      'buildRunnerScopes',
      'fileLineTargets',
      'declarationLineTarget',
      'scopes',
    }, 'schema-1 architecture policy');
    if (readInt(root, 'schema', 'schema-1 architecture policy') != 1) {
      throw const ArchitectureFailure(
        'Architecture migration source must use schema 1.',
      );
    }
    final suffixes = readStringList(
      root,
      'generatedSuffixes',
      'schema-1 architecture policy',
    );
    final runners = readStringList(
      root,
      'buildRunnerScopes',
      'schema-1 architecture policy',
    );
    if (!_sameList(suffixes, currentPolicy.generatedSuffixes) ||
        !_sameList(runners, currentPolicy.buildRunnerScopes)) {
      throw const ArchitectureFailure(
        'Schema-2 migration cannot change generated source boundaries.',
      );
    }
    final rawTargets = readObject(
      root,
      'fileLineTargets',
      'schema-1 architecture policy',
    );
    final targets = <String, int>{};
    for (final entry in rawTargets.entries) {
      if (entry.value is! int || (entry.value! as int) < 1) {
        throw ArchitectureFailure(
          'Schema-1 policy has an invalid target: ${entry.key}',
        );
      }
      targets[entry.key] = entry.value! as int;
    }
    final declarationLineTarget = readInt(
      root,
      'declarationLineTarget',
      'schema-1 architecture policy',
    );
    final rawScopes = readObject(
      root,
      'scopes',
      'schema-1 architecture policy',
    );
    expectKeys(
      rawScopes,
      currentPolicy.scopes.keys.toSet(),
      'schema-1 architecture policy.scopes',
    );
    final scopes = <String, _LegacyScope>{};
    for (final entry in rawScopes.entries) {
      final current = currentPolicy.scopes[entry.key]!;
      scopes[entry.key] = _LegacyScope.parse(
        entry.value,
        targets,
        current,
        'schema-1 architecture policy.scopes.${entry.key}',
      );
    }
    return _LegacyPolicy(
      declarationLineTarget: declarationLineTarget,
      scopes: scopes,
    );
  }

  final int declarationLineTarget;
  final Map<String, _LegacyScope> scopes;
  Set<String> get scopeNames => scopes.keys.toSet();
}

final class _LegacyScope {
  const _LegacyScope({
    required this.sourceRoot,
    required this.fallbackTarget,
    required this.profiles,
  });

  factory _LegacyScope.parse(
    Object? value,
    Map<String, int> targets,
    ScopePolicy current,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'sourceRoot',
      'generatedPrefixes',
      'fileProfiles',
    }, description);
    final sourceRoot = readString(object, 'sourceRoot', description);
    final generated = readStringList(object, 'generatedPrefixes', description);
    if (sourceRoot != current.sourceRoot ||
        !_sameList(generated, current.generatedPrefixes)) {
      throw ArchitectureFailure(
        'Schema-2 migration changed source ownership for $sourceRoot.',
      );
    }
    final rawProfiles = readObject(object, 'fileProfiles', description);
    final profiles = <_LegacyProfile>[];
    int? fallbackTarget;
    for (final entry in rawProfiles.entries) {
      final target = targets[entry.key];
      if (target == null) {
        throw ArchitectureFailure('$description uses unknown ${entry.key}.');
      }
      final profile = asObject(entry.value, '$description.${entry.key}');
      if (profile.containsKey('fallback')) {
        expectKeys(profile, const {'fallback'}, '$description.${entry.key}');
        if (!readBool(profile, 'fallback', '$description.${entry.key}') ||
            fallbackTarget != null) {
          throw ArchitectureFailure('$description has invalid fallback.');
        }
        fallbackTarget = target;
      } else {
        expectKeys(profile, const {'paths'}, '$description.${entry.key}');
        profiles.add(
          _LegacyProfile(
            paths: readStringList(
              profile,
              'paths',
              '$description.${entry.key}',
            ),
            target: target,
          ),
        );
      }
    }
    if (fallbackTarget == null) {
      throw ArchitectureFailure('$description has no fallback profile.');
    }
    return _LegacyScope(
      sourceRoot: sourceRoot,
      fallbackTarget: fallbackTarget,
      profiles: profiles,
    );
  }

  final String sourceRoot;
  final int fallbackTarget;
  final List<_LegacyProfile> profiles;

  int fileTargetFor(String path) {
    final matches = profiles
        .where(
          (profile) => profile.paths.any((item) => pathMatches(path, item)),
        )
        .toList();
    if (matches.length > 1) {
      throw ArchitectureFailure('$path matches multiple schema-1 profiles.');
    }
    return matches.isEmpty ? fallbackTarget : matches.single.target;
  }
}

final class _LegacyProfile {
  const _LegacyProfile({required this.paths, required this.target});

  final List<String> paths;
  final int target;
}

final class _LegacyBaseline {
  const _LegacyBaseline({required this.scopes});

  factory _LegacyBaseline.parse(String contents, Set<String> scopeNames) {
    final root = decodeObject(contents, 'schema-1 architecture baseline');
    expectKeys(root, const {'schema', 'scopes'}, 'schema-1 baseline');
    if (readInt(root, 'schema', 'schema-1 baseline') != 1) {
      throw const ArchitectureFailure(
        'Architecture migration baseline must use schema 1.',
      );
    }
    final rawScopes = readObject(root, 'scopes', 'schema-1 baseline');
    expectKeys(rawScopes, scopeNames, 'schema-1 baseline.scopes');
    final scopes = <String, _LegacyScopeBaseline>{};
    for (final entry in rawScopes.entries) {
      final value = asObject(entry.value, 'schema-1 baseline.${entry.key}');
      expectKeys(value, const {
        'files',
        'declarations',
      }, 'schema-1 baseline.${entry.key}');
      scopes[entry.key] = _LegacyScopeBaseline(
        files: _integerMap(value, 'files', entry.key),
        declarations: _integerMap(value, 'declarations', entry.key),
      );
    }
    return _LegacyBaseline(scopes: scopes);
  }

  final Map<String, _LegacyScopeBaseline> scopes;
}

final class _LegacyScopeBaseline {
  const _LegacyScopeBaseline({required this.files, required this.declarations});

  final Map<String, int> files;
  final Map<String, int> declarations;
}

Map<String, int> _integerMap(
  Map<String, Object?> object,
  String key,
  String scope,
) {
  final raw = readObject(object, key, 'schema-1 baseline.$scope');
  final result = <String, int>{};
  for (final entry in raw.entries) {
    if (entry.value is! int || (entry.value! as int) < 1) {
      throw ArchitectureFailure(
        'Schema-1 baseline has invalid $scope/$key/${entry.key}.',
      );
    }
    result[entry.key] = entry.value! as int;
  }
  return result;
}

bool _sameList<T>(List<T> first, List<T> second) =>
    first.length == second.length &&
    Iterable<int>.generate(
      first.length,
    ).every((index) => first[index] == second[index]);

bool _sameIntMap(Map<String, int> first, Map<String, int> second) =>
    first.length == second.length &&
    first.entries.every((entry) => second[entry.key] == entry.value);
