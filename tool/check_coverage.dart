import 'dart:convert';
import 'dart:io';

const _defaultPolicyPath = 'tool/coverage_policy.json';
const _defaultBaselinePath = 'tool/coverage_baseline.json';
const _coverageIgnoreMarker = 'coverage:ignore';

void main(List<String> arguments) {
  try {
    final options = _CliOptions.parse(arguments);
    final gate = _CoverageGate(options);
    switch (options.command) {
      case _Command.check:
        gate.check();
        return;
      case _Command.snapshot:
        stdout.writeln(gate.snapshotJson());
        return;
    }
  } on _CoverageFailure catch (error) {
    stderr.writeln('Coverage gate failed:\n${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Coverage gate failed:\n${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Coverage gate failed:\n$error');
    exitCode = 1;
  }
}

enum _Command { check, snapshot }

final class _CliOptions {
  const _CliOptions({
    required this.command,
    required this.repository,
    required this.policyPath,
    required this.baselinePath,
    required this.scopes,
    this.baseRef,
    this.ratchetRef,
  });

  factory _CliOptions.parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const _CoverageFailure(
        'Usage: dart run tool/check_coverage.dart <check|snapshot> '
        '[--scope NAME] [--base-ref REF] [--ratchet-ref REF]',
      );
    }

    final command = switch (arguments.first) {
      'check' => _Command.check,
      'snapshot' => _Command.snapshot,
      final value => throw _CoverageFailure('Unknown command: $value'),
    };
    var repository = Directory.current.absolute.path;
    var policyPath = _defaultPolicyPath;
    var baselinePath = _defaultBaselinePath;
    String? baseRef;
    String? ratchetRef;
    final scopes = <String>{};

    for (var index = 1; index < arguments.length; index++) {
      final argument = arguments[index];
      String readValue(String name) {
        if (argument.startsWith('$name=')) {
          return argument.substring(name.length + 1);
        }
        if (argument == name && index + 1 < arguments.length) {
          index++;
          return arguments[index];
        }
        throw _CoverageFailure('Missing value for $name.');
      }

      if (argument == '--scope' || argument.startsWith('--scope=')) {
        scopes.add(readValue('--scope'));
      } else if (argument == '--base-ref' ||
          argument.startsWith('--base-ref=')) {
        baseRef = readValue('--base-ref');
      } else if (argument == '--ratchet-ref' ||
          argument.startsWith('--ratchet-ref=')) {
        ratchetRef = readValue('--ratchet-ref');
      } else if (argument == '--repository' ||
          argument.startsWith('--repository=')) {
        repository = readValue('--repository');
      } else if (argument == '--policy' || argument.startsWith('--policy=')) {
        policyPath = readValue('--policy');
      } else if (argument == '--baseline' ||
          argument.startsWith('--baseline=')) {
        baselinePath = readValue('--baseline');
      } else {
        throw _CoverageFailure('Unknown argument: $argument');
      }
    }

    return _CliOptions(
      command: command,
      repository: Directory(repository).absolute.path,
      policyPath: policyPath,
      baselinePath: baselinePath,
      scopes: scopes,
      baseRef: baseRef,
      ratchetRef: ratchetRef,
    );
  }

  final _Command command;
  final String repository;
  final String policyPath;
  final String baselinePath;
  final Set<String> scopes;
  final String? baseRef;
  final String? ratchetRef;
}

final class _CoverageGate {
  _CoverageGate(this.options)
    : policy = _CoveragePolicy.load(
        _resolvePath(options.repository, options.policyPath),
      );

  final _CliOptions options;
  final _CoveragePolicy policy;

