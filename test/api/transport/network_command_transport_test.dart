import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkCommandTransport', () {
    test(
      'posts a WireCommand and applies the server snapshot response',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final server = _FakeCommandServer(
          save: _save(),
          state: GameState(
            units: [commander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
        );
        final transport = _transport(server, startTickAt: 41);

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: server.state,
          command: MoveUnitCommand(commander.id, 1, 0),
        );

        final sentCommand = server.sentCommands.single;
        expect(sentCommand.saveId, 'save_1');
        expect(sentCommand.token.value, 'jwt-token');
        expect(sentCommand.afterOffset, 0);
        final sent = sentCommand.wire;
        expect(sent.tick, 41);
        expect(sent.turn, 1);
        expect(sent.actorPlayerId, 'player_1');
        expect(sent.command['type'], 'MoveUnit');
        expect(result.offset, 1);
        expect(result.state.units.single.col, 1);
        expect(result.state.activePlayerId, 'player_1');
        expect(result.events.single, isA<UnitMovedEvent>());
        expect(result.snapshot.eventLogOffset, 1);
        expect(result.storedSnapshot, isTrue);
      },
    );

    test(
      'uses local reducer movement effects for accepted server moves',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final server = _FakeCommandServer(
          save: _save(),
          state: GameState(
            units: [commander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            selection: GameSelection.unit(commander, tile: _map().tileAt(0, 0)),
          ),
        );
        final transport = _transport(server);

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: server.snapshot.toGameState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          command: MoveUnitCommand(commander.id, 2, 0),
        );

        final effect = result.uiEffects
            .whereType<AnimateUnitMoveEffect>()
            .single;
        expect(effect.unitId, commander.id);
        expect(effect.fromCol, 0);
        expect(effect.fromRow, 0);
        expect(effect.steps.map((step) => step.col), [1, 2]);
        expect(result.state.units.single.col, 2);
      },
    );

    test('increments the client tick for each dispatch', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final initial = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(save: _save(), state: initial);
      final transport = _transport(server, startTickAt: 7);

      final first = await transport.dispatch(
        saveId: 'save_1',
        currentState: initial,
        command: MoveUnitCommand(commander.id, 1, 0),
      );
      await transport.dispatch(
        saveId: 'save_1',
        currentState: first.state,
        command: MoveUnitCommand(commander.id, 2, 0),
      );

      final ticks = [
        for (final sentCommand in server.sentCommands) sentCommand.wire.tick,
      ];
      expect(ticks, [7, 8]);
    });

    test('reuses the client tick when the same command is retried', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final initial = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(
        save: _save(),
        state: initial,
        nextError: TimeoutException('network timeout'),
      );
      final transport = _transport(server, startTickAt: 9);
      final command = MoveUnitCommand(commander.id, 1, 0);

      await expectLater(
        transport.dispatch(
          saveId: 'save_1',
          currentState: initial,
          command: command,
        ),
        throwsA(isA<TimeoutException>()),
      );
      final retried = await transport.dispatch(
        saveId: 'save_1',
        currentState: initial,
        command: command,
      );
      await transport.dispatch(
        saveId: 'save_1',
        currentState: retried.state,
        command: MoveUnitCommand(commander.id, 2, 0),
      );

      final ticks = [
        for (final sentCommand in server.sentCommands) sentCommand.wire.tick,
      ];
      expect(ticks, [9, 9, 10]);
      expect(retried.state.units.single.col, 1);
    });

    test(
      'keeps the retry wire command when the repository turn changed',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final initial = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final server = _FakeCommandServer(
          save: _save(),
          state: initial,
          nextError: TimeoutException('network timeout'),
        );
        final repository = _SnapshotRepository(server.snapshot);
        final transport = NetworkCommandTransport(
          commandDispatcher: server,
          token: AuthToken('jwt-token'),
          actorPlayerId: 'player_1',
          tickGenerator: ClientTickGenerator(startAt: 9),
          localReducer: server.reducer,
          gameRepository: repository,
        );
        final command = MoveUnitCommand(commander.id, 1, 0);

        await expectLater(
          transport.dispatch(
            saveId: 'save_1',
            currentState: initial,
            command: command,
          ),
          throwsA(isA<TimeoutException>()),
        );
        repository.snapshot = repository.snapshot.copyWith(
          save: repository.snapshot.save.copyWith(turn: 2),
        );
        await transport.dispatch(
          saveId: 'save_1',
          currentState: initial,
          command: command,
        );

        final sent = [
          for (final sentCommand in server.sentCommands) sentCommand.wire,
        ];
        expect(sent.map((wire) => wire.tick), [9, 9]);
        expect(sent.map((wire) => wire.turn), [1, 1]);
      },
    );

    test('keeps current state when the server rejects a command', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(
        save: _save(),
        state: state,
        rejectNextCommand: true,
      );
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: MoveUnitCommand(commander.id, 1, 0),
      );

      expect(result.state, state);
      expect(result.events.single, isA<CommandRejectedEvent>());
      expect(result.offset, 1);
      expect(result.storedSnapshot, isFalse);
    });

    for (final errorCode in const ['stale_tick', 'stale_turn']) {
      test('reloads snapshot when the server reports a $errorCode', () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final currentState = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final authoritative = commander.copyWith(col: 3, row: 0);
        final snapshot = SaveSnapshot.fromGameState(
          save: _save(),
          state: GameState(
            units: [authoritative],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          eventLogOffset: 12,
        );
        final dispatcher = _ScriptedCommandDispatcher((_) {
          throw _commandConflict(errorCode);
        });
        final transport = NetworkCommandTransport(
          commandDispatcher: dispatcher,
          token: AuthToken('jwt-token'),
          actorPlayerId: 'player_1',
          tickGenerator: ClientTickGenerator(startAt: 3),
          localReducer: GameStateReducer(mapData: _map()),
          gameRepository: _SnapshotRepository(snapshot),
        );

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: currentState,
          command: MoveUnitCommand(commander.id, 1, 0),
        );

        expect(dispatcher.sentCommands, hasLength(1));
        expect(result.offset, 12);
        expect(result.state.units.single.col, 3);
        expect(result.events, isEmpty);
        expect(result.storedSnapshot, isTrue);
      });
    }

    test('bumps the client tick and retries stale tick conflicts', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final currentState = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final repository = _SnapshotRepository(
        SaveSnapshot.fromGameState(
          save: _save(),
          state: currentState,
          eventLogOffset: 7,
        ),
      );
      const snapshotCodec = SnapshotCodec();
      final dispatcher = _ScriptedCommandDispatcher((sentCommand) {
        if (sentCommand.call == 1) {
          throw _commandConflict('stale_tick', nextTick: 8);
        }
        final movedState = GameState(
          units: [commander.copyWith(col: 1, row: 0)],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final snapshot = SaveSnapshot.fromGameState(
          save: _save(),
          state: movedState,
          eventLogOffset: 8,
        );
        return WireCommandAck(
          matchId: 'save_1',
          accepted: true,
          offset: 8,
          snapshot: snapshotCodec.toWire(matchId: 'save_1', snapshot: snapshot),
        );
      });
      final transport = NetworkCommandTransport(
        commandDispatcher: dispatcher,
        token: AuthToken('jwt-token'),
        actorPlayerId: 'player_1',
        tickGenerator: ClientTickGenerator(startAt: 3),
        localReducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
      );

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: currentState,
        command: MoveUnitCommand(commander.id, 1, 0),
      );

      final ticks = [
        for (final sentCommand in dispatcher.sentCommands)
          sentCommand.wire.tick,
      ];
      expect(ticks, [3, 8]);
      expect(result.offset, 8);
      expect(result.state.units.single.col, 1);
      expect(result.storedSnapshot, isTrue);
    });

    test('tracks the snapshot offset when a cached ACK is older', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(
        save: _save(),
        state: state,
        nextAcceptedSnapshot: SaveSnapshot.fromGameState(
          save: _save(),
          state: GameState(
            units: [commander.copyWith(col: 1, row: 0)],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          eventLogOffset: 12,
        ),
      );
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: MoveUnitCommand(commander.id, 1, 0),
      );

      expect(result.offset, 12);
      expect(result.snapshot.eventLogOffset, 12);
      expect(result.state.units.single.col, 1);
    });

    test('applies client-only commands locally without HTTP', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const SetActivePlayerCommand('player_2', canAct: false),
      );

      expect(server.sentCommands, isEmpty);
      expect(result.state.activePlayerId, 'player_2');
      expect(result.state.activePlayerCanAct, isFalse);
      expect(result.storedSnapshot, isFalse);
    });

    test('handles tile taps for movement preview locally', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        selection: GameSelection.unit(commander, tile: _map().tileAt(0, 0)),
        moveCommandActive: true,
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const TileTappedCommand(1, 0),
      );

      expect(server.sentCommands, isEmpty);
      expect(result.state.movePreview?.targetCol, 1);
      expect(result.state.movePreview?.targetRow, 0);
    });

    test(
      'translates confirmed tile movement to MoveUnit for the server',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          selection: GameSelection.unit(commander, tile: _map().tileAt(0, 0)),
          moveCommandActive: true,
        );
        final server = _FakeCommandServer(save: _save(), state: state);
        final transport = _transport(server);

        final preview = await transport.dispatch(
          saveId: 'save_1',
          currentState: state,
          command: const TileTappedCommand(1, 0),
        );
        final moved = await transport.dispatch(
          saveId: 'save_1',
          currentState: preview.state,
          command: const TileTappedCommand(1, 0),
        );

        expect(server.sentCommands, hasLength(1));
        final sent = server.sentCommands.single.wire;
        expect(sent.command['type'], 'MoveUnit');
        expect(sent.command['unitId'], commander.id);
        expect(sent.command['targetCol'], 1);
        expect(sent.command['targetRow'], 0);
        expect(moved.state.units.single.col, 1);
        expect(moved.storedSnapshot, isTrue);
      },
    );

    test('handles city founding territory tile taps locally', () async {
      final settler = GameUnit.produced(
        id: 'settler_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 1,
        row: 1,
      );
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        selection: GameSelection.unit(settler, tile: _map().tileAt(1, 1)),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 1, row: 0)},
            ),
          },
        ),
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'settler_player_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 1, row: 1),
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const TileTappedCommand(1, 0),
      );

      expect(server.sentCommands, isEmpty);
      expect(
        result.state.cityFoundingDraft?.controlledHexes,
        contains(const CityHex(col: 1, row: 0)),
      );
    });

    test('keeps attack target tile taps local until confirmation', () async {
      final attacker = GameUnit.produced(
        id: 'warrior_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'warrior_player_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final state = GameState(
        units: [attacker, defender],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        selection: GameSelection.unit(attacker, tile: _map().tileAt(0, 0)),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'warrior_player_1',
        ),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
              },
            ),
          },
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const TileTappedCommand(1, 0),
      );

      expect(server.sentCommands, isEmpty);
      final pending = result.state.pendingAction as PendingAttackTargeting;
      expect(pending.defenderCol, 1);
      expect(pending.defenderRow, 0);
    });

    test('keeps attack target city taps local until confirmation', () async {
      final attacker = GameUnit.produced(
        id: 'warrior_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      const city = GameCity(
        id: 'city_player_2',
        ownerPlayerId: 'player_2',
        name: 'Enemy',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        units: [attacker],
        cities: const [city],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        selection: GameSelection.unit(attacker, tile: _map().tileAt(0, 0)),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'warrior_player_1',
        ),
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
              },
            ),
          },
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const CityTappedCommand('city_player_2'),
      );

      expect(server.sentCommands, isEmpty);
      final pending = result.state.pendingAction as PendingAttackTargeting;
      expect(pending.defenderCol, 1);
      expect(pending.defenderRow, 0);
    });

    test('keeps the active player waiting after accepted submit', () async {
      const state = GameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const SubmitTurnCommand('player_1'),
      );

      expect(result.state.activePlayerId, 'player_1');
      expect(result.state.activePlayerCanAct, isFalse);
      expect(result.state.submittedPlayerIds, {'player_1'});
      expect(result.snapshot.save.turn, 1);
      expect(result.storedSnapshot, isTrue);
    });

    test(
      're-enables the active player when submit starts a new turn',
      () async {
        const state = GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final advancedSave = _save().copyWith(
          turn: 2,
          playerStates: const {'player_1': PlayerTurnState.active},
        );
        final server = _FakeCommandServer(
          save: _save(),
          state: state,
          nextAcceptedSnapshot: SaveSnapshot.fromGameState(
            save: advancedSave,
            state: const GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
            ),
            eventLogOffset: 1,
          ),
        );
        final transport = _transport(server);

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: state,
          command: const SubmitTurnCommand('player_1'),
        );

        expect(result.state.activePlayerId, 'player_1');
        expect(result.state.activePlayerCanAct, isTrue);
        expect(result.state.submittedPlayerIds, isEmpty);
        expect(result.snapshot.save.turn, 2);
        expect(result.storedSnapshot, isTrue);
      },
    );

    test(
      'emits queued movement animation effects from accepted snapshots',
      () async {
        final queued = _queuedCommander();
        final state = GameState(
          units: [queued],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final advancedSave = _save().copyWith(
          turn: 2,
          playerStates: const {'player_1': PlayerTurnState.active},
        );
        final server = _FakeCommandServer(
          save: _save(),
          state: state,
          nextAcceptedSnapshot: SaveSnapshot.fromGameState(
            save: advancedSave,
            state: GameState(
              units: [queued.copyWith(col: 2, row: 0).copyWithQueuedPath(null)],
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
            ),
            eventLogOffset: 1,
          ),
        );
        final transport = _transport(server);

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: state,
          command: const SubmitTurnCommand('player_1'),
        );

        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>().single,
          isA<AnimateUnitMoveEffect>()
              .having((effect) => effect.unitId, 'unitId', 'commander_player_1')
              .having((effect) => effect.fromCol, 'fromCol', 0)
              .having((effect) => effect.steps.last.col, 'last col', 2),
        );
        expect(result.state.units.single.col, 2);
        expect(result.state.activePlayerCanAct, isTrue);
      },
    );
  });
}

