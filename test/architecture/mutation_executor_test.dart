import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/executor.dart';
import '../../tool/mutation/failure.dart';
import '../../tool/mutation/git_repository.dart';
import '../../tool/mutation/mutant.dart';
import '../../tool/mutation/policy.dart';
import '../../tool/mutation/strict_json.dart';
import '../../tool/mutation/test_process.dart';
import '../../tool/mutation/workspace.dart';

void main() {
  group('mutation test process', () {
    test('constructs shell-free Dart and Flutter commands', () async {
      final dartExecutor = _QueueCommandExecutor([_passedOutput]);
      final dartScope = _policy(
        packageRoot: 'server',
        runner: 'dart',
        targetFile: 'server/lib/sample.dart',
        testFile: 'server/test/sample_test.dart',
      ).scopes.values.single;

      expect(
        await MutationTestProcessRunner(commandExecutor: dartExecutor).runScope(
          scope: dartScope,
          workspaceRoot: '/workspace',
          timeout: const Duration(seconds: 1),
        ),
        MutationTestOutcome.passed,
      );
      expect(dartExecutor.calls.single.executable, 'dart');
      expect(dartExecutor.calls.single.arguments, [
        'test',
        '--concurrency=1',
        '--test-randomize-ordering-seed=0',
        '--reporter=json',
        'test/sample_test.dart',
      ]);
      expect(
        dartExecutor.calls.single.workingDirectory,
        '/workspace${Platform.pathSeparator}server',
      );

      final flutterExecutor = _QueueCommandExecutor([_passedOutput]);
      final flutterScope = _policy().scopes.values.single;
      await MutationTestProcessRunner(
        commandExecutor: flutterExecutor,
      ).runScope(
        scope: flutterScope,
        workspaceRoot: '/workspace',
        timeout: const Duration(seconds: 1),
      );
      expect(flutterExecutor.calls.single.executable, 'flutter');
      expect(flutterExecutor.calls.single.arguments, [
        'test',
        '--no-pub',
        '--concurrency=1',
        '--test-randomize-ordering-seed=0',
        '--reporter=json',
        'test/sample_test.dart',
      ]);
    });

    test('kills only on a real failed test JSON event', () async {
      final executor = _QueueCommandExecutor([
        _output(result: 'failure', doneSuccess: false, exitCode: 1),
      ]);
      final outcome = await MutationTestProcessRunner(commandExecutor: executor)
          .runScope(
            scope: _policy().scopes.values.single,
            workspaceRoot: '/workspace',
            timeout: const Duration(seconds: 1),
          );

      expect(outcome, MutationTestOutcome.killed);
    });

    test(
      'does not mistake a user test named loading for suite loading',
      () async {
        final runner = MutationTestProcessRunner(
          commandExecutor: _QueueCommandExecutor([
            _output(
              name: 'loading user-owned behavior',
              result: 'failure',
              doneSuccess: false,
              exitCode: 1,
            ),
          ]),
        );

        await expectLater(
          runner.runScope(
            scope: _policy().scopes.values.single,
            workspaceRoot: '/workspace',
            timeout: const Duration(seconds: 1),
          ),
          completion(MutationTestOutcome.killed),
        );
      },
    );

    test('rejects load errors, malformed JSON, crashes, and bare exits', () {
      final failures = <MutationProcessOutput>[
        _output(
          name: 'loading test/sample_test.dart',
          groupIds: const [],
          result: 'error',
          doneSuccess: false,
          exitCode: 1,
        ),
        const MutationProcessOutput(
          exitCode: 1,
          stdout: '{not json}\n',
          stderr: '',
        ),
        _output(result: 'failure', doneSuccess: false, exitCode: 2),
        _output(result: 'success', doneSuccess: false, exitCode: 1),
        _output(result: 'failure', doneSuccess: false, exitCode: 0),
        const MutationProcessOutput(
          exitCode: 0,
          stdout:
              '{"type":"start"}\n'
              '{"type":"testStart","test":{"id":1,"name":"works",'
              '"suiteID":0,"groupIDs":[0]}}\n'
              '{"type":"done","success":true}\n',
          stderr: '',
        ),
        const MutationProcessOutput(
          exitCode: 0,
          stdout: '{"type":"start"}\n{"type":"done","success":true}\n',
          stderr: '',
        ),
      ];

      for (final output in failures) {
        final runner = MutationTestProcessRunner(
          commandExecutor: _QueueCommandExecutor([output]),
        );
        expect(
          () => runner.runScope(
            scope: _policy().scopes.values.single,
            workspaceRoot: '/workspace',
            timeout: const Duration(seconds: 1),
          ),
          throwsA(isA<MutationFailure>()),
          reason: output.stdout,
        );
      }
    });
  });

  test('Analyzer rejects ERROR diagnostics before process execution', () async {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-analyzer-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final source = File('${fixture.path}/sample.dart');
    const analyzer = MutationSourceAnalyzer();

    source.writeAsStringSync("int value = 'wrong';\n");
    await expectLater(
      analyzer.validate(path: source.path, description: 'invalid mutant'),
      throwsA(
        isA<MutationFailure>().having(
          (error) => error.message,
          'message',
          contains('Analyzer ERROR'),
        ),
      ),
    );
    source.writeAsStringSync('int value = 1;\n');
    await analyzer.validate(path: source.path, description: 'valid mutant');
  });

  group('isolated mutation execution', () {
    test('runs one baseline, builds census, and restores every kill', () async {
      final fixture = _WorkspaceFixture.create();
      addTearDown(fixture.dispose);
      final commands = _QueueCommandExecutor([
        _passedOutput,
        _output(result: 'failure', doneSuccess: false, exitCode: 1),
      ]);
      final baseline = await MutationExecutor(
        processRunner: MutationTestProcessRunner(commandExecutor: commands),
      ).execute(policy: fixture.policy, workspace: fixture.workspace);

      final scope = baseline.scopes.values.single;
      expect(scope.targets, {fixture.targetPath: 1});
      expect(scope.operatorTotals[MutationOperators.booleanLiteral], 1);
      expect(scope.survivors, isEmpty);
      expect(commands.calls, hasLength(2));
      expect(commands.calls.first.description, contains('baseline'));
      fixture.expectSourcesUntouched();
    });

    test('records survivor identity and restores its source', () async {
      final fixture = _WorkspaceFixture.create();
      addTearDown(fixture.dispose);
      final commands = _QueueCommandExecutor([_passedOutput, _passedOutput]);

      final baseline = await MutationExecutor(
        processRunner: MutationTestProcessRunner(commandExecutor: commands),
      ).execute(policy: fixture.policy, workspace: fixture.workspace);

      final survivor = baseline.scopes.values.single.survivors.values.single;
      expect(survivor.path, fixture.targetPath);
      expect(survivor.operator, MutationOperators.booleanLiteral);
      expect(survivor.original, 'true');
      expect(survivor.replacement, 'false');
      expect(commands.calls, hasLength(2));
      fixture.expectSourcesUntouched();
    });

    test('restores source when Analyzer rejects a mutant', () async {
      final fixture = _WorkspaceFixture.create(
        original: "bool enabled() => true;\nint invalidValue = 'not an int';\n",
      );
      addTearDown(fixture.dispose);
      final commands = _QueueCommandExecutor([_passedOutput]);
      final future = MutationExecutor(
        processRunner: MutationTestProcessRunner(commandExecutor: commands),
      ).execute(policy: fixture.policy, workspace: fixture.workspace);

      await expectLater(
        future,
        throwsA(
          isA<MutationFailure>().having(
            (error) => error.message,
            'message',
            contains('Analyzer ERROR'),
          ),
        ),
      );
      expect(commands.calls, hasLength(1));
      fixture.expectSourcesUntouched();
    });

    test(
      'restores source when mutant execution fails as infrastructure',
      () async {
        final fixture = _WorkspaceFixture.create();
        addTearDown(fixture.dispose);
        final commands = _QueueCommandExecutor([
          _passedOutput,
          const MutationFailure('simulated process failure'),
        ]);
        final future = MutationExecutor(
          processRunner: MutationTestProcessRunner(commandExecutor: commands),
        ).execute(policy: fixture.policy, workspace: fixture.workspace);

        await expectLater(
          future,
          throwsA(
            isA<MutationFailure>().having(
              (error) => error.message,
              'message',
              contains('simulated process failure'),
            ),
          ),
        );
        fixture.expectSourcesUntouched();
      },
    );
  });
}

