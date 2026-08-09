part of '../multiplayer_endpoint_smoke.dart';

void _registerMultiplayerEndpointQuickplaySmokeTests(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) {
  test(
    'quickplay enforces seats, countdown, country conflicts, and capacity',
    () => _verifyQuickplayLifecycle(sessionBuilder, endpoints),
  );
}

void _expectCreatedEndpointMatch(WireMatch created, _AccountSession owner) {
  expect(created.ownerUserId, owner.userIdentifier);
  expect(created.players.map((player) => player.userId), [
    owner.userIdentifier,
  ]);
  expect(created.players.map((player) => player.name), ['Owner Nick']);
  expect(created.state, 'open');
}

Future<void> _verifyQuickplayLifecycle(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) async {
  final accounts = await _quickplayAccounts(sessionBuilder, endpoints);
  final waiting = await endpoints.quickplayCurrent(
    accounts.owner.session,
    _quickplayRequest(PlayerCountry.poland),
  );
  expect(waiting.quickplay, isTrue);
  expect(waiting.maxPlayers, 4);
  expect(waiting.minPlayers, 2);
  expect(waiting.state, 'open');
  expect(waiting.autoStartAt, isNull);
  expect(waiting.players.single.country, PlayerCountry.poland);
  await _connectParticipant(endpoints, accounts.owner.session, waiting.id);

  await endpoints.emailIdp.updateDisplayName(
    accounts.owner.session,
    displayName: 'Quick Owner Renamed',
  );
  final requeued = await endpoints.quickplayCurrent(
    accounts.owner.session,
    _quickplayRequest(PlayerCountry.china),
  );
  expect(requeued.id, waiting.id);
  expect(requeued.players, hasLength(1));
  expect(requeued.players.single.name, 'Quick Owner Renamed');
  expect(requeued.players.single.country, PlayerCountry.china);

  final countdown = await _connectQuickplayGuest(
    endpoints,
    waiting.id,
    accounts.guest,
  );
  await _expectQuickplayCountryConflict(endpoints, accounts.conflict);
  final resumedCountdown = await _connectThirdQuickplayPlayer(
    endpoints,
    waiting.id,
    accounts.third,
    countdown.autoStartAt!,
  );
  expect(resumedCountdown.autoStartAt, isNotNull);
  final started = await _connectFourthQuickplayPlayer(
    endpoints,
    waiting.id,
    accounts.fourth,
  );
  expect(started.players.map((player) => player.country), [
    PlayerCountry.china,
    PlayerCountry.france,
    PlayerCountry.germany,
    PlayerCountry.japan,
  ]);

  final nextLobby = await endpoints.quickplayCurrent(
    accounts.overflow.session,
    _quickplayRequest(PlayerCountry.italy),
  );
  expect(nextLobby.id, isNot(started.id));
  expect(nextLobby.state, 'open');
  expect(nextLobby.players.single.country, PlayerCountry.italy);
}

Future<WireMatch> _connectQuickplayGuest(
  TestEndpoints endpoints,
  String matchId,
  _AccountSession guest,
) async {
  final joining = await endpoints.quickplayCurrent(
    guest.session,
    _quickplayRequest(PlayerCountry.france),
  );
  expect(joining.autoStartAt, isNull);
  await _connectParticipant(endpoints, guest.session, matchId);
  final countdown = await endpoints.loadCurrentMatch(guest.session, matchId);
  expect(countdown.id, matchId);
  expect(countdown.state, 'open');
  expect(countdown.autoStartAt, isNotNull);
  expect(countdown.players.map((player) => player.country), [
    PlayerCountry.china,
    PlayerCountry.france,
  ]);
  return countdown;
}

Future<void> _expectQuickplayCountryConflict(
  TestEndpoints endpoints,
  _AccountSession conflict,
) async {
  await expectLater(
    endpoints.quickplayCurrent(
      conflict.session,
      _quickplayRequest(PlayerCountry.france),
    ),
    throwsA(
      isA<MultiplayerException>().having(
        (error) => error.code,
        'code',
        'country_unavailable',
      ),
    ),
  );
}

Future<WireMatch> _connectThirdQuickplayPlayer(
  TestEndpoints endpoints,
  String matchId,
  _AccountSession third,
  DateTime previousCountdown,
) async {
  final joining = await endpoints.quickplayCurrent(
    third.session,
    _quickplayRequest(PlayerCountry.germany),
  );
  expect(joining.id, matchId);
  expect(joining.state, 'open');
  expect(joining.players, hasLength(3));
  expect(joining.autoStartAt, isNull);
  await _connectParticipant(endpoints, third.session, matchId);
  final resumed = await endpoints.loadCurrentMatch(third.session, matchId);
  expect(resumed.autoStartAt, isNotNull);
  expect(resumed.autoStartAt!.isAfter(previousCountdown), isTrue);
  return resumed;
}

Future<WireMatch> _connectFourthQuickplayPlayer(
  TestEndpoints endpoints,
  String matchId,
  _AccountSession fourth,
) async {
  final joining = await endpoints.quickplayCurrent(
    fourth.session,
    _quickplayRequest(PlayerCountry.japan),
  );
  expect(joining.state, 'open');
  await _connectParticipant(endpoints, fourth.session, matchId);
  final started = await endpoints.loadCurrentMatch(fourth.session, matchId);
  expect(started.id, matchId);
  expect(started.state, 'running');
  expect(started.turn, 1);
  expect(started.autoStartAt, isNull);
  expect(started.players, hasLength(4));
  return started;
}

Future<
  ({
    _AccountSession owner,
    _AccountSession guest,
    _AccountSession conflict,
    _AccountSession third,
    _AccountSession fourth,
    _AccountSession overflow,
  })
>
_quickplayAccounts(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) async {
  Future<_AccountSession> account(String role) => _accountSession(
    sessionBuilder,
    endpoints,
    email: 'quick-$role@example.test',
    displayName: 'Quick ${role[0].toUpperCase()}${role.substring(1)}',
  );
  final owner = await account('owner');
  final guest = await account('guest');
  final conflict = await account('conflict');
  final third = await account('third');
  final fourth = await account('fourth');
  final overflow = await account('overflow');
  return (
    owner: owner,
    guest: guest,
    conflict: conflict,
    third: third,
    fourth: fourth,
    overflow: overflow,
  );
}
