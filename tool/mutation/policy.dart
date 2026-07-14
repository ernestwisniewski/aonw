import 'dart:io';

import 'failure.dart';
import 'strict_json.dart';

const supportedMutationOperators = <String>[
  'boolean_literal_flip',
  'equality_negation',
  'logical_connector',
  'logical_negation',
  'relational_boundary',
  'type_test_negation',
  'wire_string_replacement',
];

final class MutationPolicy {
  MutationPolicy._({
    required this.enforcedSince,
    required this.perMutantTimeoutSeconds,
    required this.operators,
    required this.scopes,
  });

  factory MutationPolicy.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw MutationFailure('Mutation policy does not exist: $path');
    }
    return MutationPolicy.parse(file.readAsStringSync(), path);
  }

  factory MutationPolicy.parse(String contents, String description) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {
      'schema',
      'enforcedSince',
      'perMutantTimeoutSeconds',
      'operators',
      'scopes',
    }, description);
    if (readInt(root, 'schema', description) != 1) {
      throw MutationFailure('$description has an unsupported schema.');
    }
    final enforcedSince = readString(root, 'enforcedSince', description);
    if (!RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(enforcedSince)) {
      throw MutationFailure(
        '$description.enforcedSince must be a full lowercase Git object ID.',
      );
    }
    final timeout = readInt(root, 'perMutantTimeoutSeconds', description);
    if (timeout < 1 || timeout > 300) {
      throw MutationFailure(
        '$description.perMutantTimeoutSeconds must be between 1 and 300.',
      );
    }
    final operators = readStringList(root, 'operators', description);
    if (!_sameList(operators, supportedMutationOperators)) {
      throw MutationFailure(
        '$description.operators must contain exactly the supported mutation '
        'operators.',
      );
    }

    final rawScopes = readObject(root, 'scopes', description);
    if (rawScopes.isEmpty) {
      throw MutationFailure('$description.scopes must not be empty.');
    }
    final scopes = <String, MutationScopePolicy>{};
    for (final entry in rawScopes.entries) {
      validateName(entry.key, '$description scope name');
      scopes[entry.key] = MutationScopePolicy.parse(
        entry.value,
        '$description.scopes.${entry.key}',
      );
    }
    _validateDisjointTargets(scopes, description);

    final policy = MutationPolicy._(
      enforcedSince: enforcedSince,
      perMutantTimeoutSeconds: timeout,
      operators: operators,
      scopes: Map.unmodifiable(sortedMap(scopes)),
    );
    requireCanonicalJson(contents, policy.toJson(), description);
    return policy;
  }

  final String enforcedSince;
  final int perMutantTimeoutSeconds;
  final List<String> operators;
  final Map<String, MutationScopePolicy> scopes;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'enforcedSince': enforcedSince,
    'perMutantTimeoutSeconds': perMutantTimeoutSeconds,
    'operators': operators,
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());
}

final class MutationScopePolicy {
  MutationScopePolicy._({
    required this.architectureScope,
    required this.packageRoot,
    required this.runner,
    required this.targetFiles,
    required this.testFiles,
  });

  factory MutationScopePolicy.parse(Object? value, String description) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'architectureScope',
      'packageRoot',
      'runner',
      'targetFiles',
      'testFiles',
    }, description);
    final architectureScope = readString(
      object,
      'architectureScope',
      description,
    );
    validateName(architectureScope, '$description.architectureScope');
    final packageRoot = readString(object, 'packageRoot', description);
    if (packageRoot != '.') {
      validateRepositoryPath(packageRoot, '$description.packageRoot');
    }
    final runner = readString(object, 'runner', description);
    if (runner != 'dart' && runner != 'flutter') {
      throw MutationFailure(
        '$description.runner must be either dart or flutter.',
      );
    }
    final targetFiles = readStringList(object, 'targetFiles', description);
    final testFiles = readStringList(object, 'testFiles', description);
    if (targetFiles.isEmpty) {
      throw MutationFailure('$description.targetFiles must not be empty.');
    }
    if (testFiles.isEmpty) {
      throw MutationFailure('$description.testFiles must not be empty.');
    }
    for (final path in targetFiles) {
      _validateDartFile(path, packageRoot, '$description.targetFiles entry');
    }
    for (final path in testFiles) {
      _validateDartFile(path, packageRoot, '$description.testFiles entry');
    }
    return MutationScopePolicy._(
      architectureScope: architectureScope,
      packageRoot: packageRoot,
      runner: runner,
      targetFiles: targetFiles,
      testFiles: testFiles,
    );
  }

  final String architectureScope;
  final String packageRoot;
  final String runner;
  final List<String> targetFiles;
  final List<String> testFiles;

  Map<String, Object?> toJson() => {
    'architectureScope': architectureScope,
    'packageRoot': packageRoot,
    'runner': runner,
    'targetFiles': targetFiles,
    'testFiles': testFiles,
  };
}

void _validateDartFile(String path, String packageRoot, String description) {
  validateRepositoryPath(path, description);
  if (!path.endsWith('.dart')) {
    throw MutationFailure('$description must be a Dart source path: $path');
  }
  if (packageRoot != '.' && !path.startsWith('$packageRoot/')) {
    throw MutationFailure(
      '$description must be inside package root $packageRoot: $path',
    );
  }
}

void _validateDisjointTargets(
  Map<String, MutationScopePolicy> scopes,
  String description,
) {
  final owners = <String, String>{};
  for (final scope in scopes.entries) {
    for (final path in scope.value.targetFiles) {
      final portableKey = path.toLowerCase();
      final previous = owners[portableKey];
      if (previous != null) {
        throw MutationFailure(
          '$description target belongs to multiple mutation scopes: '
          '$path -> [$previous, ${scope.key}]',
        );
      }
      owners[portableKey] = scope.key;
    }
  }
}

bool _sameList<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
