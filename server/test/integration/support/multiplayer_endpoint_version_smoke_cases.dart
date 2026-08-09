part of '../multiplayer_endpoint_smoke.dart';

extension _CurrentMultiplayerTestEndpoints on TestEndpoints {
  Future<List<WireMatch>> listCurrentMatches(TestSessionBuilder session) =>
      multiplayer.listMatches(
        session,
        multiplayerVersion: kCurrentMultiplayerVersion,
      );

  Future<WireMatch> createCurrentMatch(
    TestSessionBuilder session,
    CreateMatchRequest request,
  ) => multiplayer.createMatch(
    session,
    request,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Future<WireMatch> quickplayCurrent(
    TestSessionBuilder session,
    CreateMatchRequest request,
  ) => multiplayer.quickplay(
    session,
    request,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Future<WireMatch> joinCurrentMatch(
    TestSessionBuilder session,
    String matchId,
  ) => multiplayer.joinMatch(
    session,
    matchId,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Future<WireMatch> loadCurrentMatch(
    TestSessionBuilder session,
    String matchId,
  ) => multiplayer.loadMatch(
    session,
    matchId,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Future<WireSnapshot> loadCurrentSnapshot(
    TestSessionBuilder session,
    String matchId,
  ) => multiplayer.loadSnapshot(
    session,
    matchId,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Future<List<WireEvent>> listCurrentEvents(
    TestSessionBuilder session,
    String matchId,
    int afterOffset,
  ) => multiplayer.listEvents(
    session,
    matchId,
    afterOffset,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Future<WireMatch> startCurrentMatch(
    TestSessionBuilder session,
    String matchId,
  ) => multiplayer.startMatch(
    session,
    matchId,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );

  Stream<MultiplayerServerMessage> connectCurrent(
    TestSessionBuilder session,
    String matchId,
    int afterOffset,
    Stream<MultiplayerClientMessage> input,
  ) => multiplayer.connect(
    session,
    matchId,
    afterOffset,
    input,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );
}

typedef _StartedEndpointMatchScenario = ({
  _AccountSession owner,
  _AccountSession guest,
  WireMatch created,
  WireMatch started,
  String guestPublicId,
});

Future<_StartedEndpointMatchScenario> _createStartedEndpointMatchScenario(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) async {
  final owner = await _accountSession(
    sessionBuilder,
    endpoints,
    email: 'owner-user@example.test',
    displayName: 'Owner Nick',
  );
  final guest = await _accountSession(
    sessionBuilder,
    endpoints,
    email: 'guest-user@example.test',
    displayName: 'Guest Nick',
  );
  final stranger = await _accountSession(
    sessionBuilder,
    endpoints,
    email: 'stranger-user@example.test',
    displayName: 'Stranger Nick',
  );
  final created = await endpoints.createCurrentMatch(
    owner.session,
    CreateMatchRequest(
      name: 'Endpoint smoke',
      mapName: 'myranth',
      maxPlayers: 2,
      minPlayers: 2,
      private: false,
    ),
  );
  _expectCreatedEndpointMatch(created, owner);
  final ownerPublicId = created.players.single.id;
  await _connectParticipant(endpoints, owner.session, created.id);

  final listed = await endpoints.listCurrentMatches(guest.session);
  expect(listed.map((match) => match.id), contains(created.id));
  final joined = await endpoints.joinCurrentMatch(guest.session, created.id);
  await _connectParticipant(endpoints, guest.session, joined.id);
  final guestPublicId = joined.players
      .singleWhere((player) => player.userId == guest.userIdentifier)
      .id;
  expect(joined.players.map((player) => player.userId), [
    ownerPublicId,
    guest.userIdentifier,
  ]);
  expect(joined.ownerUserId, ownerPublicId);
  expect(joined.players.map((player) => player.name), [
    'Owner Nick',
    'Guest Nick',
  ]);

  final started = await endpoints.startCurrentMatch(owner.session, created.id);
  expect(started.state, 'running');
  expect(started.turn, 1);
  expect(started.players.map((player) => player.userId), [
    owner.userIdentifier,
    guestPublicId,
  ]);
  final loaded = await endpoints.loadCurrentMatch(guest.session, created.id);
  expect(loaded.state, 'running');
  expect(loaded.players.map((player) => player.userId), [
    ownerPublicId,
    guest.userIdentifier,
  ]);
  expect(loaded.ownerUserId, ownerPublicId);
  await _expectRunningMatchVisibility(
    endpoints,
    guest: guest,
    stranger: stranger,
    matchId: created.id,
  );
  return (
    owner: owner,
    guest: guest,
    created: created,
    started: started,
    guestPublicId: guestPublicId,
  );
}

Future<void> _expectRunningMatchVisibility(
  TestEndpoints endpoints, {
  required _AccountSession guest,
  required _AccountSession stranger,
  required String matchId,
}) async {
  final guestMatches = await endpoints.listCurrentMatches(guest.session);
  final strangerMatches = await endpoints.listCurrentMatches(stranger.session);
  expect(guestMatches.map((match) => match.id), contains(matchId));
  expect(strangerMatches.map((match) => match.id), isNot(contains(matchId)));
}

void _registerMultiplayerEndpointVersionSmokeTests(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) {
  test('rejects unauthenticated Serverpod calls', () async {
    await expectLater(
      endpoints.listCurrentMatches(sessionBuilder),
      throwsA(isA<ServerpodUnauthenticatedException>()),
    );
  });

  test('rejects missing, older, and future client revisions', () async {
    final session = _authenticatedSession(
      sessionBuilder,
      'multiplayer-version-gate-user',
    );
    for (final version in <int?>[
      null,
      kCurrentMultiplayerVersion - 1,
      kCurrentMultiplayerVersion + 1,
    ]) {
      await expectLater(
        endpoints.multiplayer.listMatches(session, multiplayerVersion: version),
        throwsA(
          isA<MultiplayerException>().having(
            (error) => error.code,
            'code',
            'unsupported_multiplayer_version',
          ),
        ),
        reason: 'version $version',
      );
    }
  });

  test('accepts the current client revision at the endpoint', () async {
    final matches = await endpoints.listCurrentMatches(
      _authenticatedSession(sessionBuilder, 'current-multiplayer-version-user'),
    );

    expect(matches, isEmpty);
  });

  test('rejects an undeclared revision at the stream boundary', () async {
    final input = StreamController<MultiplayerClientMessage>();
    addTearDown(input.close);

    await expectLater(
      endpoints.multiplayer.connect(
        _authenticatedSession(sessionBuilder, 'legacy-stream-version-user'),
        'legacy-match',
        0,
        input.stream,
        multiplayerVersion: null,
      ),
      emitsError(
        isA<MultiplayerException>().having(
          (error) => error.code,
          'code',
          'unsupported_multiplayer_version',
        ),
      ),
    );
  });
}
