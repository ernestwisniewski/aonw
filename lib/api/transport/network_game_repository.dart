import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/multiplayer_snapshot_cache_key.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

class NetworkGameRepository implements GameRepository {
  final String serverpodHost;
  final String userId;
  final AuthToken token;
  final SnapshotCodec snapshotCodec;
  final SnapshotStore? snapshotCache;
  final int fallbackMaxPlayers;
  final MultiplayerBackendClient? backendClient;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;
  late final MultiplayerBackendClient _backendClient;
  late final bool _ownsBackend;
  var _closed = false;

  NetworkGameRepository({
    String? serverpodHost,
    required this.userId,
    required this.token,
    this.snapshotCodec = const SnapshotCodec(),
    this.snapshotCache,
    this.fallbackMaxPlayers = 4,
    this.backendClient,
    this.authKeyProviderFactory,
  }) : serverpodHost = _resolveServerpodHost(serverpodHost, backendClient) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Expected a non-empty multiplayer account id',
      );
    }
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
  String defaultSaveName(String mapDisplayName, DateTime now) {
    return '$mapDisplayName - ${now.year}-${_two(now.month)}-${_two(now.day)}';
  }

  @override
  Future<String> create(NewGameRequest request) async {
    final maxPlayers = request.players.isEmpty
        ? fallbackMaxPlayers
        : request.players.length;
    final match = await _backend().createMatch(
      sp.CreateMatchRequest(
        name: request.name,
        mapName: request.mapName,
        maxPlayers: maxPlayers,
        minPlayers: maxPlayers,
        private: false,
        countryId: request.players.firstOrNull?.country.name,
      ),
    );
    return match.id;
  }

  @override
  Future<List<GameSaveIndex>> list() async {
    final matches = await _backend().listMatches();
    return matches.map(_indexFromMatch).toList();
  }

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    final snapshot = await _loadNetworkSnapshot(saveId);
    if (snapshot == null) {
      throw StateError('Save snapshot not found: $saveId');
    }
    return snapshot.state;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) {
    throw UnsupportedError(
      'NetworkGameRepository is read-only; dispatch commands to mutate matches',
    );
  }

  @override
  Future<void> delete(String saveId) async {
    await _backend().leaveMatch(saveId);
  }

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) {
    throw UnsupportedError(
      'NetworkGameRepository does not persist client camera state yet',
    );
  }

  GameSaveIndex _indexFromMatch(WireMatch match) {
    return GameSaveIndex(
      id: match.id,
      name: match.name,
      mapName: match.mapName,
      mapSource: MapSource.asset,
      turn: match.turn,
      savedAt: match.createdAt,
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<Snapshot?> _loadNetworkSnapshot(String saveId) async {
    try {
      final wire = await _backend().loadSnapshot(saveId);
      final state = snapshotCodec.fromWire(wire);
      final snapshot = Snapshot(state: state, createdAt: state.save.savedAt);
      await _saveCachedSnapshot(saveId, snapshot);
      return snapshot;
    } catch (error) {
      if (error is sp.ServerpodClientException && error.statusCode == 404) {
        return null;
      }
      if (!_canReadCachedSnapshot(error)) rethrow;
      final cached = await snapshotCache?.latest(_cacheKey(saveId));
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _saveCachedSnapshot(String saveId, Snapshot snapshot) async {
    final cache = snapshotCache;
    if (cache == null) return;
    try {
      await cache.save(_cacheKey(saveId), snapshot);
    } catch (_) {
      // Cache writes are best-effort; a fresh network snapshot should still load.
    }
  }

  bool _canReadCachedSnapshot(Object error) {
    return error is TimeoutException ||
        error is sp.MethodStreamException ||
        (error is sp.ServerpodClientException &&
            (error.statusCode < 0 || error.statusCode >= 500));
  }

  String _cacheKey(String saveId) {
    return multiplayerSnapshotCacheKey(userId: userId, matchId: saveId);
  }

  MultiplayerBackendClient _backend() {
    if (_closed) throw StateError('Network game repository is closed.');
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
