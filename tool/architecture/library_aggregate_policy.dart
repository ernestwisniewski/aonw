import 'dart:io';

import 'failure.dart';
import 'policy.dart';
import 'strict_json.dart';

final class LibraryAggregatePolicy {
  LibraryAggregatePolicy._({
    required Map<String, LibraryAggregateTargets> roles,
  }) : roles = Map.unmodifiable(sortedMap(roles));

  factory LibraryAggregatePolicy.load(
    String path,
    ArchitecturePolicy architecturePolicy,
  ) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArchitectureFailure(
        'Architecture aggregate policy does not exist: $path',
      );
    }
    return LibraryAggregatePolicy.parse(
      file.readAsStringSync(),
      architecturePolicy,
      path,
    );
  }

  factory LibraryAggregatePolicy.parse(
    String contents,
    ArchitecturePolicy architecturePolicy,
    String description,
  ) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {'schema', 'roles'}, description);
    if (readInt(root, 'schema', description) != schema) {
      throw ArchitectureFailure('$description has an unsupported schema.');
    }
    final rawRoles = readObject(root, 'roles', description);
    expectKeys(
      rawRoles,
      architecturePolicy.roles.keys.toSet(),
      '$description.roles',
    );
    final roles = {
      for (final entry in rawRoles.entries)
        entry.key: LibraryAggregateTargets.parse(
          entry.value,
          '$description.roles.${entry.key}',
        ),
    };
    final policy = LibraryAggregatePolicy._(roles: roles);
    requireCanonicalJson(contents, policy.toJson(), description);
    return policy;
  }

  static const schema = 1;

  final Map<String, LibraryAggregateTargets> roles;

  LibraryAggregateTargets targetsFor(ArchitectureRole role) =>
      roles[role.name]!;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'roles': {
      for (final entry in roles.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());
}

final class LibraryAggregateTargets {
  const LibraryAggregateTargets({
    required this.sourceLines,
    required this.callableCount,
    required this.callableLines,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  factory LibraryAggregateTargets.parse(Object? value, String description) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'sourceLines',
      'callableCount',
      'callableLines',
      'cyclomaticComplexity',
      'cognitiveComplexity',
    }, description);
    int positive(String key) {
      final result = readInt(object, key, description);
      if (result < 1) {
        throw ArchitectureFailure('$description.$key must be positive.');
      }
      return result;
    }

    return LibraryAggregateTargets(
      sourceLines: positive('sourceLines'),
      callableCount: positive('callableCount'),
      callableLines: positive('callableLines'),
      cyclomaticComplexity: positive('cyclomaticComplexity'),
      cognitiveComplexity: positive('cognitiveComplexity'),
    );
  }

  final int sourceLines;
  final int callableCount;
  final int callableLines;
  final int cyclomaticComplexity;
  final int cognitiveComplexity;

  Map<String, Object?> toJson() => {
    'sourceLines': sourceLines,
    'callableCount': callableCount,
    'callableLines': callableLines,
    'cyclomaticComplexity': cyclomaticComplexity,
    'cognitiveComplexity': cognitiveComplexity,
  };
}