  void check() {
    final baseline = _CoverageBaseline.load(
      _resolvePath(options.repository, options.baselinePath),
      policy,
    );
    final scopeNames = _selectedScopeNames();
    final requestedBase = _requiredRef(options.baseRef, '--base-ref');
    final ratchetRef = _requiredRef(options.ratchetRef, '--ratchet-ref');
    final cumulativeBase = _effectiveDiffBase(requestedBase);
    final incrementalBase = _effectiveDiffBase(ratchetRef);
    _verifyHistoricalRatchet(baseline, scopeNames, ratchetRef);

    final failures = <String>[];
    final summaries = <String>[];
    for (final scopeName in scopeNames) {
      final scope = policy.scopes[scopeName]!;
      final actual = _measureScope(scopeName, scope);
      final expected = baseline.scopes[scopeName]!;
      failures.addAll(actual.baselineDifferences(expected, scopeName));

      final diffs = <String, ({String base, _DiffSnapshot snapshot})>{
        'diff': (
          base: cumulativeBase,
          snapshot: _measureDiff(scopeName, scope, cumulativeBase, 'diff'),
        ),
      };
      if (incrementalBase != cumulativeBase) {
        diffs['incremental diff'] = (
          base: incrementalBase,
          snapshot: _measureDiff(
            scopeName,
            scope,
            incrementalBase,
            'incremental diff',
          ),
        );
      }
      for (final entry in diffs.entries) {
        failures.addAll(
          entry.value.snapshot.failures(
            policy.diffLineMinimumBasisPoints,
            entry.key,
          ),
        );
      }
      summaries.add(_formatSummary(scopeName, actual, diffs));
    }

    if (failures.isNotEmpty) {
      throw _CoverageFailure(failures.join('\n'));
    }
    for (final summary in summaries) {
      stdout.writeln(summary);
    }
  }

