import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/authoritative_movement_fact_guard.dart';

void main() {
  test('movement facts follow one resolved presentation graph', () async {
    final audit = await auditMovementFactGraph();
    expect(audit.violations, isEmpty);
  });

  test(
    'resolved guard rejects replacing typed facts with an empty list',
    () async {
      final source = File(movementFactGameActionsPath).readAsStringSync();
      const anchor = 'visibleMovementExecutions: movementExecutions,';
      expect(source.split(anchor), hasLength(2));

      final audit = await auditMovementFactGraph(
        sourceOverrides: {
          movementFactGameActionsPath: source.replaceFirst(
            anchor,
            'visibleMovementExecutions: const [],',
          ),
        },
      );

      expect(
        audit.violations,
        contains(contains('must forward typed movementExecutions')),
      );
    },
  );
}