NetworkCommandTransport _transport(
  _FakeCommandServer server, {
  int startTickAt = 1,
}) {
  return NetworkCommandTransport(
    commandDispatcher: server,
    token: AuthToken('jwt-token'),
    actorPlayerId: 'player_1',
    tickGenerator: ClientTickGenerator(startAt: startTickAt),
    localReducer: server.reducer,
    gameRepository: _SnapshotRepository(server.snapshot),
  );
}

class _SentCommand {
  final String saveId;
  final AuthToken token;
  final int afterOffset;
  final WireCommand wire;

  const _SentCommand({
    required this.saveId,
    required this.token,
    required this.afterOffset,
    required this.wire,
  });
}

typedef _ScriptedCommandHandler =
    WireCommandAck Function(_ScriptedSentCommand command);

class _ScriptedSentCommand extends _SentCommand {
  final int call;

  const _ScriptedSentCommand({
    required this.call,
    required super.saveId,
    required super.token,
    required super.afterOffset,
    required super.wire,
  });
}

class _ScriptedCommandDispatcher implements WireCommandDispatcher {
  final _ScriptedCommandHandler handler;
  final sentCommands = <_ScriptedSentCommand>[];

  _ScriptedCommandDispatcher(this.handler);

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  }) async {
    final command = _ScriptedSentCommand(
      call: sentCommands.length + 1,
      saveId: saveId,
      token: token,
      afterOffset: afterOffset,
      wire: wire,
    );
    sentCommands.add(command);
    return handler(command);
  }
}

