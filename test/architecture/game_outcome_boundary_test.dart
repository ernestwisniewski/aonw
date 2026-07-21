import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

part 'support/game_outcome_boundary_collectors.dart';
part 'support/game_outcome_boundary_fixtures.dart';
part 'support/game_outcome_boundary_guard.dart';

const _resolverPath =
    'packages/aonw_core/lib/game/domain/outcome/game_outcome_resolver.dart';
const _detectorPath =
    'packages/aonw_core/lib/game/domain/outcome/game_outcome_detector.dart';
const _serverReducerPath =
    'server/lib/src/multiplayer/server_command_reducer.dart';
const _serverTurnsPath =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';
const _serverSnapshotPath =
    'server/lib/src/multiplayer/server_command_reducer_snapshot.dart';
const _serverOutcomePath =
    'server/lib/src/multiplayer/server_command_reducer_outcome.dart';

const _forbiddenResolverStateTypes = {
  'PersistentGameState',
  'GameRuntimeState',
  'GameSave',
  'DomainState',
  'MatchSessionState',
  'CanonicalGameSnapshot',
};

const _resolveRequiredParameters = {
  'playerIds': 'Iterable<String>',
  'units': 'Iterable<GameUnit>',
  'cities': 'Iterable<GameCity>',
  'artifacts': 'Iterable<WorldArtifact>',
  'fieldImprovements': 'Iterable<FieldImprovement>',
  'research': 'ResearchState',
  'playerGold': 'Map<String, int>',
  'dominationHoldTurnsByPlayerId': 'Map<String, int>',
  'culturalVictoryHoldTurnsByPlayerId': 'Map<String, int>',
  'mapObjectiveHoldStatesByObjectiveId': 'Map<String, MapObjectiveHoldState>',
  'matchRules': 'MatchRules',
};

const _resolveOptionalParameters = {'mapData': 'MapReadView?', 'turn': 'int?'};

const _alivePlayerRequiredParameters = {
  'playerIds': 'Iterable<String>',
  'units': 'Iterable<GameUnit>',
  'cities': 'Iterable<GameCity>',
};

const _serverOutcomeRequiredParameters = {
  'match': 'WireMatch',
  'domain': 'DomainState',
  'session': 'MatchSessionState',
  'mapView': 'MapReadView',
};

const _acceptedReductionRequiredParameters = {
  'match': 'WireMatch',
  'snapshot': 'WireSnapshot',
  'previousState': 'PersistentGameState',
  'nextSave': 'GameSave',
  'result': '_CommandApplication',
  'mapView': 'MapReadView',
};

