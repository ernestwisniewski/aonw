import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/network_command_transport_movement_fixtures.dart';

part 'support/network_command_transport_test_helpers.dart';
part 'support/network_command_transport_transient_snapshot_cases.dart';

extension _NetworkTransportClientBoundary on NetworkCommandTransport {
  Future<CommandTransportResult> dispatchAcrossBoundary({
    required String saveId,
    required GameState currentState,
    required Object command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (command is DomainCommand) {
      return dispatch(
        saveId: saveId,
        currentState: currentState,
        command: command,
        context: context,
      );
    }
    if (command is! GameIntent) throw ArgumentError.value(command, 'command');
    final resolution = GameIntentResolver(
      reducer: localReducer,
      context: context,
    ).resolve(currentState.interaction, command, currentState);
    final domainCommand = resolution.domainCommand;
    if (domainCommand != null) {
      return dispatch(
        saveId: saveId,
        currentState: currentState,
        command: domainCommand,
        context: context,
      );
    }
    final nextState = resolution.interaction == currentState.interaction
        ? currentState
        : currentState.copyWith(interaction: resolution.interaction);
    return CommandTransportResult(
      state: nextState,
      uiEffects: resolution.presentationFocus,
      snapshot: null,
      offset: -1,
    );
  }
}

void main() {
  test('Serverpod dispatcher stays lazy and closes idempotently', () {
    var clientFactoryCalls = 0;
    final rawClient = createServerpodClient('http://localhost:8080');
    final dispatcher = ServerpodWireCommandDispatcher(
      serverpodHost: 'http://localhost:8080',
      clientFactory: () {
        clientFactoryCalls += 1;
        return rawClient;
      },
    );

    expect(clientFactoryCalls, 0);
    expect(dispatcher.isClosed, isFalse);

    dispatcher
      ..close()
      ..close();

    expect(clientFactoryCalls, 0);
    expect(dispatcher.isClosed, isTrue);
  });

  test('NetworkCommandTransport closes its convenience dispatcher', () {
    final server = _FakeCommandServer(save: _save(), state: const GameState());
    final transport = NetworkCommandTransport(
      serverpodHost: 'http://localhost:8080',
      token: AuthToken('jwt-token'),
      actorPlayerId: 'player_1',
      tickGenerator: ClientTickGenerator(),
      localReducer: server.reducer,
      gameRepository: _SnapshotRepository(server.snapshot),
    );
    final owned = transport.commandDispatcher as ServerpodWireCommandDispatcher;

    transport
      ..close()
      ..close();

    expect(owned.isClosed, isTrue);
  });

  group('NetworkCommandTransport', () {
    _registerEngineFamilyRoutingTests();

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
        expect(result.snapshot, isNotNull);
        expect(result.snapshot!.eventLogOffset, 1);
        expect(result.storedSnapshot, isTrue);
      },
    );

    test(
      'reads the current JWT immediately before sending a command',
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
        final transport = _transport(
          server,
          tokenReader: () async => AuthToken('rotated-jwt'),
        );

        await transport.dispatch(
          saveId: 'save_1',
          currentState: server.state,
          command: MoveUnitCommand(commander.id, 1, 0),
        );

        expect(server.sentCommands.single.token.value, 'rotated-jwt');
      },
    );

