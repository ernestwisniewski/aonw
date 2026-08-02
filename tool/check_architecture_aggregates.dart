import 'dart:io';

import 'architecture/failure.dart';
import 'architecture/git_repository.dart';
import 'architecture/library_aggregate_gate.dart';

void main(List<String> arguments) {
  try {
    final options = _Options.parse(arguments);
    final gate = LibraryAggregateGate(
      repository: GitRepository(options.repository),
      architecturePolicyPath: _resolve(
        options.repository,
        options.architecturePolicyPath,
      ),
      aggregatePolicyPath: _resolve(
        options.repository,
        options.aggregatePolicyPath,
      ),
      baselinePath: _resolve(options.repository, options.baselinePath),
    );
    switch (options.command) {
      case _Command.snapshot:
        stdout.write(gate.snapshot().canonicalRepresentation);
      case _Command.check:
        final result = gate.check(options.ratchetRef!);
        stdout.writeln(
          'Architecture library aggregates pass: '
          '${result.libraryDebt} legacy libraries.',
        );
    }
  } on ArchitectureFailure catch (error) {
    stderr.writeln(
      'Architecture library aggregate gate failed:\n${error.message}',
    );
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Architecture library aggregate gate failed:\n$error');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Architecture library aggregate gate failed:\n$error');
    exitCode = 1;
  }
}

enum _Command { snapshot, check }

final class _Options {
  const _Options({
    required this.command,
    required this.repository,
    required this.architecturePolicyPath,
    required this.aggregatePolicyPath,
    required this.baselinePath,
    required this.ratchetRef,
  });

  factory _Options.parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const ArchitectureFailure(
        'Usage: dart run tool/check_architecture_aggregates.dart '
        '<snapshot|check> [--repository PATH] [--architecture-policy PATH] '
        '[--aggregate-policy PATH] [--baseline PATH] [--ratchet-ref REF]',
      );
    }
    final command = switch (arguments.first) {
      'snapshot' => _Command.snapshot,
      'check' => _Command.check,
      final value => throw ArchitectureFailure('Unknown command: $value'),
    };
    var repository = Directory.current.absolute.path;
    var architecturePolicyPath = 'tool/architecture_policy.json';
    var aggregatePolicyPath = 'tool/architecture_aggregate_policy.json';
    var baselinePath = 'tool/architecture_aggregate_baseline.json';
    String? ratchetRef;
    for (var index = 1; index < arguments.length; index++) {
      final option = _readOption(arguments, index);
      index = option.valueIndex;
      switch (option.name) {
        case '--repository':
          repository = option.value;
        case '--architecture-policy':
          architecturePolicyPath = option.value;
        case '--aggregate-policy':
          aggregatePolicyPath = option.value;
        case '--baseline':
          baselinePath = option.value;
        case '--ratchet-ref':
          ratchetRef = option.value;
        default:
          throw ArchitectureFailure('Unknown argument: ${option.name}');
      }
    }
    if (command == _Command.check && ratchetRef == null) {
      throw const ArchitectureFailure('check requires --ratchet-ref.');
    }
    return _Options(
      command: command,
      repository: Directory(repository).absolute.path,
      architecturePolicyPath: architecturePolicyPath,
      aggregatePolicyPath: aggregatePolicyPath,
      baselinePath: baselinePath,
      ratchetRef: ratchetRef,
    );
  }

  final _Command command;
  final String repository;
  final String architecturePolicyPath;
  final String aggregatePolicyPath;
  final String baselinePath;
  final String? ratchetRef;
}

({String name, String value, int valueIndex}) _readOption(
  List<String> arguments,
  int index,
) {
  final argument = arguments[index];
  final separator = argument.indexOf('=');
  if (separator > 0) {
    return (
      name: argument.substring(0, separator),
      value: argument.substring(separator + 1),
      valueIndex: index,
    );
  }
  if (index + 1 >= arguments.length) {
    throw ArchitectureFailure('Missing value for $argument.');
  }
  return (name: argument, value: arguments[index + 1], valueIndex: index + 1);
}

String _resolve(String repository, String path) => File(path).isAbsolute
    ? File(path).absolute.path
    : File('$repository${Platform.pathSeparator}$path').absolute.path;
