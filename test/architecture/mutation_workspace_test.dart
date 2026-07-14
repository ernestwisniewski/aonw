import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/executor.dart';
import '../../tool/mutation/failure.dart';
import '../../tool/mutation/git_repository.dart';
import '../../tool/mutation/policy.dart';
import '../../tool/mutation/strict_json.dart';
import '../../tool/mutation/test_process.dart';
import '../../tool/mutation/workspace.dart';

void main() {
  test(
    'snapshots tracked and untracked work without copying ignored files',
    () {
      final fixture = Directory.systemTemp.createTempSync(
        'aonw-mutation-workspace-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      _git(fixture, ['init', '--quiet']);
      _git(fixture, ['config', 'user.name', 'Mutation Test']);
      _git(fixture, ['config', 'user.email', 'mutation@example.invalid']);
      File(
        '${fixture.path}/.gitignore',
      ).writeAsStringSync('.dart_tool/\nsecret\n');
      final source = File('${fixture.path}/lib/source.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('const value = 1;\n');
      _commitAll(fixture, 'anchor');

      source.writeAsStringSync('const value = 2;\n');
      File('${fixture.path}/test/new_test.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('void main() {}\n');
      File('${fixture.path}/secret').writeAsStringSync('do not copy\n');
      for (final entry in {
        '.dart_tool/package_config.json': 'root_fixture',
        'server/.dart_tool/package_config.json': 'server_fixture',
      }.entries) {
        File('${fixture.path}/${entry.key}')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({
              'configVersion': 2,
              'packages': [
                {
                  'name': entry.value,
                  'rootUri': entry.key.startsWith('server/')
                      ? '../'
                      : Directory(
                          fixture.resolveSymbolicLinksSync(),
                        ).uri.toString(),
                  'packageUri': 'lib/',
                  'languageVersion': '3.11',
                },
              ],
            }),
          );
      }

      final workspace = MutationWorkspace.create(
        MutationGitRepository(fixture.path),
        const ['.', 'server'],
      );
      final snapshotRoot = workspace.root;
      addTearDown(workspace.dispose);

      expect(
        File('$snapshotRoot/lib/source.dart').readAsStringSync(),
        'const value = 2;\n',
      );
      expect(File('$snapshotRoot/test/new_test.dart').existsSync(), isTrue);
      expect(File('$snapshotRoot/secret').existsSync(), isFalse);
      expect(
        File('$snapshotRoot/.dart_tool/package_config.json').existsSync(),
        isTrue,
      );
      expect(
        File(
          '$snapshotRoot/server/.dart_tool/package_config.json',
        ).existsSync(),
        isTrue,
      );
      expect(source.readAsStringSync(), 'const value = 2;\n');
      final snapshotConfig =
          jsonDecode(
                File(
                  '$snapshotRoot/.dart_tool/package_config.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final snapshotPackages = snapshotConfig['packages']! as List<Object?>;
      final snapshotPackage = snapshotPackages.single as Map<String, Object?>;
      expect(
        snapshotPackage['rootUri'],
        Directory(snapshotRoot).absolute.uri.toString(),
      );

      final dependencyConfig = File(
        '$snapshotRoot/.dart_tool/package_config.json',
      );
      final pristineConfig = dependencyConfig.readAsStringSync();
      dependencyConfig.writeAsStringSync('{"tampered":true}\n');
      File('$snapshotRoot/.dart_tool/test/cache')
        ..createSync(recursive: true)
        ..writeAsStringSync('stale\n');
      File('$snapshotRoot/build/test_cache/output')
        ..createSync(recursive: true)
        ..writeAsStringSync('stale\n');

      workspace.resetRuntimeState();

      expect(dependencyConfig.readAsStringSync(), pristineConfig);
      expect(File('$snapshotRoot/.dart_tool/test/cache').existsSync(), isFalse);
      expect(Directory('$snapshotRoot/build').existsSync(), isFalse);

      final controlled = File('$snapshotRoot/test/new_test.dart')
        ..writeAsStringSync('void changed() {}\n');
      expect(workspace.assertControlledTreeClean, throwsA(isA<Exception>()));
      controlled.writeAsStringSync('void main() {}\n');
      workspace
        ..assertControlledTreeClean()
        ..dispose();
      expect(Directory(snapshotRoot).existsSync(), isFalse);
    },
  );

  test(
    'rejects a symlinked runtime ancestor without touching its destination',
    () {
      final fixture = _ServerWorkspaceFixture.create();
      final external = Directory.systemTemp.createTempSync(
        'aonw-mutation-escape-',
      );
      addTearDown(() {
        fixture.dispose();
        if (external.existsSync()) external.deleteSync(recursive: true);
      });
      final sentinel = File('${external.path}/.dart_tool/sentinel')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('must survive\n');
      final packageDirectory = Directory('${fixture.workspace.root}/server')
        ..deleteSync(recursive: true);
      Link(packageDirectory.path).createSync(external.path);

      expect(
        fixture.workspace.resetRuntimeState,
        throwsA(
          isA<MutationFailure>().having(
            (error) => error.message,
            'message',
            contains('symbolic-link ancestors'),
          ),
        ),
      );
      expect(sentinel.readAsStringSync(), 'must survive\n');
    },
    skip: Platform.isWindows
        ? 'Creating directory symlinks requires optional Windows privileges.'
        : false,
  );

  test(
    'executor does not reset runtime after controlled-tree corruption',
    () async {
      final fixture = _ServerWorkspaceFixture.create();
      final external = Directory.systemTemp.createTempSync(
        'aonw-mutation-executor-escape-',
      );
      addTearDown(() {
        fixture.dispose();
        if (external.existsSync()) external.deleteSync(recursive: true);
      });
      final externalSentinel = File('${external.path}/.dart_tool/sentinel')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('must survive\n');
      final commandExecutor = _SymlinkEscapeCommandExecutor(external.path);

      await expectLater(
        MutationExecutor(
          processRunner: MutationTestProcessRunner(
            commandExecutor: commandExecutor,
          ),
        ).execute(policy: fixture.policy, workspace: fixture.workspace),
        throwsA(isA<MutationFailure>()),
      );

      expect(commandExecutor.calls, 1);
      expect(
        File(
          '${fixture.workspace.root}/.dart_tool/runtime-marker',
        ).readAsStringSync(),
        'reset must not run\n',
      );
      expect(externalSentinel.readAsStringSync(), 'must survive\n');
    },
    skip: Platform.isWindows
        ? 'Creating directory symlinks requires optional Windows privileges.'
        : false,
  );

  test(
    'mutant restore refuses a symlinked ancestor without an external write',
    () async {
      final fixture = _ServerWorkspaceFixture.create();
      final external = Directory.systemTemp.createTempSync(
        'aonw-mutation-restore-escape-',
      );
      addTearDown(() {
        fixture.dispose();
        if (external.existsSync()) external.deleteSync(recursive: true);
      });
      final externalSource = File('${external.path}/lib/source.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('bool enabled() => false;\n');
      final commandExecutor = _MutantPathSwapCommandExecutor((packageRoot) {
        Directory(packageRoot).deleteSync(recursive: true);
        Link(packageRoot).createSync(external.path);
      });

      await expectLater(
        MutationExecutor(
          processRunner: MutationTestProcessRunner(
            commandExecutor: commandExecutor,
          ),
        ).execute(policy: fixture.policy, workspace: fixture.workspace),
        throwsA(isA<MutationFailure>()),
      );

      expect(commandExecutor.calls, 2);
      expect(externalSource.readAsStringSync(), 'bool enabled() => false;\n');
    },
    skip: Platform.isWindows
        ? 'Creating directory symlinks requires optional Windows privileges.'
        : false,
  );

  test(
    'mutant restore replaces a hard link instead of writing through it',
    () async {
      final fixture = _ServerWorkspaceFixture.create();
      final external = Directory.systemTemp.createTempSync(
        'aonw-mutation-hard-link-',
      );
      addTearDown(() {
        fixture.dispose();
        if (external.existsSync()) external.deleteSync(recursive: true);
      });
      final externalSource = File('${external.path}/source.dart')
        ..writeAsStringSync('bool enabled() => false;\n');
      final commandExecutor = _MutantPathSwapCommandExecutor((packageRoot) {
        final target = File('$packageRoot/lib/source.dart')..deleteSync();
        final result = Process.runSync(
          'ln',
          [externalSource.path, target.path],
          stdoutEncoding: systemEncoding,
          stderrEncoding: systemEncoding,
        );
        if (result.exitCode != 0) {
          throw StateError('ln failed: ${result.stderr}');
        }
      });

      await MutationExecutor(
        processRunner: MutationTestProcessRunner(
          commandExecutor: commandExecutor,
        ),
      ).execute(policy: fixture.policy, workspace: fixture.workspace);

      expect(commandExecutor.calls, 2);
      expect(externalSource.readAsStringSync(), 'bool enabled() => false;\n');
      expect(
        File(
          '${fixture.workspace.root}/server/lib/source.dart',
        ).readAsStringSync(),
        'bool enabled() => true;\n',
      );
    },
    skip: Platform.isWindows ? 'The mutation runner is POSIX-only.' : false,
  );
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

final class _SymlinkEscapeCommandExecutor implements MutationCommandExecutor {
  _SymlinkEscapeCommandExecutor(this.externalRoot);

  final String externalRoot;
  int calls = 0;

  @override
  Future<MutationProcessOutput> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
    required String description,
  }) async {
    calls += 1;
    if (calls != 1) {
      throw StateError('Unexpected mutation command: $description');
    }
    final packageDirectory = Directory(workingDirectory);
    File('${packageDirectory.parent.path}/.dart_tool/runtime-marker')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('reset must not run\n');
    packageDirectory.deleteSync(recursive: true);
    Link(packageDirectory.path).createSync(externalRoot);
    return _passedOutput;
  }
}

final class _MutantPathSwapCommandExecutor implements MutationCommandExecutor {
  _MutantPathSwapCommandExecutor(this.swapPath);

  final void Function(String packageRoot) swapPath;
  int calls = 0;

  @override
  Future<MutationProcessOutput> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
    required String description,
  }) async {
    calls += 1;
    if (calls == 2) swapPath(workingDirectory);
    if (calls > 2) {
      throw StateError('Unexpected mutation command: $description');
    }
    return _passedOutput;
  }
}

final class _ServerWorkspaceFixture {
  _ServerWorkspaceFixture._({
    required this.repository,
    required this.workspace,
    required this.policy,
  });

  factory _ServerWorkspaceFixture.create() {
    final repository = Directory.systemTemp.createTempSync(
      'aonw-mutation-server-workspace-',
    );
    try {
      _git(repository, ['init', '--quiet']);
      _git(repository, ['config', 'user.name', 'Mutation Test']);
      _git(repository, ['config', 'user.email', 'mutation@example.invalid']);
      File(
        '${repository.path}/.gitignore',
      ).writeAsStringSync('.dart_tool/\nbuild/\n');
      File('${repository.path}/server/lib/source.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('bool enabled() => true;\n');
      File('${repository.path}/server/test/source_test.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('void main() {}\n');
      _commitAll(repository, 'anchor');
      for (final entry in const {
        '.dart_tool/package_config.json': ('root_fixture', '../'),
        'server/.dart_tool/package_config.json': ('server_fixture', '../'),
      }.entries) {
        File('${repository.path}/${entry.key}')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({
              'configVersion': 2,
              'packages': [
                {
                  'name': entry.value.$1,
                  'rootUri': entry.value.$2,
                  'packageUri': 'lib/',
                  'languageVersion': '3.11',
                },
              ],
            }),
          );
      }
      final workspace = MutationWorkspace.create(
        MutationGitRepository(repository.path),
        const ['.', 'server'],
      );
      final policy = MutationPolicy.parse(
        canonicalJson({
          'schema': 1,
          'enforcedSince': '0123456789abcdef0123456789abcdef01234567',
          'perMutantTimeoutSeconds': 5,
          'operators': supportedMutationOperators,
          'scopes': {
            'fixture': {
              'architectureScope': 'server_lib',
              'packageRoot': 'server',
              'runner': 'dart',
              'targetFiles': ['server/lib/source.dart'],
              'testFiles': ['server/test/source_test.dart'],
            },
          },
        }),
        'fixture policy',
      );
      return _ServerWorkspaceFixture._(
        repository: repository,
        workspace: workspace,
        policy: policy,
      );
    } catch (_) {
      if (repository.existsSync()) repository.deleteSync(recursive: true);
      rethrow;
    }
  }

  final Directory repository;
  final MutationWorkspace workspace;
  final MutationPolicy policy;

  void dispose() {
    final packagePath = '${workspace.root}/server';
    if (FileSystemEntity.typeSync(packagePath, followLinks: false) ==
        FileSystemEntityType.link) {
      Link(packagePath).deleteSync();
    }
    workspace.dispose();
    if (repository.existsSync()) repository.deleteSync(recursive: true);
  }
}

void _commitAll(Directory repository, String message) {
  _git(repository, ['add', '.']);
  _git(repository, ['commit', '--quiet', '-m', message]);
}

String _git(Directory repository, List<String> arguments) {
  final result = Process.runSync(
    'git',
    ['-C', repository.path, ...arguments],
    stdoutEncoding: systemEncoding,
    stderrEncoding: systemEncoding,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ${arguments.join(' ')} failed:\n${result.stdout}\n${result.stderr}',
    );
  }
  return result.stdout as String;
}
