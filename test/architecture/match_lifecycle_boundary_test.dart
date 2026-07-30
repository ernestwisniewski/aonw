import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/match_lifecycle_boundary_guard.dart';

void main() {
  test('raw lifecycle values stay inside exact codec boundaries', () async {
    final audit = await auditMatchLifecycleBoundaries();
    expect(audit.violations, isEmpty);
  });

  test('guard rejects a raw authoritative finished writer', () async {
    final source = File(lifecycleServicePath).readAsStringSync();
    final audit = await auditMatchLifecycleBoundaries(
      sourceOverrides: {
        lifecycleServicePath:
            "$source\n"
            "WireMatch rawFinishedWriter(WireMatch match) => "
            "match.copyWith(state: 'finished');\n",
      },
    );

    expect(
      audit.violations,
      contains(contains('Raw lifecycle value inventory changed')),
    );
  });

  test('guard rejects a raw snapshot phase comparison', () async {
    final source = File(lifecycleServicePath).readAsStringSync();
    final audit = await auditMatchLifecycleBoundaries(
      sourceOverrides: {
        lifecycleServicePath:
            "$source\n"
            "bool rawRunningPhase(Map<String, dynamic> state) => "
            "state['phase'] == 'running';\n",
      },
    );

    expect(
      audit.violations,
      contains(contains('Raw lifecycle value inventory changed')),
    );
  });
}
