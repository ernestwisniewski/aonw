import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture/baseline.dart';
import '../../tool/architecture/failure.dart';
import '../../tool/architecture/policy.dart';
import '../../tool/architecture/strict_json.dart';

void main() {
  group('strict schema 2 policy', () {
    test('loads canonical roles and classifies every source role', () {
      final policy = ArchitecturePolicy.parse(_policyJson(), 'policy');
      final scope = policy.scopes['root']!;

      expect(scope.roleFor('lib/domain/model.dart').name, 'production');
      expect(scope.roleFor('lib/test_support/fixture.dart').name, 'test');
      expect(scope.roleFor('lib/tooling/generator.dart').name, 'tool');
      expect(
        scope.roleFor('lib/game/rendering/hex_painter.dart').name,
        'flame_rendering',
      );
      expect(
        policy.roles.map(
          (name, role) => MapEntry(name, {
            'fileLines': role.fileLines,
            'declarationLines': role.declarationLines,
            'callableLines': role.callableLines,
            'nesting': role.nesting,
            'cyclomaticComplexity': role.cyclomaticComplexity,
            'cognitiveComplexity': role.cognitiveComplexity,
          }),
        ),
        _roleTargets,
      );
    });

    test('rejects duplicate JSON keys through canonical round-trip', () {
      final canonical = _policyJson();
      final duplicated = canonical.replaceFirst(
        '"schema": 2,',
        '"schema": 2,\n  "schema": 2,',
      );

      expect(
        () => ArchitecturePolicy.parse(duplicated, 'policy'),
        throwsA(isA<ArchitectureFailure>()),
      );
    });

    test('rejects missing, renamed, and unused canonical roles', () {
      for (final roles in [
        {..._roleTargets}..remove('tool'),
        {..._roleTargets, 'utility': _roleTargets['tool']!}..remove('tool'),
      ]) {
        expect(
          () => ArchitecturePolicy.parse(_policyJson(roles: roles), 'policy'),
          throwsA(isA<ArchitectureFailure>()),
        );
      }

      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(
            roleAssignments: {
              'test': {
                'paths': ['lib/test_support/'],
              },
              'tool': {
                'paths': ['lib/tooling/'],
              },
            },
          ),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    });

    test('rejects overlapping explicit role assignments', () {
      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(
            roleAssignments: {
              'test': {
                'paths': ['lib/shared/'],
              },
              'tool': {
                'paths': ['lib/shared/tooling/'],
              },
              'flame_rendering': {
                'paths': ['lib/game/rendering/'],
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
          _policyJson(
            scopes: {
              'nested': _scopeJson('lib/game'),
              'root': _scopeJson(
                'lib',
                roleAssignments: _canonicalRoleAssignments,
              ),
            },
          ),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    });

    test('rejects unknown generator scopes and scope-local targets', () {
      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(buildRunnerScopes: const ['missing']),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
      expect(
        () => ArchitecturePolicy.parse(
          _policyJson(
            roleAssignments: {
              'test': {
                'paths': ['lib/test_support/'],
                'callableLines': 999,
              },
              'tool': {
                'paths': ['lib/tooling/'],
              },
              'flame_rendering': {
                'paths': ['lib/game/rendering/'],
              },
            },
          ),
          'policy',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    });
  });

  test('baseline ratchet covers every schema 2 debt dimension', () {
    final historical = ArchitectureBaseline(
      scopes: {
        'root': const ScopeBaseline(
          files: {'lib/old.dart': 600},
          legacyFiles: {'lib/migrated.dart': 400},
          declarations: {'lib/old.dart::class:Old': 500},
          callableLines: {'lib/old.dart::class:Old/method:run': 70},
          nesting: {'lib/old.dart::class:Old/method:run': 4},
          cyclomaticComplexity: {'lib/old.dart::class:Old/method:run': 11},
          cognitiveComplexity: {'lib/old.dart::class:Old/method:run': 16},
        ),
      },
    );
    final current = ArchitectureBaseline(
      scopes: {
        'root': const ScopeBaseline(
          files: {'lib/new.dart': 550, 'lib/old.dart': 601},
          legacyFiles: {'lib/migrated.dart': 401},
          declarations: {'lib/old.dart::class:Old': 450},
          callableLines: {'lib/old.dart::class:Old/method:run': 71},
          nesting: {'lib/old.dart::class:Old/method:run': 4},
          cyclomaticComplexity: {
            'lib/new.dart::function:calculate': 11,
            'lib/old.dart::class:Old/method:run': 10,
          },
          cognitiveComplexity: {'lib/old.dart::class:Old/method:run': 15},
        ),
      },
    );

    expect(current.ratchetDifferences(historical), [
      'root file debt cannot be introduced: [lib/new.dart]',
      'root file debt cannot grow: lib/old.dart 600 -> 601',
      'root migrated file debt cannot grow: lib/migrated.dart 400 -> 401',
      'root callable line debt cannot grow: '
          'lib/old.dart::class:Old/method:run 70 -> 71',
      'root cyclomatic complexity debt cannot be introduced: '
          '[lib/new.dart::function:calculate]',
    ]);
  });

  test('strict baseline accepts only role-specific above-target debt', () {
    final policy = ArchitecturePolicy.parse(
      _policyJson(legacyFileTargets: {'lib/migrated.dart': 350}),
      'policy',
    );
    final baseline = ArchitectureBaseline.parse(
      canonicalJson({
        'schema': 2,
        'scopes': {
          'root': {
            'files': {'lib/large.dart': 501},
            'legacyFiles': {'lib/migrated.dart': 351},
            'declarations': {'lib/large.dart::class:Large': 351},
            'callableLines': {'lib/large.dart::function:large': 61},
            'nesting': {'lib/large.dart::function:nested': 4},
            'cyclomaticComplexity': {'lib/large.dart::function:branching': 11},
            'cognitiveComplexity': {'lib/large.dart::function:complex': 16},
          },
        },
      }),
      policy,
      'baseline',
    );

    expect(baseline.fileDebtCount, 2);
    expect(baseline.declarationDebtCount, 1);
    expect(baseline.callableLineDebtCount, 1);
    expect(baseline.nestingDebtCount, 1);
    expect(baseline.cyclomaticDebtCount, 1);
    expect(baseline.cognitiveDebtCount, 1);

    for (final invalidMetrics in [
      {
        'files': {'lib/compliant.dart': 500},
      },
      {
        'callableLines': {'lib/compliant.dart::function:atTarget': 60},
      },
      {
        'callableLines': {
          'lib/test_support/not_test_debt.dart::function:longTest': 61,
        },
      },
      {
        'legacyFiles': {'lib/migrated.dart': 350},
      },
      {
        'legacyFiles': {'lib/unmapped.dart': 351},
      },
    ]) {
      expect(
        () => ArchitectureBaseline.parse(
          canonicalJson({
            'schema': 2,
            'scopes': {
              'root': {
                'files': <String, int>{},
                'legacyFiles': <String, int>{},
                'declarations': <String, int>{},
                'callableLines': <String, int>{},
                'nesting': <String, int>{},
                'cyclomaticComplexity': <String, int>{},
                'cognitiveComplexity': <String, int>{},
                ...invalidMetrics,
              },
            },
          }),
          policy,
          'baseline',
        ),
        throwsA(isA<ArchitectureFailure>()),
      );
    }
  });
}

const _roleTargets = <String, Map<String, int>>{
  'flame_rendering': {
    'fileLines': 550,
    'declarationLines': 400,
    'callableLines': 80,
    'nesting': 4,
    'cyclomaticComplexity': 12,
    'cognitiveComplexity': 18,
  },
  'production': {
    'fileLines': 500,
    'declarationLines': 350,
    'callableLines': 60,
    'nesting': 3,
    'cyclomaticComplexity': 10,
    'cognitiveComplexity': 15,
  },
  'test': {
    'fileLines': 700,
    'declarationLines': 450,
    'callableLines': 120,
    'nesting': 5,
    'cyclomaticComplexity': 20,
    'cognitiveComplexity': 25,
  },
  'tool': {
    'fileLines': 600,
    'declarationLines': 400,
    'callableLines': 100,
    'nesting': 4,
    'cyclomaticComplexity': 15,
    'cognitiveComplexity': 20,
  },
};

const _canonicalRoleAssignments = <String, Object?>{
  'flame_rendering': {
    'paths': ['lib/game/rendering/'],
  },
  'test': {
    'paths': ['lib/test_support/'],
  },
  'tool': {
    'paths': ['lib/tooling/'],
  },
};

String _policyJson({
  Map<String, Map<String, int>> roles = _roleTargets,
  Map<String, Object?> roleAssignments = _canonicalRoleAssignments,
  List<String> buildRunnerScopes = const [],
  Map<String, Object?>? scopes,
  Map<String, int> legacyFileTargets = const {},
}) => canonicalJson({
  'schema': 2,
  'enforcedSince': '0123456789abcdef0123456789abcdef01234567',
  'migration': {
    'fromSchema': 1,
    'policySha256': '0' * 64,
    'baselineSha256': '1' * 64,
    'legacyFileTargets': legacyFileTargets,
  },
  'generatedSuffixes': ['.freezed.dart', '.g.dart'],
  'buildRunnerScopes': buildRunnerScopes,
  'roles': roles,
  'scopes':
      scopes ?? {'root': _scopeJson('lib', roleAssignments: roleAssignments)},
});

Map<String, Object?> _scopeJson(
  String sourceRoot, {
  String defaultRole = 'production',
  Map<String, Object?> roleAssignments = const {},
}) => {
  'sourceRoot': sourceRoot,
  'generatedPrefixes': <String>[],
  'defaultRole': defaultRole,
  'roleAssignments': roleAssignments,
};
