part of 'check_coverage.dart';

extension _CoverageGateMeasurement on _CoverageGate {
  _ScopeSnapshot _measureScope(String name, _ScopePolicy scope) {
    final sources = _sourceFiles(scope);
    _validateExclusions(name, scope, sources);
    final records = _loadLcov(scope, sources);
    final scorable = _coverableFiles(sources, records, options, scope);
    final layersByFile = <String, String>{};
    for (final path in scorable) {
      final layer = scope.layerFor(path);
      layersByFile[path] = layer;
      final contents = File(
        _resolvePath(options.repository, path),
      ).readAsStringSync();
      if (contents.contains(_coverageIgnoreMarker)) {
        throw CoverageFailure(
          '$name: handwritten source uses a coverage ignore marker: $path',
        );
      }
    }

    final missingFiles = scorable.difference(records.keys.toSet());
    final layers = <String, _LayerSnapshot>{};
    for (final layerName in scope.layers.keys) {
      final files = layersByFile.entries
          .where((entry) => entry.value == layerName)
          .map((entry) => entry.key)
          .toSet();
      if (files.isEmpty) {
        throw CoverageFailure('$name/$layerName: layer has no source files.');
      }
      var filesHit = 0;
      var linesFound = 0;
      var linesHit = 0;
      for (final path in files) {
        final record = records[path];
        if (record == null) continue;
        final hitLines = record.lineHits.values
            .where((hits) => hits > 0)
            .length;
        if (hitLines > 0) filesHit++;
        linesFound += record.lineHits.length;
        linesHit += hitLines;
      }
      layers[layerName] = _LayerSnapshot(
        files: _Counts(hit: filesHit, found: files.length),
        lines: _Counts(hit: linesHit, found: linesFound),
      );
    }

    return _ScopeSnapshot(layers: layers, missingFiles: missingFiles);
  }

  Set<String> _sourceFiles(_ScopePolicy scope) {
    final result = _git([
      'ls-files',
      '--cached',
      '--others',
      '--exclude-standard',
      '--',
      scope.sourceRoot,
    ]);
    final files = result.stdout
        .split('\n')
        .where((path) => path.endsWith('.dart'))
        .map(_normalizeRelativePath)
        .toSet();
    final deleted = _git(['ls-files', '--deleted', '--', scope.sourceRoot])
        .stdout
        .split('\n')
        .where((path) => path.endsWith('.dart'))
        .map(_normalizeRelativePath)
        .toSet();
    files.removeAll(deleted);
    if (files.isEmpty) {
      throw CoverageFailure(
        '${scope.sourceRoot}: no non-ignored Dart source files found.',
      );
    }
    return files;
  }

  void _validateExclusions(
    String scopeName,
    _ScopePolicy scope,
    Set<String> sources,
  ) {
    for (final path in scope.excludeFiles) {
      if (!sources.contains(path)) {
        throw CoverageFailure('$scopeName: stale excluded file: $path');
      }
      _validateManualExclusion(scopeName, path);
    }
    for (final prefix in scope.excludePrefixes) {
      if (!sources.any((path) => path.startsWith(prefix))) {
        throw CoverageFailure('$scopeName: stale excluded prefix: $prefix');
      }
    }
    for (final path in sources.where(scope.isGenerated)) {
      _validateGeneratedSource(scopeName, path);
    }
  }

  void _validateManualExclusion(String scopeName, String path) {
    if (path != 'lib/main.dart') {
      throw CoverageFailure(
        '$scopeName: unsupported handwritten coverage exclusion: $path',
      );
    }
    final expected = File(
      _resolvePath(options.repository, 'tool/coverage_gate/main.dart.txt'),
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final contents = File(
      _resolvePath(options.repository, path),
    ).readAsStringSync().replaceAll('\r\n', '\n');
    if (contents != expected) {
      throw CoverageFailure(
        '$scopeName: lib/main.dart is excluded only while it remains the '
        'canonical thin composition root.',
      );
    }
  }

  void _validateGeneratedSource(String scopeName, String path) {
    final file = File(_resolvePath(options.repository, path));
    final firstLine = file.openSync()..setPositionSync(0);
    final header = utf8
        .decode(firstLine.readSync(96), allowMalformed: true)
        .split('\n')
        .first
        .trimRight();
    firstLine.closeSync();

    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      final suffix = path.endsWith('.freezed.dart')
          ? '.freezed.dart'
          : '.g.dart';
      final input = '${path.substring(0, path.length - suffix.length)}.dart';
      if (header == '// GENERATED CODE - DO NOT MODIFY BY HAND' &&
          File(_resolvePath(options.repository, input)).existsSync()) {
        return;
      }
      throw CoverageFailure(
        '$scopeName: generated suffix requires the canonical build_runner '
        'header and sibling input: $path',
      );
    }
    if (path.startsWith('server/lib/src/generated/')) {
      if (header == '/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */') {
        return;
      }
      throw CoverageFailure(
        '$scopeName: Serverpod generated path has no canonical header: $path',
      );
    }
    if (path.startsWith('lib/l10n/generated/')) {
      final basename = path.substring('lib/l10n/generated/'.length);
      if (basename == 'app_localizations.dart') return;
      final match = RegExp(
        r'^app_localizations_(.+)\.dart$',
      ).firstMatch(basename);
      if (match != null) {
        final arbPath = 'lib/l10n/app_${match.group(1)}.arb';
        if (File(_resolvePath(options.repository, arbPath)).existsSync()) {
          return;
        }
      }
      throw CoverageFailure(
        '$scopeName: localization output has no matching ARB input: $path',
      );
    }
    throw CoverageFailure(
      '$scopeName: unsupported generated-code exclusion: $path',
    );
  }

