part of 'check_coverage.dart';

final class _CoverageBaseline {
  const _CoverageBaseline({required this.scopes});

  factory _CoverageBaseline.load(String path, _CoveragePolicy policy) {
    final file = File(path);
    if (!file.existsSync()) {
      throw CoverageFailure(
        'Coverage baseline does not exist: $path. Generate a reviewed '
        'snapshot first.',
      );
    }
    return _CoverageBaseline.parse(file.readAsStringSync(), policy, path);
  }

  factory _CoverageBaseline.parse(
    String contents,
    _CoveragePolicy policy,
    String description,
  ) {
    final root = _decodeObject(contents, description);
    _expectKeys(root, const {'schema', 'scopes'}, description);
    final schema = _readInt(root, 'schema', description);
    if (schema != 1) {
      throw CoverageFailure('$description: unsupported schema $schema.');
    }
    final rawScopes = _readObject(root, 'scopes', description);
    _expectKeys(rawScopes, policy.scopes.keys.toSet(), '$description scopes');
    final scopes = <String, _ScopeSnapshot>{};
    for (final entry in rawScopes.entries) {
      scopes[entry.key] = _ScopeSnapshot.parse(
        entry.value,
        '$description scope ${entry.key}',
        policy.scopes[entry.key]!,
      );
    }
    return _CoverageBaseline(scopes: Map.unmodifiable(scopes));
  }

  final Map<String, _ScopeSnapshot> scopes;
}

final class _ScopeSnapshot {
  const _ScopeSnapshot({required this.layers, required this.missingFiles});

  factory _ScopeSnapshot.parse(
    Object? value,
    String description,
    _ScopePolicy policy,
  ) {
    final object = _asObject(value, description);
    _expectKeys(object, const {'layers', 'missingFiles'}, description);
    final rawLayers = _readObject(object, 'layers', description);
    _expectKeys(rawLayers, policy.layers.keys.toSet(), '$description layers');
    final layers = <String, _LayerSnapshot>{};
    for (final entry in rawLayers.entries) {
      layers[entry.key] = _LayerSnapshot.parse(
        entry.value,
        '$description layer ${entry.key}',
      );
    }
    final missing = _readStringList(object, 'missingFiles', description);
    _requireUnique(missing, '$description missingFiles');
    final sorted = [...missing]..sort();
    if (!_sameList(missing, sorted)) {
      throw CoverageFailure('$description: missingFiles must be sorted.');
    }
    for (final path in missing) {
      _validatePolicyPath(path, '$description missing file');
      if (!path.startsWith('${policy.sourceRoot}/') ||
          !path.endsWith('.dart') ||
          policy.isExcluded(path)) {
        throw CoverageFailure(
          '$description: invalid missing source file: $path',
        );
      }
      policy.layerFor(path);
    }
    return _ScopeSnapshot(
      layers: Map.unmodifiable(layers),
      missingFiles: Set.unmodifiable(missing),
    );
  }

  final Map<String, _LayerSnapshot> layers;
  final Set<String> missingFiles;

  List<String> baselineDifferences(_ScopeSnapshot expected, String scopeName) {
    final failures = <String>[];
    for (final layerName in layers.keys) {
      final actual = layers[layerName]!;
      final baseline = expected.layers[layerName]!;
      failures.addAll(
        actual.baselineDifferences(baseline, '$scopeName/$layerName'),
      );
    }
    final newlyMissing = missingFiles.difference(expected.missingFiles);
    final unexpectedlyLoaded = expected.missingFiles.difference(missingFiles);
    if (newlyMissing.isNotEmpty) {
      failures.add(
        '$scopeName: source files newly absent from LCOV: '
        '${_sorted(newlyMissing)}',
      );
    }
    if (unexpectedlyLoaded.isNotEmpty) {
      failures.add(
        '$scopeName: coverage improved for previously missing files; review '
        'and refresh the baseline: ${_sorted(unexpectedlyLoaded)}',
      );
    }
    return failures;
  }