  String snapshotJson() {
    final scopes = <String, Object?>{};
    for (final scopeName in _selectedScopeNames()) {
      scopes[scopeName] = _measureScope(
        scopeName,
        policy.scopes[scopeName]!,
      ).toJson();
    }
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'schema': 1, 'scopes': scopes});
  }

  List<String> _selectedScopeNames() {
    final selected = options.scopes.isEmpty
        ? policy.scopes.keys.toSet()
        : options.scopes;
    final unknown = selected.difference(policy.scopes.keys.toSet());
    if (unknown.isNotEmpty) {
      throw _CoverageFailure('Unknown coverage scopes: ${_sorted(unknown)}');
    }
    return selected.toList()..sort();
  }

  _ScopeSnapshot _measureScope(String name, _ScopePolicy scope) {
    final sources = _sourceFiles(scope);
    _validateExclusions(name, scope, sources);
    final scorable = sources.where((path) => !scope.isExcluded(path)).toSet();
    final layersByFile = <String, String>{};
    for (final path in scorable) {
      final layer = scope.layerFor(path);
      layersByFile[path] = layer;
      final contents = File(
        _resolvePath(options.repository, path),
      ).readAsStringSync();
      if (contents.contains(_coverageIgnoreMarker)) {
        throw _CoverageFailure(
          '$name: handwritten source uses a coverage ignore marker: $path',
        );
      }
    }

    final records = _loadLcov(scope, sources);
    final missingFiles = scorable.difference(records.keys.toSet());
    final layers = <String, _LayerSnapshot>{};
    for (final layerName in scope.layers.keys) {
      final files = layersByFile.entries
          .where((entry) => entry.value == layerName)
          .map((entry) => entry.key)
          .toSet();
      if (files.isEmpty) {
        throw _CoverageFailure('$name/$layerName: layer has no source files.');
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
      throw _CoverageFailure(
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
        throw _CoverageFailure('$scopeName: stale excluded file: $path');
      }
      _validateManualExclusion(scopeName, path);
    }
    for (final prefix in scope.excludePrefixes) {
      if (!sources.any((path) => path.startsWith(prefix))) {
        throw _CoverageFailure('$scopeName: stale excluded prefix: $prefix');
      }
    }
    for (final path in sources.where(scope.isGenerated)) {
      _validateGeneratedSource(scopeName, path);
    }
  }

  void _validateManualExclusion(String scopeName, String path) {
    if (path != 'lib/main.dart') {
      throw _CoverageFailure(
        '$scopeName: unsupported handwritten coverage exclusion: $path',
      );
    }
    const expected = """import 'package:aonw/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: HexApp()));
}
""";
    final contents = File(
      _resolvePath(options.repository, path),
    ).readAsStringSync().replaceAll('\r\n', '\n');
    if (contents != expected) {
      throw _CoverageFailure(
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
      throw _CoverageFailure(
        '$scopeName: generated suffix requires the canonical build_runner '
        'header and sibling input: $path',
      );
    }
    if (path.startsWith('server/lib/src/generated/')) {
      if (header == '/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */') {
        return;
      }
      throw _CoverageFailure(
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
      throw _CoverageFailure(
        '$scopeName: localization output has no matching ARB input: $path',
      );
    }
    throw _CoverageFailure(
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
        throw _CoverageFailure(
          '${scope.lcovPath}: LCOV record is outside ${scope.sourceRoot}: '
          '$normalized',
        );
      }
      if (!sources.contains(normalized)) {
        throw _CoverageFailure(
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
        throw _CoverageFailure(
          '${scope.lcovPath}: LCOV references lines outside $normalized '
          '($sourceLineCount lines): ${outOfRangeLines.join(', ')}',
        );
      }
      if (records.containsKey(normalized)) {
        throw _CoverageFailure(
          '${scope.lcovPath}: duplicate normalized SF record: $normalized',
        );
      }
      records[normalized] = rawRecord.withSource(normalized);
    }
    if (records.isEmpty) {
      throw _CoverageFailure(
        '${scope.lcovPath}: no records belong to ${scope.sourceRoot}.',
      );
    }
    return records;
  }

  _DiffSnapshot _measureDiff(
    String scopeName,
    _ScopePolicy scope,
    String baseRef,
    String label,
  ) {
    final changedLines = _changedLines(scope, baseRef);
    final sources = _sourceFiles(scope);
    final records = _loadLcov(scope, sources);
    final byLayer = <String, _Counts>{};
    final uncoveredByLayer = <String, Set<String>>{};
    final failures = <String>[];

    for (final entry in changedLines.entries) {
      final path = entry.key;
      if (!sources.contains(path) || scope.isExcluded(path)) continue;
      final layer = scope.layerFor(path);
      final record = records[path];
      if (record == null) {
        failures.add(
          '$scopeName $label: changed source is absent from LCOV: $path',
        );
        continue;
      }
      final coverable = entry.value.intersection(record.lineHits.keys.toSet());
      if (coverable.isEmpty) continue;
      final hit = coverable
          .where((line) => (record.lineHits[line] ?? 0) > 0)
          .length;
      for (final line in coverable) {
        if ((record.lineHits[line] ?? 0) == 0) {
          uncoveredByLayer
              .putIfAbsent(layer, () => <String>{})
              .add('$path:$line');
        }
      }
      byLayer.update(
        layer,
        (counts) => counts + _Counts(hit: hit, found: coverable.length),
        ifAbsent: () => _Counts(hit: hit, found: coverable.length),
      );
    }

    return _DiffSnapshot(
      byLayer: byLayer,
      uncoveredByLayer: {
        for (final entry in uncoveredByLayer.entries)
          entry.key: entry.value.toList()..sort(),
      },
      structuralFailures: failures,
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
        throw _CoverageFailure('Unsupported quoted Git diff path: $line');
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

  String _effectiveDiffBase(String requested) {
    final anchor = policy.enforcedSince;
    _requireCommit(anchor, 'coverage rollout anchor');
    _requireCommit(requested, 'coverage diff base');
    if (!_isAncestor(anchor, 'HEAD')) {
      throw _CoverageFailure(
        'Coverage rollout anchor $anchor is not an ancestor of HEAD.',
      );
    }
    final mergeBases = _git([
      'merge-base',
      '--all',
      requested,
      'HEAD',
    ]).stdout.split('\n').where((value) => value.isNotEmpty).toList();
    if (mergeBases.length != 1) {
      throw _CoverageFailure(
        'Expected exactly one merge base for $requested and HEAD, found '
        '${mergeBases.length}.',
      );
    }
    final mergeBase = mergeBases.single;
    if (_isAncestor(mergeBase, anchor)) return anchor;
    if (_isAncestor(anchor, mergeBase)) return mergeBase;
    throw _CoverageFailure(
      'Coverage diff base $mergeBase and rollout anchor $anchor are '
      'incomparable ancestors of HEAD.',
    );
  }

  void _verifyHistoricalRatchet(
    _CoverageBaseline current,
    List<String> scopeNames,
    String ratchetRef,
  ) {
    _requireCommit(ratchetRef, 'coverage ratchet ref');
    final baselinePath = _repositoryPath(options.baselinePath);
    final policyPath = _repositoryPath(options.policyPath);
    final oldBaselineText = _gitShow(ratchetRef, baselinePath);
    final oldPolicyText = _gitShow(ratchetRef, policyPath);
    if (oldBaselineText == null && oldPolicyText == null) {
      if (_isAncestor(ratchetRef, policy.enforcedSince)) return;
      throw _CoverageFailure(
        'Trusted ratchet ref $ratchetRef is newer than the rollout boundary '
        'but has no coverage policy or baseline.',
      );
    }
    if (oldBaselineText == null || oldPolicyText == null) {
      throw _CoverageFailure(
        'Trusted ratchet ref $ratchetRef must contain both $baselinePath and '
        '$policyPath.',
      );
    }

    final oldPolicy = _CoveragePolicy.parse(oldPolicyText, 'historical policy');
    if (oldPolicy.enforcedSince != policy.enforcedSince) {
      throw const _CoverageFailure(
        'coverage_policy.json enforcedSince is immutable.',
      );
    }
    if (oldPolicy.structuralSignature != policy.structuralSignature) {
      throw const _CoverageFailure(
        'Coverage scope, layer, and exclusion policy is immutable after the '
        'rollout anchor.',
      );
    }
    if (policy.diffLineMinimumBasisPoints <
        oldPolicy.diffLineMinimumBasisPoints) {
      throw _CoverageFailure(
        'Diff coverage minimum cannot decrease: '
        '${oldPolicy.diffLineMinimumPercent}% -> '
        '${policy.diffLineMinimumPercent}%.',
      );
    }

    final oldBaseline = _CoverageBaseline.parse(
      oldBaselineText,
      oldPolicy,
      'historical baseline',
    );
    final failures = <String>[];
    for (final scopeName in scopeNames) {
      final oldScope = oldBaseline.scopes[scopeName];
      final currentScope = current.scopes[scopeName];
      if (oldScope == null || currentScope == null) continue;
      failures.addAll(currentScope.ratchetDifferences(oldScope, scopeName));
    }
    if (failures.isNotEmpty) {
      throw _CoverageFailure(failures.join('\n'));
    }
  }

  String _repositoryPath(String path) {
    final absolute = _resolvePath(options.repository, path);
    return _relativeToRepository(options.repository, absolute);
  }

  String? _gitShow(String ref, String path) {
    final check = Process.runSync(
      'git',
      ['-C', options.repository, 'cat-file', '-e', '$ref:$path'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (check.exitCode != 0) return null;
    return _git(['show', '$ref:$path']).stdout;
  }

  bool _isAncestor(String ancestor, String descendant) {
    final result = Process.runSync(
      'git',
      [
        '-C',
        options.repository,
        'merge-base',
        '--is-ancestor',
        ancestor,
        descendant,
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode == 0) return true;
    if (result.exitCode == 1) return false;
    throw _CoverageFailure(
      'git merge-base failed: ${(result.stderr as String).trim()}',
    );
  }

  bool _commitExists(String ref) {
    final result = Process.runSync(
      'git',
      ['-C', options.repository, 'rev-parse', '--verify', '$ref^{commit}'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result.exitCode == 0;
  }

  void _requireCommit(String ref, String description) {
    if (!_commitExists(ref)) {
      throw _CoverageFailure('Unknown $description: $ref');
    }
  }

  _GitOutput _git(List<String> arguments) {
    final result = Process.runSync(
      'git',
      ['-C', options.repository, ...arguments],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw _CoverageFailure(
        'git ${arguments.join(' ')} failed:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    return _GitOutput(
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }
}

final class _CoveragePolicy {
  const _CoveragePolicy({
    required this.enforcedSince,
    required this.diffLineMinimumBasisPoints,
    required this.excludeSuffixes,
    required this.scopes,
    required this.structuralSignature,
  });

  factory _CoveragePolicy.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw _CoverageFailure('Coverage policy does not exist: $path');
    }
    return _CoveragePolicy.parse(file.readAsStringSync(), path);
  }

  factory _CoveragePolicy.parse(String contents, String description) {
    final root = _decodeObject(contents, description);
    _expectKeys(root, const {
      'schema',
      'enforcedSince',
      'diffLineMinimumBasisPoints',
      'excludeSuffixes',
      'scopes',
    }, description);
    final schema = _readInt(root, 'schema', description);
    if (schema != 1) {
      throw _CoverageFailure('$description: unsupported schema $schema.');
    }
    final enforcedSince = _readString(root, 'enforcedSince', description);
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(enforcedSince)) {
      throw _CoverageFailure(
        '$description: enforcedSince must be a full lowercase commit SHA.',
      );
    }
    final diffMinimum = _readInt(
      root,
      'diffLineMinimumBasisPoints',
      description,
    );
    if (diffMinimum < 0 || diffMinimum > 10000) {
      throw _CoverageFailure(
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
        throw _CoverageFailure(
          '$description: invalid excluded suffix: $suffix',
        );
      }
    }

    final rawScopes = _readObject(root, 'scopes', description);
    if (rawScopes.isEmpty) {
      throw _CoverageFailure('$description: scopes cannot be empty.');
    }
    final scopes = <String, _ScopePolicy>{};
    for (final entry in rawScopes.entries) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key)) {
        throw _CoverageFailure(
          '$description: invalid scope name: ${entry.key}',
        );
      }
      scopes[entry.key] = _ScopePolicy.parse(
        entry.value,
        '$description scope ${entry.key}',
        excludeSuffixes,
      );
    }

    final structuralJson = <String, Object?>{
      'schema': schema,
      'enforcedSince': enforcedSince,
      'excludeSuffixes': excludeSuffixes,
      'scopes': {
        for (final name in scopes.keys.toList()..sort())
          name: scopes[name]!.toJson(),
      },
    };
    return _CoveragePolicy(
      enforcedSince: enforcedSince,
      diffLineMinimumBasisPoints: diffMinimum,
      excludeSuffixes: List.unmodifiable(excludeSuffixes),
      scopes: Map.unmodifiable(scopes),
      structuralSignature: jsonEncode(structuralJson),
    );
  }

  final String enforcedSince;
  final int diffLineMinimumBasisPoints;
  final List<String> excludeSuffixes;
  final Map<String, _ScopePolicy> scopes;
  final String structuralSignature;

  String get diffLineMinimumPercent =>
      (diffLineMinimumBasisPoints / 100).toStringAsFixed(2);
}

final class _ScopePolicy {
  const _ScopePolicy({
    required this.packageRoot,
    required this.sourceRoot,
    required this.lcovPath,
    required this.excludePrefixes,
    required this.excludeFiles,
    required this.layers,
    required this.excludeSuffixes,
  });

  factory _ScopePolicy.parse(
    Object? value,
    String description,
    List<String> excludeSuffixes,
  ) {
    final object = _asObject(value, description);
    _expectKeys(object, const {
      'packageRoot',
      'sourceRoot',
      'lcov',
      'excludePrefixes',
      'excludeFiles',
      'layers',
    }, description);
    final packageRoot = _readString(object, 'packageRoot', description);
    final sourceRoot = _readString(object, 'sourceRoot', description);
    final lcovPath = _readString(object, 'lcov', description);
    _validatePolicyPath(
      packageRoot,
      '$description packageRoot',
      allowDot: true,
    );
    _validatePolicyPath(sourceRoot, '$description sourceRoot');
    _validatePolicyPath(lcovPath, '$description lcov');
    if (packageRoot != '.' &&
        sourceRoot != packageRoot &&
        !sourceRoot.startsWith('$packageRoot/')) {
      throw _CoverageFailure(
        '$description: sourceRoot must be inside packageRoot.',
      );
    }

    final excludePrefixes = _readStringList(
      object,
      'excludePrefixes',
      description,
    );
    final excludeFiles = _readStringList(object, 'excludeFiles', description);
    _requireUnique(excludePrefixes, '$description excludePrefixes');
    _requireUnique(excludeFiles, '$description excludeFiles');
    for (final prefix in excludePrefixes) {
      _validatePolicyPath(prefix, '$description excluded prefix');
      if (!prefix.endsWith('/') || !prefix.startsWith('$sourceRoot/')) {
        throw _CoverageFailure(
          '$description: excluded prefix must be inside sourceRoot and end '
          'with /: $prefix',
        );
      }
    }
    for (final file in excludeFiles) {
      _validatePolicyPath(file, '$description excluded file');
      if (!file.endsWith('.dart') || !file.startsWith('$sourceRoot/')) {
        throw _CoverageFailure(
          '$description: excluded file must be a Dart file inside sourceRoot: '
          '$file',
        );
      }
    }

    final rawLayers = _readObject(object, 'layers', description);
    if (rawLayers.isEmpty) {
      throw _CoverageFailure('$description: layers cannot be empty.');
    }
    final layers = <String, List<String>>{};
    final allPatterns = <String>[];
    for (final entry in rawLayers.entries) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key)) {
        throw _CoverageFailure(
          '$description: invalid layer name: ${entry.key}',
        );
      }
      final patterns = _asStringList(
        entry.value,
        '$description layer ${entry.key}',
      );
      if (patterns.isEmpty) {
        throw _CoverageFailure(
          '$description: layer ${entry.key} has no path patterns.',
        );
      }
      _requireUnique(patterns, '$description layer ${entry.key}');
      for (final pattern in patterns) {
        _validatePolicyPath(pattern, '$description layer pattern');
        final isDirectory = pattern.endsWith('/');
        final isFile = pattern.endsWith('.dart');
        if ((!isDirectory && !isFile) || !pattern.startsWith('$sourceRoot/')) {
          throw _CoverageFailure(
            '$description: layer pattern must be a Dart file or directory '
            'inside sourceRoot: $pattern',
          );
        }
      }
      allPatterns.addAll(patterns);
      layers[entry.key] = List.unmodifiable(patterns);
    }
    _requireUnique(allPatterns, '$description layer patterns');

    return _ScopePolicy(
      packageRoot: packageRoot,
      sourceRoot: sourceRoot,
      lcovPath: lcovPath,
      excludePrefixes: List.unmodifiable(excludePrefixes),
      excludeFiles: List.unmodifiable(excludeFiles),
      layers: Map.unmodifiable(layers),
      excludeSuffixes: excludeSuffixes,
    );
  }

  final String packageRoot;
  final String sourceRoot;
  final String lcovPath;
  final List<String> excludePrefixes;
  final List<String> excludeFiles;
  final Map<String, List<String>> layers;
  final List<String> excludeSuffixes;

  bool isExcluded(String path) =>
      excludeFiles.contains(path) || isGenerated(path);

  bool isGenerated(String path) =>
      excludePrefixes.any(path.startsWith) ||
      excludeSuffixes.any(path.endsWith);

  String layerFor(String path) {
    final matches = <String>[];
    for (final entry in layers.entries) {
      if (entry.value.any((pattern) => _matchesPattern(path, pattern))) {
        matches.add(entry.key);
      }
    }
    if (matches.length != 1) {
      throw _CoverageFailure(
        '$path must match exactly one coverage layer; matched '
        '${matches.isEmpty ? 'none' : matches.join(', ')}.',
      );
    }
    return matches.single;
  }

  String normalizeLcovPath(String rawPath, String repository) {
    final portablePath = rawPath.replaceAll('\\', '/');
    if (_isAbsolutePath(portablePath)) {
      return _relativeToRepository(repository, portablePath);
    }
    final path = _normalizeRelativePath(portablePath);
    if (path == sourceRoot || path.startsWith('$sourceRoot/')) return path;
    if (packageRoot != '.' && (path == 'lib' || path.startsWith('lib/'))) {
      return _normalizeRelativePath('$packageRoot/$path');
    }
    return path;
  }

  Map<String, Object?> toJson() => {
    'packageRoot': packageRoot,
    'sourceRoot': sourceRoot,
    'lcov': lcovPath,
    'excludePrefixes': excludePrefixes,
    'excludeFiles': excludeFiles,
    'layers': {
      for (final name in layers.keys.toList()..sort()) name: layers[name],
    },
  };

  static bool _matchesPattern(String path, String pattern) =>
      pattern.endsWith('/') ? path.startsWith(pattern) : path == pattern;
}

final class _CoverageBaseline {
  const _CoverageBaseline({required this.scopes});

  factory _CoverageBaseline.load(String path, _CoveragePolicy policy) {
    final file = File(path);
    if (!file.existsSync()) {
      throw _CoverageFailure(
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
      throw _CoverageFailure('$description: unsupported schema $schema.');
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
      throw _CoverageFailure('$description: missingFiles must be sorted.');
    }
    for (final path in missing) {
      _validatePolicyPath(path, '$description missing file');
      if (!path.startsWith('${policy.sourceRoot}/') ||
          !path.endsWith('.dart') ||
          policy.isExcluded(path)) {
        throw _CoverageFailure(
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
      throw _CoverageFailure(
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

abstract final class _LcovParser {
  static List<_LcovRecord> parse(File file) {
    if (!file.existsSync()) {
      throw _CoverageFailure('LCOV report does not exist: ${file.path}');
    }
    final contents = file.readAsStringSync();
    if (contents.trim().isEmpty) {
      throw _CoverageFailure('LCOV report is empty: ${file.path}');
    }

    final records = <_LcovRecord>[];
    final rawSources = <String>{};
    String? source;
    Map<int, int>? lineHits;
    int? declaredFound;
    int? declaredHit;

    void finishRecord(int lineNumber) {
      if (source == null || lineHits == null) {
        throw _CoverageFailure(
          '${file.path}:$lineNumber: end_of_record without SF.',
        );
      }
      if (declaredFound == null || declaredHit == null) {
        throw _CoverageFailure(
          '${file.path}:$lineNumber: record is missing LF or LH.',
        );
      }
      final computedFound = lineHits!.length;
      final computedHit = lineHits!.values.where((hits) => hits > 0).length;
      if (declaredFound != computedFound || declaredHit != computedHit) {
        throw _CoverageFailure(
          '${file.path}:$lineNumber: LF/LH do not match DA entries for '
          '$source (declared $declaredHit/$declaredFound, computed '
          '$computedHit/$computedFound).',
        );
      }
      records.add(
        _LcovRecord(source: source!, lineHits: Map.unmodifiable(lineHits!)),
      );
      source = null;
      lineHits = null;
      declaredFound = null;
      declaredHit = null;
    }

    final lines = const LineSplitter().convert(contents);
    for (var index = 0; index < lines.length; index++) {
      final lineNumber = index + 1;
      final line = lines[index];
      if (line.isEmpty) continue;
      if (line.startsWith('SF:')) {
        if (source != null) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: SF before end_of_record.',
          );
        }
        final value = line.substring(3);
        if (value.isEmpty || !rawSources.add(value)) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: empty or duplicate SF: $value',
          );
        }
        source = value;
        lineHits = <int, int>{};
      } else if (line.startsWith('DA:')) {
        if (lineHits == null || declaredFound != null || declaredHit != null) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: DA appears outside the DA section.',
          );
        }
        final fields = line.substring(3).split(',');
        if (fields.length != 2) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: malformed DA record.',
          );
        }
        final sourceLine = int.tryParse(fields[0]);
        final hits = int.tryParse(fields[1]);
        if (sourceLine == null ||
            sourceLine <= 0 ||
            hits == null ||
            hits < 0 ||
            lineHits!.containsKey(sourceLine)) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: invalid or duplicate DA record.',
          );
        }
        lineHits![sourceLine] = hits;
      } else if (line.startsWith('LF:')) {
        if (source == null ||
            lineHits == null ||
            declaredFound != null ||
            declaredHit != null) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: LF appears outside its record order.',
          );
        }
        declaredFound = _parseLcovCount(
          line.substring(3),
          file.path,
          lineNumber,
          'LF',
          declaredFound,
        );
      } else if (line.startsWith('LH:')) {
        if (source == null ||
            lineHits == null ||
            declaredFound == null ||
            declaredHit != null) {
          throw _CoverageFailure(
            '${file.path}:$lineNumber: LH appears outside its record order.',
          );
        }
        declaredHit = _parseLcovCount(
          line.substring(3),
          file.path,
          lineNumber,
          'LH',
          declaredHit,
        );
      } else if (line == 'end_of_record') {
        finishRecord(lineNumber);
      } else {
        throw _CoverageFailure(
          '${file.path}:$lineNumber: unsupported LCOV directive: $line',
        );
      }
    }
    if (source != null) {
      throw _CoverageFailure(
        '${file.path}: missing end_of_record for $source.',
      );
    }
    if (records.isEmpty) {
      throw _CoverageFailure('${file.path}: contains no LCOV records.');
    }
    return records;
  }
}