    test(
      'uses authoritative movement effects for accepted server moves',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final server = _FakeCommandServer(
          save: _save(),
          state: GameState(
            units: [commander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            interaction: GameInteractionState(
              selection: GameSelection.unit(
                commander,
                tile: _map().tileAt(0, 0),
              ),
            ),
          ),
          nextMovementExecutions: _twoStepMovementExecutions(commander.id),
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

        final execution = result.movementExecutions.single;
        expect(execution.unitId, commander.id);
        expect(execution.fromCol, 0);
        expect(execution.fromRow, 0);
        expect(execution.steps.map((step) => step.col), [1, 2]);
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

    test('keeps command ids unique when a match is resumed', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final initial = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final server = _FakeCommandServer(save: _save(), state: initial);

      final firstSession = _transport(server);
      final first = await firstSession.dispatch(
        saveId: 'save_1',
        currentState: initial,
        command: MoveUnitCommand(commander.id, 1, 0),
      );

      final resumedSession = _transport(server);
      final resumed = await resumedSession.dispatch(
        saveId: 'save_1',
        currentState: first.state,
        command: MoveUnitCommand(commander.id, 2, 0),
      );

      expect(server.sentCommands.map((sent) => sent.wire.tick), [1, 1]);
      expect(
        server.sentCommands.map((sent) => sent.clientMessageId).toSet(),
        hasLength(2),
      );
      expect(
        server.sentCommands.map((sent) => sent.clientMessageId.length),
        everyElement(lessThanOrEqualTo(128)),
      );
      expect(
        server.sentCommands.map((sent) => sent.clientMessageId),
        everyElement(matches(RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$'))),
      );
      expect(resumed.state.units.single.col, 2);
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
      final messageIds = server.sentCommands
          .map((sent) => sent.clientMessageId)
          .toList(growable: false);
      expect(messageIds[1], messageIds[0]);
      expect(messageIds[2], isNot(messageIds[0]));
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

    test(
      'applies the authoritative snapshot and emits feedback when rejected',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final currentState = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final authoritativeSnapshot = SaveSnapshot.fromGameState(
          save: _save(),
          state: GameState(
            units: [commander.copyWith(col: 2, row: 0)],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          eventLogOffset: 7,
        );
        const snapshotCodec = SnapshotCodec();
        final dispatcher = _ScriptedCommandDispatcher((sentCommand) {
          return WireCommandAck(
            matchId: sentCommand.saveId,
            accepted: false,
            offset: 7,
            snapshot: snapshotCodec.toWire(
              matchId: sentCommand.saveId,
              snapshot: authoritativeSnapshot,
            ),
            reason: 'unit_unavailable',
            movementExecutions: WireMovementExecutionList(const []),
          );
        });
        final transport = NetworkCommandTransport(
          commandDispatcher: dispatcher,
          token: AuthToken('jwt-token'),
          actorPlayerId: 'player_1',
          tickGenerator: ClientTickGenerator(),
          localReducer: GameStateReducer(mapData: _map()),
          gameRepository: _SnapshotRepository(authoritativeSnapshot),
        );

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: currentState,
          command: MoveUnitCommand(commander.id, 1, 0),
        );

        expect(result.state.units.single.col, 2);
        expect(result.events, [
          isA<CommandRejectedEvent>().having(
            (event) => event.reason,
            'reason',
            'unit_unavailable',
          ),
        ]);
        expect(result.offset, 7);
        expect(result.snapshot, isNotNull);
        expect(result.storedSnapshot, isTrue);
      },
    );

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
        expect(result.snapshot, same(snapshot));
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
          movementExecutions: WireMovementExecutionList(const []),
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

      final result = await transport.dispatchAcrossBoundary(
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
      expect(result.snapshot, isNotNull);
      expect(result.storedSnapshot, isTrue);
    });

    test(
      'applies the server snapshot when stale turn is returned as a rejected ACK',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final currentState = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final authoritativeState = GameState(
          units: [commander.copyWith(col: 3, row: 0)],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final authoritativeSnapshot = SaveSnapshot.fromGameState(
          save: _save().copyWith(turn: 2),
          state: authoritativeState,
          eventLogOffset: 12,
        );
        const snapshotCodec = SnapshotCodec();
        final dispatcher = _ScriptedCommandDispatcher((sentCommand) {
          return WireCommandAck(
            matchId: 'save_1',
            accepted: false,
            offset: 12,
            snapshot: snapshotCodec.toWire(
              matchId: 'save_1',
              snapshot: authoritativeSnapshot,
            ),
            reason: 'stale_turn',
            movementExecutions: WireMovementExecutionList(const []),
          );
        });
        final transport = NetworkCommandTransport(
          commandDispatcher: dispatcher,
          token: AuthToken('jwt-token'),
          actorPlayerId: 'player_1',
          tickGenerator: ClientTickGenerator(startAt: 3),
          localReducer: GameStateReducer(mapData: _map()),
          gameRepository: _SnapshotRepository(authoritativeSnapshot),
        );

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: currentState,
          command: MoveUnitCommand(commander.id, 1, 0),
        );

        expect(dispatcher.sentCommands, hasLength(1));
        expect(result.offset, 12);
        expect(result.snapshot, isNotNull);
        expect(result.snapshot!.eventLogOffset, 12);
        expect(result.snapshot!.save.turn, 2);
        expect(result.state.units.single.col, 3);
        expect(result.events, isEmpty);
        expect(result.storedSnapshot, isTrue);
      },
    );

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
      expect(result.snapshot, isNotNull);
      expect(result.snapshot!.eventLogOffset, 12);
      expect(result.state.units.single.col, 1);
    });

    _registerTransientSnapshotCases();

    test('handles tile taps for movement preview locally', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          selection: GameSelection.unit(commander, tile: _map().tileAt(0, 0)),
          moveCommandActive: true,
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatchAcrossBoundary(
        saveId: 'save_1',
        currentState: state,
        command: const TileTappedCommand(1, 0),
      );

      expect(server.sentCommands, isEmpty);
      expect(result.state.movePreview?.targetCol, 1);
      expect(result.state.movePreview?.targetRow, 0);
    });

