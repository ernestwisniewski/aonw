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
      expect(backend.listEventsAfterOffset, 10);
      expect(entries.single.offset, 12);
      expect(entries.single.actorPlayerId, 'player_1');
      expect(entries.single.command, const MoveUnitCommand('u1', 1, 0));
      expect(entries.single.events.single, isA<UnitMovedEvent>());
    });

    test('rejects wire events without command payloads', () async {
      final backend = _FakeMultiplayerBackend(
        events: [
          WireEvent(
            matchId: 'match_1',
            offset: 1,
            timestamp: DateTime.utc(2026),
          ),
        ],
      );
      final log = NetworkEventLog(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      await expectLater(
        log.readSince('match_1').toList(),
        throwsA(isA<NetworkEventFormatException>()),
      );
    });
  });
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
