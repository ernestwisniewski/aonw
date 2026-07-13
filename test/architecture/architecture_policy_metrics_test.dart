import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/baseline.dart';
import '../../tool/architecture/dart_metrics.dart';
import '../../tool/architecture/failure.dart';
import '../../tool/architecture/policy.dart';
import '../../tool/architecture/strict_json.dart';

void main() {
  group('strict policy', () {
    test('loads canonical schema and classifies exact profiles', () {
      final policy = ArchitecturePolicy.parse(
        _policyJson(
          targets: {'default': 500, 'use_case': 180},
          profiles: {
            'default': {'fallback': true},
            'use_case': {
              'paths': ['lib/use_cases/'],
            },
          },
        ),
        'policy',
      );

      expect(
        policy.scopes['root']!.profileFor('lib/use_cases/start.dart').name,
        'use_case',
      );
      expect(
        policy.scopes['root']!.profileFor('lib/domain/model.dart').name,
        'default',
      );
      expect(policy.fileLineTargets, {'default': 500, 'use_case': 180});
      expect(policy.declarationLineTarget, 350);
    });

    test('rejects duplicate JSON keys through canonical round-trip', () {
      final canonical = _policyJson(
        targets: {'default': 500},
        profiles: {
          'default': {'fallback': true},
        },
      );
      final duplicated = canonical.replaceFirst(
        '"schema": 1,',
        '"schema": 1,\n  "schema": 1,',
      );

      expect(
        () => ArchitecturePolicy.parse(duplicated, 'policy'),
        throwsA(isA<ArchitectureFailure>()),
      );
    });

    test('rejects overlapping explicit profiles', () {
      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(
            targets: {'default': 500, 'game': 400, 'widgets': 350},
            profiles: {
              'default': {'fallback': true},
              'game': {
                'paths': ['lib/game/'],
              },
              'widgets': {
                'paths': ['lib/game/widgets/'],
              },
            },
          ),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    });

    test('rejects overlapping source roots', () {
      expect(
        () => ArchitecturePolicy.parse(
          canonicalJson({
            'schema': 1,
            'enforcedSince': '0123456789abcdef0123456789abcdef01234567',
            'generatedSuffixes': ['.freezed.dart', '.g.dart'],
            'buildRunnerScopes': <String>[],
            'fileLineTargets': {'default': 500},
            'declarationLineTarget': 350,
            'scopes': {
              'nested': _scopeJson('lib/game'),
              'root': _scopeJson('lib'),
            },
          }),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    });

    test('rejects unknown generator scopes and scope-local targets', () {
      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(
            targets: {'default': 500},
            profiles: {
              'default': {'fallback': true},
            },
            buildRunnerScopes: const ['missing'],
          ),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(
            targets: {'default': 500},
            profiles: {
              'default': {'fallback': true, 'lineTarget': 999},
            },
          ),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    });
  });

  test('analyzer 12.1 public AST measures each supported type kind', () {
    final metrics = measureDartSource(
      'lib/sample.dart',
      '''
/// Documentation is deliberately outside the declaration span.
@deprecated
class Alpha {
  void first() {}
}

enum Choice { one }
mixin Capability {}
extension NamedStrings on String {}
extension on int {}
extension type Meter(int value) {}
'''
          .trimLeft(),
    );
    final byKey = {
      for (final metric in metrics.declarations) metric.key: metric,
    };

    expect(byKey.keys, contains('lib/sample.dart::class:Alpha'));
    expect(byKey.keys, contains('lib/sample.dart::enum:Choice'));
    expect(byKey.keys, contains('lib/sample.dart::mixin:Capability'));
    expect(byKey.keys, contains('lib/sample.dart::extension:NamedStrings'));
    expect(byKey.keys, contains('lib/sample.dart::extension:<anonymous#1>'));
    expect(byKey.keys, contains('lib/sample.dart::extension_type:Meter'));
    expect(byKey['lib/sample.dart::class:Alpha']!.startLine, 2);
    expect(byKey['lib/sample.dart::class:Alpha']!.lines, 4);
  });

  test('baseline ratchet rejects growth and new legacy keys', () {
    final historical = ArchitectureBaseline(
      scopes: {
        'root': const ScopeBaseline(
          files: {'lib/old.dart': 600},
          declarations: {'lib/old.dart::class:Old': 500},
        ),
      },
    );
    final current = ArchitectureBaseline(
      scopes: {
        'root': const ScopeBaseline(
          files: {'lib/new.dart': 550, 'lib/old.dart': 601},
          declarations: {'lib/old.dart::class:Old': 450},
        ),
      },
    );

    expect(
      current.ratchetDifferences(historical),
      containsAll([contains('cannot be introduced'), contains('cannot grow')]),
    );
  });

  test('strict baseline accepts only above-target canonical debt', () {
    final policy = ArchitecturePolicy.parse(
      _policyJson(
        targets: {'default': 500},
        profiles: {
          'default': {'fallback': true},
        },
      ),
      'policy',
    );
    final baseline = ArchitectureBaseline.parse(
      canonicalJson({
        'schema': 1,
        'scopes': {
          'root': {
            'files': {'lib/large.dart': 501},
            'declarations': {'lib/large.dart::class:Large': 351},
          },
        },
      }),
      policy,
      'baseline',
    );

    expect(baseline.fileDebtCount, 1);
    expect(baseline.declarationDebtCount, 1);
    expect(
      () => ArchitectureBaseline.parse(
        canonicalJson({
          'schema': 1,
          'scopes': {
            'root': {
              'files': {'lib/compliant.dart': 500},
              'declarations': <String, int>{},
            },
          },
        }),
        policy,
        'baseline',
      ),
      throwsA(isA<ArchitectureFailure>()),
    );
  });
}

String _policyJson({
  required Map<String, int> targets,
  required Map<String, Object?> profiles,
  List<String> buildRunnerScopes = const [],
}) => canonicalJson({
  'schema': 1,
  'enforcedSince': '0123456789abcdef0123456789abcdef01234567',
  'generatedSuffixes': ['.freezed.dart', '.g.dart'],
  'buildRunnerScopes': buildRunnerScopes,
  'fileLineTargets': targets,
  'declarationLineTarget': 350,
  'scopes': {
    'root': {
      'sourceRoot': 'lib',
      'generatedPrefixes': <String>[],
      'fileProfiles': profiles,
    },
  },
});

Map<String, Object?> _scopeJson(String sourceRoot) => {
  'sourceRoot': sourceRoot,
  'generatedPrefixes': <String>[],
  'fileProfiles': {
    'default': {'fallback': true},
  },
};
