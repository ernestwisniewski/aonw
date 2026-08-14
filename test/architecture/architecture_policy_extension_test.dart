import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/policy.dart';
import '../../tool/architecture/strict_json.dart';

const _policyPath = 'tool/architecture_policy.json';

void main() {
  test('schema 2 permits only additive disjoint scopes', () {
    final current = ArchitecturePolicy.load(_policyPath);
    final extensionJson = _policyJson();
    final scopes = extensionJson['scopes']! as Map<String, Object?>;
    scopes['adapter'] = {
      'sourceRoot': 'packages/adapter/lib',
      'generatedPrefixes': <String>[],
      'defaultRole': 'production',
      'roleAssignments': <String, Object?>{},
    };
    extensionJson['scopes'] = sortedMap(scopes);
    final extension = ArchitecturePolicy.parse(
      canonicalJson(extensionJson),
      'extension',
    );

    expect(extension.isMonotonicExtensionOf(current), isTrue);
    expect(current.isMonotonicExtensionOf(extension), isFalse);
  });

  test('schema 2 rejects changes to existing targets', () {
    final current = ArchitecturePolicy.load(_policyPath);
    final changedJson = _policyJson();
    final roles = changedJson['roles']! as Map<String, Object?>;
    final production = roles['production']! as Map<String, Object?>;
    production['fileLines'] = 999;
    final changed = ArchitecturePolicy.parse(
      canonicalJson(changedJson),
      'changed policy',
    );

    expect(changed.isMonotonicExtensionOf(current), isFalse);
  });
}

Map<String, Object?> _policyJson() =>
    jsonDecode(File(_policyPath).readAsStringSync()) as Map<String, Object?>;
