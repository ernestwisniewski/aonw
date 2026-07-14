import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';

import 'baseline.dart';
import 'discoverer.dart';
import 'failure.dart';
import 'mutant.dart';
import 'policy.dart';
import 'test_process.dart';
import 'workspace.dart';

final class MutationExecutor {
  const MutationExecutor({
    MutationTestProcessRunner processRunner = const MutationTestProcessRunner(),
    MutationSourceAnalyzer sourceAnalyzer = const MutationSourceAnalyzer(),
  }) : _processRunner = processRunner,
       _sourceAnalyzer = sourceAnalyzer;

  final MutationTestProcessRunner _processRunner;
  final MutationSourceAnalyzer _sourceAnalyzer;

  Future<MutationBaseline> execute({
    required MutationPolicy policy,
    required MutationWorkspace workspace,
  }) async {
    final timeout = Duration(seconds: policy.perMutantTimeoutSeconds);
    final scopes = <String, MutationScopeBaseline>{};
    for (final entry in policy.scopes.entries) {
      final scopeName = entry.key;
      final scope = entry.value;
      stderr.writeln('Mutation scope $scopeName: validating baseline tests.');
      workspace
        ..resetRuntimeState()
        ..assertControlledTreeClean();
      late final MutationTestOutcome baselineOutcome;
      try {
        baselineOutcome = await _processRunner.runScope(
          scope: scope,
          workspaceRoot: workspace.root,
          timeout: timeout,
          description: '$scopeName unmodified baseline',
        );
      } finally {
        _finishTestRun(workspace);
      }
      if (baselineOutcome != MutationTestOutcome.passed) {
        throw MutationFailure(
          '$scopeName unmodified baseline tests must pass before mutation.',
        );
      }
      scopes[scopeName] = await _executeScope(
        scopeName: scopeName,
        scope: scope,
        policy: policy,
        workspace: workspace,
        timeout: timeout,
      );
    }
    return MutationBaseline(scopes: scopes);
  }

  Future<MutationScopeBaseline> _executeScope({
    required String scopeName,
    required MutationScopePolicy scope,
    required MutationPolicy policy,
    required MutationWorkspace workspace,
    required Duration timeout,
  }) async {
    final targets = <String, int>{};
    final operatorTotals = {for (final name in policy.operators) name: 0};
    final originals = <String, String>{};
    final mutants = <Mutant>[];
    for (final path in scope.targetFiles) {
      final file = File(_resolve(workspace.root, path));
      final original = _readSource(file, '$scopeName target $path');
      originals[path] = original;
      late final List<Mutant> discovered;
      try {
        discovered = discoverMutants(path: path, content: original);
      } on Object catch (error) {
        throw MutationFailure(
          '$scopeName could not discover mutants in $path: $error',
        );
      }
      if (discovered.isEmpty) {
        throw MutationFailure(
          '$scopeName target produced no mutants and would create a vacuous '
          'gate: $path',
        );
      }
      for (final mutant in discovered) {
        if (!policy.operators.contains(mutant.operator)) {
          throw MutationFailure(
            '$scopeName discovered unsupported operator '
            '${mutant.operator} in ${mutant.id}.',
          );
        }
        operatorTotals[mutant.operator] = operatorTotals[mutant.operator]! + 1;
      }
      targets[path] = discovered.length;
      mutants.addAll(discovered);
    }
    mutants.sort();
    final duplicateIds = _duplicates(mutants.map((mutant) => mutant.id));
    if (duplicateIds.isNotEmpty) {
      throw MutationFailure(
        '$scopeName discovered duplicate mutation IDs: $duplicateIds',
      );
    }
    stderr.writeln(
      'Mutation scope $scopeName: executing ${mutants.length} mutants.',
    );

    final survivors = <String, MutationSurvivor>{};
    for (var index = 0; index < mutants.length; index += 1) {
      final mutant = mutants[index];
      final outcome = await _executeMutant(
        scopeName: scopeName,
        scope: scope,
        workspace: workspace,
        mutant: mutant,
        original: originals[mutant.path]!,
        timeout: timeout,
      );
      if (outcome == MutationTestOutcome.passed) {
        survivors[mutant.id] = MutationSurvivor(
          path: mutant.path,
          operator: mutant.operator,
          declaration: mutant.declaration,
          original: mutant.original,
          replacement: mutant.replacement,
        );
      }
      final completed = index + 1;
      if (completed == mutants.length || completed % 10 == 0) {
        stderr.writeln(
          'Mutation scope $scopeName: $completed/${mutants.length}, '
          '${survivors.length} survivors.',
        );
      }
    }
    return MutationScopeBaseline(
      targets: targets,
      operatorTotals: operatorTotals,
      survivors: survivors,
    );
  }

