import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/failure.dart';
import '../../tool/mutation/test_process.dart';

void main() {
  if (Platform.isWindows) {
    test(
      'fails before starting a command without Windows Job Objects',
      () async {
        await expectLater(
          const SystemMutationCommandExecutor().run(
            executable: 'dart',
            arguments: const ['--version'],
            workingDirectory: Directory.current.path,
            timeout: const Duration(seconds: 1),
            description: 'Windows isolation fixture',
          ),
          throwsA(
            isA<MutationFailure>().having(
              (error) => error.message,
              'message',
              contains('Windows Job Objects'),
            ),
          ),
        );
      },
    );
    return;
  }

  test('drains large stdout and stderr without deadlock', () async {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-process-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final script = File('${fixture.path}/large_output.dart')
      ..writeAsStringSync('''
import 'dart:io';

void main() {
  final block = List.filled(250000, 'x').join();
  stdout.write(block);
  stderr.write(block);
}
''');

    final output = await const SystemMutationCommandExecutor().run(
      executable: 'dart',
      arguments: [script.path],
      workingDirectory: fixture.path,
      timeout: const Duration(seconds: 10),
      description: 'large-output fixture',
    );

    expect(output.exitCode, 0);
    expect(output.stdout, hasLength(250000));
    expect(output.stderr, hasLength(250000));
  });

  test('closes command stdin immediately', () async {
    final fixture = Directory.systemTemp.createTempSync('aonw-mutation-stdin-');
    addTearDown(() => fixture.deleteSync(recursive: true));
    final script = File('${fixture.path}/stdin.dart')
      ..writeAsStringSync('''
import 'dart:io';

Future<void> main() async {
  final bytes = await stdin.fold<int>(0, (count, chunk) => count + chunk.length);
  stdout.write(bytes);
}
''');

    final output = await const SystemMutationCommandExecutor().run(
      executable: 'dart',
      arguments: [script.path],
      workingDirectory: fixture.path,
      timeout: const Duration(seconds: 10),
      description: 'stdin fixture',
    );

    expect(output.exitCode, 0);
    expect(output.stdout, '0');
  });

  test(
    'terminates a command and its child at the configured timeout',
    () async {
      final fixture = Directory.systemTemp.createTempSync(
        'aonw-mutation-timeout-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      final child = File('${fixture.path}/child.dart')
        ..writeAsStringSync('''
import 'dart:io';

Future<void> main() async {
  ProcessSignal.sigterm.watch().listen((_) {});
  stdout.writeln('child started');
  await Future<void>.delayed(const Duration(seconds: 30));
}
''');
      final script = File('${fixture.path}/timeout.dart')
        ..writeAsStringSync('''
import 'dart:io';

Future<void> main() async {
  final child = await Process.start(
    Platform.resolvedExecutable,
    [${jsonEncode(child.path)}],
    mode: ProcessStartMode.inheritStdio,
  );
  File(${jsonEncode('${fixture.path}/child.pid')})
      .writeAsStringSync('\${child.pid}');
  await Future<void>.delayed(const Duration(seconds: 30));
}
''');

      await expectLater(
        () => const SystemMutationCommandExecutor().run(
          executable: 'dart',
          arguments: [script.path],
          workingDirectory: fixture.path,
          timeout: const Duration(seconds: 3),
          description: 'timeout fixture',
        ),
        throwsA(
          isA<MutationFailure>().having(
            (error) => error.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
      final childPidFile = File('${fixture.path}/child.pid');
      expect(childPidFile.existsSync(), isTrue);
      final childPid = int.parse(childPidFile.readAsStringSync());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(_processExists(childPid), isFalse);
    },
  );

  test('terminates descendants after a successful parent exit', () async {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-descendant-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final pidFile = File('${fixture.path}/child.pid');
    final child = File('${fixture.path}/child.dart')
      ..writeAsStringSync('''
Future<void> main() => Future<void>.delayed(const Duration(seconds: 30));
''');
    final script = File('${fixture.path}/parent.dart')
      ..writeAsStringSync('''
import 'dart:io';

Future<void> main() async {
  final child = await Process.start(
    Platform.resolvedExecutable,
    [${jsonEncode(child.path)}],
    mode: ProcessStartMode.inheritStdio,
  );
  File(${jsonEncode(pidFile.path)}).writeAsStringSync('\${child.pid}');
  exit(0);
}
''');

    final output = await const SystemMutationCommandExecutor().run(
      executable: 'dart',
      arguments: [script.path],
      workingDirectory: fixture.path,
      timeout: const Duration(seconds: 10),
      description: 'descendant fixture',
    );

    expect(output.exitCode, 0);
    final childPid = int.parse(pidFile.readAsStringSync());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(_processExists(childPid), isFalse);
  });

  test('never signals a process outside the isolated group', () async {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-group-boundary-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final sleeper = File('${fixture.path}/sleeper.dart')
      ..writeAsStringSync('''
Future<void> main() => Future<void>.delayed(const Duration(seconds: 30));
''');
    final unrelated = await Process.start('dart', [sleeper.path]);
    addTearDown(() async {
      unrelated.kill(ProcessSignal.sigkill);
      await unrelated.exitCode;
    });
    final command = File('${fixture.path}/command.dart')
      ..writeAsStringSync('void main() {}\n');

    final output = await const SystemMutationCommandExecutor().run(
      executable: 'dart',
      arguments: [command.path],
      workingDirectory: fixture.path,
      timeout: const Duration(seconds: 10),
      description: 'process-group boundary fixture',
    );

    expect(output.exitCode, 0);
    expect(_processExists(unrelated.pid), isTrue);
  });

  test('bounds command output before it can exhaust memory', () async {
    final fixture = Directory.systemTemp.createTempSync(
      'aonw-mutation-output-limit-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    final script = File('${fixture.path}/excessive_output.dart')
      ..writeAsStringSync('''
import 'dart:io';

void main() {
  final block = List.filled(1024, 'x').join();
  for (var index = 0; index < 10000; index += 1) {
    stdout.write(block);
  }
}
''');

    await expectLater(
      () => const SystemMutationCommandExecutor().run(
        executable: 'dart',
        arguments: [script.path],
        workingDirectory: fixture.path,
        timeout: const Duration(seconds: 10),
        description: 'output-limit fixture',
      ),
      throwsA(
        isA<MutationFailure>().having(
          (error) => error.message,
          'message',
          contains('stdout limit'),
        ),
      ),
    );
  });
}

bool _processExists(int pid) {
  final result = Process.runSync(
    'kill',
    ['-0', '$pid'],
    stdoutEncoding: systemEncoding,
    stderrEncoding: systemEncoding,
  );
  return result.exitCode == 0;
}
