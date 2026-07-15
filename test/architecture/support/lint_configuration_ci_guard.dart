import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void expectQualityGateSteps(List<YamlMap> steps) {
  final checkout = _stepNamed(steps, 'Checkout repository');
  final checkoutWith = checkout['with'];
  expect(checkoutWith, isA<YamlMap>());
  expect(checkoutWith as YamlMap, containsPair('fetch-depth', 0));
  final fetchRatchets = _stepNamed(steps, 'Fetch CI ratchet commits');
  expect(_keySet(fetchRatchets), {'name', 'run'});
  expect(
    fetchRatchets['run'],
    contains(
      r'for ref in "$COVERAGE_BASE_REF" "$COVERAGE_RATCHET_REF" '
      r'"$ARCHITECTURE_RATCHET_REF"; do',
    ),
  );
  expect(fetchRatchets['run'], contains(r'case "$ref" in'));
  expect(fetchRatchets['run'], contains('origin/*)'));
  expect(fetchRatchets['run'], contains(r'branch="${ref#origin/}"'));
  expect(
    fetchRatchets['run'],
    contains(
      r'git fetch --no-tags origin "refs/heads/$branch:refs/remotes/origin/$branch"',
    ),
  );
  expect(fetchRatchets['run'], contains(r'git fetch --no-tags origin "$ref"'));
  expect(steps.indexOf(fetchRatchets), greaterThan(steps.indexOf(checkout)));
  final analyze = _stepNamed(steps, 'Analyze');
  expect(_keySet(analyze), {'name', 'run'});
  expect(analyze, containsPair('run', r'${{ matrix.analyze }}'));
  final test = _stepNamed(steps, 'Test');
  expect(_keySet(test), {'name', 'run'});
  expect(test, containsPair('run', r'${{ matrix.test }}'));
  expect(steps.any((step) => step['name'] == 'Get dependencies'), isFalse);
}

YamlMap _stepNamed(List<YamlMap> steps, String name) =>
    steps.singleWhere((step) => step['name'] == name);

Set<String> _keySet(YamlMap map) => map.keys.cast<String>().toSet();
