import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('typed response parser rejects unknown nested fields', () {
    final source = _success({
      'type': 'snapshot',
      'snapshot': {
        'stamp': _stamp,
        'units': [
          {
            'id': 'unit-1',
            'ownerPlayerId': 'player-1',
            'kind': 'worker',
            'name': 'Worker',
            'coordinate': {'col': 1, 'row': 2},
            'movementUnits': 4,
            'posture': 'active',
            'unknown': true,
          },
        ],
      },
    });

    expect(() => AonwClientResponse.parse(source), throwsFormatException);
  });

  test('typed parser covers lifecycle and persistence responses', () {
    final cases = <String, Type>{
      _success({
        'type': 'capabilities',
        'behaviorVersion': 2,
        'features': ['snapshot', 'moveUnit'],
      }): AonwCapabilitiesResponse,
      _success({'type': 'sessionOpened', 'stamp': _stamp}):
          AonwSessionOpenedResponse,
      _success({'type': 'sessionClosed'}): AonwSessionClosedResponse,
      _success({'type': 'saveExported', 'document': '{}'}):
          AonwSaveExportedResponse,
      _success({'type': 'saveOpened', 'stamp': _stamp}): AonwSaveOpenedResponse,
      _success({'type': 'replayExported', 'document': '{}'}):
          AonwReplayExportedResponse,
      _success({
        'type': 'replayVerified',
        'verification': {
          'entryCount': 3,
          'finalEventOffset': 8,
          'finalStamp': _stamp,
        },
      }): AonwReplayVerifiedResponse,
    };

    for (final MapEntry(key: source, value: expectedType) in cases.entries) {
      expect(
        AonwClientResponse.parse(source).response.runtimeType,
        expectedType,
      );
    }
  });

  test('typed parser covers both movement query results', () {
    final reachable = AonwClientResponse.parse(
      _success({
        'type': 'query',
        'result': {
          'type': 'reachable',
          'stamp': _stamp,
          'unitId': 'unit-1',
          'availableMovementUnits': 4,
          'tiles': [
            {
              'coordinate': {'col': 2, 'row': 2},
              'costUnits': 2,
              'exhaustsMovement': false,
            },
          ],
        },
      }),
    ).require<AonwQueryResponse>();
    expect(reachable.result, isA<AonwReachableResult>());

    final route = AonwClientResponse.parse(
      _success({
        'type': 'query',
        'result': {
          'type': 'routePlan',
          'stamp': _stamp,
          'unitId': 'unit-1',
          'target': {'col': 3, 'row': 2},
          'destination': {'col': 3, 'row': 2},
          'totalCostUnits': 4,
          'availableMovementUnits': 4,
          'remainingMovementUnits': 0,
          'steps': [
            {
              'coordinate': {'col': 3, 'row': 2},
              'enterCostUnits': 4,
              'cumulativeCostUnits': 4,
            },
          ],
        },
      }),
    ).require<AonwQueryResponse>();
    expect(route.result, isA<AonwRoutePlanResult>());
  });

  test('command result uses one tagged accepted or rejected outcome', () {
    final accepted = AonwCommandResult.fromJson(
      _commandResult(const {'status': 'accepted'}),
    );
    final rejected = AonwCommandResult.fromJson(
      _commandResult(const {'status': 'rejected', 'code': 'stale_revision'}),
    );

    expect(accepted.accepted, isTrue);
    expect(accepted.rejection, isNull);
    expect(rejected.accepted, isFalse);
    expect(rejected.rejection, 'stale_revision');
    expect(
      () => AonwCommandResult.fromJson({
        ..._commandResult(const {'status': 'accepted'}),
        'accepted': true,
      }),
      throwsFormatException,
    );
  });

  test('failure response is typed and cannot be required as success', () {
    final response = AonwClientResponse.parse(
      jsonEncode({
        'apiVersion': aonwClientApiVersion,
        'outcome': {
          'status': 'failure',
          'error': {'code': 'invalid_request', 'message': 'invalid'},
        },
      }),
    );

    expect(response.error?.code, 'invalid_request');
    expect(response.require<AonwSessionClosedResponse>, throwsStateError);
  });
}

const _stamp = {
  'behaviorVersion': 2,
  'revision': 7,
  'stateDigest': 'digest-7',
  'mapHash': 'map-hash',
  'rulesetHash': 'ruleset-hash',
};

String _success(Map<String, Object?> response) => jsonEncode({
  'apiVersion': aonwClientApiVersion,
  'outcome': {'status': 'success', 'response': response},
});

Map<String, Object?> _commandResult(Map<String, Object?> outcome) => {
  'stamp': _stamp,
  'outcome': outcome,
  'events': const [],
  'evidence': null,
  'viewPatch': const {
    'fromRevision': 7,
    'toRevision': 7,
    'upsertedUnits': [],
    'removedUnitIds': [],
  },
};
