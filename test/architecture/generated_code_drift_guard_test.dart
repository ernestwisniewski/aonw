import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'tool/check_generated_code.sh';

void main() {
  test('Freezed output keeps its generator-owned whitespace policy', () {
    final attributes = File('.gitattributes').readAsStringSync();

    expect(attributes, contains('*.freezed.dart whitespace=-trailing-space'));
  });

  test('generated-code checker exists, is executable, and fails closed', () {
    final script = File(_scriptPath);

    expect(script.existsSync(), isTrue, reason: _scriptPath);
    if (!Platform.isWindows) {
      expect(
        script.statSync().mode & 0x49,
        isNot(0),
        reason: '$_scriptPath must have at least one executable mode bit',
      );
    }

    final source = script.readAsStringSync();
    expect(source, contains('set -euo pipefail'));
    expect(source, contains('mktemp -d'));
    expect(source, matches(RegExp(r'trap [^\n]*EXIT')));
  });

  test('checker snapshots HEAD, binary changes, and untracked files', () {
    final source = _shellSource();

    expect(
      source,
      matches(RegExp(r'git[^\n;]*archive[^\n;]*\bHEAD\b')),
      reason: 'The temporary snapshot must start from tracked HEAD contents.',
    );
    expect(
      source,
      matches(RegExp(r'git[^\n;]*diff[^\n;]*--binary[^\n;]*\bHEAD\b')),
      reason: 'Staged and unstaged binary-safe changes must be applied.',
    );
    expect(
      source,
      matches(
        RegExp(r'git[^\n;]*ls-files[^\n;]*--others[^\n;]*--exclude-standard'),
      ),
      reason: 'Untracked, non-ignored inputs must be copied into the snapshot.',
    );
  });

  test('checker creates a temporary Git baseline before generation', () {
    final source = _shellSource();

    expect(source, contains('snapshot_git init'));
    expect(source, contains('snapshot_git add -A'));
    expect(source, contains('snapshot_git commit'));
    expect(source, contains('GIT_CONFIG_NOSYSTEM=1'));
    expect(source, contains('GIT_CONFIG_GLOBAL=/dev/null'));
    expect(source, contains('commit.gpgSign false'));
    expect(source, contains('core.hooksPath /dev/null'));
  });

  test('checker resolves locked dependencies and runs every generator', () {
    final source = _shellSource();
    final pubGetCommands = RegExp(
      r'(?:flutter|dart)\s+pub\s+get[^\n;]*',
    ).allMatches(source).map((match) => match.group(0)!).toList();

    expect(pubGetCommands, isNotEmpty);
    expect(
      pubGetCommands,
      everyElement(contains('--enforce-lockfile')),
      reason: 'Every pub resolution in the drift oracle must honor its lock.',
    );
    expect(source, contains('packages/aonw_core'));
    expect(source, contains('server'));
    expect(source, contains('tool/check_toolchain.sh'));
    expect(source, isNot(contains('.github/workflows/ci.yml')));
    expect(source, isNot(contains('flutter --version --machine')));

    expect(
      source,
      contains('dart run build_runner build'),
      reason: 'aonw_core needs its own build_runner invocation.',
    );
    expect(
      source,
      contains('flutter pub run build_runner build'),
      reason: 'The Flutter root needs its own build_runner invocation.',
    );
    expect(
      source,
      isNot(contains('--delete-conflicting-outputs')),
      reason: 'The isolated oracle must expose conflicts instead of deleting.',
    );
    expect(source, contains('flutter gen-l10n'));
    expect(source, contains('SERVERPOD_CLI'));
    expect(source, matches(RegExp(r'serverpod_cli[^\n;]*\s+generate\b')));
    expect(source, contains('create-migration'));
  });

  test('checker recreates every generated exclusion from source', () {
    final source = _shellSource();

    expect(
      RegExp(
        r"find lib -type f \\\( -name '\*\.g\.dart' -o -name "
        r"'\*\.freezed\.dart' \\\) -delete",
      ).allMatches(source),
      hasLength(2),
    );
    for (final path in const [
      'lib/l10n/generated',
      'lib/src/generated',
      '../packages/aonw_server_client/lib/src/protocol',
      'test/integration/test_tools',
    ]) {
      expect(source, contains(path), reason: path);
    }
    expect(
      source,
      isNot(contains('test/integration/test_tools/serverpod_test_tools.dart')),
      reason: 'The entire generated test-tools directory must be recreated.',
    );
    expect(
      source.indexOf('rm -rf lib/l10n/generated'),
      lessThan(source.indexOf('flutter gen-l10n')),
    );
    expect(
      source.indexOf('lib/src/generated'),
      lessThan(source.indexOf(r'"${serverpod_cli}" generate')),
    );
  });

  test('checker ends with a complete tracked and untracked status check', () {
    final source = _shellSource();
    final statuses = RegExp(
      r'git[^\n;]*status[^\n;]*--porcelain[^\n;]*--untracked-files=all[^\n;]*',
    ).allMatches(source).map((match) => match.group(0)!).toList();

    expect(statuses, isNotEmpty);
    expect(
      statuses,
      everyElement(isNot(contains(' -- '))),
      reason: 'The final oracle must inspect the whole temporary repository.',
    );
  });

  test(
    'Make exposes one generated-code gate and keeps compatibility alias',
    () {
      final makefile = File('Makefile').readAsStringSync();
      final generatedTarget = _makeTarget(makefile, 'generated-code-check');
      final ciTarget = _makeTarget(makefile, 'ci');
      final migrationAlias = _makeTarget(makefile, 'check-migrations');

      expect(
        RegExp(
          r'^\.PHONY:[^\n]*\bgenerated-code-check\b',
          multiLine: true,
        ).hasMatch(makefile),
        isTrue,
      );
      expect(generatedTarget, contains(_scriptPath));
      expect(ciTarget, contains('generated-code-check'));
      expect(migrationAlias, contains('generated-code-check'));
      expect(migrationAlias, isNot(contains('serverpod generate')));
      expect(migrationAlias, isNot(contains('create-migration')));
    },
  );

  test('CI runs generated-code drift in one dedicated job', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final calls = RegExp(
      r'^\s*run:\s*make generated-code-check\s*$',
      multiLine: true,
    ).allMatches(workflow).toList();

    expect(calls, hasLength(1));
    final job = _workflowJobAt(workflow, calls.single.start);
    expect(job.name, contains('generated'));
    expect(job.name, isNot('quality-gate'));
    expect(job.body, contains('actions/checkout@'));
    expect(job.body, contains('subosito/flutter-action@'));
    expect(job.body, contains('make bootstrap'));
    expect(
      job.body.indexOf('make bootstrap'),
      lessThan(job.body.indexOf('make generated-code-check')),
    );
  });

  test('contributor and deployment docs name the generated-code gate', () {
    for (final path in const [
      'README.md',
      'CONTRIBUTING.md',
      'docs/build-and-deploy.md',
      '.github/PULL_REQUEST_TEMPLATE.md',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(
        file.readAsStringSync(),
        contains('generated-code-check'),
        reason: path,
      );
    }
  });
}