  List<String> ratchetDifferences(_ScopeSnapshot old, String scopeName) {
    final failures = <String>[];
    final oldNames = old.layers.keys.toSet();
    final currentNames = layers.keys.toSet();
    if (!_sameSet(oldNames, currentNames)) {
      failures.add('$scopeName: coverage layer set cannot change.');
      return failures;
    }
    for (final layerName in currentNames) {
      failures.addAll(
        layers[layerName]!.ratchetDifferences(
          old.layers[layerName]!,
          '$scopeName/$layerName',
        ),
      );
    }
    final newlyMissing = missingFiles.difference(old.missingFiles);
    if (newlyMissing.isNotEmpty) {
      failures.add(
        '$scopeName: the missing-source set may only shrink; added '
        '${_sorted(newlyMissing)}',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() => {
    'layers': {
      for (final name in layers.keys.toList()..sort())
        name: layers[name]!.toJson(),
    },
    'missingFiles': missingFiles.toList()..sort(),
  };
}

final class _LayerSnapshot {
  const _LayerSnapshot({required this.files, required this.lines});

  factory _LayerSnapshot.parse(Object? value, String description) {
    final object = _asObject(value, description);
    _expectKeys(object, const {'files', 'lines'}, description);
    return _LayerSnapshot(
      files: _Counts.parse(object['files'], '$description files'),
      lines: _Counts.parse(object['lines'], '$description lines'),
    );
  }

  final _Counts files;
  final _Counts lines;

  List<String> baselineDifferences(_LayerSnapshot expected, String name) => [
    ...files.baselineFailures(expected.files, '$name files'),
    ...lines.baselineFailures(expected.lines, '$name lines'),
  ];

  List<String> ratchetDifferences(_LayerSnapshot old, String name) => [
    ...files.ratchetFailures(old.files, '$name files'),
    ...lines.ratchetFailures(old.lines, '$name lines'),
  ];

  Map<String, Object?> toJson() => {
    'files': files.toJson(),
    'lines': lines.toJson(),
  };
}

final class _Counts {
  const _Counts({required this.hit, required this.found})
    : assert(hit >= 0),
      assert(found >= hit);

  factory _Counts.parse(Object? value, String description) {
    final object = _asObject(value, description);
    _expectKeys(object, const {'hit', 'found'}, description);
    final hit = _readInt(object, 'hit', description);
    final found = _readInt(object, 'found', description);
    if (hit < 0 || found < 0 || hit > found) {
      throw CoverageFailure(
        '$description: expected 0 <= hit <= found, got $hit/$found.',
      );
    }
    return _Counts(hit: hit, found: found);
  }

  final int hit;
  final int found;

  int get uncovered => found - hit;

  _Counts operator +(_Counts other) =>
      _Counts(hit: hit + other.hit, found: found + other.found);

  List<String> baselineFailures(_Counts expected, String name) {
    final failures = <String>[];
    if (found != expected.found) {
      failures.add(
        '$name total changed: ${expected.found} -> $found. Review the '
        'instrumentation change and refresh the baseline.',
      );
    }
    if (hit < expected.hit) {
      failures.add('$name covered count regressed: ${expected.hit} -> $hit.');
    }
    return failures;
  }

  List<String> ratchetFailures(_Counts old, String name) {
    final failures = <String>[];
    if (hit * old.found < old.hit * found) {
      failures.add('$name ratio decreased: $old -> $this.');
    }
    if (uncovered > old.uncovered) {
      failures.add(
        '$name uncovered count increased: ${old.uncovered} -> $uncovered.',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() => {'hit': hit, 'found': found};

  @override
  bool operator ==(Object other) =>
      other is _Counts && hit == other.hit && found == other.found;

  @override
  int get hashCode => Object.hash(hit, found);

  @override
  String toString() => '$hit/$found (${_formatPercent(this)})';
}

final class _DiffSnapshot {
  const _DiffSnapshot({
    required this.byLayer,
    required this.uncoveredByLayer,
    required this.structuralFailures,
  });

  final Map<String, _Counts> byLayer;
  final Map<String, List<String>> uncoveredByLayer;
  final List<String> structuralFailures;

  _Counts get total => byLayer.values.fold(
    const _Counts(hit: 0, found: 0),
    (total, value) => total + value,
  );

  List<String> failures(int minimumBasisPoints, String label) {
    final failures = [...structuralFailures];
    for (final layerName in byLayer.keys.toList()..sort()) {
      final counts = byLayer[layerName]!;
      if (!_meetsMinimum(counts, minimumBasisPoints)) {
        failures.add(
          '$label/$layerName line coverage is ${_formatPercent(counts)}; '
          'minimum is ${_formatBasisPoints(minimumBasisPoints)}; uncovered '
          '${_formatLocations(uncoveredByLayer[layerName] ?? const [])}.',
        );
      }
    }
    if (total.found > 0 && !_meetsMinimum(total, minimumBasisPoints)) {
      failures.add(
        '$label/overall line coverage is ${_formatPercent(total)}; minimum is '
        '${_formatBasisPoints(minimumBasisPoints)}.',
      );
    }
    return failures;
  }

  static bool _meetsMinimum(_Counts counts, int minimumBasisPoints) =>
      counts.found == 0 ||
      counts.hit * 10000 >= minimumBasisPoints * counts.found;
}

final class _LcovRecord {
  const _LcovRecord({required this.source, required this.lineHits});

  final String source;
  final Map<int, int> lineHits;

  _LcovRecord withSource(String value) =>
      _LcovRecord(source: value, lineHits: lineHits);
}