void main() {
  group('game outcome boundary', () {
    test(
      'outcome resolver remains a persistence-neutral collection kernel',
      () {
        final resolver = _unitAt(_resolverPath);
        final namedTypes = _NamedTypeCollector()..collect(resolver);
        final forbiddenTypes = typeNamesBackedBy(
          productionDartSources(),
          _forbiddenResolverStateTypes,
        );
        expect(namedTypes.names.intersection(forbiddenTypes), isEmpty);

        expect(
          _methodContract(
            resolver,
            ownerName: 'GameOutcomeResolver',
            methodName: 'resolve',
          ),
          const _MethodContract(
            requiredNamed: _resolveRequiredParameters,
            optionalNamed: _resolveOptionalParameters,
          ),
        );
        expect(
          _methodContract(
            resolver,
            ownerName: 'GameOutcomeResolver',
            methodName: 'alivePlayerIds',
          ),
          const _MethodContract(
            requiredNamed: _alivePlayerRequiredParameters,
            optionalNamed: {},
          ),
        );
      },
    );

    test('canonical detector entry requires domain and session state', () {
      final detector = _unitAt(_detectorPath);
      final contract = _methodContract(
        detector,
        ownerName: 'GameOutcomeDetector',
        methodName: 'evaluateCanonical',
      );

      expect(
        contract,
        const _MethodContract(
          requiredNamed: {
            'state': 'DomainState',
            'session': 'MatchSessionState',
          },
          optionalNamed: {'mapData': 'MapReadView?'},
        ),
      );
    });

    test(
      'server outcome reuses the canonical snapshot with a lazy fallback',
      () {
        final reducer = _unitAt(_serverReducerPath);
        final outcome = _unitAt(_serverOutcomePath);
        final reducerSources = _serverReducerUnits();

        expect(_canonicalSnapshotFieldViolations(reducer), isEmpty);
        expect(
          _canonicalSnapshotDeclarationViolations(reducerSources),
          isEmpty,
        );
        expect(_canonicalSnapshotReferenceViolations(reducerSources), isEmpty);
        expect(_canonicalSnapshotProviderViolations(reducerSources), isEmpty);
        expect(_acceptedReductionCanonicalFlowViolations(outcome), isEmpty);
        final acceptedReductionCalls = _MethodInvocationCollector(
          '_acceptedReduction',
        )..collect(reducer);
        expect(acceptedReductionCalls.invocations, hasLength(2));
        for (final methodName in const ['reduce', 'reduceTimedOutTurn']) {
          expect(
            _rootReductionDelegationViolations(reducer, methodName),
            isEmpty,
            reason: methodName,
          );
        }
        expect(_serverOutcomeViolations(outcome), isEmpty);
      },
    );

    test('lazy fallback guard rejects eagerly computed conversion', () {
      final unit = _parse('''
final class Reducer {
  void _acceptedReduction({
    required WireMatch match,
    required WireSnapshot snapshot,
    required PersistentGameState previousState,
    required GameSave nextSave,
    required _CommandApplication result,
    required MapReadView mapView,
  }) {
    final eager = _canonicalSnapshot(save, state);
    final canonicalSnapshot = result.canonicalSnapshot ?? eager;
    _gameOutcome(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
    );
  }
}
''', 'eager_fallback_fixture.dart');

      expect(
        _acceptedReductionCanonicalFlowViolations(unit),
        contains(
          '_acceptedReduction canonicalSnapshot fallback must directly call '
          '_canonicalSnapshot',
        ),
      );
    });

    test('canonical conversion allowlist rejects every reference form', () {
      for (final entry in _canonicalSnapshotReferenceFixtures.entries) {
        final sources = _serverReducerUnits();
        final fixturePath =
            'server/lib/src/multiplayer/server_command_reducer_'
            '${entry.key.replaceAll(' ', '_')}_extra.dart';
        sources[fixturePath] = _parse(entry.value, fixturePath);

        expect(
          _canonicalSnapshotReferenceViolations(sources),
          contains(
            '$fixturePath must contain 0 _canonicalSnapshot references; '
            'found 1',
          ),
          reason: entry.key,
        );
      }
    });

    test('canonical conversion rejects every shadowing declaration', () {
      for (final entry in _canonicalSnapshotShadowingFixtures.entries) {
        final sources = _serverReducerUnits();
        sources[_serverOutcomePath] = _parse(
          entry.value.source,
          _serverOutcomePath,
        );

        expect(
          _canonicalSnapshotReferenceViolations(sources),
          isEmpty,
          reason: '${entry.key} must defeat the lexical reference count',
        );
        expect(
          _canonicalSnapshotDeclarationViolations(sources),
          contains(entry.value.violation),
          reason: entry.key,
        );
      }
    });

    test('canonical snapshot provider rejects another accept argument', () {
      for (final entry in _canonicalSnapshotProviderFixtures.entries) {
        final sources = _serverReducerUnits();
        const fixturePath =
            'server/lib/src/multiplayer/server_command_reducer_extra.dart';
        sources[fixturePath] = _parse(entry.value, fixturePath);

        expect(
          _canonicalSnapshotProviderViolations(sources),
          contains(
            'reducer library must provide canonicalSnapshot to '
            '_CommandApplication.accept exactly once; found 2',
          ),
          reason: entry.key,
        );
      }
    });

    test('factory forwarding must be its sole returned construction', () {
      for (final entry in _acceptFactoryForwardingFixtures.entries) {
        final sources = _serverReducerUnits();
        sources[_serverReducerPath] = _parse(entry.value, _serverReducerPath);

        final violations = _canonicalSnapshotProviderViolations(sources);
        expect(
          violations,
          contains(
            '_CommandApplication.accept must forward canonicalSnapshot '
            'exactly once; found 0',
          ),
          reason: entry.key,
        );
        expect(
          violations,
          contains(
            'reducer library must provide canonicalSnapshot to '
            '_CommandApplication.accept exactly once; found 2',
          ),
          reason: entry.key,
        );
      }
    });
  });
}
