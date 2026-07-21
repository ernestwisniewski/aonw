import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

part 'support/timeout_actor_integration_fixtures.dart';
part 'support/timeout_actor_integration_guard.dart';
part 'support/timeout_actor_integration_selection_guard.dart';
part 'support/timeout_actor_integration_flow_guard.dart';
part 'support/timeout_actor_integration_reducer_guard.dart';

const _timeoutServicePath =
    'server/lib/src/multiplayer/match_command_service_timeout.dart';
const _reducerPath = 'server/lib/src/multiplayer/server_command_reducer.dart';
const _reducerSnapshotPath =
    'server/lib/src/multiplayer/server_command_reducer_snapshot.dart';
const _reducerTurnsPath =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';

void main() {
  group('timeout actor canonical integration', () {
    test('service selects from ordered roster and canonical session', () {
      expect(
        _timeoutSelectionViolations(_unitAt(_timeoutServicePath)),
        isEmpty,
      );
    });

    test('service decodes once and forwards the same snapshot', () {
      expect(
        _timeoutCanonicalFlowViolations(_unitAt(_timeoutServicePath)),
        isEmpty,
      );
    });

    test('reducer keeps only the running snapshot alias and codec seam', () {
      expect(
        _decodedSnapshotAliasViolations(_unitAt(_reducerSnapshotPath)),
        isEmpty,
      );
      expect(_reducerSnapshotDecodeViolations(_unitAt(_reducerPath)), isEmpty);
      expect(
        _timeoutReducerForwardingViolations(
          reducer: _unitAt(_reducerPath),
          turns: _unitAt(_reducerTurnsPath),
        ),
        isEmpty,
      );
    });

    test('canonical snapshot reads stay limited to service and finalizer', () {
      final sources = productionDartSources();
      expect(
        instanceMemberReferenceCountsByPath(
          sources,
          'DecodedRunningMatchSnapshot',
          'canonical',
        ),
        {_timeoutServicePath: 1, _reducerTurnsPath: 1},
      );
      expect(
        instanceMemberReferenceCountsByPath(
          sources,
          'DecodedRunningMatchSnapshot',
          'toCanonical',
        ),
        isEmpty,
      );
    });

    test('selection guard rejects runtime, sorting, and raw Wire roster', () {
      final violations = _timeoutSelectionViolations(
        _parse(_invalidTimeoutSelectionFixture),
      );

      expect(
        violations,
        contains(
          'timeout active IDs must use save players and canonical turn states',
        ),
      );
      expect(
        violations,
        contains('timeout selection must use the filtered Wire roster'),
      );
      expect(
        violations,
        contains(
          'timeout selection must read submitted from canonical session',
        ),
      );
      expect(
        violations,
        contains('timeout selection must not read runtimeState'),
      );
      expect(
        violations,
        contains('timeout selection must preserve Wire order without sort()'),
      );
      expect(
        violations,
        contains('timeout selector result must be returned directly'),
      );
    });

    test('canonical flow guard rejects stale decode and duplicate reads', () {
      final violations = _timeoutCanonicalFlowViolations(
        _parse(_invalidTimeoutCanonicalFlowFixture),
      );

      expect(
        violations,
        contains(
          'advanceTimedOutTurn must decode state.match/state.snapshot once',
        ),
      );
      expect(
        violations,
        contains(
          'canonicalSnapshot must be a final local reading '
          'decodedSnapshot.canonical once',
        ),
      );
      expect(
        violations,
        contains('timeout canonical flow must not call toCanonical'),
      );
    });

    test('alias and reducer guards reject wrappers and direct decoding', () {
      final aliasViolations = _decodedSnapshotAliasViolations(
        _parse(_invalidDecodedSnapshotAliasFixture),
      );
      expect(
        aliasViolations,
        contains(
          'DecodedMatchSnapshot must be exactly a typedef to '
          'DecodedRunningMatchSnapshot',
        ),
      );
      expect(
        aliasViolations,
        contains('DecodedMatchSnapshot must not declare a concrete wrapper'),
      );

      final decodeViolations = _reducerSnapshotDecodeViolations(
        _parse(_invalidReducerSnapshotDecodeFixture),
      );
      expect(
        decodeViolations,
        contains(
          'decodeSnapshot must require match/snapshot and delegate directly '
          'to RunningMatchSnapshotCodec',
        ),
      );
      expect(
        decodeViolations,
        contains('reduce must decode its match and snapshot once'),
      );
    });

    test('forwarding guard rejects substituted snapshots and conversions', () {
      final violations = _timeoutReducerForwardingViolations(
        reducer: _parse(_invalidTimeoutReducerFixture),
        turns: _parse(_invalidTimeoutTurnsFixture),
      );
      expect(
        violations,
        contains('reduceTimedOutTurn must forward decodedSnapshot once'),
      );
      expect(
        violations,
        contains('_submitTurn must finalize a fresh submitted snapshot'),
      );
      expect(
        violations,
        contains(
          '_finalizeSimultaneousTurn must read decodedSnapshot.canonical once',
        ),
      );
    });
  });
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

CompilationUnit _parse(String source) => parseString(content: source).unit;
