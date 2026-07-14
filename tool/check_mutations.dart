import 'dart:io';

import 'mutation/failure.dart';
import 'mutation/gate.dart';
import 'mutation/git_repository.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final repository = MutationGitRepository(options.repository);
    final gate = MutationGate(
      repository: repository,
      policyPath: _resolve(options.repository, options.policyPath),
      baselinePath: _resolve(options.repository, options.baselinePath),
      architecturePolicyPath: _resolve(
        options.repository,
        options.architecturePolicyPath,
      ),
    );
    switch (options.command) {
      case _Command.snapshot:
        stdout.write((await gate.snapshot()).canonicalRepresentation);
      case _Command.check:
        final result = await gate.check(options.ratchetRef!);
        stdout.writeln(
          'Mutation gate passes: ${result.mutants} mutants, '
          '${result.survivors} survivors.',
        );
    }
  } on MutationFailure catch (error) {
    stderr.writeln('Mutation gate failed:\n${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Mutation gate failed:\n${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Mutation gate failed:\n$error');
    exitCode = 1;
  } on ProcessException catch (error) {
    stderr.writeln('Mutation gate failed:\n$error');
    exitCode = 1;
  }
}

enum _Command { snapshot, check }

final class _Options {
  const _Options({
    required this.command,
    required this.repository,
    required this.policyPath,
    required this.baselinePath,
    required this.architecturePolicyPath,
    required this.ratchetRef,
  });

  factory _Options.parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const MutationFailure(
        'Usage: dart run tool/check_mutations.dart <snapshot|check> '
        '[--repository PATH] [--policy PATH] [--baseline PATH] '
        '[--architecture-policy PATH] [--ratchet-ref REF]',
      );
    }
    final command = switch (arguments.first) {
      'snapshot' => _Command.snapshot,
      'check' => _Command.check,
      final value => throw MutationFailure('Unknown command: $value'),
    };
    var repository = Directory.current.absolute.path;
    var policyPath = 'tool/mutation_policy.json';
    var baselinePath = 'tool/mutation_baseline.json';
    var architecturePolicyPath = 'tool/architecture_policy.json';
    String? ratchetRef;
    for (var index = 1; index < arguments.length; index++) {
      final argument = arguments[index];
      String valueFor(String name) {
        if (argument.startsWith('$name=')) {
          return argument.substring(name.length + 1);
        }
        if (argument == name && index + 1 < arguments.length) {
          index += 1;
          return arguments[index];
        }
        throw MutationFailure('Missing value for $name.');
      }

      if (argument == '--repository' || argument.startsWith('--repository=')) {
        repository = Directory(valueFor('--repository')).absolute.path;
      } else if (argument == '--policy' || argument.startsWith('--policy=')) {
        policyPath = valueFor('--policy');
      } else if (argument == '--baseline' ||
          argument.startsWith('--baseline=')) {
        baselinePath = valueFor('--baseline');
      } else if (argument == '--architecture-policy' ||
          argument.startsWith('--architecture-policy=')) {
        architecturePolicyPath = valueFor('--architecture-policy');
      } else if (argument == '--ratchet-ref' ||
          argument.startsWith('--ratchet-ref=')) {
        ratchetRef = valueFor('--ratchet-ref');
      } else {
        throw MutationFailure('Unknown argument: $argument');
      }
    }
    if (command == _Command.check && ratchetRef == null) {
      throw const MutationFailure('check requires --ratchet-ref.');
    }
    return _Options(
      command: command,
      repository: repository,
      policyPath: policyPath,
      baselinePath: baselinePath,
      architecturePolicyPath: architecturePolicyPath,
      ratchetRef: ratchetRef,
    );
  }

  final _Command command;
  final String repository;
  final String policyPath;
  final String baselinePath;
  final String architecturePolicyPath;
  final String? ratchetRef;
}

String _resolve(String repository, String path) {
  if (_isAbsolutePath(path)) return File(path).absolute.path;
  return File(
    '$repository${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}',
  ).absolute.path;
}

bool _isAbsolutePath(String path) =>
    path.startsWith('/') ||
    path.startsWith(r'\\') ||
    RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
