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
  _expectSynchronizedDevRatchetsStep(steps, fetchRatchets);
  final analyze = _stepNamed(steps, 'Analyze');
  expect(_keySet(analyze), {'name', 'run'});
  expect(analyze, containsPair('run', r'${{ matrix.analyze }}'));
  final test = _stepNamed(steps, 'Test');
  expect(_keySet(test), {'name', 'run'});
  expect(test, containsPair('run', r'${{ matrix.test }}'));
  final buildCoverageDiagnostic = _stepNamed(
    steps,
    'Build coverage baseline diagnostic',
  );
  expect(_keySet(buildCoverageDiagnostic), {
    'name',
    'if',
    'continue-on-error',
    'run',
  });
  expect(
    buildCoverageDiagnostic,
    containsPair('if', "always() && matrix.package != 'server_client'"),
  );
  expect(buildCoverageDiagnostic, containsPair('continue-on-error', true));
  expect(
    buildCoverageDiagnostic['run'],
    '''report="coverage/\${{ matrix.package }}.lcov.info"
if [ -f "\$report" ]; then
  dart run tool/check_coverage.dart snapshot \\
    --scope "\${{ matrix.package }}" \\
    > "/tmp/aonw-coverage-\${{ matrix.package }}.json"
fi
''',
  );
  expect(
    steps.indexOf(buildCoverageDiagnostic),
    greaterThan(steps.indexOf(test)),
  );
  final uploadCoverageDiagnostics = _stepNamed(
    steps,
    'Upload coverage diagnostics',
  );
  expect(_keySet(uploadCoverageDiagnostics), {'name', 'if', 'uses', 'with'});
  expect(
    uploadCoverageDiagnostics,
    containsPair('if', "always() && matrix.package != 'server_client'"),
  );
  expect(
    uploadCoverageDiagnostics,
    containsPair(
      'uses',
      'actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a',
    ),
  );
  final uploadWith = uploadCoverageDiagnostics['with'];
  expect(uploadWith, isA<YamlMap>());
  expect(_keySet(uploadWith! as YamlMap), {
    'name',
    'path',
    'if-no-files-found',
    'retention-days',
  });
  expect(
    uploadWith,
    containsPair('name', r'coverage-${{ matrix.package }}-${{ github.sha }}'),
  );
  expect(
    uploadWith,
    containsPair(
      'path',
      '/tmp/aonw-coverage-\${{ matrix.package }}.json\n'
          'coverage/\${{ matrix.package }}.lcov.info\n',
    ),
  );
  expect(uploadWith, containsPair('if-no-files-found', 'ignore'));
  expect(uploadWith, containsPair('retention-days', 14));
  expect(
    steps.indexOf(uploadCoverageDiagnostics),
    greaterThan(steps.indexOf(buildCoverageDiagnostic)),
  );
  expect(steps.any((step) => step['name'] == 'Get dependencies'), isFalse);
}

void _expectSynchronizedDevRatchetsStep(
  List<YamlMap> steps,
  YamlMap fetchRatchets,
) {
  final normalize = _stepNamed(steps, 'Normalize synchronized dev ratchets');
  expect(_keySet(normalize), {'name', 'if', 'run'});
  expect(
    normalize['if'],
    "github.event_name == 'push' && github.ref_name == 'dev'",
  );
  expect(
    normalize['run'],
    contains(r'"$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"'),
  );
  expect(
    normalize['run'],
    contains(r'echo "COVERAGE_RATCHET_REF=origin/main" >> "$GITHUB_ENV"'),
  );
  expect(
    normalize['run'],
    contains(r'echo "ARCHITECTURE_RATCHET_REF=origin/main" >> "$GITHUB_ENV"'),
  );
  expect(steps.indexOf(normalize), greaterThan(steps.indexOf(fetchRatchets)));
}

YamlMap _stepNamed(List<YamlMap> steps, String name) =>
    steps.singleWhere((step) => step['name'] == name);

Set<String> _keySet(YamlMap map) => map.keys.cast<String>().toSet();
