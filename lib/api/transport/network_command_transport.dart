import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/authoritative_command_policy.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

class ClientTickGenerator {
  int _nextTick;

  ClientTickGenerator({int startAt = 1}) : _nextTick = startAt;

  int next() {
    final tick = _nextTick;
    _nextTick += 1;
    return tick;
  }

  void ensureAtLeast(int nextTick) {
    if (nextTick > _nextTick) _nextTick = nextTick;
  }
}

class NetworkCommandRejectedException implements Exception {
  final int offset;
  final String? reason;

  const NetworkCommandRejectedException({
    required this.offset,
    required this.reason,
  });

  @override
  String toString() {
    return 'NetworkCommandRejectedException(offset: $offset, reason: $reason)';
  }
}

class NetworkCommandConflictException implements Exception {
  final String code;
  final int? nextTick;

  const NetworkCommandConflictException({required this.code, this.nextTick});

  @override
  String toString() {
    final suffix = nextTick == null ? '' : ', nextTick=$nextTick';
    return 'NetworkCommandConflictException(code: $code$suffix)';
  }
}

abstract interface class WireCommandDispatcher {
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  });
}

class ServerpodWireCommandDispatcher implements WireCommandDispatcher {
  final String serverpodHost;
  final Duration timeout;

  const ServerpodWireCommandDispatcher({
    required this.serverpodHost,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  }) async {
    final input = StreamController<sp.MultiplayerClientMessage>();
    StreamSubscription<sp.MultiplayerServerMessage>? subscription;
    final ack = Completer<WireCommandAck>();
    try {
      final client = createServerpodClient(serverpodHost, token: token);
      final output = client.multiplayer.connect(
        saveId,
        afterOffset,
        input.stream,
      );
      subscription = output.listen(
        (message) {
          final commandAck = message.ack;
          if (commandAck != null && !ack.isCompleted) {
            ack.complete(commandAck);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!ack.isCompleted) ack.completeError(error, stackTrace);
        },
        onDone: () {
          if (!ack.isCompleted) {
            ack.completeError(
              StateError('Serverpod command stream closed before ack.'),
            );
          }
        },
        cancelOnError: false,
      );
      input.add(
        sp.MultiplayerClientMessage(
          clientMessageId:
              'cmd-${wire.actorPlayerId}-${wire.tick}-${DateTime.now().microsecondsSinceEpoch}',
          lastSeenOffset: afterOffset,
          requestSnapshot: false,
          command: wire,
        ),
      );
      return await ack.future.timeout(timeout);
    } finally {
      await subscription?.cancel();
      await input.close();
    }
  }
}

class NetworkCommandTransport implements CommandTransport {
  final AuthToken token;
  final String actorPlayerId;
  final WireCommandDispatcher commandDispatcher;
  final CommandCodec commandCodec;
  final EventCodec eventCodec;
  final SnapshotCodec snapshotCodec;
  final ClientTickGenerator tickGenerator;
  final GameStateReducer localReducer;
  final GameRepository gameRepository;
  _RetryableServerCommand? _retryableCommand;
  final Map<String, int> _lastKnownTurnBySaveId = {};
  final Map<String, int> _lastKnownOffsetBySaveId = {};