final class _GitOutput {
  const _GitOutput({required this.stdout, required this.stderr});

  final String stdout;
  final String stderr;
}

final class _CoverageFailure implements Exception {
  const _CoverageFailure(this.message);

  final String message;
}

String _formatSummary(
  String scopeName,
  _ScopeSnapshot snapshot,
  Map<String, ({String base, _DiffSnapshot snapshot})> diffs,
) {
  final buffer = StringBuffer('Coverage $scopeName:');
  for (final layerName in snapshot.layers.keys.toList()..sort()) {
    final layer = snapshot.layers[layerName]!;
    buffer.write('\n  $layerName: lines ${layer.lines}, files ${layer.files}');
  }
  buffer.write('\n  missing LCOV records: ${snapshot.missingFiles.length}');
  for (final entry in diffs.entries) {
    buffer.write(
      '\n  ${entry.key} (${entry.value.base}) changed coverable lines: '
      '${entry.value.snapshot.total}',
    );
  }
  return buffer.toString();
}

String _formatPercent(_Counts counts) => counts.found == 0
    ? 'n/a'
    : '${(counts.hit * 100 / counts.found).toStringAsFixed(2)}%';

String _formatBasisPoints(int basisPoints) =>
    '${(basisPoints / 100).toStringAsFixed(2)}%';

