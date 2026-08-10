import 'dart:convert';
import 'dart:io';

import 'coverage_gate/coverable_source.dart';
import 'coverage_gate/coverage_failure.dart';
import 'coverage_gate/diff_measurement.dart';
import 'coverage_gate/ratchet_epoch.dart';

part 'check_coverage_gate.dart';
part 'check_coverage_gate_measurement.dart';
part 'check_coverage_gate_git.dart';
part 'check_coverage_policy.dart';
part 'check_coverage_models.dart';
part 'check_coverage_support.dart';

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
  } on CoverageFailure catch (error) {
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

List<String> _scopeNames(_CoveragePolicy policy, Set<String> requested) {
  final selected = requested.isEmpty ? policy.scopes.keys.toSet() : requested;
  final unknown = selected.difference(policy.scopes.keys.toSet());
  if (unknown.isEmpty) return selected.toList()..sort();
  throw CoverageFailure('Unknown coverage scopes: ${_sorted(unknown)}');
}

Set<String> _coverableFiles(
  Set<String> sources,
  Map<String, _LcovRecord> records,
  _CliOptions options, [
  _ScopePolicy? scope,
]) => retainCoverable(
  sources.where((path) => !(scope?.isExcluded(path) ?? false)),
  recorded: records.keys.toSet(),
  resolve: (path) => _resolvePath(options.repository, path),
);

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
      throw const CoverageFailure(
        'Usage: dart run tool/check_coverage.dart <check|snapshot> '
        '[--scope NAME] [--base-ref REF] [--ratchet-ref REF]',
      );
    }

    final command = switch (arguments.first) {
      'check' => _Command.check,
      'snapshot' => _Command.snapshot,
      final value => throw CoverageFailure('Unknown command: $value'),
    };
    var repository = Directory.current.absolute.path;
    var policyPath = _defaultPolicyPath;
    var baselinePath = _defaultBaselinePath;
    String? baseRef, ratchetRef;
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
        throw CoverageFailure('Missing value for $name.');
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
        throw CoverageFailure('Unknown argument: $argument');
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
      throw CoverageFailure(
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
        throw CoverageFailure(
          '$description: excluded prefix must be inside sourceRoot and end '
          'with /: $prefix',
        );
      }
    }
    for (final file in excludeFiles) {
      _validatePolicyPath(file, '$description excluded file');
      if (!file.endsWith('.dart') || !file.startsWith('$sourceRoot/')) {
        throw CoverageFailure(
          '$description: excluded file must be a Dart file inside sourceRoot: '
          '$file',
        );
      }
    }

    final rawLayers = _readObject(object, 'layers', description);
    if (rawLayers.isEmpty) {
      throw CoverageFailure('$description: layers cannot be empty.');
    }
    final layers = <String, List<String>>{};
    final allPatterns = <String>[];
    for (final entry in rawLayers.entries) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.key)) {
        throw CoverageFailure('$description: invalid layer name: ${entry.key}');
      }
      final patterns = _asStringList(
        entry.value,
        '$description layer ${entry.key}',
      );
      if (patterns.isEmpty) {
        throw CoverageFailure(
          '$description: layer ${entry.key} has no path patterns.',
        );
      }
      _requireUnique(patterns, '$description layer ${entry.key}');
      for (final pattern in patterns) {
        _validatePolicyPath(pattern, '$description layer pattern');
        final isDirectory = pattern.endsWith('/');
        final isFile = pattern.endsWith('.dart');
        if ((!isDirectory && !isFile) || !pattern.startsWith('$sourceRoot/')) {
          throw CoverageFailure(
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
      throw CoverageFailure(
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

abstract final class _LcovParser {
  static List<_LcovRecord> parse(File file) {
    if (!file.existsSync()) {
      throw CoverageFailure('LCOV report does not exist: ${file.path}');
    }
    final contents = file.readAsStringSync();
    if (contents.trim().isEmpty) {
      throw CoverageFailure('LCOV report is empty: ${file.path}');
    }

    final records = <_LcovRecord>[];
    final rawSources = <String>{};
    String? source;
    Map<int, int>? lineHits;
    int? declaredFound;
    int? declaredHit;

    void finishRecord(int lineNumber) {
      if (source == null || lineHits == null) {
        throw CoverageFailure(
          '${file.path}:$lineNumber: end_of_record without SF.',
        );
      }
      if (declaredFound == null || declaredHit == null) {
        throw CoverageFailure(
          '${file.path}:$lineNumber: record is missing LF or LH.',
        );
      }
      final computedFound = lineHits!.length;
      final computedHit = lineHits!.values.where((hits) => hits > 0).length;
      if (declaredFound != computedFound || declaredHit != computedHit) {
        throw CoverageFailure(
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
          throw CoverageFailure(
            '${file.path}:$lineNumber: SF before end_of_record.',
          );
        }
        final value = line.substring(3);
        if (value.isEmpty || !rawSources.add(value)) {
          throw CoverageFailure(
            '${file.path}:$lineNumber: empty or duplicate SF: $value',
          );
        }
        source = value;
        lineHits = <int, int>{};
      } else if (line.startsWith('DA:')) {
        if (lineHits == null || declaredFound != null || declaredHit != null) {
          throw CoverageFailure(
            '${file.path}:$lineNumber: DA appears outside the DA section.',
          );
        }
        final fields = line.substring(3).split(',');
        if (fields.length != 2) {
          throw CoverageFailure(
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
          throw CoverageFailure(
            '${file.path}:$lineNumber: invalid or duplicate DA record.',
          );
        }
        lineHits![sourceLine] = hits;
      } else if (line.startsWith('LF:')) {
        if (source == null ||
            lineHits == null ||
            declaredFound != null ||
            declaredHit != null) {
          throw CoverageFailure(
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
          throw CoverageFailure(
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
        throw CoverageFailure(
          '${file.path}:$lineNumber: unsupported LCOV directive: $line',
        );
      }
    }
    if (source != null) {
      throw CoverageFailure('${file.path}: missing end_of_record for $source.');
    }
    if (records.isEmpty) {
      throw CoverageFailure('${file.path}: contains no LCOV records.');
    }
    return records;
  }
}