NetworkCommandConflictException _commandConflict(
  String errorCode, {
  int? nextTick,
}) {
  return NetworkCommandConflictException(code: errorCode, nextTick: nextTick);
}

class _FakeCommandServer implements WireCommandDispatcher {
  final GameStateReducer reducer = GameStateReducer(mapData: _map());
  final CommandCodec commandCodec = const CommandCodec();
  final EventCodec eventCodec = const EventCodec();
  final SnapshotCodec snapshotCodec = const SnapshotCodec();
  final List<_SentCommand> sentCommands = [];
  GameSave save;
  GameState state;
  bool rejectNextCommand;
  SaveSnapshot? nextAcceptedSnapshot;
  Object? nextError;
  int offset = 0;

  _FakeCommandServer({
    required this.save,
    required this.state,
    this.rejectNextCommand = false,
    this.nextAcceptedSnapshot,
    this.nextError,
  });

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  }) async {
    sentCommands.add(
      _SentCommand(
        saveId: saveId,
        token: token,
        afterOffset: afterOffset,
        wire: wire,
      ),
    );
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    offset += 1;

    if (rejectNextCommand) {
      rejectNextCommand = false;
      return WireCommandAck(
        matchId: wire.matchId,
        accepted: false,
        offset: offset,
        snapshot: snapshotCodec.toWire(
          matchId: wire.matchId,
          snapshot: SaveSnapshot.fromGameState(
            save: save,
            state: state,
            eventLogOffset: offset,
          ),
        ),
        events: eventCodec.eventsToJsonList(const [
          CommandRejectedEvent(reason: 'rejected by fake server'),
        ]),
        reason: 'rejected by fake server',
      );
    }

    final command = commandCodec.fromWire(wire);
    final transition = reducer.reduce(
      state,
      command,
      context: commandCodec.contextFromWire(wire),
    );
    state = transition.state;
    final snapshot =
        nextAcceptedSnapshot ??
        SaveSnapshot.fromGameState(
          save: save.copyWith(
            savedAt: DateTime.utc(2026, 4, 26, 12, 0, offset),
          ),
          state: state,
          eventLogOffset: offset,
        );
    nextAcceptedSnapshot = null;
    save = snapshot.save;
    state = snapshot.toGameState(
      activePlayerId: state.activePlayerId,
      activePlayerCanAct: state.activePlayerCanAct,
    );
    return WireCommandAck(
      matchId: wire.matchId,
      accepted: true,
      offset: offset,
      snapshot: snapshotCodec.toWire(matchId: wire.matchId, snapshot: snapshot),
      events: eventCodec.eventsToJsonList(transition.events),
    );
  }

  SaveSnapshot get snapshot => SaveSnapshot.fromGameState(
    save: save,
    state: state,
    eventLogOffset: offset,
  );
}

class _SnapshotRepository implements GameRepository {
  SaveSnapshot snapshot;

  _SnapshotRepository(this.snapshot);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final updated = snapshot.copyWith(
      save: snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? snapshot.save.savedAt,
      ),
    );
    snapshot = updated;
    return updated;
  }
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
}

GameUnit _queuedCommander() {
  return GameUnit.startingCommander(ownerPlayerId: 'player_1')
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        ),
      );
}

MapData _map() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
