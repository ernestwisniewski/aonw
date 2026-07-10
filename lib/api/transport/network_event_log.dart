import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';

class NetworkEventLog implements EventLog {
  final String serverpodHost;
  final AuthToken token;
  final EventCodec eventCodec;
  final MultiplayerBackendClient? backendClient;

  NetworkEventLog({
    String? serverpodHost,
    required this.token,
    this.eventCodec = const EventCodec(),
    this.backendClient,
  }) : serverpodHost = _resolveServerpodHost(serverpodHost, backendClient);

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
    final events = await _backend().listEvents(saveId, 0);
    var latest = 0;
    for (final event in events) {
      if (event.offset > latest) latest = event.offset;
    }
    return latest;
  }

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    final events = await _backend().listEvents(saveId, offset);
    for (final wire in events) {
      final command = eventCodec.commandFromWire(wire);
      if (command == null) continue;
      yield LoggedCommand(
        offset: wire.offset,
        timestamp: wire.timestamp,
        turn: wire.tick ?? 0,
        actorPlayerId: wire.actorPlayerId,
        command: command,
        events: eventCodec.eventsFromWire(wire),
      );
    }
  }

  MultiplayerBackendClient _backend() {
    return backendClient ??
        ServerpodMultiplayerBackendClient(
          serverpodHost: serverpodHost,
          token: token,
        );
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
