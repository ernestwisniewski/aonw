import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

class NetworkSnapshotStore implements SnapshotStore {
  final String serverpodHost;
  final AuthToken token;
  final SnapshotCodec snapshotCodec;
  final MultiplayerBackendClient? backendClient;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;
  late final MultiplayerBackendClient _backendClient;
  late final bool _ownsBackend;
  var _closed = false;

  NetworkSnapshotStore({
    String? serverpodHost,
    required this.token,
    this.snapshotCodec = const SnapshotCodec(),
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
  Future<Snapshot?> latest(String saveId) async {
    try {
      final wire = await _backend().loadSnapshot(saveId);
      final snapshot = snapshotCodec.fromWire(wire);
      return Snapshot(
        offset: wire.offset,
        state: snapshot,
        createdAt: snapshot.save.savedAt,
      );
    } on sp.ServerpodClientException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) {
    throw UnsupportedError('NetworkSnapshotStore is read-only on the client');
  }

  MultiplayerBackendClient _backend() {
    if (_closed) throw StateError('Network snapshot store is closed.');
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
