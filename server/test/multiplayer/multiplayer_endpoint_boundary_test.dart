import 'dart:async';

import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

typedef _EndpointCall = ({String name, Future<void> Function() invoke});

void main() {
  final endpoint = MultiplayerEndpoint();
  const session = _UnauthenticatedSession();

  test('requires Serverpod authentication', () {
    expect(endpoint.requireLogin, isTrue);
  });

  test(
    'all request-response operations reject an undeclared revision',
    () async {
      final calls = [
        ..._lobbyCalls(endpoint, session),
        ..._matchCalls(endpoint, session),
      ];

      for (final call in calls) {
        await expectLater(
          call.invoke(),
          throwsA(_multiplayerError('unsupported_multiplayer_version')),
          reason: call.name,
        );
      }
    },
  );

  test(
    'streaming rejects an undeclared revision before opening input',
    () async {
      await expectLater(
        () => endpoint.connect(
          session,
          'match-1',
          0,
          const Stream<MultiplayerClientMessage>.empty(),
          multiplayerVersion: null,
        ),
        throwsA(_multiplayerError('unsupported_multiplayer_version')),
      );
    },
  );

  test('current revision delegates to authentication enforcement', () async {
    await expectLater(
      endpoint.listMatches(
        session,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
      throwsA(_multiplayerError('auth_required')),
    );
  });
}

List<_EndpointCall> _lobbyCalls(
  MultiplayerEndpoint endpoint,
  Session session,
) => [
  (
    name: 'listMatches',
    invoke: () async {
      await endpoint.listMatches(session, multiplayerVersion: null);
    },
  ),
  (
    name: 'createMatch',
    invoke: () async {
      await endpoint.createMatch(session, _request(), multiplayerVersion: null);
    },
  ),
  (
    name: 'quickplay',
    invoke: () async {
      await endpoint.quickplay(session, _request(), multiplayerVersion: null);
    },
  ),
  (
    name: 'joinMatch',
    invoke: () async {
      await endpoint.joinMatch(session, 'match-1', multiplayerVersion: null);
    },
  ),
  (
    name: 'joinPrivateMatch',
    invoke: () async {
      await endpoint.joinPrivateMatch(
        session,
        'ABCDEF',
        multiplayerVersion: null,
      );
    },
  ),
];

List<_EndpointCall> _matchCalls(
  MultiplayerEndpoint endpoint,
  Session session,
) => [
  (
    name: 'loadMatch',
    invoke: () async {
      await endpoint.loadMatch(session, 'match-1', multiplayerVersion: null);
    },
  ),
  (
    name: 'loadSnapshot',
    invoke: () async {
      await endpoint.loadSnapshot(session, 'match-1', multiplayerVersion: null);
    },
  ),
  (
    name: 'listEvents',
    invoke: () async {
      await endpoint.listEvents(
        session,
        'match-1',
        0,
        multiplayerVersion: null,
      );
    },
  ),
  (
    name: 'startMatch',
    invoke: () async {
      await endpoint.startMatch(session, 'match-1', multiplayerVersion: null);
    },
  ),
  (
    name: 'markMapLoaded',
    invoke: () async {
      await endpoint.markMapLoaded(
        session,
        'match-1',
        multiplayerVersion: null,
      );
    },
  ),
  (
    name: 'resignMatch',
    invoke: () async {
      await endpoint.resignMatch(session, 'match-1', multiplayerVersion: null);
    },
  ),
  (
    name: 'leaveMatch',
    invoke: () async {
      await endpoint.leaveMatch(session, 'match-1', multiplayerVersion: null);
    },
  ),
];

CreateMatchRequest _request() => CreateMatchRequest(
  name: 'Endpoint boundary',
  mapName: 'myranth',
  maxPlayers: 2,
  minPlayers: 2,
  private: false,
);

Matcher _multiplayerError(String code) =>
    isA<MultiplayerException>().having((error) => error.code, 'code', code);

final class _UnauthenticatedSession implements Session {
  const _UnauthenticatedSession();

  @override
  AuthenticationInfo? get authenticated => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected session call: $invocation');
}
