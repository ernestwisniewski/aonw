import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/acknowledged_command_presentation.dart';
import 'package:aonw/api/transport/wire_command_message_id.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/accepted_engine_command_interaction_source.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';
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
  /// Sends one delivery attempt of [wire]. Retries of the same command must
  /// reuse [clientMessageId] so the server can deduplicate them safely.
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  });
}

typedef CommandAuthTokenReader = Future<AuthToken> Function();
typedef ServerpodCommandClientFactory = sp.Client Function();

class ServerpodWireCommandDispatcher implements WireCommandDispatcher {
  final String serverpodHost;
  final Duration timeout;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;
  final ServerpodCommandClientFactory _clientFactory;
  sp.Client? _client;
  var _closed = false;

  ServerpodWireCommandDispatcher({
    required String serverpodHost,
    this.timeout = const Duration(seconds: 10),
    this.authKeyProviderFactory,
    ServerpodCommandClientFactory? clientFactory,
  }) : serverpodHost = serverpodHost,
       _clientFactory =
           clientFactory ??
           (() => _createCommandClient(serverpodHost, authKeyProviderFactory));

  bool get isClosed => _closed;

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    final client = _activeClient;
    if (authKeyProviderFactory == null) {
      client.authKeyProvider = ServerpodAuthTokenProvider(token);
    }
    final input = StreamController<sp.MultiplayerClientMessage>();
    StreamSubscription<sp.MultiplayerServerMessage>? subscription;
    final ack = Completer<WireCommandAck>();
    try {
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
          clientMessageId: clientMessageId,
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

  void close() {
    if (_closed) return;
    _closed = true;
    _client?.close();
    _client = null;
  }

  sp.Client get _activeClient {
    if (_closed) throw StateError('Serverpod command dispatcher is closed.');
    return _client ??= _clientFactory();
  }
}

sp.Client _createCommandClient(
  String serverpodHost,
  ServerpodAuthKeyProviderFactory? authKeyProviderFactory,
) {
  final authKeyProvider = authKeyProviderFactory?.call();
  return createServerpodClient(serverpodHost, authKeyProvider: authKeyProvider);
}

class NetworkCommandTransport implements CommandTransport {
  final AuthToken token;
  final CommandAuthTokenReader? tokenReader;
  final String actorPlayerId;
  final WireCommandDispatcher commandDispatcher;
  final CommandCodec commandCodec;
  final EventCodec eventCodec;
  final SnapshotCodec snapshotCodec;
  final ClientTickGenerator tickGenerator;
  final GameStateReducer localReducer;
  final GameRepository gameRepository;
  final WireCommandMessageIdGenerator messageIdGenerator;
  final bool _ownsCommandDispatcher;
  _RetryableServerCommand? _retryableCommand;
  final Map<String, int> _lastKnownTurnBySaveId = {};
  final Map<String, int> _lastKnownOffsetBySaveId = {};

  NetworkCommandTransport({
    String? serverpodHost,
    WireCommandDispatcher? commandDispatcher,
    required this.token,
    this.tokenReader,
    required this.actorPlayerId,
    this.commandCodec = const CommandCodec(),
    this.eventCodec = const EventCodec(),
    this.snapshotCodec = const SnapshotCodec(),
    required this.tickGenerator,
    required this.localReducer,
    required this.gameRepository,
    WireCommandMessageIdGenerator? messageIdGenerator,
  }) : _ownsCommandDispatcher = commandDispatcher == null,
       messageIdGenerator =
           messageIdGenerator ?? WireCommandMessageIdGenerator(),
       commandDispatcher =
           commandDispatcher ??
           ServerpodWireCommandDispatcher(
             serverpodHost:
                 serverpodHost ??
                 (throw ArgumentError(
                   'Expected serverpodHost or commandDispatcher for '
                   'NetworkCommandTransport.',
                 )),
           );

