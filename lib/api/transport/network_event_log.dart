import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw_core/protocol.dart';

class NetworkEventLog implements EventLog {
  static const _eventPageSize = 256;

  final String serverpodHost;
  final AuthToken token;
  final EventCodec eventCodec;
  final MultiplayerBackendClient? backendClient;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;

  NetworkEventLog({
    String? serverpodHost,
    required this.token,
    this.eventCodec = const EventCodec(),
    this.backendClient,
    this.authKeyProviderFactory,
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

  Stream<WireEvent> _wireEvents(
    String saveId, {
    required int afterOffset,
  }) async* {
    final backend = _backend();
    var cursor = afterOffset;
    while (true) {
      final page = await backend.listEvents(saveId, cursor);
      if (page.length > _eventPageSize) {
        throw StateError(
          'Multiplayer event page exceeded $_eventPageSize entries.',
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
      if (page.length < _eventPageSize) return;
    }
  }

  MultiplayerBackendClient _backend() {
    return backendClient ??
        ServerpodMultiplayerBackendClient(
          serverpodHost: serverpodHost,
          token: token,
          authKeyProviderFactory: authKeyProviderFactory,
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
