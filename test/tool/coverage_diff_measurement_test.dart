import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_gate/diff_measurement.dart';

void main() {
  test('allows only an acknowledged export-only barrel without LCOV', () {
    final fixture = _DiffFixture.create(
      "export 'domain/logic.dart' show answer;\n",
    );
    addTearDown(fixture.dispose);

    final result = fixture.measure(
      acknowledgedMissingFiles: const {'lib/domain.dart'},
    );

    expect(result.structuralFailures, isEmpty);
    expect(result.byLayer, isEmpty);
    expect(result.uncoveredByLayer, isEmpty);
  });

  test('rejects an acknowledged missing source with declarations', () {
    final fixture = _DiffFixture.create('int answer() => 42;\n');
    addTearDown(fixture.dispose);

    final result = fixture.measure(
      acknowledgedMissingFiles: const {'lib/domain.dart'},
    );

    expect(
      result.structuralFailures,
      equals(const [
        'root diff: changed source is absent from LCOV: lib/domain.dart',
      ]),
    );
  });

  test('reports the coverable hits and uncovered changed lines by layer', () {
    final fixture = _DiffFixture.create("export 'domain/logic.dart';\n");
    addTearDown(fixture.dispose);

    final result = measureCoverageDiff(
      repository: fixture.directory.path,
      scopeName: 'root',
      label: 'diff',
      changedLines: const {
        'lib/domain/logic.dart': {2, 3},
      },
      sources: const {'lib/domain/logic.dart'},
      lineHitsByPath: const {
        'lib/domain/logic.dart': {2: 1, 3: 0},
      },
      isExcluded: (_) => false,
      layerFor: (_) => 'domain',
      acknowledgedMissingFiles: const {},
    );

    expect(result.byLayer, equals(const {'domain': (hit: 1, found: 2)}));
    expect(
      result.uncoveredByLayer,
      equals(const {
        'domain': ['lib/domain/logic.dart:3'],
      }),
    );
    expect(result.structuralFailures, isEmpty);
  });
}

final class _DiffFixture {
  _DiffFixture._(this.directory);

  factory _DiffFixture.create(String source) {
    final directory = Directory.systemTemp.createTempSync(
      'aonw-coverage-diff-',
    );
    final file = File('${directory.path}/lib/domain.dart');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(source);
    return _DiffFixture._(directory);
  }

  final Directory directory;

  void dispose() => directory.deleteSync(recursive: true);

  CoverageDiffMeasurement measure({
    required Set<String> acknowledgedMissingFiles,
  }) => measureCoverageDiff(
    repository: directory.path,
    scopeName: 'root',
    label: 'diff',
    changedLines: const {
      'lib/domain.dart': {1},
    },
    sources: const {'lib/domain.dart'},
    lineHitsByPath: const {},
    isExcluded: (_) => false,
    layerFor: (_) => 'domain',
    acknowledgedMissingFiles: acknowledgedMissingFiles,
  );
}
