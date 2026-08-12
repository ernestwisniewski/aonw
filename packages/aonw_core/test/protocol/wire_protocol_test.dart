import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('wire protocol', () {
    test('round-trips command ack with snapshot and events', () {
      final ack = WireCommandAck(
        matchId: 'match_1',
        clientMessageId: 'command_1',
        accepted: false,
        offset: 3,
        tick: 17,
        timestamp: DateTime.utc(2026, 8, 2, 12),
        snapshot: const WireSnapshot(
          matchId: 'match_1',
          offset: 3,
          save: {'id': 'match_1'},
          state: {'units': <Object>[]},
        ),
        events: [SystemEventWire.commandRejected(reason: 'not_allowed')],
        reason: 'not_allowed',
        movementExecutions: WireMovementExecutionList(const []),
      );

      final restored = WireCommandAck.fromJson(ack.toJson());

      expect(restored.v, kProtocolVersion);
      expect(restored.snapshot.v, kSnapshotEventVersion);
      expect(restored.matchId, 'match_1');
      expect(restored.clientMessageId, 'command_1');
      expect(restored.accepted, isFalse);
      expect(restored.tick, 17);
      expect(restored.timestamp, DateTime.utc(2026, 8, 2, 12));
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
        state: 'finished',
        createdAt: DateTime.utc(2026, 4, 27, 12),
        endedAt: DateTime.utc(2026, 4, 27, 13),
        outcomeCondition: 'conquest',
        winnerPlayerId: 'player_1',
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
        turn: 7,
        command: const {'type': 'SmokeCommand'},
        events: const [
          {'type': 'CommandAcceptedEvent'},
        ],
        movementExecutions: WireMovementExecutionList(const []),
      );

      final decodedMatch = WireMatch.fromJson(match.toJson());
      expect(decodedMatch.players.single.id, 'player_1');
      expect(decodedMatch.players.single.ready, isTrue);
      expect(decodedMatch.players.single.country, PlayerCountry.france);
      expect(decodedMatch.endedAt, DateTime.utc(2026, 4, 27, 13));
      expect(decodedMatch.outcomeCondition, 'conquest');
      expect(decodedMatch.winnerPlayerId, 'player_1');
      expect(
        decodedMatch
            .copyWith(
              endedAt: null,
              outcomeCondition: null,
              winnerPlayerId: null,
            )
            .toJson(),
        isNot(contains('endedAt')),
      );
      expect(
        WireEvent.fromJson(event.toJson()).command?['type'],
        'SmokeCommand',
      );
      expect(WireEvent.fromJson(event.toJson()).turn, 7);
      expect(event.toJson()['turn'], 7);
    });

    test('decodes a strict v4 ACK with its nested current snapshot', () {
      final ack = WireCommandAck(
        matchId: 'match_1',
        clientMessageId: 'command_1',
        accepted: true,
        offset: 3,
        snapshot: const WireSnapshot(
          matchId: 'match_1',
          offset: 3,
          save: {'id': 'match_1'},
          state: <String, dynamic>{},
        ),
        movementExecutions: WireMovementExecutionList(const []),
      );

      final json = ack.toJson();
      final restored = WireCommandAck.fromJson(json);

      expect(json['v'], kProtocolVersion);
      expect(
        (json['snapshot']! as Map<String, dynamic>)['v'],
        kSnapshotEventVersion,
      );
      expect(restored.v, kProtocolVersion);
      expect(restored.snapshot.v, kSnapshotEventVersion);
    });

    test(
      'snapshot and event readers accept v3 through v5 during expansion',
      () {
        const snapshot = WireSnapshot(
          matchId: 'match_1',
          offset: 3,
          save: {'id': 'match_1'},
          state: <String, dynamic>{},
        );
        final event = WireEvent(
          matchId: 'match_1',
          offset: 3,
          timestamp: DateTime.utc(2026, 8, 9),
          movementExecutions: WireMovementExecutionList(const []),
        );

        expect(
          WireSnapshot.fromJson(snapshot.toJson()).v,
          kSnapshotEventVersion,
        );
        expect(WireEvent.fromJson(event.toJson()).v, kSnapshotEventVersion);
        expect(
          WireSnapshot.fromJson({
            ...snapshot.toJson(),
            'v': kLegacySnapshotEventVersion,
          }).v,
          kLegacySnapshotEventVersion,
        );
        expect(
          WireEvent.fromJson({
            ...event.toJson(),
            'v': kLegacySnapshotEventVersion,
          }).v,
          kLegacySnapshotEventVersion,
        );
        expect(
          WireSnapshot.fromJson({
            ...snapshot.toJson(),
            'v': kOldestSnapshotEventVersion,
          }).v,
          kOldestSnapshotEventVersion,
        );
        expect(
          () => WireSnapshot.fromJson({...snapshot.toJson(), 'v': 2}),
          throwsArgumentError,
        );
        expect(
          () => WireEvent.fromJson({...event.toJson(), 'v': 6}),
          throwsArgumentError,
        );
      },
    );

    test('current ACK reads a legacy v3 nested snapshot', () {
      final ack = WireCommandAck(
        matchId: 'match_1',
        clientMessageId: 'command_legacy_snapshot',
        accepted: true,
        offset: 3,
        snapshot: const WireSnapshot(
          v: kLegacySnapshotEventVersion,
          matchId: 'match_1',
          offset: 3,
          save: {'id': 'match_1'},
          state: <String, dynamic>{},
        ),
        movementExecutions: WireMovementExecutionList(const []),
      );

      final restored = WireCommandAck.fromJson(ack.toJson());

      expect(restored.v, kProtocolVersion);
      expect(restored.snapshot.v, kLegacySnapshotEventVersion);
    });

    test('command, ACK, and match envelopes are strict v4', () {
      const command = WireCommand(
        matchId: 'match_1',
        tick: 3,
        actorPlayerId: 'player_1',
        command: {'type': 'EndTurn'},
      );
      final ack = WireCommandAck(
        matchId: 'match_1',
        clientMessageId: 'command_1',
        accepted: true,
        offset: 3,
        snapshot: const WireSnapshot(
          matchId: 'match_1',
          offset: 3,
          save: {'id': 'match_1'},
          state: <String, dynamic>{},
        ),
        movementExecutions: WireMovementExecutionList(const []),
      );
      final match = WireMatch(
        id: 'match_1',
        ownerUserId: 'user_1',
        name: 'Duel',
        mapName: 'verdantia',
        players: const [],
        turn: 1,
        state: 'open',
        createdAt: DateTime.utc(2026, 8, 9),
      );

      expect(WireCommand.fromJson(command.toJson()).v, 4);
      expect(WireCommandAck.fromJson(ack.toJson()).v, 4);
      expect(WireMatch.fromJson(match.toJson()).v, 4);
      expect(
        () => WireCommand.fromJson({...command.toJson(), 'v': 3}),
        throwsArgumentError,
      );
      expect(
        () => WireCommandAck.fromJson({...ack.toJson(), 'v': 3}),
        throwsArgumentError,
      );
      expect(
        () => WireMatch.fromJson({...match.toJson(), 'v': 3}),
        throwsArgumentError,
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