  NetworkCommandTransport({
    String? serverpodHost,
    WireCommandDispatcher? commandDispatcher,
    required this.token,
    required this.actorPlayerId,
    this.commandCodec = const CommandCodec(),
    this.eventCodec = const EventCodec(),
    this.snapshotCodec = const SnapshotCodec(),
    required this.tickGenerator,
    required this.localReducer,
    required this.gameRepository,
  }) : commandDispatcher =
           commandDispatcher ??
           ServerpodWireCommandDispatcher(
             serverpodHost:
                 serverpodHost ??
                 (throw ArgumentError(
                   'Expected serverpodHost or commandDispatcher for '
                   'NetworkCommandTransport.',
                 )),
           );

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _dispatch(
      saveId: saveId,
      currentState: currentState,
      command: command,
      context: context,
    );
  }

  Future<CommandTransportResult> _dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
    int staleTickRetries = 0,
  }) async {
    final authoritativeCommand =
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          currentState,
          command,
          context,
        );
    if (authoritativeCommand != null) {
      return _dispatch(
        saveId: saveId,
        currentState: currentState,
        command: authoritativeCommand,
        context: context,
        staleTickRetries: staleTickRetries,
      );
    }

    if (AuthoritativeCommandPolicy.isClientOnly(command)) {
      return _dispatchClientOnly(
        saveId: saveId,
        currentState: currentState,
        command: command,
        context: context,
      );
    }

    final actor = context.actorPlayerId ?? actorPlayerId;
    final retryable = _retryableCommand;
    final turn =
        retryable != null &&
            retryable.isSameCommand(
              saveId: saveId,
              actorPlayerId: actor,
              command: command,
            )
        ? retryable.turn
        : await _turnFor(saveId);
    final wire = _wireCommandForRetryableDispatch(
      saveId: saveId,
      actorPlayerId: actor,
      turn: turn,
      command: command,
    );
    final WireCommandAck ack;
    try {
      ack = await _sendWireCommand(saveId: saveId, wire: wire);
    } on NetworkCommandConflictException catch (error) {
      final nextTick = _nextTickFromStaleTickError(error);
      if (_isStaleTickError(error) &&
          nextTick != null &&
          staleTickRetries < 2) {
        _clearRetryableCommand(wire);
        tickGenerator.ensureAtLeast(nextTick);
        final snapshot = await gameRepository.load(saveId);
        _rememberSnapshot(saveId, snapshot);
        return _dispatch(
          saveId: saveId,
          currentState: snapshot.toGameState(
            activePlayerId: currentState.activePlayerId,
            activePlayerCanAct: currentState.activePlayerCanAct,
          ),
          command: command,
          context: context,
          staleTickRetries: staleTickRetries + 1,
        );
      }
      if (_isStaleCommandVersionError(error)) {
        _clearRetryableCommand(wire);
        return _reloadAfterStaleCommand(
          saveId: saveId,
          currentState: currentState,
          command: command,
        );
      }
      rethrow;
    }
    final snapshot = snapshotCodec.fromWire(ack.snapshot);
    final effectiveOffset = _effectiveOffset(ack.offset, snapshot);
    _rememberSnapshot(saveId, snapshot, offset: effectiveOffset);
    final events = eventCodec.eventsFromJsonList(ack.events);
    _clearRetryableCommand(wire);
    if (!ack.accepted) {
      return CommandTransportResult(
        state: currentState,
        snapshot: snapshot,
        offset: effectiveOffset,
        events: events,
      );
    }

    final nextState = snapshot.toGameState(
      activePlayerId: currentState.activePlayerId,
      activePlayerCanAct: _activePlayerCanActAfter(
        currentState: currentState,
        command: command,
        snapshot: snapshot,
      ),
    );
    final localTransition = localReducer.reduce(
      currentState,
      command,
      context: context,
    );

    return CommandTransportResult(
      state: nextState,
      uiEffects: _acceptedCommandEffects(
        localEffects: localTransition.uiEffects,
        currentState: currentState,
        nextState: nextState,
      ),
      snapshot: snapshot,
      offset: effectiveOffset,
      events: events,
      storedSnapshot: true,
    );
  }

  List<UiEffect> _acceptedCommandEffects({
    required List<UiEffect> localEffects,
    required GameState currentState,
    required GameState nextState,
  }) {
    if (localEffects.isNotEmpty) return localEffects;
    return QueuedMovementEffectBuilder.fromUnitDelta(
      beforeUnits: currentState.units,
      afterUnits: nextState.units,
    );
  }

  WireCommand _wireCommandForRetryableDispatch({
    required String saveId,
    required String actorPlayerId,
    required int? turn,
    required GameCommand command,
  }) {
    final retryable = _retryableCommand;
    if (retryable != null &&
        retryable.matches(
          saveId: saveId,
          actorPlayerId: actorPlayerId,
          turn: turn,
          command: command,
        )) {
      return retryable.wire;
    }

    _retryableCommand = null;
    return commandCodec.toWire(
      matchId: saveId,
      tick: tickGenerator.next(),
      turn: turn,
      actorPlayerId: actorPlayerId,
      command: command,
    );
  }

  Future<WireCommandAck> _sendWireCommand({
    required String saveId,
    required WireCommand wire,
  }) async {
    try {
      return await commandDispatcher.send(
        saveId: saveId,
        token: token,
        afterOffset: _lastKnownOffsetBySaveId[saveId] ?? 0,
        wire: wire,
      );
    } catch (error) {
      if (_isRetryableCommandSendError(error)) {
        _retryableCommand = _RetryableServerCommand(
          saveId: saveId,
          actorPlayerId: wire.actorPlayerId,
          turn: wire.turn,
          command: commandCodec.fromWire(wire),
          wire: wire,
        );
      } else {
        _clearRetryableCommand(wire);
      }
      rethrow;
    }
  }

  Future<int?> _turnFor(String saveId) async {
    try {
      final snapshot = await gameRepository.load(saveId);
      final turn = snapshot.save.turn;
      _lastKnownTurnBySaveId[saveId] = turn;
      _lastKnownOffsetBySaveId[saveId] = snapshot.eventLogOffset;
      return turn;
    } catch (_) {
      return _lastKnownTurnBySaveId[saveId];
    }
  }

  Future<CommandTransportResult> _reloadAfterStaleCommand({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
  }) async {
    final snapshot = await gameRepository.load(saveId);
    _rememberSnapshot(saveId, snapshot);
    final nextState = snapshot.toGameState(
      activePlayerId: currentState.activePlayerId,
      activePlayerCanAct: _activePlayerCanActAfter(
        currentState: currentState,
        command: command,
        snapshot: snapshot,
      ),
    );
    return CommandTransportResult(
      state: nextState,
      snapshot: snapshot,
      offset: snapshot.eventLogOffset,
      storedSnapshot: true,
    );
  }

  void _clearRetryableCommand(WireCommand wire) {
    final retryable = _retryableCommand;
    if (retryable == null || identical(retryable.wire, wire)) {
      _retryableCommand = null;
    }
  }

  bool _isRetryableCommandSendError(Object error) {
    return error is TimeoutException ||
        error is sp.MethodStreamException ||
        (error is sp.ServerpodClientException &&
            (error.statusCode < 0 || error.statusCode >= 500));
  }

  bool _isStaleCommandVersionError(NetworkCommandConflictException error) {
    return error.code == 'stale_tick' || error.code == 'stale_turn';
  }

  bool _isStaleTickError(NetworkCommandConflictException error) {
    return error.code == 'stale_tick';
  }

  int? _nextTickFromStaleTickError(NetworkCommandConflictException error) {
    return error.nextTick;
  }

  int _effectiveOffset(int ackOffset, SaveSnapshot snapshot) {
    return snapshot.eventLogOffset > ackOffset
        ? snapshot.eventLogOffset
        : ackOffset;
  }

  void _rememberSnapshot(String saveId, SaveSnapshot snapshot, {int? offset}) {
    _lastKnownTurnBySaveId[saveId] = snapshot.save.turn;
    _lastKnownOffsetBySaveId[saveId] = offset ?? snapshot.eventLogOffset;
  }

  Future<CommandTransportResult> _dispatchClientOnly({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    required GameCommandContext context,
  }) async {
    final transition = localReducer.reduce(
      currentState,
      command,
      context: context,
    );
    final offset = _lastKnownOffsetBySaveId[saveId] ?? -1;
    final snapshot = SaveSnapshot.fromGameState(
      save: _clientOnlySave(saveId, currentState),
      state: transition.state,
      eventLogOffset: offset < 0 ? 0 : offset,
    );
    return CommandTransportResult(
      state: transition.state,
      uiEffects: transition.uiEffects,
      events: transition.events,
      snapshot: snapshot,
      offset: offset,
    );
  }

  GameSave _clientOnlySave(String saveId, GameState state) {
    final playerIds = <String>[
      ...state.playerColors.keys,
      ...state.playerCountries.keys.where(
        (id) => !state.playerColors.containsKey(id),
      ),
      if (state.activePlayerId.isNotEmpty &&
          !state.playerColors.containsKey(state.activePlayerId) &&
          !state.playerCountries.containsKey(state.activePlayerId))
        state.activePlayerId,
    ];
    return GameSave(
      id: saveId,
      name: saveId,
      mapName: '',
      turn: _lastKnownTurnBySaveId[saveId] ?? 0,
      playerStates: {
        for (final playerId in playerIds) playerId: PlayerTurnState.active,
      },
      savedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      camera: CameraState.zero,
      players: [
        for (var index = 0; index < playerIds.length; index++)
          Player(
            id: playerIds[index],
            name: playerIds[index],
            colorValue:
                state.playerColors[playerIds[index]] ??
                Player.palette[index % Player.palette.length],
            country: state.countryForPlayer(playerIds[index]),
          ),
      ],
      gameMode: GameMode.multiplayer,
    );
  }

  bool _activePlayerCanActAfter({
    required GameState currentState,
    required GameCommand command,
    required SaveSnapshot snapshot,
  }) {
    if (command case SubmitTurnCommand(
      :final playerId,
    ) when playerId == currentState.activePlayerId) {
      return !snapshot.runtimeState.hasSubmitted(playerId);
    }
    return currentState.activePlayerCanAct;
  }
}

class _RetryableServerCommand {
  final String saveId;
  final String actorPlayerId;
  final int? turn;
  final GameCommand command;
  final WireCommand wire;

  const _RetryableServerCommand({
    required this.saveId,
    required this.actorPlayerId,
    required this.turn,
    required this.command,
    required this.wire,
  });

  bool matches({
    required String saveId,
    required String actorPlayerId,
    required int? turn,
    required GameCommand command,
  }) {
    return this.saveId == saveId &&
        this.actorPlayerId == actorPlayerId &&
        this.turn == turn &&
        this.command == command;
  }

  bool isSameCommand({
    required String saveId,
    required String actorPlayerId,
    required GameCommand command,
  }) {
    return this.saveId == saveId &&
        this.actorPlayerId == actorPlayerId &&
        this.command == command;
  }
}