  Map<String, _LcovRecord> _loadLcov(_ScopePolicy scope, Set<String> sources) {
    final path = _resolvePath(options.repository, scope.lcovPath);
    final rawRecords = _LcovParser.parse(File(path));
    final records = <String, _LcovRecord>{};
    for (final rawRecord in rawRecords) {
      final normalized = scope.normalizeLcovPath(
        rawRecord.source,
        options.repository,
      );
      if (!normalized.startsWith('${scope.sourceRoot}/')) {
        throw CoverageFailure(
          '${scope.lcovPath}: LCOV record is outside ${scope.sourceRoot}: '
          '$normalized',
        );
      }
      if (!sources.contains(normalized)) {
        throw CoverageFailure(
          '${scope.lcovPath}: LCOV references a non-source or stale file: '
          '$normalized',
        );
      }
      final sourceLineCount = File(
        _resolvePath(options.repository, normalized),
      ).readAsLinesSync().length;
      final outOfRangeLines =
          rawRecord.lineHits.keys
              .where((line) => line > sourceLineCount)
              .toList()
            ..sort();
      if (outOfRangeLines.isNotEmpty) {
        throw CoverageFailure(
          '${scope.lcovPath}: LCOV references lines outside $normalized '
          '($sourceLineCount lines): ${outOfRangeLines.join(', ')}',
        );
      }
      if (records.containsKey(normalized)) {
        throw CoverageFailure(
          '${scope.lcovPath}: duplicate normalized SF record: $normalized',
        );
      }
      records[normalized] = rawRecord.withSource(normalized);
    }
    if (records.isEmpty) {
      throw CoverageFailure(
        '${scope.lcovPath}: no records belong to ${scope.sourceRoot}.',
      );
    }
    return records;
  }

  _DiffSnapshot _measureDiff(
    String scopeName,
    _ScopePolicy scope,
    String baseRef,
    String label, {
    required Set<String> acknowledgedMissingFiles,
  }) {
    final sources = _sourceFiles(scope);
    final records = _loadLcov(scope, sources);
    final coverable = _coverableFiles(sources, records, options);
    final measurement = measureCoverageDiff(
      repository: options.repository,
      scopeName: scopeName,
      label: label,
      changedLines: _changedLines(scope, baseRef),
      sources: coverable,
      lineHitsByPath: {
        for (final entry in records.entries) entry.key: entry.value.lineHits,
      },
      isExcluded: scope.isExcluded,
      layerFor: scope.layerFor,
      acknowledgedMissingFiles: acknowledgedMissingFiles,
    );
    return _DiffSnapshot(
      byLayer: {
        for (final entry in measurement.byLayer.entries)
          entry.key: _Counts(hit: entry.value.hit, found: entry.value.found),
      },
      uncoveredByLayer: measurement.uncoveredByLayer,
      structuralFailures: measurement.structuralFailures,
    );
  }

  Map<String, Set<int>> _changedLines(_ScopePolicy scope, String baseRef) {
    final result = _git([
      'diff',
      '--unified=0',
      '--no-color',
      '--no-ext-diff',
      '--no-renames',
      '--diff-filter=AM',
      baseRef,
      '--',
      scope.sourceRoot,
    ]);
    final changed = <String, Set<int>>{};
    String? currentPath;
    final hunkPattern = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@');
    for (final line in const LineSplitter().convert(result.stdout)) {
      if (line.startsWith('diff --git ')) {
        currentPath = null;
        continue;
      }
      if (line.startsWith('+++ b/')) {
        currentPath = _normalizeRelativePath(line.substring(6));
        continue;
      }
      if (line.startsWith('+++ ') && line != '+++ /dev/null') {
        throw CoverageFailure('Unsupported quoted Git diff path: $line');
      }
      final match = hunkPattern.firstMatch(line);
      if (match == null || currentPath == null) continue;
      final start = int.parse(match.group(1)!);
      final count = int.parse(match.group(2) ?? '1');
      final lines = changed.putIfAbsent(currentPath, () => <int>{});
      for (var offset = 0; offset < count; offset++) {
        lines.add(start + offset);
      }
    }

    final untracked = _git([
      'ls-files',
      '--others',
      '--exclude-standard',
      '--',
      scope.sourceRoot,
    ]);
    for (final rawPath in untracked.stdout.split('\n')) {
      if (!rawPath.endsWith('.dart')) continue;
      final path = _normalizeRelativePath(rawPath);
      final lineCount = File(
        _resolvePath(options.repository, path),
      ).readAsLinesSync().length;
      changed[path] = {for (var line = 1; line <= lineCount; line++) line};
    }
    return changed;
  }
}
