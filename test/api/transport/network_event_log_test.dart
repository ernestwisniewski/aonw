import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/api/transport/network_event_log.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkEventLog', () {
    test('reads server events as LoggedCommand entries', () async {
      const codec = EventCodec();
      final wire = codec.toWire(
        matchId: 'match_1',
        offset: 12,
        timestamp: DateTime.utc(2026, 4, 26, 12),
        actorPlayerId: 'player_1',
        tick: 3,
        command: const MoveUnitCommand('u1', 1, 0),
        events: const [
          UnitMovedEvent(
            unitId: 'u1',
            fromCol: 0,
            fromRow: 0,
            toCol: 1,
            toRow: 0,
          ),
        ],
      );
      final backend = _FakeMultiplayerBackend(events: [wire]);
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      final entries = await log.readSince('match_1', offset: 10).toList();

      expect(backend.listEventsMatchId, 'match_1');
      expect(backend.listEventsAfterOffset, 9);
      expect(entries.single.offset, 12);
      expect(entries.single.actorPlayerId, 'player_1');
      expect(entries.single.command, const MoveUnitCommand('u1', 1, 0));
      expect(entries.single.events.single, isA<UnitMovedEvent>());
    });

    test(
      'skips redacted events while preserving their latest offset',
      () async {
        final backend = _FakeMultiplayerBackend(
          events: [
            WireEvent(
              matchId: 'match_1',
              offset: 9,
              timestamp: DateTime.utc(2026),
            ),
          ],
        );
        final log = NetworkEventLog(
          backendClient: backend,
          token: AuthToken('jwt-token'),
        );

        expect(await log.readSince('match_1').toList(), isEmpty);
        expect(await log.latestOffset('match_1'), 9);
        expect(backend.listEventsAfterOffset, 0);
      },
    );

    test('reads a full 256-event page and the following page', () async {
      final backend = _PagedMultiplayerBackend([
        for (var offset = 1; offset <= 257; offset++) _wireCommand(offset),
      ]);
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      final entries = await log.readSince('match_1').toList();

      expect(entries, hasLength(257));
      expect(entries.first.offset, 1);
      expect(entries.last.offset, 257);
      expect(backend.requestedOffsets, [0, 256]);

      backend.requestedOffsets.clear();
      expect(await log.latestOffset('match_1'), 257);
      expect(backend.requestedOffsets, [0, 256]);
    });

    test('redacted boundary event advances the next-page cursor', () async {
      final backend = _PagedMultiplayerBackend([
        for (var offset = 1; offset < 256; offset++) _wireCommand(offset),
        WireEvent(
          matchId: 'match_1',
          offset: 256,
          timestamp: DateTime.utc(2026),
        ),
        _wireCommand(257),
      ]);
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      final entries = await log.readSince('match_1').toList();

      expect(entries, hasLength(256));
      expect(entries.last.offset, 257);
      expect(backend.requestedOffsets, [0, 256]);

      backend.requestedOffsets.clear();
      expect(await log.latestOffset('match_1'), 257);
      expect(backend.requestedOffsets, [0, 256]);
    });

    test('rejects a backend page that does not advance its offset', () async {
      final backend = _NonMonotonicMultiplayerBackend();
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      await expectLater(
        log.readSince('match_1').toList(),
        throwsA(isA<StateError>()),
      );
      expect(backend.requestedOffsets, [0, 256]);

      final latestBackend = _NonMonotonicMultiplayerBackend();
      final latestLog = NetworkEventLog(
        backendClient: latestBackend,
        token: AuthToken('jwt-token'),
      );
      await expectLater(
        latestLog.latestOffset('match_1'),
        throwsA(isA<StateError>()),
      );
      expect(latestBackend.requestedOffsets, [0, 256]);
    });
  });
}

WireEvent _wireCommand(int offset) {
  return const EventCodec().toWire(
    matchId: 'match_1',
    offset: offset,
    timestamp: DateTime.utc(2026),
    actorPlayerId: 'player_1',
    tick: offset,
    command: const MoveUnitCommand('u1', 1, 0),
    events: const [],
  );
}

class _FakeMultiplayerBackend implements MultiplayerBackendClient {
  _FakeMultiplayerBackend({this.events = const []});

  final List<WireEvent> events;

  String? listEventsMatchId;
  int? listEventsAfterOffset;

  @override
  Future<WireMatch> createMatch(sp.CreateMatchRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveMatch(String matchId) {
    throw UnimplementedError();
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    listEventsMatchId = matchId;
    listEventsAfterOffset = afterOffset;
    return events;
  }

  @override
  Future<List<WireMatch>> listMatches() {
    throw UnimplementedError();
  }

  @override
  Future<WireSnapshot> loadSnapshot(String matchId) {
    throw UnimplementedError();
  }
}

class _PagedMultiplayerBackend extends _FakeMultiplayerBackend {
  _PagedMultiplayerBackend(this.allEvents);

  final List<WireEvent> allEvents;
  final requestedOffsets = <int>[];

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    requestedOffsets.add(afterOffset);
    return allEvents
        .where((event) => event.offset > afterOffset)
        .take(256)
        .toList();
  }
}

final class _NonMonotonicMultiplayerBackend extends _FakeMultiplayerBackend {
  final requestedOffsets = <int>[];

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    requestedOffsets.add(afterOffset);
    if (afterOffset == 0) {
      return [
        for (var offset = 1; offset <= 256; offset++) _wireCommand(offset),
      ];
    }
    return [_wireCommand(afterOffset)];
  }
}
