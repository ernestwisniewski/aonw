import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/services/game_activity_event_projector.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/protocol.dart';

class NetworkEventLog implements EventLog {
  final String serverpodHost;
  final AuthToken token;
  final EventCodec eventCodec;
  final String? recipientPlayerId;
  final MultiplayerBackendClient? backendClient;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;
  late final MultiplayerBackendClient _backendClient;
  late final bool _ownsBackend;
  var _closed = false;

  NetworkEventLog({
    String? serverpodHost,
    required this.token,
    this.recipientPlayerId,
    this.eventCodec = const EventCodec(),
    this.backendClient,
    this.authKeyProviderFactory,
  }) : serverpodHost = _resolveServerpodHost(serverpodHost, backendClient) {
    _ownsBackend = backendClient == null;
    _backendClient =
        backendClient ??
        ServerpodMultiplayerBackendClient(
          serverpodHost: this.serverpodHost,
          token: token,
          authKeyProviderFactory: authKeyProviderFactory,
        );
  }

  bool get isClosed => _closed;

  @override
  Future<void> append(String saveId, LoggedCommand command) {
    throw UnsupportedError('NetworkEventLog is read-only on the client');
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) {
    return readSince(saveId);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    await for (final wire in _wireEvents(saveId, afterOffset: 0)) {
      latest = wire.offset;
    }
    return latest;
  }

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    final afterOffset = offset <= 0 ? 0 : offset - 1;
    await for (final wire in _wireEvents(saveId, afterOffset: afterOffset)) {
      final command = eventCodec.commandFromWire(wire);
      final events = eventCodec.eventsFromWire(wire);
      yield LoggedCommand(
        offset: wire.offset,
        timestamp: wire.timestamp,
        turn: wire.turn,
        actorPlayerId: wire.actorPlayerId,
        commandTick: wire.tick ?? 0,
        command: command,
        events: events,
        activity: _activityFor(events),
      );
    }
  }

  List<LoggedActivityEntry> _activityFor(List<GameEvent> events) {
    final playerId = recipientPlayerId;
    if (playerId == null || playerId.isEmpty) return const [];
    return List.unmodifiable([
      for (var index = 0; index < events.length; index++)
        if (GameActivityEventProjector.isActivityWorthy(events[index]))
          LoggedActivityEntry(
            eventIndex: index,
            playerId: playerId,
            event: events[index],
            context: GameActivityContext.empty,
          ),
    ]);
  }

  Stream<WireEvent> _wireEvents(
    String saveId, {
    required int afterOffset,
  }) async* {
    final backend = _backend();
    var cursor = afterOffset;
    while (true) {
      final page = await backend.listEvents(saveId, cursor);
      if (page.length > multiplayerEventPageSize) {
        throw StateError(
          'Multiplayer event page exceeded $multiplayerEventPageSize entries.',
        );
      }
      for (final wire in page) {
        if (wire.offset <= cursor) {
          throw StateError(
            'Multiplayer event offsets must increase strictly: '
            '${wire.offset} followed $cursor.',
          );
        }
        cursor = wire.offset;
        yield wire;
      }
      if (page.length < multiplayerEventPageSize) return;
    }
  }

  MultiplayerBackendClient _backend() {
    if (_closed) throw StateError('Network event log is closed.');
    return _backendClient;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsBackend) _backendClient.close();
  }
}

String _resolveServerpodHost(
  String? serverpodHost,
  MultiplayerBackendClient? backendClient,
) {
  if (backendClient != null) return '';
  if (serverpodHost == null) {
    throw ArgumentError('Expected serverpodHost or backendClient.');
  }
  return serverpodHost;
}