  Future<MutationTestOutcome> _executeMutant({
    required String scopeName,
    required MutationScopePolicy scope,
    required MutationWorkspace workspace,
    required Mutant mutant,
    required String original,
    required Duration timeout,
  }) async {
    final file = File(_resolve(workspace.root, mutant.path));
    workspace
      ..resetRuntimeState()
      ..assertControlledTreeClean();
    final before = _readSource(file, mutant.id);
    if (before != original) {
      throw MutationFailure(
        '${mutant.id} target drifted before mutation; source restoration '
        'from an earlier mutant was incomplete.',
      );
    }
    late final String mutated;
    try {
      mutated = mutant.apply(original);
    } on Object catch (error) {
      throw MutationFailure('${mutant.id} could not be applied: $error');
    }

    var attemptedWrite = false;
    try {
      attemptedWrite = true;
      _writeSource(file, mutated, mutant.id);
      final applied = _readSource(file, mutant.id);
      mutant.validateApplied(applied);
      if (applied != mutated) {
        throw MutationFailure(
          '${mutant.id} changed bytes outside its declared source edit.',
        );
      }
      await _sourceAnalyzer.validate(path: file.path, description: mutant.id);
      return await _processRunner.runScope(
        scope: scope,
        workspaceRoot: workspace.root,
        timeout: timeout,
        description: '$scopeName mutant ${mutant.id}',
      );
    } finally {
      if (attemptedWrite) {
        _restoreSource(
          workspace: workspace,
          file: file,
          mutant: mutant,
          mutated: mutated,
          original: original,
        );
        _finishTestRun(workspace);
      }
    }
  }
}

void _finishTestRun(MutationWorkspace workspace) {
  workspace
    ..assertControlledTreeClean()
    ..resetRuntimeState();
}

final class MutationSourceAnalyzer {
  const MutationSourceAnalyzer({this.sdkPath});

  final String? sdkPath;

  Future<void> validate({
    required String path,
    required String description,
  }) async {
    final absolute = File(path).absolute.path;
    AnalysisContextCollection? collection;
    try {
      collection = AnalysisContextCollection(
        includedPaths: [absolute],
        sdkPath: sdkPath ?? _locateDartSdk(),
      );
      final context = collection.contextFor(absolute);
      final result = await context.currentSession.getErrors(absolute);
      if (result is! ErrorsResult) {
        throw MutationFailure(
          '$description could not be analyzed by Analyzer 12.1: '
          '${result.runtimeType}.',
        );
      }
      final errors = result.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.diagnosticCode.severity == DiagnosticSeverity.ERROR,
          )
          .toList();
      if (errors.isNotEmpty) {
        final details = errors
            .map(
              (diagnostic) =>
                  '${diagnostic.diagnosticCode.lowerCaseUniqueName}@'
                  '${diagnostic.offset}: ${diagnostic.message}',
            )
            .join('\n');
        throw MutationFailure(
          '$description produced Analyzer ERROR diagnostics:\n$details',
        );
      }
    } on MutationFailure {
      rethrow;
    } on Object catch (error) {
      throw MutationFailure(
        '$description could not be checked by Analyzer 12.1: $error',
      );
    } finally {
      await collection?.dispose();
    }
  }
}

String _locateDartSdk() {
  final candidates = <String?>[
    _sdkForExecutable(Platform.resolvedExecutable),
    Platform.environment['FLUTTER_ROOT'] == null
        ? null
        : '${Platform.environment['FLUTTER_ROOT']}'
              '${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
              '${Platform.pathSeparator}dart-sdk',
  ];
  final locator = Process.runSync(
    Platform.isWindows ? 'where' : 'which',
    ['dart'],
    stdoutEncoding: systemEncoding,
    stderrEncoding: systemEncoding,
  );
  if (locator.exitCode == 0) {
    final executable = (locator.stdout as String)
        .split(RegExp(r'\r?\n'))
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '')
        .trim();
    if (executable.isNotEmpty) {
      candidates.add(_sdkForExecutable(executable));
    }
  }
  for (final candidate in candidates.whereType<String>()) {
    if (_isDartSdk(candidate)) return candidate;
  }
  throw const MutationFailure(
    'Could not locate the Dart SDK required by Analyzer 12.1.',
  );
}