String _formatLocations(List<String> locations) {
  const limit = 50;
  if (locations.length <= limit) return locations.join(', ');
  return '${locations.take(limit).join(', ')} '
      '(and ${locations.length - limit} more)';
}

String _requiredRef(String? raw, String option) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || RegExp(r'^0+$').hasMatch(value)) {
    throw _CoverageFailure(
      'Coverage checks require $option. Use the Make targets, which choose '
      'local and CI refs explicitly.',
    );
  }
  return value;
}

int _parseLcovCount(
  String raw,
  String path,
  int lineNumber,
  String directive,
  int? previous,
) {
  final value = int.tryParse(raw);
  if (previous != null || value == null || value < 0) {
    throw _CoverageFailure(
      '$path:$lineNumber: invalid or duplicate $directive record.',
    );
  }
  return value;
}

Map<String, Object?> _decodeObject(String contents, String description) {
  try {
    return _asObject(jsonDecode(contents), description);
  } on FormatException catch (error) {
    throw _CoverageFailure('$description: invalid JSON: ${error.message}');
  }
}

Map<String, Object?> _asObject(Object? value, String description) {
  if (value is! Map<Object?, Object?>) {
    throw _CoverageFailure('$description must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw _CoverageFailure('$description contains a non-string key.');
    }
    result[key] = entry.value;
  }
  return result;
}

