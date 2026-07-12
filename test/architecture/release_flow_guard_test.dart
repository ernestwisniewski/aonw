import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final makefile = File('Makefile').readAsStringSync();

  test('store uploads are opt-in for the aggregate release flow', () {
    expect(makefile, contains('DEPLOY_ALL_STEAMWORKS ?= 0'));
    expect(makefile, contains('DEPLOY_ALL_GOOGLE_PLAY ?= 0'));
  });

  test('release commit passes the full gate before push and publication', () {
    final deployAll = _targetBody(
      makefile,
      target: 'deploy-all',
      nextTarget: 'preflight-release',
    );
    final gates = RegExp(
      r'\$\(MAKE\) --no-print-directory release-check',
    ).allMatches(deployAll).toList();
    final bump = deployAll.indexOf(
      r'$(MAKE) --no-print-directory bump-version',
    );
    final push = deployAll.indexOf('git push origin main');
    final steamUpload = deployAll.indexOf(
      r'$(MAKE) --no-print-directory steam-upload',
    );
    final googlePlayUpload = deployAll.indexOf(
      r'$(MAKE) --no-print-directory android-deploy',
    );

    expect(gates, hasLength(2));
    expect(bump, greaterThanOrEqualTo(0));
    expect(push, greaterThan(bump));
    expect(steamUpload, greaterThan(push));
    expect(googlePlayUpload, greaterThan(push));
    expect(gates.first.start, lessThan(bump));
    expect(gates.last.start, greaterThan(bump));
    expect(gates.last.start, lessThan(push));
    expect(gates.last.start, lessThan(steamUpload));
    expect(gates.last.start, lessThan(googlePlayUpload));
  });
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
