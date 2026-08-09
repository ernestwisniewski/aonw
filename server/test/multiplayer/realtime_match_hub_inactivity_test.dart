import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:test/test.dart';

import 'realtime_match_hub_test.dart';

void main() {
  test('pauses a timed-out turn while every human is offline', () async {
    final fixture = await _createInactivityFixture('all-offline');
    final offline = await fixture.stateWithPresence(
      connectedHumanIndexes: const {},
    );
    await fixture.store.saveState(offline);

    fixture.elapse(const Duration(seconds: 11));
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);

    final updated = await fixture.state();
    expect(updated.snapshot, offline.snapshot);
    expect(updated.match.turn, 1);
    expect(await fixture.events(), isEmpty);
  });

  test('keeps the turn timeout active while one human is online', () async {
    final fixture = await _createInactivityFixture('one-online');
    final oneOnline = await fixture.stateWithPresence(
      connectedHumanIndexes: const {0},
    );
    await fixture.store.saveState(oneOnline);
    final activityAt = oneOnline.snapshot.state['lastHumanActivityAt'];

    fixture.elapse(const Duration(seconds: 11));
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);

    final updated = await fixture.state();
    expect(updated.match.turn, 2);
    expect(await fixture.events(), hasLength(1));
    expect(updated.snapshot.state['lastHumanActivityAt'], activityAt);
  });

  test('abandons an offline match at exactly twelve hours', () async {
    final logs = <String>[];
    final fixture = await _createInactivityFixture(
      'inactive-abandonment',
      operationalEvents: _recordingOperationalEvents(logs),
    );
    await fixture.store.saveState(
      await fixture.stateWithPresence(
        connectedHumanIndexes: const {},
        lastHumanActivityAt: fixture.now,
      ),
    );

    fixture.elapse(const Duration(hours: 11, minutes: 59, seconds: 59));
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);
    expect((await fixture.state()).match.state, 'running');

    fixture.elapse(const Duration(seconds: 1));
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);

    final abandoned = await fixture.state();
    expect(abandoned.match.state, 'abandoned');
    expect(abandoned.match.endedAt, fixture.now);
    expect(abandoned.match.winnerPlayerId, isNull);
    expect(abandoned.match.outcomeCondition, isNull);
    expect(abandoned.snapshot.state['phase'], 'abandoned');
    expect(abandoned.snapshot.state['reason'], 'all_players_inactive');
    expect(abandoned.presenceLeases, isEmpty);
    expect(await fixture.events(), isEmpty);
    expect(
      logs,
      contains(
        'event=multiplayer_match_abandoned '
        'match_id=${fixture.match.id} reason=all_players_inactive',
      ),
    );
  });

  test('first reconnect after a global pause restarts the clock', () async {
    final fixture = await _createInactivityFixture('restart-clock');
    final offline = await fixture.stateWithPresence(
      connectedHumanIndexes: const {},
    );
    await fixture.store.saveState(offline);
    fixture.elapse(const Duration(hours: 1));

    final input = StreamController<MultiplayerClientMessage>();
    final stream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: fixture.match.players.first.userId,
          matchId: fixture.match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    final initial = await stream.first;
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        initial.snapshot!.state,
      ).turnStartedAt,
      fixture.now,
    );
    expect(initial.snapshot!.offset, offline.snapshot.offset);
    expect(await fixture.events(), isEmpty);

    fixture.elapse(const Duration(seconds: 9));
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);
    expect((await fixture.state()).match.turn, 1);

    final timeoutUpdate = stream.firstWhere((message) => message.event != null);
    fixture.elapse(const Duration(seconds: 2));
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);
    await timeoutUpdate.timeout(const Duration(seconds: 1));
    expect((await fixture.state()).match.turn, 2);
    await input.close();
  });
}

Future<_InactivityFixture> _createInactivityFixture(
  String suffix, {
  ServerOperationalEventSink operationalEvents =
      const NoopServerOperationalEventSink(),
}) async {
  final mapCatalog = TestMapCatalog(testMap());
  final fixture = _InactivityFixture(
    mapCatalog: mapCatalog,
    now: DateTime.utc(2026, 8, 8, 8),
    store: TestMatchStore(operationalEvents: operationalEvents),
  );
  fixture.match = await startRunningTestMatch(
    hub: fixture.hub,
    store: fixture.store,
    suffix: suffix,
    mapCatalog: mapCatalog,
  );
  return fixture;
}

ServerpodOperationalEventSink _recordingOperationalEvents(
  List<String> messages,
) {
  return ServerpodOperationalEventSink.withWriter((
    message, {
    required level,
    stackTrace,
  }) {
    messages.add(message);
  });
}

final class _InactivityFixture {
  _InactivityFixture({
    required TestMapCatalog mapCatalog,
    required this.now,
    required this.store,
  }) {
    hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(
        mapCatalog: mapCatalog,
        turnTimeout: const Duration(seconds: 10),
      ),
      nowUtc: () => now,
    );
  }

  final TestMatchStore store;
  late final RealtimeMatchHub hub;
  DateTime now;
  late WireMatch match;

  void elapse(Duration duration) => now = now.add(duration);

  Future<StoredMatchState> state() async => (await store.findState(match.id))!;

  Future<List<WireEvent>> events() => store.listEvents(match.id, 0);

  Future<StoredMatchState> stateWithPresence({
    required Set<int> connectedHumanIndexes,
    DateTime? lastHumanActivityAt,
  }) async {
    final current = await state();
    final humanPlayers = current.match.players
        .where((player) => player.kind == WirePlayerKind.human)
        .toList(growable: false);
    final connectedUserIds = {
      for (final index in connectedHumanIndexes) humanPlayers[index].userId,
    };
    final domain = CanonicalGameSnapshotCodec.decodeDomainState(
      current.snapshot.state,
    );
    final activity =
        lastHumanActivityAt?.toUtc().toIso8601String() ??
        current.snapshot.state['lastHumanActivityAt'];
    return current.copyWith(
      match: current.match.copyWith(
        players: [
          for (final player in current.match.players)
            player.kind == WirePlayerKind.human
                ? player.copyWith(
                    connectionState: connectedUserIds.contains(player.userId)
                        ? WirePlayerConnectionState.connected
                        : WirePlayerConnectionState.offline,
                  )
                : player,
        ],
      ),
      snapshot: current.snapshot.copyWith(
        state: {
          ...CanonicalGameSnapshotCodec.encodeDomainState(
            domain.copyWith(turnStartedAt: now),
          ),
          'lastHumanActivityAt': ?activity,
        },
      ),
      presenceLeases: {
        for (final entry in current.presenceLeases.entries)
          if (connectedUserIds.contains(entry.key)) entry.key: entry.value,
      },
    );
  }
}
