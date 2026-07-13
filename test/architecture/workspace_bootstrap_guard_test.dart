import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _bootstrapPath = 'tool/bootstrap_workspace.sh';
const _toolchainPath = 'tool/check_toolchain.sh';

void main() {
  test('.fvmrc is the single exact Flutter SDK pin', () {
    final pin =
        jsonDecode(File('.fvmrc').readAsStringSync()) as Map<String, dynamic>;

    expect(pin, hasLength(1));
    expect(pin, contains('flutter'));
    expect(
      pin['flutter'],
      matches(RegExp(r'^\d+\.\d+\.\d+$')),
      reason: 'The workspace must select one exact Flutter release.',
    );

    final gitignore = File('.gitignore').readAsStringSync();
    expect(
      RegExp(r'^\.fvm/$', multiLine: true).hasMatch(gitignore),
      isTrue,
      reason: 'FVM state is local; only .fvmrc is committed.',
    );
  });

  test('every GitHub Flutter setup consumes .fvmrc', () {
    final workflowDirectory = Directory('.github/workflows');
    final workflows = workflowDirectory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.yml') || file.path.endsWith('.yaml'),
    );
    var setupCount = 0;

    for (final workflow in workflows) {
      final source = workflow.readAsStringSync();
      final steps = source.split(RegExp(r'(?=^\s+- name:)', multiLine: true));
      for (final step in steps.where(
        (step) => step.contains('uses: subosito/flutter-action@'),
      )) {
        final pins = RegExp(
          r'^\s*flutter-version-file:\s*\.fvmrc\s*$',
          multiLine: true,
        ).allMatches(step).length;
        expect(pins, 1, reason: workflow.path);
        setupCount += 1;
      }

      expect(
        RegExp(r'^\s*flutter-version:', multiLine: true).hasMatch(source),
        isFalse,
        reason: '${workflow.path} duplicates the canonical SDK pin.',
      );
    }

    expect(setupCount, greaterThan(0));
  });

  test('toolchain checker validates Flutter and its bundled Dart', () {
    final checker = File(_toolchainPath);

    expect(checker.existsSync(), isTrue, reason: _toolchainPath);
    _expectExecutable(checker);
    final source = checker.readAsStringSync();
    expect(source, contains('set -euo pipefail'));
    expect(source, contains('.fvmrc'));
    expect(source, contains('--version --machine'));
    expect(source, contains('frameworkVersion'));
    expect(source, contains('dartSdkVersion'));
    expect(source, contains('flutterRoot'));
    expect(source, contains('command -v flutter'));
    expect(source, contains('command -v dart'));
    expect(source, contains('pin_pattern'));
    expect(source, isNot(contains("tr -d '[:space:]'")));
    expect(source, isNot(contains('FLUTTER_BIN')));
    expect(source, isNot(contains('DART_BIN')));
    expect(source, contains('Flutter and Dart must both come directly from'));
  });

  test('toolchain checker fails closed when Flutter is unavailable', () {
    if (Platform.isWindows) return;

    final result = Process.runSync(
      'bash',
      [_toolchainPath],
      environment: {...Platform.environment, 'PATH': '/usr/bin:/bin'},
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Flutter is required'));
  });

  test('toolchain checker rejects a malformed FVM config', () {
    if (Platform.isWindows) return;
    final repository = Directory.systemTemp.createTempSync(
      'aonw-malformed-fvmrc.',
    );
    addTearDown(() => repository.deleteSync(recursive: true));
    final toolDirectory = Directory('${repository.path}/tool')..createSync();
    File(_toolchainPath).copySync('${toolDirectory.path}/check_toolchain.sh');
    for (final malformed in const [
      '"flutter": "3.44.2"\n',
      '{"flutter": "3. 44.2"}\n',
    ]) {
      File('${repository.path}/.fvmrc').writeAsStringSync(malformed);
      final result = Process.runSync('bash', [
        '${toolDirectory.path}/check_toolchain.sh',
      ], environment: Platform.environment);

      expect(result.exitCode, isNot(0), reason: malformed);
      expect(
        result.stderr,
        contains('.fvmrc must contain only one exact'),
        reason: malformed,
      );
    }
  });

  test('toolchain checker rejects a different Flutter release', () {
    if (Platform.isWindows) return;
    final fake = _temporaryExecutable('flutter', '''
#!/bin/sh
printf '%s\\n' '{'
printf '%s\\n' '  "frameworkVersion": "0.0.0",'
printf '%s\\n' '  "channel": "stable",'
printf '%s\\n' '  "dartSdkVersion": "0.0.0"'
printf '%s\\n' '}'
''');
    addTearDown(() => fake.directory.deleteSync(recursive: true));

    final result = Process.runSync(
      'bash',
      [_toolchainPath],
      environment: {
        ...Platform.environment,
        'PATH': '${fake.directory.path}:${Platform.environment['PATH']}',
      },
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Flutter version mismatch'));
  });

  test('toolchain checker rejects same-version shims outside the SDK', () {
    if (Platform.isWindows) return;
    final dartVersion = Platform.version.split(' ').first;
    final fake = _temporaryExecutable('dart', '''
#!/bin/sh
printf '%s\\n' 'Dart SDK version: $dartVersion (stable) on "test"' >&2
''');
    _writeExecutable(fake.directory, 'flutter', '''
#!/bin/sh
exec "\$AONW_REAL_FLUTTER" "\$@"
''');
    addTearDown(() => fake.directory.deleteSync(recursive: true));
    final flutterMachine =
        jsonDecode(
              Process.runSync('flutter', ['--version', '--machine']).stdout
                  as String,
            )
            as Map<String, dynamic>;
    final realFlutter = '${flutterMachine['flutterRoot']}/bin/flutter';

    final result = Process.runSync(
      'bash',
      [_toolchainPath],
      environment: {
        ...Platform.environment,
        'PATH': '${fake.directory.path}:${Platform.environment['PATH']}',
        'AONW_REAL_FLUTTER': realFlutter,
      },
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Flutter and Dart must both come directly'));
  });

  test('bootstrap resolves all four lockfiles without generating code', () {
    final bootstrap = File(_bootstrapPath);

    expect(bootstrap.existsSync(), isTrue, reason: _bootstrapPath);
    _expectExecutable(bootstrap);
    final source = bootstrap.readAsStringSync();
    expect(source, contains('set -euo pipefail'));
    expect(source, contains('tool/check_toolchain.sh'));
    expect(source, contains('pubspec.yaml'));
    expect(source, contains('pubspec.lock'));
    expect(source, contains('packages/aonw_core'));
    expect(source, contains('packages/aonw_server_client'));
    expect(source, contains('server'));
    expect(
      source,
      contains(
        'for package in packages/aonw_core packages/aonw_server_client server',
      ),
    );
    expect(source, contains('cd "\${repo_root}/\${package}"'));

    final pubGets = RegExp(
      r'(?:flutter|dart)\s+pub\s+get[^\n;]*',
    ).allMatches(source).map((match) => match.group(0)!).toList();
    expect(pubGets, isNotEmpty);
    expect(pubGets, everyElement(contains('--enforce-lockfile')));
    expect(source, isNot(contains('third_party/sign_in_with_apple')));
    expect(source, isNot(contains('build_runner')));
    expect(source, isNot(contains('gen-l10n')));
    expect(source, isNot(contains('create-migration')));
    expect(source, isNot(matches(RegExp(r'\bmake\s+ci\b'))));
  });

  test('Make exposes one bootstrap and prefers an installed local SDK', () {
    final makefile = File('Makefile').readAsStringSync();
    final bootstrap = _makeTarget(makefile, 'bootstrap');
    final toolchain = _makeTarget(makefile, 'toolchain-check');
    final generated = _makeTarget(makefile, 'generated-code-check');

    expect(
      RegExp(
        r'^\.PHONY:[^\n]*\bbootstrap\b',
        multiLine: true,
      ).hasMatch(makefile),
      isTrue,
    );
    expect(makefile, contains('.fvm/flutter_sdk/bin'));
    expect(makefile, contains('export PATH :='));
    expect(bootstrap, contains(_bootstrapPath));
    expect(bootstrap, contains('serverpod-cli-ensure'));
    expect(toolchain, contains(_toolchainPath));
    expect(generated, contains('toolchain-check'));
  });

  test('CI exercises bootstrap before generated-code drift', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final bootstrap = workflow.indexOf('run: make bootstrap');
    final generated = workflow.indexOf('run: make generated-code-check');

    expect(bootstrap, greaterThanOrEqualTo(0));
    expect(generated, greaterThan(bootstrap));
  });

  test('setup documentation uses the single bootstrap command', () {
    for (final path in const [
      'README.md',
      'CONTRIBUTING.md',
      'docs/README.md',
      'docs/build-and-deploy.md',
      '.github/PULL_REQUEST_TEMPLATE.md',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('make bootstrap'), reason: path);
    }
  });
}

void _expectExecutable(File file) {
  if (Platform.isWindows) return;
  expect(
    file.statSync().mode & 0x49,
    isNot(0),
    reason: '${file.path} must have at least one executable mode bit',
  );
}

({Directory directory, File file}) _temporaryExecutable(
  String name,
  String source,
) {
  final directory = Directory.systemTemp.createTempSync(
    'aonw-toolchain-guard.',
  );
  final file = _writeExecutable(directory, name, source);
  return (directory: directory, file: file);
}

File _writeExecutable(Directory directory, String name, String source) {
  final file = File('${directory.path}/$name')..writeAsStringSync(source);
  final chmod = Process.runSync('chmod', ['+x', file.path]);
  expect(chmod.exitCode, 0, reason: chmod.stderr.toString());
  return file;
}

String _makeTarget(String makefile, String name) {
  final header = RegExp(
    '^${RegExp.escape(name)}:[^\\n]*(?:\\n|\$)',
    multiLine: true,
  ).firstMatch(makefile);
  expect(header, isNotNull, reason: 'Missing Make target: $name');

  final nextTarget = RegExp(
    r'^[A-Za-z0-9_.-]+:[^=\n]*(?:\n|$)',
    multiLine: true,
  ).allMatches(makefile, header!.end).firstOrNull;
  return makefile.substring(header.start, nextTarget?.start ?? makefile.length);
}
