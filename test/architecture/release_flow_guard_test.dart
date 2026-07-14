import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/options.dart';

void main() {
  final makefile = File('Makefile').readAsStringSync();
  final docs = File('docs/build-and-deploy.md').readAsStringSync();

  test('public release options have one documented default registry', () {
    expect(releaseOptions, hasLength(17));
    for (final option in releaseOptions) {
      expect(
        makefile,
        contains(
          '${option.name} ?='
          '${option.defaultValue.isEmpty ? '' : ' ${option.defaultValue}'}',
        ),
        reason: 'Make default drifted for ${option.name}',
      );
      expect(makefile, contains(option.name));
      final docsRow = docs
          .split('\n')
          .singleWhere((line) => line.startsWith('| `${option.name}` |'));
      final documentedDefault = option.defaultValue.isEmpty
          ? '| empty |'
          : '| `${option.defaultValue}` |';
      expect(
        docsRow,
        contains(documentedDefault),
        reason: 'Docs default drifted for ${option.name}',
      );
      for (final value in option.allowedValues.split('|')) {
        final documented = value == 'integer>current'
            ? 'integer greater than current'
            : value;
        expect(
          docsRow,
          contains(documented),
          reason: 'Docs enum drifted for ${option.name}: $value',
        );
      }
    }
  });

  test('deploy-all-plan delegates only to the read-only Dart planner', () {
    final plan = _targetBody(
      makefile,
      target: 'deploy-all-plan',
      nextTarget: 'deploy-all-preflight',
    );

    expect(plan, contains('dart tool/release/deploy_all_plan.dart'));
    for (final option in releaseOptions) {
      expect(plan, contains(option.name), reason: option.name);
    }
    for (final forbidden in [
      'git ',
      'ssh ',
      'flutter ',
      r'$(MAKE) --no-print-directory release-check',
      r'$(MAKE) --no-print-directory bump-version',
    ]) {
      expect(plan, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test(
    'planner implementation has no filesystem, process, or network action',
    () {
      final sources = Directory('tool/release')
          .listSync()
          .whereType<File>()
          .map((file) => file.readAsStringSync())
          .join('\n');
      for (final forbidden in [
        'Process.',
        'File(',
        'Directory(',
        'HttpClient(',
        'Socket.',
      ]) {
        expect(sources, isNot(contains(forbidden)), reason: forbidden);
      }
    },
  );

  test('every external store action is strict opt-in', () {
    expect(makefile, contains('DEPLOY_ALL_STEAMWORKS ?= 0'));
    expect(makefile, contains('DEPLOY_ALL_GOOGLE_PLAY ?= 0'));
    expect(makefile, contains('DEPLOY_ALL_ITCH ?= 0'));
    final deployAll = _deployAllBody(makefile);
    expect(deployAll, contains(r'[ "$(DEPLOY_ALL_ITCH)" = "1" ]'));
    expect(deployAll, isNot(contains(r'[ -n "$(ITCH_TARGET)" ]')));
  });

  test(
    'release gates precede push and backend precedes client publication',
    () {
      final deployAll = _deployAllBody(makefile);
      final gates = RegExp(
        r'\$\(MAKE\) --no-print-directory release-check',
      ).allMatches(deployAll).toList();
      final preflight = deployAll.indexOf(
        r'$(MAKE) --no-print-directory deploy-all-preflight',
      );
      final bump = deployAll.indexOf(
        r'$(MAKE) --no-print-directory bump-version',
      );
      final push = deployAll.indexOf('git push origin main');
      final prepare = deployAll.indexOf(r'$(MAKE) --no-print-directory steam ');
      final backend = deployAll.indexOf('make deploy PROFILE=');
      final backendHealth = deployAll.indexOf(
        r'$(MAKE) --no-print-directory health',
        backend,
      );
      final steamUpload = deployAll.indexOf(
        r'$(MAKE) --no-print-directory steam-upload',
      );
      final googlePlay = deployAll.indexOf(
        r'$(MAKE) --no-print-directory android-upload',
      );
      final itch = deployAll.indexOf(
        r'$(MAKE) --no-print-directory itch-upload',
      );

      expect(gates, hasLength(2));
      expect(preflight, greaterThanOrEqualTo(0));
      expect(gates.first.start, greaterThan(preflight));
      expect(bump, greaterThan(gates.first.start));
      expect(gates.last.start, greaterThan(bump));
      expect(push, greaterThan(gates.last.start));
      expect(prepare, greaterThan(push));
      expect(backend, greaterThan(prepare));
      expect(backendHealth, greaterThan(backend));
      expect(steamUpload, greaterThan(backendHealth));
      expect(googlePlay, greaterThan(backendHealth));
      expect(itch, greaterThan(backendHealth));
      expect(deployAll, isNot(contains('android-deploy')));
    },
  );

  test('failure-sensitive branches cannot continue with stale artifacts', () {
    final deployAll = _deployAllBody(makefile);
    final steamBlock = deployAll.substring(
      deployAll.indexOf('[7/13]'),
      deployAll.indexOf('[8/13]'),
    );
    expect(steamBlock, contains('@set -e;'));
    expect(
      steamBlock.indexOf('steam-upload'),
      greaterThan(steamBlock.indexOf('steam-prepare-from-dist')),
    );

    final ios = _targetBody(
      makefile,
      target: 'archive-ios-if-possible',
      nextTarget: 'android-keystore',
    );
    expect(ios, contains('off)'));
    expect(ios, contains('best-effort)'));
    expect(ios, contains('required)'));
    expect(ios, isNot(contains('archive-ios ||')));
    expect(
      makefile,
      contains('Google Play validation finished; no release was published'),
    );
  });

  test('one Linux artifact serves three independent consumers', () {
    expect(
      makefile,
      contains(
        r'DEPLOY_ALL_INCLUDE_LINUX = $(if $(filter 1,$(STEAM_INCLUDE_LINUX) $(ITCH_INCLUDE_LINUX) $(DOWNLOAD_INCLUDE_LINUX)),1,0)',
      ),
    );
    expect(makefile, contains('DOWNLOAD_INCLUDE_LINUX ?= 0'));
    expect(makefile, isNot(contains(r'DOWNLOAD_INCLUDE_LINUX ?= $(ITCH')));
  });

  test('static publication consumes prepared bytes without rebuilding', () {
    final webWrapper = _targetBody(
      makefile,
      target: 'deploy-web',
      nextTarget: 'deploy-web-files',
    );
    final webUpload = _targetBody(
      makefile,
      target: 'deploy-web-files',
      nextTarget: 'build-homepage',
    );
    final homepageWrapper = _targetBody(
      makefile,
      target: 'deploy-homepage',
      nextTarget: 'deploy-homepage-files',
    );
    final homepageUpload = _targetBody(
      makefile,
      target: 'deploy-homepage-files',
      nextTarget: 'download-artifacts',
    );

    expect(webWrapper, contains(r'$(MAKE) --no-print-directory build-web'));
    expect(
      webWrapper,
      contains(r'$(MAKE) --no-print-directory deploy-web-files'),
    );
    expect(
      homepageWrapper,
      contains(r'$(MAKE) --no-print-directory build-homepage'),
    );
    expect(
      homepageWrapper,
      contains(r'$(MAKE) --no-print-directory deploy-homepage-files'),
    );
    for (final upload in [webUpload, homepageUpload]) {
      expect(upload, contains('rsync -avz --delete'));
      expect(upload, isNot(contains('flutter build')));
      expect(upload, isNot(contains('build-web')));
      expect(upload, isNot(contains('build-homepage')));
    }
  });
}

String _deployAllBody(String makefile) => _targetBody(
  makefile,
  target: 'deploy-all',
  nextTarget: 'preflight-release',
);

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
