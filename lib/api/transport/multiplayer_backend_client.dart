import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

abstract interface class MultiplayerBackendClient {
  Future<List<WireMatch>> listMatches();

  Future<WireMatch> createMatch(sp.CreateMatchRequest request);

  Future<WireSnapshot> loadSnapshot(String matchId);

  Future<List<WireEvent>> listEvents(String matchId, int afterOffset);

  Future<void> leaveMatch(String matchId);
}

class ServerpodMultiplayerBackendClient implements MultiplayerBackendClient {
  ServerpodMultiplayerBackendClient({
    required String serverpodHost,
    required AuthToken token,
  }) : _client = createServerpodClient(serverpodHost, token: token);

  final sp.Client _client;

  @override
  Future<List<WireMatch>> listMatches() {
    return _client.multiplayer.listMatches();
  }

  @override
  Future<WireMatch> createMatch(sp.CreateMatchRequest request) {
    return _client.multiplayer.createMatch(request);
  }

  @override
  Future<WireSnapshot> loadSnapshot(String matchId) {
    return _client.multiplayer.loadSnapshot(matchId);
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) {
    return _client.multiplayer.listEvents(matchId, afterOffset);
  }

  @override
  Future<void> leaveMatch(String matchId) {
    return _client.multiplayer.leaveMatch(matchId);
  }
}
