import 'dart:async';

import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:test/test.dart';

void main() {
  test('broadcasts a public-lobby departure immediately', () async {
    final hub = RealtimeMatchHub();
    final store = _LobbyPresenceStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Live roster',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: false,
      ),
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );
    final input = StreamController<MultiplayerClientMessage>();
    final stream = hub
        .connect(
          store: store,
          userIdentifier: 'owner-user',
          matchId: match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    await stream.first;
    final rosterUpdate = stream.firstWhere(
      (message) =>
          message.match?.players.every(
            (player) => player.userId != 'guest-user',
          ) ??
          false,
    );

    await hub.leaveMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );

    expect(
      (await rosterUpdate.timeout(
        const Duration(seconds: 1),
      )).match!.players.map((player) => player.userId),
      ['owner-user'],
    );
    await input.close();
  });

  test(
    'broadcasts quickplay joins and retains players when owner leaves',
    () async {
      final hub = RealtimeMatchHub();
      final store = _LobbyPresenceStore();
      final waiting = await _quickplay(
        hub,
        store,
        user: 'owner-user',
        country: PlayerCountry.japan,
      );
      await _quickplay(
        hub,
        store,
        user: 'guest-user',
        country: PlayerCountry.france,
      );
      final input = StreamController<MultiplayerClientMessage>();
      final stream = hub
          .connect(
            store: store,
            userIdentifier: 'guest-user',
            matchId: waiting.id,
            afterOffset: 0,
            input: input.stream,
          )
          .asBroadcastStream();
      await stream.first;

      final thirdJoined = stream.firstWhere(
        (message) => message.match?.players.length == 3,
      );
      await _quickplay(
        hub,
        store,
        user: 'third-user',
        country: PlayerCountry.germany,
      );
      expect((await thirdJoined).match!.players, hasLength(3));

      final ownerLeft = stream.firstWhere(
        (message) =>
            message.match?.ownerUserId == 'guest-user' &&
            message.match?.players.length == 2,
      );
      await hub.leaveMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: waiting.id,
      );
      final remaining = (await ownerLeft).match!;
      expect(remaining.state, 'open');
      expect(remaining.players, hasLength(2));
      expect(remaining.players.first.userId, 'guest-user');
      expect(
        remaining.players.map((player) => player.userId),
        isNot(contains('owner-user')),
      );
      await input.close();
    },
  );

  test('expires inactive running matches from older protocols', () async {
    var now = DateTime.utc(2026, 6, 30, 8);
    final hub = RealtimeMatchHub(
      matchInactivityTimeout: const Duration(hours: 1),
      nowUtc: () => now,
    );
    final store = _LobbyPresenceStore();
    await store.createState(
      StoredMatchState(
        match: WireMatch(
          id: 'inactive-match',
          ownerUserId: 'owner-user',
          name: 'Inactive match',
          mapName: 'verdantia',
          players: const [],
          maxPlayers: 2,
          minPlayers: 2,
          quickplay: false,
          turn: 1,
          state: 'running',
          createdAt: now,
        ),
        snapshot: WireSnapshot(
          v: kProtocolVersion - 1,
          matchId: 'inactive-match',
          offset: 0,
          save: const {},
          state: {
            'phase': 'running',
            'lastHumanActivityAt': now.toIso8601String(),
          },
        ),
      ),
    );

    now = now.add(const Duration(hours: 1));
    expect(await hub.advanceTimedOutTurns(store: store), isEmpty);

    final abandoned = (await store.findState('inactive-match'))!;
    expect(abandoned.match.state, 'abandoned');
    expect(abandoned.match.endedAt, now);
    expect(abandoned.snapshot.state['reason'], 'all_players_inactive');
  });
}

Future<WireMatch> _quickplay(
  RealtimeMatchHub hub,
  MultiplayerMatchStore store, {
  required String user,
  required PlayerCountry country,
}) {
  return hub.quickplay(
    store: store,
    userIdentifier: user,
    request: CreateMatchRequest(
      name: 'Quickplay',
      mapName: 'verdantia',
      maxPlayers: 4,
      minPlayers: 2,
      private: false,
      countryId: country.name,
    ),
  );
}

final class _LobbyPresenceStore implements MultiplayerMatchStore {
  final _states = <String, StoredMatchState>{};
  final _events = <String, List<WireEvent>>{};

  @override
  final operationalEvents = const NoopServerOperationalEventSink();

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) => action(this);

  @override
  Future<StoredMatchState> createState(StoredMatchState state) async {
    _states[state.match.id] = state;
    _events[state.match.id] = [];
    return state;
  }

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) async {
    _states[state.match.id] = state;
    return state;
  }

  @override
  Future<StoredMatchState?> findState(
    String matchId, {
    bool lock = false,
  }) async => _states[matchId];

  @override
  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  ) async {
    for (final state in _states.values) {
      final match = state.match;
      if (match.state == 'open' &&
          match.quickplay &&
          match.players.length < match.maxPlayers) {
        return state;
      }
    }
    return null;
  }

  @override
  Future<RunningMatchStatePage> listRunningStates({
    RunningMatchCursor? after,
  }) async {
    return RunningMatchStatePage(
      states: _states.values.where((state) => state.match.state == 'running'),
      nextCursor: null,
    );
  }

  @override
  Future<StoredMatchState?> findPrivateState(
    String inviteCode, {
    bool lock = false,
  }) async => null;

  @override
  Future<List<WireMatch>> listVisibleMatches(String userIdentifier) async => [];

  @override
  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  }) async {
    await saveState(state);
    _events.putIfAbsent(state.match.id, () => []).add(event);
    return state;
  }

  @override
  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  }) async => null;

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    return [
      for (final event in _events[matchId] ?? const <WireEvent>[])
        if (event.offset > afterOffset) event,
    ];
  }
}
