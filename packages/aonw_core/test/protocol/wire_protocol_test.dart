import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('wire protocol', () {
    test('round-trips command ack with snapshot and events', () {
      final ack = WireCommandAck(
        matchId: 'match_1',
        accepted: false,
        offset: 3,
        snapshot: const WireSnapshot(
          matchId: 'match_1',
          offset: 3,
          save: {'id': 'match_1'},
          state: {'units': <Object>[]},
        ),
        events: [SystemEventWire.commandRejected(reason: 'not_allowed')],
        reason: 'not_allowed',
      );

      final restored = WireCommandAck.fromJson(ack.toJson());

      expect(restored.v, kProtocolVersion);
      expect(restored.matchId, 'match_1');
      expect(restored.accepted, isFalse);
      expect(restored.snapshot.state['units'], isEmpty);
      expect(restored.events.single['reason'], 'not_allowed');
    });

    test('builds shared system event JSON', () {
      expect(SystemEventWire.commandRejected(reason: 'not_allowed'), {
        'type': SystemEventWire.commandRejectedType,
        'reason': 'not_allowed',
      });
      expect(
        SystemEventWire.allPlayersSubmitted(
          turn: 2,
          playerIds: const ['player_1', 'player_2'],
        ),
        {
          'type': SystemEventWire.allPlayersSubmittedType,
          'turn': 2,
          'playerIds': ['player_1', 'player_2'],
        },
      );
      expect(SystemEventWire.playerTimedOut(turn: 2, playerId: 'player_2'), {
        'type': SystemEventWire.playerTimedOutType,
        'turn': 2,
        'playerId': 'player_2',
      });
      expect(
        SystemEventWire.turnAutoResolved(
          turn: 2,
          playerId: 'player_2',
          unitOrderCount: 1,
          cityProductionCount: 0,
          researchSelected: true,
        ),
        {
          'type': SystemEventWire.turnAutoResolvedType,
          'turn': 2,
          'playerId': 'player_2',
          'unitOrderCount': 1,
          'cityProductionCount': 0,
          'researchSelected': true,
        },
      );
      expect(
        SystemEventWire.playerKicked(
          turn: 2,
          playerId: 'player_2',
          reason: 'turn_timeout',
          timeoutStreak: 3,
        ),
        {
          'type': SystemEventWire.playerKickedType,
          'turn': 2,
          'playerId': 'player_2',
          'reason': 'turn_timeout',
          'timeoutStreak': 3,
        },
      );
    });

    test('reads first command rejection reason', () {
      final events = [
        {'type': 'SomeOtherEvent'},
        SystemEventWire.commandRejected(reason: 'turn_already_submitted'),
      ];

      expect(
        SystemEventWire.firstCommandRejectedReason(events),
        'turn_already_submitted',
      );
      expect(SystemEventWire.containsCommandRejected(events), isTrue);
    });

    test('round-trips match players and events', () {
      final match = WireMatch(
        id: 'match_1',
        ownerUserId: 'user_1',
        name: 'Duel',
        mapName: 'verdantia',
        turn: 1,
        state: 'open',
        createdAt: DateTime.utc(2026, 4, 27, 12),
        players: const [
          WirePlayer(
            id: 'player_1',
            userId: 'user_1',
            name: 'Owner',
            colorValue: 0xFF2563EB,
            country: PlayerCountry.france,
            kind: WirePlayerKind.human,
            connectionState: WirePlayerConnectionState.connected,
            ready: true,
          ),
        ],
      );
      final event = WireEvent(
        matchId: match.id,
        offset: 1,
        timestamp: DateTime.utc(2026, 4, 27, 12, 1),
        actorPlayerId: 'player_1',
        tick: 1,
        command: const {'type': 'SmokeCommand'},
        events: const [
          {'type': 'CommandAcceptedEvent'},
        ],
      );

      expect(WireMatch.fromJson(match.toJson()).players.single.id, 'player_1');
      expect(WireMatch.fromJson(match.toJson()).players.single.ready, isTrue);
      expect(
        WireMatch.fromJson(match.toJson()).players.single.country,
        PlayerCountry.france,
      );
      expect(
        WireEvent.fromJson(event.toJson()).command?['type'],
        'SmokeCommand',
      );
    });

    test('round-trips AI player metadata without exposing seed', () {
      const player = WirePlayer(
        id: 'player_2',
        userId: 'ai:match_1:player_2',
        name: 'AI Random',
        colorValue: 0xFFDC2626,
        kind: WirePlayerKind.ai,
        connectionState: WirePlayerConnectionState.connected,
        ai: WireAiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
        ),
      );

      final json = player.toJson();
      final restored = WirePlayer.fromJson(json);

      expect(json['ai'], isNot(contains('seed')));
      expect(restored.kind, WirePlayerKind.ai);
      expect(restored.ready, isFalse);
      expect(restored.ai?.strategyId, AiStrategyId.random);
    });
  });
}