  /// Releases the dispatcher created by the convenience constructor.
  ///
  /// Injected dispatchers remain owned by their provider or caller.
  void close() {
    if (!_ownsCommandDispatcher) return;
    final owned = commandDispatcher;
    if (owned is ServerpodWireCommandDispatcher) owned.close();
  }

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
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
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    int staleTickRetries = 0,
  }) async {
    final domainCommand = command;
    final actor = context.actorPlayerId ?? actorPlayerId;
    final retryable = _retryableCommand;
    final turn =
        retryable != null &&
            retryable.isSameCommand(
              saveId: saveId,
              actorPlayerId: actor,
              command: domainCommand,
            )
        ? retryable.turn
        : await _turnFor(saveId);
    final outgoing = _wireCommandForRetryableDispatch(
      saveId: saveId,
      actorPlayerId: actor,
      turn: turn,
      command: domainCommand,
    );
    final wire = outgoing.wire;
    final WireCommandAck ack;
    try {
      ack = await _sendWireCommand(
        saveId: saveId,
        wire: wire,
        clientMessageId: outgoing.clientMessageId,
      );
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
          currentState: _stateFromSnapshot(
            snapshot: snapshot,
            currentState: currentState,
            command: domainCommand,
            interactionSource: currentState,
          ),
          command: domainCommand,
          context: context,
          staleTickRetries: staleTickRetries + 1,
        );
      }
      if (_isStaleCommandVersionError(error)) {
        _clearRetryableCommand(wire);
        return _reloadAfterStaleCommand(
          saveId: saveId,
          currentState: currentState,
          command: domainCommand,
        );
      }
      rethrow;
    }
    final snapshot = snapshotCodec.fromWire(ack.snapshot);
    final effectiveOffset = _effectiveOffset(ack.offset, snapshot);
    _clearRetryableCommand(wire);
    if (!ack.accepted) {
      if (_isStaleAckReason(ack.reason)) {
        return _snapshotRecoveryResult(
          saveId: saveId,
          currentState: currentState,
          command: domainCommand,
          snapshot: snapshot,
          offset: effectiveOffset,
        );
      }
      _rememberSnapshot(saveId, snapshot, offset: effectiveOffset);
      final nextState = _stateFromSnapshot(
        snapshot: snapshot,
        currentState: currentState,
        command: domainCommand,
        interactionSource: currentState,
      );
      final hasRejectionEvent = ack.events.any(
        (event) => event['type'] == SystemEventWire.commandRejectedType,
      );
      final reason = ack.reason?.trim();
      final rejectionEvents = eventCodec.eventsFromJsonList([
        ...ack.events,
        if (!hasRejectionEvent)
          SystemEventWire.commandRejected(
            reason: reason == null || reason.isEmpty
                ? 'command_rejected'
                : reason,
          ),
      ]);
      return CommandTransportResult(
        state: nextState,
        snapshot: snapshot,
        offset: effectiveOffset,
        events: rejectionEvents,
        storedSnapshot: true,
      );
    }
    _rememberSnapshot(saveId, snapshot, offset: effectiveOffset);
    final localTransition = localReducer.acceptedNetworkCommandTransition(
      currentState,
      domainCommand,
      context,
    );
    final nextState = _stateFromSnapshot(
      snapshot: snapshot,
      currentState: currentState,
      command: domainCommand,
      interactionSource: localTransition.state,
    );
    final presentation = projectAcknowledgedCommandPresentation(
      localEffects: localTransition.uiEffects,
      movementExecutions: ack.movementExecutions,
    );
    return CommandTransportResult(
      state: nextState,
      uiEffects: presentation.interactionEffects,
      snapshot: snapshot,
      offset: effectiveOffset,
      events: eventCodec.eventsFromJsonList(ack.events),
      movementExecutions: presentation.movementExecutions,
      combatAnimations: eventCodec.combatAnimationFactsFromJsonList(ack.events),
      storedSnapshot: true,
    );
  }

  ({WireCommand wire, String clientMessageId})
  _wireCommandForRetryableDispatch({
    required String saveId,
    required String actorPlayerId,
    required int? turn,
    required DomainCommand command,
  }) {
    final retryable = _retryableCommand;
    if (retryable != null &&
        retryable.matches(
          saveId: saveId,
          actorPlayerId: actorPlayerId,
          turn: turn,
          command: command,
        )) {
      return (wire: retryable.wire, clientMessageId: retryable.clientMessageId);
    }

    _retryableCommand = null;
    final wire = commandCodec.toWire(
      matchId: saveId,
      tick: tickGenerator.next(),
      turn: turn,
      actorPlayerId: actorPlayerId,
      command: command,
    );
    return (wire: wire, clientMessageId: messageIdGenerator.next());
  }

  Future<WireCommandAck> _sendWireCommand({
    required String saveId,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    try {
      final currentToken = await tokenReader?.call() ?? token;
      return await commandDispatcher.send(
        saveId: saveId,
        token: currentToken,
        afterOffset: _lastKnownOffsetBySaveId[saveId] ?? 0,
        wire: wire,
        clientMessageId: clientMessageId,
      );
    } catch (error) {
      if (_isRetryableCommandSendError(error)) {
        _retryableCommand = _RetryableServerCommand(
          saveId: saveId,
          actorPlayerId: wire.actorPlayerId,
          turn: wire.turn,
          command: commandCodec.fromWire(wire),
          wire: wire,
          clientMessageId: clientMessageId,
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
      final turn = snapshot.domain.turn;
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
    required DomainCommand command,
  }) async {
    final snapshot = await gameRepository.load(saveId);
    _rememberSnapshot(saveId, snapshot);
    final nextState = _stateFromSnapshot(
      snapshot: snapshot,
      currentState: currentState,
      command: command,
      interactionSource: currentState,
    );
    return CommandTransportResult(
      state: nextState,
      snapshot: snapshot,
      offset: snapshot.eventLogOffset,
      storedSnapshot: true,
    );
  }

  CommandTransportResult _snapshotRecoveryResult({
    required String saveId,
    required GameState currentState,
    required DomainCommand command,
    required SaveSnapshot snapshot,
    required int offset,
  }) {
    _rememberSnapshot(saveId, snapshot, offset: offset);
    final nextState = _stateFromSnapshot(
      snapshot: snapshot,
      currentState: currentState,
      command: command,
      interactionSource: currentState,
    );
    return CommandTransportResult(
      state: nextState,
      snapshot: snapshot,
      offset: offset,
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

  bool _isStaleAckReason(String? reason) {
    return reason == 'stale_tick' || reason == 'stale_turn';
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
    _lastKnownTurnBySaveId[saveId] = snapshot.domain.turn;
    _lastKnownOffsetBySaveId[saveId] = offset ?? snapshot.eventLogOffset;
  }

  bool _activePlayerCanActAfter({
    required GameState currentState,
    required DomainCommand command,
    required SaveSnapshot snapshot,
  }) {
    if (command case SubmitTurnCommand(
      :final playerId,
    ) when playerId == currentState.activePlayerId) {
      return !snapshot.session.hasSubmitted(playerId);
    }
    return currentState.activePlayerCanAct;
  }

  GameState _stateFromSnapshot({
    required SaveSnapshot snapshot,
    required GameState currentState,
    required DomainCommand command,
    required GameState interactionSource,
  }) {
    final authoritative = snapshot.toGameState(
      activePlayerId: currentState.activePlayerId,
      activePlayerCanAct: _activePlayerCanActAfter(
        currentState: currentState,
        command: command,
        snapshot: snapshot,
      ),
    );
    return MultiplayerInteractionReconciler.reconcile(
      authoritativeState: authoritative,
      interactionSource: interactionSource,
    );
  }
}

class _RetryableServerCommand {
  final String saveId;
  final String actorPlayerId;
  final int? turn;
  final DomainCommand command;
  final WireCommand wire;
  final String clientMessageId;

  const _RetryableServerCommand({
    required this.saveId,
    required this.actorPlayerId,
    required this.turn,
    required this.command,
    required this.wire,
    required this.clientMessageId,
  });

  bool matches({
    required String saveId,
    required String actorPlayerId,
    required int? turn,
    required DomainCommand command,
  }) {
    return this.saveId == saveId &&
        this.actorPlayerId == actorPlayerId &&
        this.turn == turn &&
        this.command == command;
  }

  bool isSameCommand({
    required String saveId,
    required String actorPlayerId,
    required DomainCommand command,
  }) {
    return this.saveId == saveId &&
        this.actorPlayerId == actorPlayerId &&
        this.command == command;
  }
}