const _passedOutput = MutationProcessOutput(
  exitCode: 0,
  stdout:
      '{"type":"start"}\n'
      '{"type":"testStart","test":{"id":1,"name":"works",'
      '"suiteID":0,"groupIDs":[0]}}\n'
      '{"type":"testDone","testID":1,"result":"success"}\n'
      '{"type":"done","success":true}\n',
  stderr: '',
);

MutationProcessOutput _output({
  String name = 'sample behavior',
  List<int> groupIds = const [0],
  required String result,
  required bool doneSuccess,
  required int exitCode,
}) => MutationProcessOutput(
  exitCode: exitCode,
  stdout: [
    {'type': 'start'},
    {
      'type': 'testStart',
      'test': {'id': 1, 'name': name, 'suiteID': 0, 'groupIDs': groupIds},
    },
    {'type': 'testDone', 'testID': 1, 'result': result},
    {'type': 'done', 'success': doneSuccess},
  ].map(jsonEncode).join('\n'),
  stderr: '',
);

MutationPolicy _policy({
  String packageRoot = '.',
  String runner = 'flutter',
  String targetFile = 'lib/sample.dart',
  String testFile = 'test/sample_test.dart',
}) => MutationPolicy.parse(
  canonicalJson({
    'schema': 1,
    'enforcedSince': '0123456789abcdef0123456789abcdef01234567',
    'perMutantTimeoutSeconds': 5,
    'operators': supportedMutationOperators,
    'scopes': {
      'fixture': {
        'architectureScope': packageRoot == '.' ? 'root_lib' : 'server_lib',
        'packageRoot': packageRoot,
        'runner': runner,
        'targetFiles': [targetFile],
        'testFiles': [testFile],
      },
    },
  }),
  'fixture policy',
);

