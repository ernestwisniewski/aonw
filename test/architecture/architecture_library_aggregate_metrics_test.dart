import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/dart_metrics.dart';
import '../../tool/architecture/failure.dart';
import '../../tool/architecture/library_aggregate_baseline.dart';
import '../../tool/architecture/library_aggregate_metrics.dart';
import '../../tool/architecture/library_aggregate_policy.dart';
import '../../tool/architecture/policy.dart';

void main() {
  test('library aggregate sums functions, lines, and both complexities', () {
    final root = measureDartSource(
      'lib/root.dart',
      '''
void root(bool enabled) {
  if (enabled) return;
}
'''
          .trimLeft(),
    );
    final part = measureDartSource(
      'lib/src/part.dart',
      '''
part of '../root.dart';

int normalize(int value) => value > 0 ? value : 0;
'''
          .trimLeft(),
    );

    final aggregate = LibraryAggregateMetric.fromSources([root, part]);

    expect(aggregate.sourceLines, root.fileLines + part.fileLines);
    expect(aggregate.callableCount, 2);
    expect(
      aggregate.callableLines,
      root.callables.single.lines + part.callables.single.lines,
    );
    expect(aggregate.cyclomaticComplexity, 4);
    expect(aggregate.cognitiveComplexity, 2);
  });

  test('part-of URI resolves to one stable repository library owner', () {
    expect(
      resolveLibraryOwner(
        'lib/feature/support/actions.dart',
        "part of '../feature.dart';\n",
      ),
      'lib/feature/feature.dart',
    );
    expect(
      () => resolveRepositoryUri('lib/part.dart', '../../outside.dart'),
      throwsA(isA<ArchitectureFailure>()),
    );
  });

  test('committed aggregate debt is canonical and above role targets', () {
    final architecturePolicy = ArchitecturePolicy.load(
      'tool/architecture_policy.json',
    );
    final aggregatePolicy = LibraryAggregatePolicy.load(
      'tool/architecture_aggregate_policy.json',
      architecturePolicy,
    );
    final baseline = LibraryAggregateBaseline.load(
      'tool/architecture_aggregate_baseline.json',
      architecturePolicy,
      aggregatePolicy,
    );
    final gameHud = baseline.scopes['root_test']!;

    expect(
      gameHud.sourceLines['test/game/game_hud_test.dart'],
      greaterThan(2500),
    );
    expect(
      gameHud.callableCount['test/game/game_hud_test.dart'],
      greaterThan(120),
    );
    expect(
      gameHud.callableLines['test/game/game_hud_test.dart'],
      greaterThan(2200),
    );
  });

  test(
    'aggregate ratchet rejects new debt and growth but allows reduction',
    () {
      final historical = _aggregateBaseline(
        sourceLines: const {'lib/legacy.dart': 1600},
        callableCount: const {'lib/legacy.dart': 90},
      );
      final current = _aggregateBaseline(
        sourceLines: const {'lib/legacy.dart': 1601, 'lib/new_debt.dart': 1700},
      );

      expect(current.ratchetDifferences(historical), [
        'root library lines debt cannot be introduced: [lib/new_debt.dart]',
        'root library lines debt cannot grow: lib/legacy.dart 1600 -> 1601',
      ]);
      expect(
        _aggregateBaseline(
          sourceLines: const {'lib/legacy.dart': 1501},
        ).ratchetDifferences(historical),
        isEmpty,
      );
    },
  );
}

LibraryAggregateBaseline _aggregateBaseline({
  Map<String, int> sourceLines = const {},
  Map<String, int> callableCount = const {},
}) {
  return LibraryAggregateBaseline(
    scopes: {
      'root': ScopeLibraryAggregateBaseline(
        sourceLines: sourceLines,
        callableCount: callableCount,
        callableLines: const {},
        cyclomaticComplexity: const {},
        cognitiveComplexity: const {},
      ),
    },
  );
}