Map<String, Object?> _readObject(
  Map<String, Object?> object,
  String key,
  String description,
) => _asObject(object[key], '$description.$key');

String _readString(
  Map<String, Object?> object,
  String key,
  String description,
) {
  final value = object[key];
  if (value is! String || value.isEmpty) {
    throw _CoverageFailure('$description.$key must be a non-empty string.');
  }
  return value;
}

int _readInt(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! int) {
    throw _CoverageFailure('$description.$key must be an integer.');
  }
  return value;
}

List<String> _readStringList(
  Map<String, Object?> object,
  String key,
  String description,
) => _asStringList(object[key], '$description.$key');

List<String> _asStringList(Object? value, String description) {
  if (value is! List<Object?>) {
    throw _CoverageFailure('$description must be a JSON array.');
  }
  final result = <String>[];
  for (final entry in value) {
    if (entry is! String || entry.isEmpty) {
      throw _CoverageFailure('$description entries must be non-empty strings.');
    }
    result.add(entry);
  }
  return result;
}

void _expectKeys(
  Map<String, Object?> object,
  Set<String> expected,
  String description,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual);
  final extra = actual.difference(expected);
  if (missing.isNotEmpty || extra.isNotEmpty) {
    throw _CoverageFailure(
      '$description has invalid keys; missing [${_sorted(missing)}], extra '
      '[${_sorted(extra)}].',
    );
  }
}

