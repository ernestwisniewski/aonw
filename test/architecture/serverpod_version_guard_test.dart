import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedDirectPackages = <String, Set<String>>{
    'pubspec.yaml': {
      'serverpod_auth_core_client',
      'serverpod_auth_idp_flutter',
    },
    'packages/aonw_server_client/pubspec.yaml': {
      'serverpod_client',
      'serverpod_auth_core_client',
      'serverpod_auth_idp_client',
    },
    'server/pubspec.yaml': {
      'serverpod',
      'serverpod_auth_core_server',
      'serverpod_auth_idp_server',
      'serverpod_test',
    },
  };

  test('Serverpod manifests and lockfiles share one exact version', () {
    final pinsByPubspec = {
      for (final entry in expectedDirectPackages.entries)
        entry.key: _serverpodManifestPins(
          entry.key,
          expectedPackages: entry.value,
        ),
    };
    final runtimeVersion = pinsByPubspec['server/pubspec.yaml']!['serverpod'];

    expect(runtimeVersion, isNotNull);
    expect(runtimeVersion, matches(_exactVersion));

    for (final entry in pinsByPubspec.entries) {
      for (final pin in entry.value.entries) {
        expect(pin.value, runtimeVersion, reason: '${entry.key}: ${pin.key}');
      }
    }

    const lockToManifest = {
      'pubspec.lock': 'pubspec.yaml',
      'packages/aonw_server_client/pubspec.lock':
          'packages/aonw_server_client/pubspec.yaml',
      'server/pubspec.lock': 'server/pubspec.yaml',
    };
    for (final entry in lockToManifest.entries) {
      final pins = _serverpodLockPins(entry.key);
      expect(pins, isNotEmpty, reason: entry.key);
      expect(
        pins.keys,
        containsAll(pinsByPubspec[entry.value]!.keys),
        reason: entry.key,
      );
      for (final pin in pins.entries) {
        expect(pin.value, runtimeVersion, reason: '${entry.key}: ${pin.key}');
      }
    }
  });

  test('migration drift check requires the exact runtime CLI version', () {
    final makefile = File('Makefile').readAsStringSync();
    final versionTarget = _targetBody(
      makefile,
      target: 'serverpod-version',
      nextTarget: 'serverpod-cli-install',
    );
    final installTarget = _targetBody(
      makefile,
      target: 'serverpod-cli-install',
      nextTarget: 'serverpod-cli-check',
    );
    final cliCheckTarget = _targetBody(
      makefile,
      target: 'serverpod-cli-check',
      nextTarget: 'generated-code-check',
    );

    expect(versionTarget, contains('server/pubspec.yaml'));
    expect(versionTarget, contains(r'^dependencies:[[:space:]]*$$'));
    expect(versionTarget, contains('in_dependencies'));
    expect(versionTarget, contains(r'$$1 == "serverpod:" && NF == 2'));
    expect(versionTarget, contains("grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+"));
    expect(
      installTarget,
      contains(r'dart pub global activate serverpod_cli "$$version"'),
    );
    expect(
      installTarget,
      contains(r'version=$$($(MAKE) --no-print-directory serverpod-version)'),
    );
    expect(
      installTarget,
      contains(r'$(MAKE) --no-print-directory serverpod-cli-check'),
    );
    expect(makefile, contains(r'PUB_CACHE ?= $(HOME)/.pub-cache'));
    expect(makefile, contains(r'SERVERPOD_CLI ?= $(PUB_CACHE)/bin/serverpod'));
    expect(cliCheckTarget, contains(r'"$(SERVERPOD_CLI)" --version'));
    expect(
      cliCheckTarget,
      contains(r'expected=$$($(MAKE) --no-print-directory serverpod-version)'),
    );
    expect(
      cliCheckTarget,
      contains(r'if [ "$$actual" != "$$expected" ]; then'),
    );
    expect(cliCheckTarget, contains('Serverpod CLI version mismatch'));
    expect(
      makefile,
      contains('generated-code-check: toolchain-check serverpod-cli-check'),
    );
    expect(makefile, contains('check-migrations: generated-code-check'));
  });

  test('CI bootstraps the CLI version declared by the server runtime', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final bootstrapCommands = RegExp(
      r'^\s*run: make bootstrap\s*$',
      multiLine: true,
    ).allMatches(workflow).toList();
    final bootstrap = workflow.indexOf('run: make bootstrap');
    final driftCheck = workflow.indexOf('run: make generated-code-check');

    expect(bootstrapCommands, hasLength(1));
    expect(bootstrap, greaterThanOrEqualTo(0));
    expect(driftCheck, greaterThan(bootstrap));
    expect(workflow, isNot(contains('run: make serverpod-cli-install')));
    expect(workflow, isNot(contains('dart pub global activate serverpod_cli')));
    expect(
      workflow,
      isNot(matches(RegExp(r'serverpod_cli\s+[0-9]+\.[0-9]+\.[0-9]+'))),
    );
  });
}

final _exactVersion = RegExp(
  r'^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$',
);

Map<String, String> _serverpodManifestPins(
  String path, {
  required Set<String> expectedPackages,
}) {
  final pins = <String, String>{};
  final sectionHeader = RegExp(r'^([a-z][a-z0-9_]*):[ \t]*$');
  final dependency = RegExp(
    r'^  (serverpod(?:_[a-z0-9_]+)?):[ \t]+([^ \t\r\n#]+)[ \t]*$',
  );
  var readsDependencies = false;

  for (final line in File(path).readAsLinesSync()) {
    final sectionMatch = sectionHeader.firstMatch(line);
    if (sectionMatch != null) {
      readsDependencies = const {
        'dependencies',
        'dev_dependencies',
      }.contains(sectionMatch.group(1));
      continue;
    }

    if (!readsDependencies) continue;
    final match = dependency.firstMatch(line);
    if (match == null) continue;

    final package = match.group(1)!;
    expect(
      pins,
      isNot(contains(package)),
      reason: 'Duplicate $package in $path',
    );
    pins[package] = match.group(2)!;
  }

  expect(pins.keys.toSet(), expectedPackages, reason: path);
  for (final pin in pins.entries) {
    expect(pin.value, matches(_exactVersion), reason: '$path: ${pin.key}');
  }
  return pins;
}

Map<String, String> _serverpodLockPins(String path) {
  final pins = <String, String>{};
  final packages = <String>{};
  final packageHeader = RegExp(r'^  ([a-z0-9_]+):$');
  final versionLine = RegExp(r'^    version: "([^"]+)"$');
  String? currentPackage;

  for (final line in File(path).readAsLinesSync()) {
    final packageMatch = packageHeader.firstMatch(line);
    if (packageMatch != null) {
      final package = packageMatch.group(1)!;
      currentPackage =
          package == 'serverpod' || package.startsWith('serverpod_')
          ? package
          : null;
      if (currentPackage != null) packages.add(currentPackage);
      continue;
    }

    if (currentPackage == null) continue;
    final versionMatch = versionLine.firstMatch(line);
    if (versionMatch != null) {
      pins[currentPackage] = versionMatch.group(1)!;
      currentPackage = null;
    }
  }

  expect(pins.keys.toSet(), packages, reason: path);
  return pins;
}

String _targetBody(
  String makefile, {
  required String target,
  required String nextTarget,
}) {
  final start = makefile.indexOf('\n$target:');
  final end = makefile.indexOf('\n$nextTarget:', start + 1);
  expect(start, greaterThanOrEqualTo(0), reason: 'Missing target $target');
  expect(end, greaterThan(start), reason: 'Missing target $nextTarget');
  return makefile.substring(start, end);
}