    test(
      'keeps worker draft local and sends a self-contained confirmation',
      () async {
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 1,
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 1)],
        );
        final base = GameState(
          units: [worker],
          cities: const [city],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.agriculture},
              ),
            },
          ),
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          interaction: GameInteractionState(
            selection: GameSelection.unit(worker, tile: _map().tileAt(1, 1)),
          ),
        );
        final server = _FakeCommandServer(save: _save(), state: base);
        final transport = _transport(server);

        final started = await transport.dispatchAcrossBoundary(
          saveId: 'save_1',
          currentState: base,
          command: const StartWorkerActionSelectionCommand('worker_1'),
        );
        final selected = await transport.dispatchAcrossBoundary(
          saveId: 'save_1',
          currentState: started.state,
          command: const ChooseWorkerImprovementIntent(
            'worker_1',
            FieldImprovementType.farm,
          ),
        );

        expect(server.sentCommands, isEmpty);
        expect(
          (selected.state.pendingAction as PendingWorkerActionSelection)
              .improvementType,
          FieldImprovementType.farm,
        );

        final confirmed = await transport.dispatchAcrossBoundary(
          saveId: 'save_1',
          currentState: selected.state,
          command: const ConfirmWorkerImprovementIntent('worker_1'),
        );

        expect(server.sentCommands, hasLength(1));
        expect(server.sentCommands.single.wire.command, {
          'type': 'ConfirmWorkerImprovement',
          'unitId': 'worker_1',
          'improvementType': 'farm',
        });
        expect(
          confirmed.state.units.single.workerJob?.improvementType,
          FieldImprovementType.farm,
        );
        expect(confirmed.state.pendingAction, isNull);
      },
    );

    test(
      'translates confirmed tile movement to MoveUnit for the server',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          interaction: GameInteractionState(
            selection: GameSelection.unit(commander, tile: _map().tileAt(0, 0)),
            moveCommandActive: true,
          ),
        );
        final server = _FakeCommandServer(save: _save(), state: state);
        final transport = _transport(server);

        final preview = await transport.dispatchAcrossBoundary(
          saveId: 'save_1',
          currentState: state,
          command: const TileTappedCommand(1, 0),
        );
        final moved = await transport.dispatchAcrossBoundary(
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
        expect(moved.snapshot, isNotNull);
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
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 1, row: 0)},
            ),
          },
        ),
        interaction: GameInteractionState(
          selection: GameSelection.unit(settler, tile: _map().tileAt(1, 1)),
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'settler_player_1',
            ownerPlayerId: 'player_1',
            center: const CityHex(col: 1, row: 1),
          ),
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatchAcrossBoundary(
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
        interaction: GameInteractionState(
          selection: GameSelection.unit(attacker, tile: _map().tileAt(0, 0)),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'warrior_player_1',
          ),
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatchAcrossBoundary(
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
        interaction: GameInteractionState(
          selection: GameSelection.unit(attacker, tile: _map().tileAt(0, 0)),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'warrior_player_1',
          ),
        ),
      );
      final server = _FakeCommandServer(save: _save(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatchAcrossBoundary(
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
      final server = _FakeCommandServer(save: _multiplayerSave(), state: state);
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const SubmitTurnCommand('player_1'),
      );

      expect(result.state.activePlayerId, 'player_1');
      expect(result.state.activePlayerCanAct, isFalse);
      expect(result.state.submittedPlayerIds, {'player_1'});
      expect(result.snapshot, isNotNull);
      expect(result.snapshot!.save.turn, 1);
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
        expect(result.snapshot, isNotNull);
        expect(result.snapshot!.save.turn, 2);
        expect(result.storedSnapshot, isTrue);
      },
    );

    test(
      'new-turn submit ACK clears skip and restores targeting through reconciliation',
      () async {
        final skippedUnit = GameUnit.produced(
          id: 'skipped_unit',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ).copyWith(movementPoints: 0);
        final pendingSkip = PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: skippedUnit.id,
          restoreMovementPoints: 3,
        );
        final stalePreview = UnitMovementPlan(
          unitId: skippedUnit.id,
          targetCol: 1,
          targetRow: 0,
          totalCost: 1,
          availableMovementPoints: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        );
        final before = GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          turnStartedAt: DateTime.utc(2026, 7, 31, 10),
          units: [skippedUnit],
          interaction: GameInteractionState(
            selection: GameSelection.unit(skippedUnit),
            movePreview: stalePreview,
            pendingAction: pendingSkip,
          ),
        );
        final restoredUnit = skippedUnit.copyWith(movementPoints: 3);
        final advancedSave = _save().copyWith(
          turn: 2,
          playerStates: const {'player_1': PlayerTurnState.active},
        );
        final server = _FakeCommandServer(
          save: _save(),
          state: before,
          nextAcceptedSnapshot: SaveSnapshot.fromGameState(
            save: advancedSave,
            state: GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              turnStartedAt: DateTime.utc(2026, 7, 31, 10, 1),
              units: [restoredUnit],
            ),
            eventLogOffset: 1,
          ),
        );
        final transport = _transport(server);

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: before,
          command: const SubmitTurnCommand('player_1'),
        );

        expect(result.snapshot?.save.turn, 2);
        expect(result.state.activePlayerCanAct, isTrue);
        expect(result.state.pendingAction, isNull);
        expect(result.state.movePreview, isNull);
        expect(result.state.selectedUnit, same(result.state.units.single));
        expect(result.state.selectedUnit?.movementPoints, 3);
        expect(result.state.moveCommandActive, isTrue);
      },
    );

    test('exposes queued movement evidence from accepted snapshots', () async {
      final queued = queuedNetworkCommander();
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
        nextMovementExecutions: _twoStepMovementExecutions(queued.id),
      );
      final transport = _transport(server);

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: state,
        command: const SubmitTurnCommand('player_1'),
      );

      expect(server.lastAck!.toJson()['movementExecutions'], hasLength(1));
      final move = result.movementExecutions.single;
      expect(move.unitId, 'commander_player_1');
      expect((move.fromCol, move.fromRow), (0, 0));
      expect(
        [
          for (final step in move.steps)
            (step.col, step.row, step.enterCost, step.cumulativeCost),
        ],
        const [(1, 0, 1, 1), (2, 0, 1, 2)],
      );
      expect(result.state.units.single.col, 2);
      expect(result.state.activePlayerCanAct, isTrue);
    });
  });
}

class _SentCommand {
  final String saveId;
  final AuthToken token;
  final int afterOffset;
  final WireCommand wire;
  final String clientMessageId;

  const _SentCommand({
    required this.saveId,
    required this.token,
    required this.afterOffset,
    required this.wire,
    required this.clientMessageId,
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
    required super.clientMessageId,
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
    required String clientMessageId,
  }) async {
    final command = _ScriptedSentCommand(
      call: sentCommands.length + 1,
      saveId: saveId,
      token: token,
      afterOffset: afterOffset,
      wire: wire,
      clientMessageId: clientMessageId,
    );
    sentCommands.add(command);
    return handler(command);
  }
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
