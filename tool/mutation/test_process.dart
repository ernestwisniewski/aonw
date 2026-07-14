import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'failure.dart';
import 'policy.dart';

part 'system_command_executor.dart';

enum MutationTestOutcome { passed, killed }

final class MutationProcessOutput {
  const MutationProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class MutationCommandExecutor {
  Future<MutationProcessOutput> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
    required String description,
  });
}

final class MutationTestProcessRunner {
  const MutationTestProcessRunner({
    MutationCommandExecutor commandExecutor =
        const SystemMutationCommandExecutor(),
  }) : _commandExecutor = commandExecutor;

  final MutationCommandExecutor _commandExecutor;

  Future<MutationTestOutcome> runScope({
    required MutationScopePolicy scope,
    required String workspaceRoot,
    required Duration timeout,
    String description = 'mutation test',
  }) async {
    final packageDirectory = _resolve(workspaceRoot, scope.packageRoot);
    final testFiles = scope.testFiles
        .map((path) => _packageRelative(path, scope.packageRoot))
        .toList(growable: false);
    final arguments = <String>[
      'test',
      if (scope.runner == 'flutter') '--no-pub',
      '--concurrency=1',
      '--test-randomize-ordering-seed=0',
      '--reporter=json',
      ...testFiles,
    ];
    final output = await _commandExecutor.run(
      executable: scope.runner,
      arguments: arguments,
      workingDirectory: packageDirectory,
      timeout: timeout,
      description: description,
    );
    return _classify(output, description);
  }
}

MutationTestOutcome _classify(
  MutationProcessOutput output,
  String description,
) {
  if (output.exitCode < 0 || output.exitCode > 1) {
    throw MutationFailure(
      '$description crashed with exit code ${output.exitCode}.'
      '${_outputContext(output)}',
    );
  }
  final events = _decodeEvents(output.stdout, description);
  final testNames = <int, String>{};
  final loadingTestIds = <int>{};
  final completedTestIds = <int>{};
  final failedTestIds = <int>{};
  var sawStart = false;
  bool? doneSuccess;
  for (final event in events) {
    final type = event['type'];
    if (type is! String) {
      throw MutationFailure('$description emitted a JSON event without type.');
    }
    if (!sawStart && type != 'start') {
      throw MutationFailure('$description emitted an event before start.');
    }
    if (doneSuccess != null) {
      throw MutationFailure('$description emitted an event after done.');
    }
    switch (type) {
      case 'start':
        if (sawStart) {
          throw MutationFailure('$description emitted duplicate start events.');
        }
        sawStart = true;
      case 'testStart':
        final test = event['test'];
        if (test is! Map<String, Object?> ||
            test['id'] is! int ||
            test['name'] is! String ||
            test['suiteID'] is! int ||
            test['groupIDs'] is! List<Object?> ||
            (test['groupIDs']! as List<Object?>).any(
              (groupId) => groupId is! int,
            )) {
          throw MutationFailure(
            '$description emitted a malformed testStart event.',
          );
        }
        final id = test['id']! as int;
        if (testNames.containsKey(id)) {
          throw MutationFailure('$description reused test id $id.');
        }
        testNames[id] = test['name']! as String;
        if ((test['groupIDs']! as List<Object?>).isEmpty) {
          loadingTestIds.add(id);
        }
      case 'testDone':
        final id = event['testID'];
        final result = event['result'];
        if (id is! int || result is! String || !testNames.containsKey(id)) {
          throw MutationFailure(
            '$description emitted a malformed testDone event.',
          );
        }
        if (!completedTestIds.add(id)) {
          throw MutationFailure('$description completed test id $id twice.');
        }
        if (result == 'failure' || result == 'error') {
          if (loadingTestIds.contains(id)) {
            throw MutationFailure(
              '$description failed while loading a test suite.'
              '${_outputContext(output)}',
            );
          }
          failedTestIds.add(id);
        } else if (result != 'success') {
          throw MutationFailure(
            '$description emitted unknown test result $result.',
          );
        }
      case 'error':
        final id = event['testID'];
        if (id is! int || !testNames.containsKey(id)) {
          throw MutationFailure(
            '$description emitted an error outside a known test.',
          );
        }
        if (loadingTestIds.contains(id)) {
          throw MutationFailure(
            '$description reported a suite-load error.'
            '${_outputContext(output)}',
          );
        }
      case 'done':
        final success = event['success'];
        if (success is! bool || doneSuccess != null) {
          throw MutationFailure('$description emitted a malformed done event.');
        }
        doneSuccess = success;
      default:
        // Other documented JSON reporter events do not affect classification.
        break;
    }
  }
  if (!sawStart || doneSuccess == null) {
    throw MutationFailure(
      '$description ended without a complete JSON test protocol.'
      '${_outputContext(output)}',
    );
  }
  if (completedTestIds.length != testNames.length) {
    final incomplete =
        testNames.keys.where((id) => !completedTestIds.contains(id)).toList()
          ..sort();
    throw MutationFailure(
      '$description ended before completing test IDs $incomplete.'
      '${_outputContext(output)}',
    );
  }
  if (testNames.keys.every(loadingTestIds.contains)) {
    throw MutationFailure(
      '$description did not execute any user tests.'
      '${_outputContext(output)}',
    );
  }
  if (failedTestIds.isNotEmpty) {
    if (doneSuccess != false || output.exitCode != 1) {
      throw MutationFailure(
        '$description reported failed tests with inconsistent completion.',
      );
    }
    return MutationTestOutcome.killed;
  }
  if (output.exitCode != 0 || doneSuccess != true) {
    throw MutationFailure(
      '$description exited with code ${output.exitCode} without a failed test.'
      '${_outputContext(output)}',
    );
  }
  return MutationTestOutcome.passed;
}

List<Map<String, Object?>> _decodeEvents(String source, String description) {
  final events = <Map<String, Object?>>[];
  for (final line in const LineSplitter().convert(source)) {
    if (line.trim().isEmpty) continue;
    late final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException catch (error) {
      throw MutationFailure(
        '$description emitted malformed JSON: $error\n${_truncate(line)}',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw MutationFailure('$description emitted a non-object JSON event.');
    }
    events.add(decoded);
  }
  return events;
}

String _packageRelative(String path, String packageRoot) =>
    packageRoot == '.' ? path : path.substring(packageRoot.length + 1);

String _resolve(String root, String repositoryPath) => repositoryPath == '.'
    ? root
    : '$root${Platform.pathSeparator}'
          '${repositoryPath.replaceAll('/', Platform.pathSeparator)}';

String _outputContext(MutationProcessOutput output) {
  final stdoutText = _truncate(output.stdout.trim());
  final stderrText = _truncate(output.stderr.trim());
  if (stdoutText.isEmpty && stderrText.isEmpty) return '';
  return '\nstdout:\n$stdoutText\nstderr:\n$stderrText';
}

String _truncate(String value) => value.length <= 4000
    ? value
    : '${value.substring(0, 4000)}\n... output truncated ...';

sealed class _ProcessCompletion {
  const _ProcessCompletion();
}

final class _ProcessCompleted extends _ProcessCompletion {
  const _ProcessCompleted(this.output);

  final MutationProcessOutput output;
}

final class _ProcessTimedOut extends _ProcessCompletion {
  const _ProcessTimedOut();
}