String _shellSource() {
  final file = File(_scriptPath);
  expect(file.existsSync(), isTrue, reason: _scriptPath);
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'\\\r?\n'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ');
}

String _makeTarget(String makefile, String name) {
  final header = RegExp(
    '^${RegExp.escape(name)}:[^\\n]*(?:\\n|\$)',
    multiLine: true,
  ).firstMatch(makefile);
  expect(header, isNotNull, reason: 'Missing Make target: $name');

  final bodyStart = header!.start;
  final nextTarget = RegExp(
    r'^[A-Za-z0-9_.-]+:[^=\n]*(?:\n|$)',
    multiLine: true,
  ).allMatches(makefile, header.end).firstOrNull;
  return makefile.substring(bodyStart, nextTarget?.start ?? makefile.length);
}

({String name, String body}) _workflowJobAt(String workflow, int offset) {
  final headers = RegExp(
    r'^  ([a-zA-Z0-9_-]+):\s*$',
    multiLine: true,
  ).allMatches(workflow).where((match) => match.start < offset).toList();
  expect(
    headers,
    isNotEmpty,
    reason: 'Generated-code call is outside a CI job',
  );

  final header = headers.last;
  final nextHeader = RegExp(
    r'^  [a-zA-Z0-9_-]+:\s*$',
    multiLine: true,
  ).allMatches(workflow, header.end).firstOrNull;
  return (
    name: header.group(1)!,
    body: workflow.substring(
      header.start,
      nextHeader?.start ?? workflow.length,
    ),
  );
}
