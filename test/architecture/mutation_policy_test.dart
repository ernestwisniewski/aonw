import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/baseline.dart';
import '../../tool/mutation/failure.dart';
import '../../tool/mutation/policy.dart';
import '../../tool/mutation/strict_json.dart';

void main() {
  group('mutation policy', () {
    test('loads the exact operator contract and package-relative scopes', () {
      final policy = MutationPolicy.parse(_policyJson(), 'policy');

      expect(policy.enforcedSince, _anchor);
      expect(policy.perMutantTimeoutSeconds, 90);
      expect(policy.operators, supportedMutationOperators);
      expect(policy.scopes.keys, ['root_reducers']);
      final scope = policy.scopes['root_reducers']!;
      expect(scope.architectureScope, 'root_lib');
      expect(scope.packageRoot, '.');
      expect(scope.runner, 'flutter');
      expect(scope.targetFiles, ['lib/game/reducer.dart']);
      expect(scope.testFiles, ['test/game/reducer_test.dart']);
    });

    test('rejects non-canonical JSON and duplicate keys', () {
      final canonical = _policyJson();
      final duplicate = canonical.replaceFirst(
        '"schema": 1,',
        '"schema": 1,\n  "schema": 1,',
      );

      expect(
        () => MutationPolicy.parse('$canonical\n', 'policy'),
        throwsA(isA<MutationFailure>()),
      );
      expect(
        () => MutationPolicy.parse(duplicate, 'policy'),
        throwsA(isA<MutationFailure>()),
      );
    });

    test('rejects unknown, missing, and unsorted operators', () {
      final withUnknown = <String>[
        ...supportedMutationOperators,
        'unsupported_operator',
      ]..sort();
      final unsorted = [...supportedMutationOperators.reversed];

      for (final operators in [
        withUnknown,
        supportedMutationOperators.sublist(1),
        unsorted,
      ]) {
        expect(
          () =>
              MutationPolicy.parse(_policyJson(operators: operators), 'policy'),
          throwsA(isA<MutationFailure>()),
          reason: operators.toString(),
        );
      }
    });

    test('rejects overlapping targets across scopes', () {
      final scopes = {'first': _scopeJson(), 'second': _scopeJson()};

      expect(
        () => MutationPolicy.parse(_policyJson(scopes: scopes), 'policy'),
        throwsA(isA<MutationFailure>()),
      );
    });

    test('rejects bad and package-external paths', () {
      for (final scope in [
        _scopeJson(targetFiles: ['lib/../game/reducer.dart']),
        _scopeJson(targetFiles: ['lib/CON.dart']),
        _scopeJson(targetFiles: ['lib/bad:name.dart']),
        _scopeJson(targetFiles: ['lib/trailing./source.dart']),
        _scopeJson(targetFiles: ['lib/Foo.dart', 'lib/foo.dart']),
        _scopeJson(
          packageRoot: 'server',
          runner: 'dart',
          targetFiles: ['lib/game/reducer.dart'],
          testFiles: ['server/test/reducer_test.dart'],
        ),
        _scopeJson(targetFiles: ['lib/game/reducer.txt']),
      ]) {
        expect(
          () => MutationPolicy.parse(
            _policyJson(scopes: {'invalid': scope}),
            'policy',
          ),
          throwsA(isA<MutationFailure>()),
          reason: scope.toString(),
        );
      }
    });

    test('accepts full SHA-256 rollout object ids', () {
      final policy = MutationPolicy.parse(
        _policyJson(anchor: _sha256Anchor),
        'policy',
      );

      expect(policy.enforcedSince, _sha256Anchor);
    });

    test('rejects invalid timeout, runner, and empty scope lists', () {
      for (final timeout in [0, 301]) {
        expect(
          () => MutationPolicy.parse(_policyJson(timeout: timeout), 'policy'),
          throwsA(isA<MutationFailure>()),
        );
      }
      expect(
        () => MutationPolicy.parse(
          _policyJson(scopes: {'root': _scopeJson(runner: 'shell')}),
          'policy',
        ),
        throwsA(isA<MutationFailure>()),
      );
      expect(
        () => MutationPolicy.parse(
          _policyJson(scopes: {'root': _scopeJson(targetFiles: [])}),
          'policy',
        ),
        throwsA(isA<MutationFailure>()),
      );
    });
  });

  group('mutation baseline', () {
    test('loads exact target, operator, and survivor census', () {
      final policy = MutationPolicy.parse(_policyJson(), 'policy');
      final baseline = MutationBaseline.parse(
        _baselineJson(),
        policy,
        'baseline',
      );

      expect(baseline.mutantCount, 1);
      expect(baseline.survivorCount, 1);
      final scope = baseline.scopes['root_reducers']!;
      expect(scope.targets, {'lib/game/reducer.dart': 1});
      expect(scope.operatorTotals['equality_negation'], 1);
      expect(scope.survivors.keys, ['mutant-1']);
    });

    test('rejects stale targets and unknown survivor operators', () {
      final policy = MutationPolicy.parse(_policyJson(), 'policy');
      final staleTarget = _baselineJson(targets: {'lib/game/other.dart': 1});
      final unknownOperator = _baselineJson(
        survivor: {..._survivorJson(), 'operator': 'unsupported_operator'},
      );

      for (final baseline in [staleTarget, unknownOperator]) {
        expect(
          () => MutationBaseline.parse(baseline, policy, 'baseline'),
          throwsA(isA<MutationFailure>()),
        );
      }
    });

    test('rejects inconsistent counts and non-canonical baseline JSON', () {
      final policy = MutationPolicy.parse(_policyJson(), 'policy');
      final inconsistent = _baselineJson(
        operatorTotals: {
          for (final operator in supportedMutationOperators) operator: 0,
        },
      );
      final canonical = _baselineJson();

      expect(
        () => MutationBaseline.parse(inconsistent, policy, 'baseline'),
        throwsA(isA<MutationFailure>()),
      );
      expect(
        () => MutationBaseline.parse('$canonical\n', policy, 'baseline'),
        throwsA(isA<MutationFailure>()),
      );
    });

    test('ratchet rejects only new or rebound survivors', () {
      final policy = MutationPolicy.parse(_policyJson(), 'policy');
      final historical = MutationBaseline.parse(
        _baselineJson(),
        policy,
        'historical',
      );
      final improved = MutationBaseline.empty(policy);
      final rebound = MutationBaseline.parse(
        _baselineJson(survivor: {..._survivorJson(), 'replacement': 'true'}),
        policy,
        'rebound',
      );

      expect(improved.ratchetDifferences(historical), isEmpty);
      expect(
        rebound.ratchetDifferences(historical),
        contains(contains('identity changed')),
      );
      expect(
        historical.ratchetDifferences(improved),
        contains(contains('cannot introduce')),
      );
    });
  });
}