final class _QueueCommandExecutor implements MutationCommandExecutor {
  _QueueCommandExecutor(this.results);

  final List<Object> results;
  final List<_CommandCall> calls = [];

  @override
  Future<MutationProcessOutput> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
    required String description,
  }) async {
    calls.add(
      _CommandCall(
        executable: executable,
        arguments: List.unmodifiable(arguments),
        workingDirectory: workingDirectory,
        description: description,
      ),
    );
    if (results.isEmpty) {
      throw StateError('Unexpected mutation command: $description');
    }
    final result = results.removeAt(0);
    if (result is MutationProcessOutput) return result;
    throw result;
  }
}

final class _CommandCall {
  const _CommandCall({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.description,
  });

  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final String description;
}

final class _WorkspaceFixture {
  _WorkspaceFixture._({
    required this.repository,
    required this.workspace,
    required this.policy,
    required this.targetPath,
    required this.original,
  });

  factory _WorkspaceFixture.create({
    String original = 'bool enabled() => true;\n',
  }) {
    final repository = Directory.systemTemp.createTempSync(
      'aonw-mutation-workspace-fixture-',
    );
    const targetPath = 'lib/sample.dart';
    const testPath = 'test/sample_test.dart';
    File('${repository.path}/$targetPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(original);
    File('${repository.path}/$testPath')
      ..createSync(recursive: true)
      ..writeAsStringSync("void main() {}\n");
    File('${repository.path}/pubspec.yaml').writeAsStringSync('''
name: mutation_fixture
environment:
  sdk: ^3.11.0
''');
    File('${repository.path}/.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'mutation_fixture',
              'rootUri': '../',
              'packageUri': 'lib/',
              'languageVersion': '3.11',
            },
          ],
        }),
      );
    _git(repository, ['init', '-b', 'dev']);
    _git(repository, ['config', 'user.email', 'mutations@example.test']);
    _git(repository, ['config', 'user.name', 'Mutation Fixture']);
    _git(repository, ['add', 'lib', 'test', 'pubspec.yaml']);
    _git(repository, ['commit', '-m', 'fixture']);
    final workspace = MutationWorkspace.create(
      MutationGitRepository(repository.path),
      const ['.'],
    );
    return _WorkspaceFixture._(
      repository: repository,
      workspace: workspace,
      policy: _policy(
        runner: 'dart',
        targetFile: targetPath,
        testFile: testPath,
      ),
      targetPath: targetPath,
      original: original,
    );
  }

  final Directory repository;
  final MutationWorkspace workspace;
  final MutationPolicy policy;
  final String targetPath;
  final String original;

  void expectSourcesUntouched() {
    expect(File('${repository.path}/$targetPath').readAsStringSync(), original);
    expect(File('${workspace.root}/$targetPath').readAsStringSync(), original);
  }

  void dispose() {
    workspace.dispose();
    if (repository.existsSync()) repository.deleteSync(recursive: true);
  }
}

String _git(Directory repository, List<String> arguments) {
  final result = Process.runSync(
    'git',
    ['-C', repository.path, ...arguments],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout as String;
}
