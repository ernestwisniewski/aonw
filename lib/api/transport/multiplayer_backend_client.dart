import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

abstract interface class MultiplayerBackendClient {
  Future<List<WireMatch>> listMatches();

  Future<WireMatch> createMatch(sp.CreateMatchRequest request);

  Future<WireSnapshot> loadSnapshot(String matchId);

  Future<List<WireEvent>> listEvents(String matchId, int afterOffset);

  Future<void> leaveMatch(String matchId);

  void close();
}

typedef MultiplayerServerpodClientFactory = sp.Client Function();

class ServerpodMultiplayerBackendClient implements MultiplayerBackendClient {
  ServerpodMultiplayerBackendClient({
    required String serverpodHost,
    required AuthToken token,
    ServerpodAuthKeyProviderFactory? authKeyProviderFactory,
    MultiplayerServerpodClientFactory? clientFactory,
  }) : _client =
           clientFactory?.call() ??
           _createConfiguredClient(
             serverpodHost: serverpodHost,
             token: token,
             authKeyProviderFactory: authKeyProviderFactory,
           );

  final sp.Client _client;
  var _closed = false;

  bool get isClosed => _closed;

  @override
  Future<List<WireMatch>> listMatches() {
    return _activeClient.multiplayer.listMatches();
  }

  @override
  Future<WireMatch> createMatch(sp.CreateMatchRequest request) {
    return _activeClient.multiplayer.createMatch(request);
  }

  @override
  Future<WireSnapshot> loadSnapshot(String matchId) {
    return _activeClient.multiplayer.loadSnapshot(matchId);
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) {
    return _activeClient.multiplayer.listEvents(matchId, afterOffset);
  }

  @override
  Future<void> leaveMatch(String matchId) {
    return _activeClient.multiplayer.leaveMatch(matchId);
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }

  sp.Client get _activeClient {
    if (_closed) throw StateError('Multiplayer backend client is closed.');
    return _client;
  }
}

sp.Client _createConfiguredClient({
  required String serverpodHost,
  required AuthToken token,
  required ServerpodAuthKeyProviderFactory? authKeyProviderFactory,
}) {
  final authKeyProvider = authKeyProviderFactory?.call();
  return createServerpodClient(
    serverpodHost,
    token: authKeyProvider == null ? token : null,
    authKeyProvider: authKeyProvider,
  );
}
