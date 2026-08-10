part of 'check_coverage.dart';

final class _CoveragePolicy {
  const _CoveragePolicy({
    required this.enforcedSince,
    required this.ratchetEpoch,
    required this.diffLineMinimumBasisPoints,
    required this.excludeSuffixes,
    required this.scopes,
    required this.structuralSignature,
  });

  factory _CoveragePolicy.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw CoverageFailure('Coverage policy does not exist: $path');
    }
    return _CoveragePolicy.parse(file.readAsStringSync(), path);
  }

  factory _CoveragePolicy.parse(String contents, String description) {
    final root = _decodeObject(contents, description);
    final schema = _readInt(root, 'schema', description);
    _expectKeys(
      root,
      coveragePolicyKeysForSchema(schema, description),
      description,
    );
    final enforcedSince = _readString(root, 'enforcedSince', description);
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(enforcedSince)) {
      throw CoverageFailure(
        '$description: enforcedSince must be a full lowercase commit SHA.',
      );
    }
    final ratchetEpoch = readCoverageRatchetEpoch(
      root['ratchetEpoch'],
      schema,
      description,
    );
    final diffMinimum = _readInt(
      root,
      'diffLineMinimumBasisPoints',
      description,
    );
    if (diffMinimum < 0 || diffMinimum > 10000) {
      throw CoverageFailure(
        '$description: diffLineMinimumBasisPoints must be in 0..10000.',
      );
    }
    final excludeSuffixes = _readStringList(
      root,
      'excludeSuffixes',
      description,
    );
    _requireUnique(excludeSuffixes, '$description excludeSuffixes');
    for (final suffix in excludeSuffixes) {
      if (!suffix.startsWith('.') || suffix.contains('/')) {
        throw CoverageFailure('$description: invalid excluded suffix: $suffix');
      }
    }

    final rawScopes = _readObject(root, 'scopes', description);
    if (rawScopes.isEmpty) {
      throw CoverageFailure('$description: scopes cannot be empty.');
    }
    final scopes = <String, _ScopePolicy>{};
    for (final entry in rawScopes.entries) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key)) {
        throw CoverageFailure('$description: invalid scope name: ${entry.key}');
      }
      scopes[entry.key] = _ScopePolicy.parse(
        entry.value,
        '$description scope ${entry.key}',
        excludeSuffixes,
      );
    }

    final structuralJson = <String, Object?>{
      'schema': 1,
      'enforcedSince': enforcedSince,
      'excludeSuffixes': excludeSuffixes,
      'scopes': {
        for (final name in scopes.keys.toList()..sort())
          name: scopes[name]!.toJson(),
      },
    };
    return _CoveragePolicy(
      enforcedSince: enforcedSince,
      ratchetEpoch: ratchetEpoch,
      diffLineMinimumBasisPoints: diffMinimum,
      excludeSuffixes: List.unmodifiable(excludeSuffixes),
      scopes: Map.unmodifiable(scopes),
      structuralSignature: jsonEncode(structuralJson),
    );
  }

  final String enforcedSince;
  final int ratchetEpoch;
  final int diffLineMinimumBasisPoints;
  final List<String> excludeSuffixes;
  final Map<String, _ScopePolicy> scopes;
  final String structuralSignature;

  String get diffLineMinimumPercent =>
      (diffLineMinimumBasisPoints / 100).toStringAsFixed(2);
}
