import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

class NetworkSnapshotStore implements SnapshotStore {
  final String serverpodHost;
  final AuthToken token;
  final SnapshotCodec snapshotCodec;
  final MultiplayerBackendClient? backendClient;

  NetworkSnapshotStore({
    String? serverpodHost,
    required this.token,
    this.snapshotCodec = const SnapshotCodec(),
    this.backendClient,
  }) : serverpodHost = _resolveServerpodHost(serverpodHost, backendClient);

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