const _anchor = '0123456789abcdef0123456789abcdef01234567';
const _sha256Anchor =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

String _policyJson({
  String anchor = _anchor,
  int timeout = 90,
  List<String> operators = supportedMutationOperators,
  Map<String, Object?>? scopes,
}) => canonicalJson({
  'schema': 1,
  'enforcedSince': anchor,
  'perMutantTimeoutSeconds': timeout,
  'operators': operators,
  'scopes': scopes ?? {'root_reducers': _scopeJson()},
});

Map<String, Object?> _scopeJson({
  String architectureScope = 'root_lib',
  String packageRoot = '.',
  String runner = 'flutter',
  List<String> targetFiles = const ['lib/game/reducer.dart'],
  List<String> testFiles = const ['test/game/reducer_test.dart'],
}) => {
  'architectureScope': architectureScope,
  'packageRoot': packageRoot,
  'runner': runner,
  'targetFiles': targetFiles,
  'testFiles': testFiles,
};

String _baselineJson({
  Map<String, int> targets = const {'lib/game/reducer.dart': 1},
  Map<String, int>? operatorTotals,
  Map<String, Object?>? survivor,
}) => canonicalJson({
  'schema': 1,
  'scopes': {
    'root_reducers': {
      'targets': targets,
      'operatorTotals':
          operatorTotals ??
          {
            for (final operator in supportedMutationOperators)
              operator: operator == 'equality_negation' ? 1 : 0,
          },
      'survivors': {'mutant-1': survivor ?? _survivorJson()},
    },
  },
});

Map<String, Object?> _survivorJson() => {
  'path': 'lib/game/reducer.dart',
  'operator': 'equality_negation',
  'declaration': 'reduce',
  'original': '==',
  'replacement': '!=',
};
