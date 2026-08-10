import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/acknowledged_command_presentation.dart';
import 'package:aonw/api/transport/wire_command_message_id.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/wire_command_dispatcher.dart';
import 'package:aonw/game/application/services/accepted_engine_command_interaction_source.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

part 'network_command_transport_exceptions.dart';
part 'network_command_transport_retry.dart';
part 'network_command_transport_snapshot.dart';

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
        multiplayerVersion: kCurrentMultiplayerVersion,
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
    required GameClientState currentState,
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
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    int staleTickRetries = 0,
  }) async {
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
    final outgoing = _wireCommandForRetryableDispatch(
      saveId: saveId,
      actorPlayerId: actor,
      turn: turn,
      command: command,
    );
    final WireCommandAck ack;
    try {
      ack = await _sendWireCommand(
        saveId: saveId,
        wire: outgoing.wire,
        clientMessageId: outgoing.clientMessageId,
      );
    } on NetworkCommandConflictException catch (error) {
      final nextTick = _nextTickFromStaleTickError(error);
      if (_isStaleTickError(error) &&
          nextTick != null &&
          staleTickRetries < 2) {
        _clearRetryableCommand(outgoing.wire);
        tickGenerator.ensureAtLeast(nextTick);
        final snapshot = await gameRepository.load(saveId);
        _remember(saveId, snapshot);
        return _dispatch(
          saveId: saveId,
          currentState: _stateFromSnapshot(
            snapshot: snapshot,
            currentState: currentState,
            command: command,
            interactionSource: currentState,
          ),
          command: command,
          context: context,
          staleTickRetries: staleTickRetries + 1,
        );
      }
      if (_isStaleCommandVersionError(error)) {
        _clearRetryableCommand(outgoing.wire);
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
    _clearRetryableCommand(outgoing.wire);
    if (!ack.accepted) {
      if (_isStaleAckReason(ack.reason)) {
        return _snapshotRecoveryResult(
          saveId: saveId,
          currentState: currentState,
          command: command,
          snapshot: snapshot,
          offset: effectiveOffset,
        );
      }
      _remember(saveId, snapshot, offset: effectiveOffset);
      final nextState = _stateFromSnapshot(
        snapshot: snapshot,
        currentState: currentState,
        command: command,
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
      return acknowledgedCommandTransportResult(
        acknowledgment: ack,
        state: nextState,
        snapshot: snapshot,
        offset: effectiveOffset,
        events: rejectionEvents,
        uiEffects: commandRejectionUiEffects(reason),
      );
    }
    _remember(saveId, snapshot, offset: effectiveOffset);
    final localTransition = localReducer.acceptedNetworkCommandTransition(
      currentState,
      command,
      context,
    );
    final nextState = _stateFromSnapshot(
      snapshot: snapshot,
      currentState: currentState,
      command: command,
      interactionSource: localTransition.state,
    );
    final presentation = projectAcknowledgedCommandPresentation(
      localEffects: localTransition.uiEffects,
      movementExecutions: ack.movementExecutions,
    );
    return acknowledgedCommandTransportResult(
      acknowledgment: ack,
      state: nextState,
      uiEffects: presentation.interactionEffects,
      snapshot: snapshot,
      offset: effectiveOffset,
      events: eventCodec.eventsFromJsonList(ack.events),
      movementExecutions: presentation.movementExecutions,
      combatAnimations: eventCodec.combatAnimationFactsFromJsonList(ack.events),
    );
  }
}
