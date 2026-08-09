part of '../serverpod_critical_e2e.dart';

extension _CriticalE2eLobby on _CriticalE2e {
  Future<
    ({
      WireMatch started,
      CriticalMatchStream ownerLobbyStream,
      CriticalMatchStream guestLobbyStream,
    })
  >
  _createAndStartLiveMatch({
    required sp.Client ownerClient,
    required sp.Client guestClient,
    required int runId,
  }) async {
    final created = await _request(
      ownerClient.multiplayer.createCurrentMatch(
        sp.CreateMatchRequest(
          name: 'Critical E2E $runId',
          mapName: config.mapName,
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      ),
    );
    _expect(
      created.state == 'open' && created.players.length == 1,
      'Expected a one-player open match after create.',
    );
    final ownerLobbyStream = await _open(ownerClient, created.id, 0);
    _expectInitialSnapshot(
      ownerLobbyStream.initialMessage,
      matchId: created.id,
      offset: 0,
      context: 'owner lobby presence',
    );
    final joined = await _request(
      guestClient.multiplayer.joinCurrentMatch(created.id),
    );
    _expect(
      joined.state == 'open' && joined.players.length == 2,
      'Expected the guest to join the open match.',
    );
    final guestLobbyStream = await _open(guestClient, created.id, 0);
    _expectInitialSnapshot(
      guestLobbyStream.initialMessage,
      matchId: created.id,
      offset: 0,
      context: 'guest lobby presence',
    );
    final started = await _request(
      ownerClient.multiplayer.startCurrentMatch(created.id),
    );
    _expect(
      started.state == 'running' &&
          started.turn == 1 &&
          started.players.length == 2,
      'Expected a running two-player match at turn 1.',
    );
    return (
      started: started,
      ownerLobbyStream: ownerLobbyStream,
      guestLobbyStream: guestLobbyStream,
    );
  }
}