void _requireUnique(Iterable<String> values, String description) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    if (!seen.add(value)) duplicates.add(value);
  }
  if (duplicates.isNotEmpty) {
    throw _CoverageFailure(
      '$description contains duplicates: ${_sorted(duplicates)}',
    );
  }
}

void _validatePolicyPath(
  String path,
  String description, {
  bool allowDot = false,
}) {
  if (allowDot && path == '.') return;
  if (_isAbsolutePath(path) ||
      path.contains('\\') ||
      path.startsWith('./') ||
      path.contains('//')) {
    throw _CoverageFailure('$description is not a canonical relative path.');
  }
  final withoutTrailingSlash = path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  _normalizeRelativePath(withoutTrailingSlash);
}

String _resolvePath(String repository, String path) {
  if (_isAbsolutePath(path)) return File(path).absolute.path;
  return File('$repository/$path').absolute.path;
}

String _relativeToRepository(String repository, String absolutePath) {
  final root = Directory(repository).absolute.path;
  final candidate = File(absolutePath).absolute.path;
  if (candidate == root) return '.';
  final prefix = '$root${Platform.pathSeparator}';
  if (!candidate.startsWith(prefix)) {
    throw _CoverageFailure('Path is outside the repository: $absolutePath');
  }
  return _normalizeRelativePath(
    candidate.substring(prefix.length).replaceAll(Platform.pathSeparator, '/'),
  );
}

String _normalizeRelativePath(String path) {
  if (path.isEmpty || _isAbsolutePath(path) || path.contains('\\')) {
    throw _CoverageFailure('Invalid relative path: $path');
  }
  final result = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      throw _CoverageFailure('Relative path escapes its root: $path');
    }
    result.add(segment);
  }
  if (result.isEmpty) {
    throw _CoverageFailure('Invalid relative path: $path');
  }
  return result.join('/');
}

bool _isAbsolutePath(String path) =>
    path.startsWith('/') || RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);

String _sorted(Iterable<String> values) {
  final sorted = values.toList()..sort();
  return sorted.join(', ');
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
