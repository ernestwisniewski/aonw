import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommandCodec', () {
    test('wraps a domain command with protocol metadata', () {
      const codec = CommandCodec();
      const command = MoveUnitCommand('unit_1', 3, 4);

      final wire = codec.toWire(
        matchId: 'match_1',
        tick: 42,
        turn: 3,
        actorPlayerId: 'player_1',
        command: command,
      );

      expect(wire.v, kProtocolVersion);
      expect(wire.matchId, 'match_1');
      expect(wire.tick, 42);
      expect(wire.turn, 3);
      expect(wire.actorPlayerId, 'player_1');
      expect(wire.command['type'], 'MoveUnit');
      expect(codec.fromWire(WireCommand.fromJson(wire.toJson())), command);
      expect(codec.contextFromWire(wire).actorPlayerId, 'player_1');
    });

    test('rejects unsupported protocol versions', () {
      expect(
        () => WireCommand.fromJson({
          'v': kProtocolVersion + 1,
          'matchId': 'match_1',
          'tick': 1,
          'actorPlayerId': 'player_1',
          'command': {'type': 'EndTurn', 'playerId': 'player_1'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('EventCodec', () {
    test('round-trips command and domain events through WireEvent', () {
      const codec = EventCodec();
      const command = MoveUnitCommand('unit_1', 3, 4);
      const event = UnitMovedEvent(
        unitId: 'unit_1',
        fromCol: 2,
        fromRow: 4,
        toCol: 3,
        toRow: 4,
      );

      final wire = codec.toWire(
        matchId: 'match_1',
        offset: 9,
        timestamp: DateTime.utc(2026, 4, 26, 10, 30),
        actorPlayerId: 'player_1',
        tick: 7,
        command: command,
        events: const [event],
      );
      final restored = codec.eventsFromWire(wire);
      final fromJson = codec
          .eventsFromWire(WireEvent.fromJson(wire.toJson()))
          .single;

      expect(wire.v, kProtocolVersion);
      expect(wire.offset, 9);
      expect(codec.commandFromWire(WireEvent.fromJson(wire.toJson())), command);
      expect(restored.single, isA<UnitMovedEvent>());
      expect(fromJson, isA<UnitMovedEvent>());
      final moved = fromJson as UnitMovedEvent;
      expect(moved.unitId, 'unit_1');
      expect(moved.fromCol, 2);
      expect(moved.toCol, 3);
    });

    test('parses server command rejection events', () {
      const codec = EventCodec();
      final wire = WireEvent(
        matchId: 'match_1',
        offset: 1,
        timestamp: DateTime.utc(2026, 4, 27, 12),
        actorPlayerId: 'player_1',
        tick: 3,
        command: const {'type': 'EndTurn', 'playerId': 'player_1'},
        events: [
          SystemEventWire.commandRejected(
            reason: 'domain_reducer_not_configured',
          ),
        ],
      );

      final event = codec
          .eventsFromWire(WireEvent.fromJson(wire.toJson()))
          .single;

      expect(event, isA<CommandRejectedEvent>());
      expect(
        (event as CommandRejectedEvent).reason,
        'domain_reducer_not_configured',
      );
      expect(codec.eventsToJsonList([event]).single, {
        'type': SystemEventWire.commandRejectedType,
        'reason': 'domain_reducer_not_configured',
      });
    });

    test('parses all players submitted events', () {
      const codec = EventCodec();
      final wire = WireEvent(
        matchId: 'match_1',
        offset: 2,
        timestamp: DateTime.utc(2026, 4, 27, 12),
        actorPlayerId: 'player_2',
        tick: 4,
        command: const {'type': 'SubmitTurn', 'playerId': 'player_2'},
        events: [
          SystemEventWire.allPlayersSubmitted(
            turn: 1,
            playerIds: const ['player_1', 'player_2'],
          ),
        ],
      );

      final event = codec
          .eventsFromWire(WireEvent.fromJson(wire.toJson()))
          .single;

      expect(event, isA<AllPlayersSubmittedEvent>());
      final submitted = event as AllPlayersSubmittedEvent;
      expect(submitted.turn, 1);
      expect(submitted.playerIds, ['player_1', 'player_2']);
    });

    test('parses player timed out events', () {
      const codec = EventCodec();
      final wire = WireEvent(
        matchId: 'match_1',
        offset: 3,
        timestamp: DateTime.utc(2026, 4, 27, 12),
        actorPlayerId: 'player_2',
        tick: 4,
        command: const {
          'type': 'SubmitTurn',
          'playerId': 'player_2',
          'timedOut': true,
        },
        events: [SystemEventWire.playerTimedOut(turn: 1, playerId: 'player_2')],
      );

      final event = codec
          .eventsFromWire(WireEvent.fromJson(wire.toJson()))
          .single;

      expect(event, isA<PlayerTimedOutEvent>());
      final timedOut = event as PlayerTimedOutEvent;
      expect(timedOut.turn, 1);
      expect(timedOut.playerId, 'player_2');
    });

    test('round-trips domination threshold events', () {
      const codec = EventCodec();
      const event = DominationThresholdReachedEvent(
        playerId: 'player_2',
        controlPercent: 43.2,
        requiredControlPercent: 42,
        holdTurns: 1,
        requiredHoldTurns: 4,
      );

      final restored = codec.eventsFromJsonList(
        codec.eventsToJsonList(const [event]),
      );

      expect(restored.single, isA<DominationThresholdReachedEvent>());
      final threshold = restored.single as DominationThresholdReachedEvent;
      expect(threshold.playerId, 'player_2');
      expect(threshold.controlPercent, 43.2);
      expect(threshold.requiredControlPercent, 42);
      expect(threshold.holdTurns, 1);
      expect(threshold.requiredHoldTurns, 4);
    });
  });

  group('SnapshotCodec', () {
    test(
      'round-trips persistent state without importing infrastructure codecs',
      () {
        const codec = SnapshotCodec();
        final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 2, row: 3),
        );
        final snapshot = SaveSnapshot(
          save: _save(),
          playerColors: const {'player_1': 0xFF2563EB},
          playerCountries: const {'player_1': PlayerCountry.france},
          playerGold: const {'player_1': 11},
          units: [unit],
          cities: const [city],
          fieldImprovements: const [
            FieldImprovement(
              hex: CityHex(col: 2, row: 4),
              type: FieldImprovementType.farm,
              builtByCityId: 'city_1',
            ),
          ],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {const HexCoordinate(col: 2, row: 3)},
              ),
            },
          ),
          runtimeState: const GameRuntimeState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'commander_player_1',
              defenderCol: 2,
              defenderRow: 3,
            ),
            submittedPlayerIds: {'player_1'},
          ),
          eventLogOffset: 12,
        );

        final wire = codec.toWire(matchId: 'match_1', snapshot: snapshot);
        final restored = codec.fromWire(WireSnapshot.fromJson(wire.toJson()));

        expect(wire.v, kProtocolVersion);
        expect(wire.offset, 12);
        expect(wire.state['playerGold'], {'player_1': 11});
        expect(restored.save.id, 'save_1');
        expect(restored.playerColors, {'player_1': 0xFF2563EB});
        expect(restored.playerCountries, {'player_1': PlayerCountry.france});
        expect(restored.playerGold, {'player_1': 11});
        expect(restored.units.single.id, unit.id);
        expect(restored.cities.single.id, city.id);
        expect(
          restored.fieldImprovements.single.type,
          FieldImprovementType.farm,
        );
        expect(
          restored.fogOfWar.isVisible(
            'player_1',
            const HexCoordinate(col: 2, row: 3),
          ),
          isTrue,
        );
        expect(
          restored.runtimeState.pendingAction,
          isA<PendingAttackTargeting>(),
        );
        final pending =
            restored.runtimeState.pendingAction as PendingAttackTargeting;
        expect(pending.defenderCol, 2);
        expect(pending.defenderRow, 3);
        expect(restored.runtimeState.submittedPlayerIds, {'player_1'});
        expect(restored.eventLogOffset, 12);
      },
    );
  });

  group('WireMatch', () {
    test('round-trips lobby metadata', () {
      const player = WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF2563EB,
        country: PlayerCountry.canada,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      );
      final match = WireMatch(
        id: 'match_1',
        ownerUserId: 'user_1',
        name: 'Sunday test',
        mapName: 'verdantia',
        players: const [player],
        maxPlayers: 4,
        minPlayers: 2,
        quickplay: true,
        turn: 3,
        state: 'open',
        createdAt: DateTime.utc(2026, 4, 26, 11),
        autoStartAt: DateTime.utc(2026, 4, 26, 11, 0, 30),
      );

      final restored = WireMatch.fromJson(match.toJson());

      expect(restored.v, kProtocolVersion);
      expect(restored.id, 'match_1');
      expect(restored.ownerUserId, 'user_1');
      expect(restored.players.single.userId, 'user_1');
      expect(restored.players.single.country, PlayerCountry.canada);
      expect(restored.players.single.kind, WirePlayerKind.human);
      expect(
        restored.players.single.connectionState,
        WirePlayerConnectionState.connected,
      );
      expect(restored.createdAt, DateTime.utc(2026, 4, 26, 11));
      expect(restored.maxPlayers, 4);
      expect(restored.minPlayers, 2);
      expect(restored.quickplay, isTrue);
      expect(restored.autoStartAt, DateTime.utc(2026, 4, 26, 11, 0, 30));
      expect(restored.copyWith(autoStartAt: null).autoStartAt, isNull);
    });
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 4, 26, 10),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
    ],
    gameMode: GameMode.multiplayer,
  );
}
