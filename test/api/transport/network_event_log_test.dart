import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/api/transport/network_event_log.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkEventLog', () {
    test('reads server events as RecordedDomainCommand entries', () async {
      const codec = EventCodec();
      final wire = codec.toWire(
        matchId: 'match_1',
        offset: 12,
        timestamp: DateTime.utc(2026, 4, 26, 12),
        actorPlayerId: 'player_1',
        tick: 3,
        turn: 7,
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
      expect(entries.single.turn, 7);
      expect(entries.single.commandTick, 3);
      expect(entries.single.command, const MoveUnitCommand('u1', 1, 0));
      expect(entries.single.events.single, isA<UnitMovedEvent>());
    });

    test(
      'preserves fully redacted entries as event-only log records',
      () async {
        final backend = _FakeMultiplayerBackend(
          events: [
            WireEvent(
              matchId: 'match_1',
              offset: 9,
              timestamp: DateTime.utc(2026),
              movementExecutions: WireMovementExecutionList(const []),
            ),
          ],
        );
        final log = NetworkEventLog(
          backendClient: backend,
          token: AuthToken('jwt-token'),
        );

        final entries = await log.readSince('match_1').toList();

        expect(entries.single.offset, 9);
        expect(entries.single.command, isNull);
        expect(entries.single.events, isEmpty);
        expect(await log.latestOffset('match_1'), 9);
        expect(backend.listEventsAfterOffset, 0);
      },
    );

    test('preserves projected events when their command is redacted', () async {
      const codec = EventCodec();
      final wire = codec.toWire(
        matchId: 'match_1',
        offset: 10,
        timestamp: DateTime.utc(2026, 5, 17, 12),
        actorPlayerId: 'player_3',
        tick: 4,
        turn: 2,
        events: const [
          CityCapturedEvent(
            cityId: 'city_2',
            previousOwnerPlayerId: 'player_2',
            newOwnerPlayerId: 'player_3',
          ),
        ],
      );
      final log = NetworkEventLog(
        backendClient: _FakeMultiplayerBackend(events: [wire]),
        token: AuthToken('jwt-token'),
        recipientPlayerId: 'player_2',
      );

      final entry = (await log.readSince('match_1').toList()).single;

      expect(entry.command, isNull);
      expect(entry.actorPlayerId, 'player_3');
      expect(entry.events.single, isA<CityCapturedEvent>());
      expect(entry.activity.single.playerId, 'player_2');
      expect(entry.activity.single.event, isA<CityCapturedEvent>());
    });

    test(
      'keeps authoritative movement plans out of RecordedDomainCommand history',
      () async {
        final wire = WireEvent(
          matchId: 'match_1',
          offset: 11,
          timestamp: DateTime.utc(2026, 7, 25),
          movementExecutions: WireMovementExecutionList([
            WireMovementExecution(
              unitId: 'renderer-movement-canary',
              fromCol: 0,
              fromRow: 0,
              steps: const [
                WireMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ]),
        );
        final log = NetworkEventLog(
          backendClient: _FakeMultiplayerBackend(events: [wire]),
          token: AuthToken('jwt-token'),
        );

        final entry = (await log.readSince('match_1').toList()).single;

        expect(entry.offset, 11);
        expect(entry.command, isNull);
        expect(entry.events, isEmpty);
        expect(entry.activity, isEmpty);
        expect(entry.toJson(), isNot(contains('movementExecutions')));
        expect(
          entry.toJson().toString(),
          isNot(contains('renderer-movement-canary')),
        );
      },
    );

    test('reads a full protocol page and the following page', () async {
      final backend = _PagedMultiplayerBackend([
        for (var offset = 1; offset <= multiplayerEventPageSize + 1; offset++)
          _wireCommand(offset),
      ]);
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      final entries = await log.readSince('match_1').toList();

      expect(entries, hasLength(multiplayerEventPageSize + 1));
      expect(entries.first.offset, 1);
      expect(entries.last.offset, multiplayerEventPageSize + 1);
      expect(backend.requestedOffsets, [0, multiplayerEventPageSize]);

      backend.requestedOffsets.clear();
      expect(await log.latestOffset('match_1'), multiplayerEventPageSize + 1);
      expect(backend.requestedOffsets, [0, multiplayerEventPageSize]);
    });

    test('redacted boundary entry advances the next-page cursor', () async {
      final backend = _PagedMultiplayerBackend([
        for (var offset = 1; offset < multiplayerEventPageSize; offset++)
          _wireCommand(offset),
        WireEvent(
          matchId: 'match_1',
          offset: multiplayerEventPageSize,
          timestamp: DateTime.utc(2026),
          movementExecutions: WireMovementExecutionList(const []),
        ),
        _wireCommand(multiplayerEventPageSize + 1),
      ]);
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      final entries = await log.readSince('match_1').toList();

      expect(entries, hasLength(multiplayerEventPageSize + 1));
      expect(entries[multiplayerEventPageSize - 1].command, isNull);
      expect(entries.last.offset, multiplayerEventPageSize + 1);
      expect(backend.requestedOffsets, [0, multiplayerEventPageSize]);

      backend.requestedOffsets.clear();
      expect(await log.latestOffset('match_1'), multiplayerEventPageSize + 1);
      expect(backend.requestedOffsets, [0, multiplayerEventPageSize]);
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
      expect(backend.requestedOffsets, [0, multiplayerEventPageSize]);

      final latestBackend = _NonMonotonicMultiplayerBackend();
      final latestLog = NetworkEventLog(
        backendClient: latestBackend,
        token: AuthToken('jwt-token'),
      );
      await expectLater(
        latestLog.latestOffset('match_1'),
        throwsA(isA<StateError>()),
      );
      expect(latestBackend.requestedOffsets, [0, multiplayerEventPageSize]);
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
    turn: 1,
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
  void close() {}

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
        .take(multiplayerEventPageSize)
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
        for (var offset = 1; offset <= multiplayerEventPageSize; offset++)
          _wireCommand(offset),
      ];
    }
    return [_wireCommand(afterOffset)];
  }
}