String? _sdkForExecutable(String executable) {
  final file = File(executable).absolute;
  final standard = file.parent.parent.path;
  if (_isDartSdk(standard)) return standard;
  final flutterCache =
      '${file.parent.path}${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}dart-sdk';
  if (_isDartSdk(flutterCache)) return flutterCache;
  return null;
}

bool _isDartSdk(String path) => File(
  '$path${Platform.pathSeparator}lib${Platform.pathSeparator}_internal'
  '${Platform.pathSeparator}sdk_library_metadata'
  '${Platform.pathSeparator}lib${Platform.pathSeparator}libraries.dart',
).existsSync();

String _readSource(File file, String description) {
  if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw MutationFailure('$description must be a regular source file.');
  }
  try {
    return utf8.decode(file.readAsBytesSync(), allowMalformed: false);
  } on FileSystemException catch (error) {
    throw MutationFailure('$description could not be read: $error');
  } on FormatException catch (error) {
    throw MutationFailure('$description is not valid UTF-8: $error');
  }
}

void _writeSource(File file, String contents, String description) {
  try {
    file.writeAsBytesSync(utf8.encode(contents), flush: true);
  } on FileSystemException catch (error) {
    throw MutationFailure(
      '$description could not write mutated source: $error',
    );
  }
}

void _restoreSource({
  required MutationWorkspace workspace,
  required File file,
  required Mutant mutant,
  required String mutated,
  required String original,
}) {
  try {
    workspace.requireControlledRegularFile(mutant.path, mutant.id);
    final current = _readSource(file, mutant.id);
    mutant.validateApplied(current);
    if (current != mutated) {
      throw MutationFailure(
        '${mutant.id} source changed outside the declared mutation before '
        'restore.',
      );
    }
  } on Object catch (error) {
    throw MutationFailure(
      '${mutant.id} could not validate mutated source before restore: $error',
    );
  }

  try {
    _replaceSourceAtomically(
      workspace: workspace,
      file: file,
      repositoryPath: mutant.path,
      contents: original,
      description: '${mutant.id} restore',
    );
    final restored = _readSource(file, '${mutant.id} restore');
    mutant.validateOriginal(restored);
    if (restored != original) {
      throw MutationFailure(
        '${mutant.id} restore did not reproduce the original source exactly.',
      );
    }
  } on Object catch (error) {
    throw MutationFailure('${mutant.id} source restore failed: $error');
  }
}

void _replaceSourceAtomically({
  required MutationWorkspace workspace,
  required File file,
  required String repositoryPath,
  required String contents,
  required String description,
}) {
  workspace.requireControlledRegularFile(repositoryPath, description);
  final temporary = File(
    '${file.path}.mutation-restore-$pid-'
    '${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    temporary
      ..createSync(exclusive: true)
      ..writeAsBytesSync(utf8.encode(contents), flush: true);
    if (FileSystemEntity.typeSync(temporary.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw MutationFailure('$description temporary source is not regular.');
    }
    workspace.requireControlledRegularFile(repositoryPath, description);
    temporary.renameSync(file.path);
    workspace.requireControlledRegularFile(repositoryPath, description);
  } on FileSystemException catch (error) {
    throw MutationFailure('$description could not replace source: $error');
  } finally {
    if (FileSystemEntity.typeSync(temporary.path, followLinks: false) ==
        FileSystemEntityType.file) {
      temporary.deleteSync();
    }
  }
}

List<String> _duplicates(Iterable<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    if (!seen.add(value)) duplicates.add(value);
  }
  return duplicates.toList()..sort();
}

String _resolve(String root, String repositoryPath) =>
    '$root${Platform.pathSeparator}'
    '${repositoryPath.replaceAll('/', Platform.pathSeparator)}';
